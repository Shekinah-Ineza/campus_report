import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/incident.dart';
import '../models/incident_enums.dart';
import '../models/incident_filter.dart';
import '../models/status_change.dart';
import 'auth_providers.dart';
import 'repository_providers.dart';

// ---------------------------------------------------------------- Reading

/// Live list of all incidents, newest first.
final incidentsProvider = StreamProvider<List<Incident>>(
  (ref) => ref.watch(incidentRepositoryProvider).watchIncidents(),
);

/// A single incident, kept live so status changes appear instantly.
final incidentProvider = StreamProvider.autoDispose.family<Incident?, String>(
  (ref, id) => ref.watch(incidentRepositoryProvider).watchIncident(id),
);

/// The status history (audit trail) for one incident.
final statusHistoryProvider =
    StreamProvider.autoDispose.family<List<StatusChange>, String>(
  (ref, id) => ref.watch(incidentRepositoryProvider).watchHistory(id),
);

// --------------------------------------------------------------- Filtering

class IncidentFilterNotifier extends Notifier<IncidentFilter> {
  @override
  IncidentFilter build() => const IncidentFilter();

  void setQuery(String query) => state = _copy(query: query);
  void setCategory(IncidentCategory? category) => state = _copy(category: () => category);
  void setStatus(IncidentStatus? status) => state = _copy(status: () => status);
  void setMineOnly(bool mineOnly) => state = _copy(mineOnly: mineOnly);
  void setSort(IncidentSort sort) => state = _copy(sort: sort);
  void reset() => state = IncidentFilter(sort: state.sort);

  // Nullable fields are passed as functions so "set to null" and
  // "leave unchanged" can be told apart.
  IncidentFilter _copy({
    String? query,
    IncidentCategory? Function()? category,
    IncidentStatus? Function()? status,
    bool? mineOnly,
    IncidentSort? sort,
  }) =>
      IncidentFilter(
        query: query ?? state.query,
        category: category != null ? category() : state.category,
        status: status != null ? status() : state.status,
        mineOnly: mineOnly ?? state.mineOnly,
        sort: sort ?? state.sort,
      );
}

final incidentFilterProvider =
    NotifierProvider<IncidentFilterNotifier, IncidentFilter>(IncidentFilterNotifier.new);

/// The list the feed actually shows: live data with the filter applied.
/// Recomputes whenever either the data or the filter changes.
final filteredIncidentsProvider = Provider<AsyncValue<List<Incident>>>((ref) {
  final filter = ref.watch(incidentFilterProvider);
  final uid = ref.watch(authStateProvider).valueOrNull?.uid;
  return ref
      .watch(incidentsProvider)
      .whenData((list) => filter.apply(list, currentUid: uid));
});

// --------------------------------------------------------------- Writing

/// Submits a new report: uploads the optional photo to Cloudinary, then
/// writes the report (with the photo URL) to Firestore.
class ReportFormController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> submit({
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    File? image,
  }) async {
    final reporter = ref.read(currentUserProfileProvider).valueOrNull;
    if (reporter == null) {
      state = AsyncError('Sign in to submit a report.', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final incidents = ref.read(incidentRepositoryProvider);
      final id = incidents.newIncidentId();
      String? imageUrl;
      if (image != null) {
        imageUrl = await ref.read(cloudinaryRepositoryProvider).uploadIncidentImage(image);
      }
      await incidents.createIncident(
        id: id,
        reporter: reporter,
        title: title,
        description: description,
        category: category,
        location: location,
        imageUrl: imageUrl,
      );
    });
    return !state.hasError;
  }
}

final reportFormControllerProvider =
    AsyncNotifierProvider.autoDispose<ReportFormController, void>(ReportFormController.new);

/// Staff-only status updates.
class StatusUpdateController extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> updateStatus(Incident incident, IncidentStatus newStatus, String note) async {
    final staff = ref.read(currentUserProfileProvider).valueOrNull;
    if (staff == null || !staff.isStaff) {
      state = AsyncError('Only staff can change a report\'s status.', StackTrace.current);
      return false;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(incidentRepositoryProvider).updateStatus(
            incident: incident,
            newStatus: newStatus,
            staff: staff,
            note: note,
          ),
    );
    return !state.hasError;
  }
}

final statusUpdateControllerProvider =
    AsyncNotifierProvider.autoDispose<StatusUpdateController, void>(StatusUpdateController.new);
