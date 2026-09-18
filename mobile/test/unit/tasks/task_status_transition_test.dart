import 'package:flutter_test/flutter_test.dart';
import 'package:field_flow/features/tasks/domain/entities/task_status.dart';

void main() {
  group('TaskStatus State Machine Transitions', () {
    test('ASSIGNED should only transition to ACCEPTED or CANCELLED', () {
      const status = TaskStatus.assigned;
      expect(status.canTransitionTo(TaskStatus.accepted), isTrue);
      expect(status.canTransitionTo(TaskStatus.cancelled), isTrue);
      expect(status.canTransitionTo(TaskStatus.inProgress), isFalse);
      expect(status.canTransitionTo(TaskStatus.completed), isFalse);
    });

    test('ACCEPTED should only transition to IN_PROGRESS or CANCELLED', () {
      const status = TaskStatus.accepted;
      expect(status.canTransitionTo(TaskStatus.inProgress), isTrue);
      expect(status.canTransitionTo(TaskStatus.cancelled), isTrue);
      expect(status.canTransitionTo(TaskStatus.assigned), isFalse);
      expect(status.canTransitionTo(TaskStatus.completed), isFalse);
    });

    test('IN_PROGRESS should only transition to COMPLETED or CANCELLED', () {
      const status = TaskStatus.inProgress;
      expect(status.canTransitionTo(TaskStatus.completed), isTrue);
      expect(status.canTransitionTo(TaskStatus.cancelled), isTrue);
      expect(status.canTransitionTo(TaskStatus.assigned), isFalse);
      expect(status.canTransitionTo(TaskStatus.accepted), isFalse);
    });

    test('COMPLETED is a terminal state and cannot transition to any other state', () {
      const status = TaskStatus.completed;
      expect(status.allowedTransitions, isEmpty);
      expect(status.canTransitionTo(TaskStatus.inProgress), isFalse);
      expect(status.canTransitionTo(TaskStatus.cancelled), isFalse);
      expect(status.canTransitionTo(TaskStatus.assigned), isFalse);
    });

    test('CANCELLED is a terminal state and cannot transition to any other state', () {
      const status = TaskStatus.cancelled;
      expect(status.allowedTransitions, isEmpty);
      expect(status.canTransitionTo(TaskStatus.assigned), isFalse);
      expect(status.canTransitionTo(TaskStatus.inProgress), isFalse);
    });

    test('Transitioning to the exact same status is always considered valid', () {
      for (final status in TaskStatus.values) {
        expect(status.canTransitionTo(status), isTrue);
      }
    });

    test('String parsing and serialization round-trip works correctly', () {
      expect(TaskStatus.fromString('ASSIGNED'), TaskStatus.assigned);
      expect(TaskStatus.fromString('IN_PROGRESS'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('COMPLETED'), TaskStatus.completed);
      expect(TaskStatus.inProgress.toServerString(), 'IN_PROGRESS');
      expect(TaskStatus.completed.toServerString(), 'COMPLETED');
    });
  });
}

