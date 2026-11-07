import 'package:campus_report/core/format.dart';
import 'package:campus_report/models/app_user.dart';
import 'package:campus_report/models/incident.dart';
import 'package:campus_report/models/incident_enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Incident.fromMap reads Firestore data', () {
    final created = DateTime(2026, 3, 1, 10);
    final incident = Incident.fromMap('id1', {
      'title': 'Leaking roof',
      'description': 'Water drips onto desks.',
      'category': 'facilities',
      'location': 'Lecture hall 2',
      'status': 'in_progress',
      'reporterId': 'u1',
      'reporterName': 'Ama',
      'createdAt': Timestamp.fromDate(created),
      'updatedAt': Timestamp.fromDate(created),
      'upvotes': ['u2', 'u3'],
      'imageUrl': null,
      'lastNote': 'Roofer booked',
    });
    expect(incident.category, IncidentCategory.facilities);
    expect(incident.status, IncidentStatus.inProgress);
    expect(incident.createdAt, created);
    expect(incident.upvotes, hasLength(2));
    expect(incident.hasImage, isFalse);
    expect(incident.isUpvotedBy('u2'), isTrue);
  });

  test('unknown values fall back safely', () {
    final incident = Incident.fromMap('id2', {'category': 'aliens', 'status': '???'});
    expect(incident.category, IncidentCategory.other);
    expect(incident.status, IncidentStatus.submitted);
  });

  test('only resolved and rejected count as closed', () {
    expect(IncidentStatus.inReview.isOpen, isTrue);
    expect(IncidentStatus.resolved.isOpen, isFalse);
    expect(IncidentStatus.rejected.isOpen, isFalse);
  });

  test('AppUser role parsing defaults to student', () {
    expect(AppUser.fromMap('u', {'role': 'staff'}).isStaff, isTrue);
    expect(AppUser.fromMap('u', {'role': 'admin?'}).isStaff, isFalse);
    expect(AppUser.fromMap('u', {}).role, UserRole.student);
  });

  test('timeAgo formats relative times', () {
    final now = DateTime(2026, 5, 10, 12);
    expect(timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'just now');
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5m ago');
    expect(timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3h ago');
    expect(timeAgo(now.subtract(const Duration(days: 2)), now: now), '2d ago');
    expect(timeAgo(DateTime(2026, 1, 2), now: now), '2 Jan 2026');
  });
}
