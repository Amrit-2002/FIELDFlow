import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_flow/features/tasks/domain/entities/priority.dart';
import 'package:field_flow/features/tasks/domain/entities/task.dart';
import 'package:field_flow/features/tasks/domain/entities/task_status.dart';
import 'package:field_flow/features/tasks/presentation/widgets/conflict_resolution_dialog.dart';

void main() {
  final localTask = Task(
    id: 'task-conflict-1',
    title: 'Solar Inverter Inspection',
    description: 'Ground fault error',
    customerName: 'Solar Systems Co',
    customerPhone: '+1-555-1212',
    address: '500 Solar Way',
    latitude: 37.77,
    longitude: -122.41,
    priority: Priority.urgent,
    status: TaskStatus.completed,
    scheduledAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    serverVersion: 2,
    localUpdatedAt: DateTime.now(),
    syncStatus: SyncStatus.conflict,
  );

  testWidgets('ConflictResolutionDialog renders comparison and invokes resolution callback', (tester) async {
    bool? resolvedWithKeepLocal;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => ConflictResolutionDialog(
                    localTask: localTask,
                    serverData: const {'status': 'CANCELLED', 'version': 3},
                    onResolve: (keepLocal) {
                      resolvedWithKeepLocal = keepLocal;
                    },
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pumpAndSettle();

    // Verify Title and comparison texts
    expect(find.text('Version Conflict Detected'), findsOneWidget);
    expect(find.textContaining('Your Local Version'), findsOneWidget);
    expect(find.text('Server Version'), findsOneWidget);
    expect(find.textContaining('Completed'), findsOneWidget);
    expect(find.textContaining('CANCELLED'), findsOneWidget);

    // Tap "Keep My Changes"
    await tester.tap(find.text('Keep My Changes'));
    await tester.pumpAndSettle();

    expect(resolvedWithKeepLocal, isTrue);
  });
}
