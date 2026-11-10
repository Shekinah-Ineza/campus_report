import 'package:campus_report/models/incident_enums.dart';
import 'package:campus_report/ui/widgets/status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StatusChip shows the status label', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: StatusChip(status: IncidentStatus.inProgress)),
    ));
    expect(find.text('In progress'), findsOneWidget);
  });
}
