import 'package:equatable/equatable.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';

abstract class TaskState extends Equatable {
  const TaskState();

  @override
  List<Object?> get props => [];
}

class TaskLoading extends TaskState {}

class TaskLoaded extends TaskState {
  final List<Task> tasks;
  final String searchQuery;
  final TaskStatus? selectedStatus;
  final Priority? selectedPriority;

  const TaskLoaded({
    required this.tasks,
    this.searchQuery = '',
    this.selectedStatus,
    this.selectedPriority,
  });

  List<Task> get filteredTasks {
    return tasks.where((t) {
      if (selectedStatus != null && t.status != selectedStatus) return false;
      if (selectedPriority != null && t.priority != selectedPriority) return false;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final match = t.title.toLowerCase().contains(query) ||
            t.customerName.toLowerCase().contains(query) ||
            t.address.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();
  }

  TaskLoaded copyWith({
    List<Task>? tasks,
    String? searchQuery,
    TaskStatus? selectedStatus,
    Priority? selectedPriority,
    bool clearStatus = false,
    bool clearPriority = false,
  }) {
    return TaskLoaded(
      tasks: tasks ?? this.tasks,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedPriority: clearPriority ? null : (selectedPriority ?? this.selectedPriority),
    );
  }

  @override
  List<Object?> get props => [tasks, searchQuery, selectedStatus, selectedPriority];
}

class TaskError extends TaskState {
  final String message;
  const TaskError(this.message);

  @override
  List<Object?> get props => [message];
}
