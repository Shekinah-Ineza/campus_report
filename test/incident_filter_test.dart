import 'package:campus_report/models/incident.dart';
import 'package:campus_report/models/incident_enums.dart';
import 'package:campus_report/models/incident_filter.dart';
import 'package:flutter_test/flutter_test.dart';

Incident makeIncident({
  required String id,
  String title = 'Broken light',
  String description = 'The corridor light is off.',
  String location = 'Block A',
  IncidentCategory category = IncidentCategory.electricity,
  IncidentStatus status = IncidentStatus.submitted,
  String reporterId = 'u1',
  List<String> upvotes = const [],
  required DateTime createdAt,
}) =>
    Incident(
      id: id,
      title: title,
      description: description,
      category: category,
      location: location,
      status: status,
      reporterId: reporterId,
      reporterName: 'Test',
      createdAt: createdAt,
      updatedAt: createdAt,
      upvotes: upvotes,
    );

void main() {
  final day1 = DateTime(2026, 1, 1);
  final day2 = DateTime(2026, 1, 2);
  final day3 = DateTime(2026, 1, 3);

  final incidents = [
    makeIncident(id: 'a', createdAt: day1, title: 'No water in hostel',
        category: IncidentCategory.water, reporterId: 'u1', upvotes: ['x', 'y']),
    makeIncident(id: 'b', createdAt: day2, location: 'Library',
        status: IncidentStatus.resolved, reporterId: 'u2'),
    makeIncident(id: 'c', createdAt: day3, title: 'Broken chair',
        category: IncidentCategory.furniture, reporterId: 'u1', upvotes: ['x']),
  ];

  List<String> ids(List<Incident> list) => list.map((i) => i.id).toList();

  test('no filter returns everything, newest first', () {
    expect(ids(const IncidentFilter().apply(incidents)), ['c', 'b', 'a']);
  });

  test('search matches title, description and location, case-insensitively', () {
    expect(ids(const IncidentFilter(query: 'WATER').apply(incidents)), ['a']);
    expect(ids(const IncidentFilter(query: 'library').apply(incidents)), ['b']);
  });

  test('filters by category and status', () {
    expect(ids(const IncidentFilter(category: IncidentCategory.furniture).apply(incidents)), ['c']);
    expect(ids(const IncidentFilter(status: IncidentStatus.resolved).apply(incidents)), ['b']);
  });

  test('"My reports" keeps only the current user\'s reports', () {
    expect(ids(const IncidentFilter(mineOnly: true).apply(incidents, currentUid: 'u1')), ['c', 'a']);
  });

  test('filters combine', () {
    const filter = IncidentFilter(mineOnly: true, category: IncidentCategory.water);
    expect(ids(filter.apply(incidents, currentUid: 'u1')), ['a']);
  });

  test('sorts oldest first and by most affected', () {
    expect(ids(const IncidentFilter(sort: IncidentSort.oldest).apply(incidents)), ['a', 'b', 'c']);
    expect(ids(const IncidentFilter(sort: IncidentSort.mostAffected).apply(incidents)), ['a', 'c', 'b']);
  });

  test('isActive ignores sort but notices filters', () {
    expect(const IncidentFilter(sort: IncidentSort.oldest).isActive, isFalse);
    expect(const IncidentFilter(query: ' x ').isActive, isTrue);
  });
}
