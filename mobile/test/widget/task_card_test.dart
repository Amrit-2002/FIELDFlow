import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_flow/features/tasks/domain/entities/priority.dart';
import 'package:field_flow/features/tasks/domain/entities/task.dart';
import 'package:field_flow/features/tasks/domain/entities/task_status.dart';
import 'package:field_flow/features/tasks/presentation/widgets/task_card.dart';

void main() {
  final testTask = Task(
    id: 'task-101',
    title: 'HVAC Chiller Sensor Diagnostics',
    description: 'Investigate low airflow on 3rd floor',
    customerName: 'Apex Data Center',
    customerPhone: '+1-555-9080',
    address: '100 Technology Parkway, Suite 200',
    latitude: 37.7749,
    longitude: -122.4194,
    priority: Priority.high,
    status: TaskStatus.inProgress,
    scheduledAt: DateTime(2026, 9, 20, 10, 30),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    serverVersion: 3,
    localUpdatedAt: DateTime.now(),
    syncStatus: SyncStatus.synced,
  );

  testWidgets('TaskCard renders title, customer name, priority and responds to tap', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: testTask,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    // Verify Title
    expect(find.text('HVAC Chiller Sensor Diagnostics'), findsOneWidget);

    // Verify Customer Name
    expect(find.text('Apex Data Center'), findsOneWidget);

    // Verify Address
    expect(find.text('100 Technology Parkway, Suite 200'), findsOneWidget);

    // Verify Priority and Status Badge
    expect(find.text('High'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);

    // Verify Version
    expect(find.text('v3'), findsOneWidget);

    // Tap Card
    await tester.tap(find.byType(TaskCard));
    expect(tapped, isTrue);
  });
}
