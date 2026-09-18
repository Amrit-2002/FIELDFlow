enum TaskStatus {
  assigned,
  accepted,
  inProgress,
  completed,
  cancelled;

  static TaskStatus fromString(String val) {
    switch (val.toUpperCase().replaceAll('-', '_')) {
      case 'ASSIGNED':
        return TaskStatus.assigned;
      case 'ACCEPTED':
        return TaskStatus.accepted;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'COMPLETED':
        return TaskStatus.completed;
      case 'CANCELLED':
        return TaskStatus.cancelled;
      default:
        return TaskStatus.assigned;
    }
  }

  String toServerString() {
    switch (this) {
      case TaskStatus.assigned:
        return 'ASSIGNED';
      case TaskStatus.accepted:
        return 'ACCEPTED';
      case TaskStatus.inProgress:
        return 'IN_PROGRESS';
      case TaskStatus.completed:
        return 'COMPLETED';
      case TaskStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get displayName {
    switch (this) {
      case TaskStatus.assigned:
        return 'Assigned';
      case TaskStatus.accepted:
        return 'Accepted';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  List<TaskStatus> get allowedTransitions {
    switch (this) {
      case TaskStatus.assigned:
        return [TaskStatus.accepted, TaskStatus.cancelled];
      case TaskStatus.accepted:
        return [TaskStatus.inProgress, TaskStatus.cancelled];
      case TaskStatus.inProgress:
        return [TaskStatus.completed, TaskStatus.cancelled];
      case TaskStatus.completed:
      case TaskStatus.cancelled:
        return [];
    }
  }

  bool canTransitionTo(TaskStatus target) {
    if (this == target) return true;
    return allowedTransitions.contains(target);
  }
}

