import 'package:equatable/equatable.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';

abstract class TaskEvent extends Equatable {
  const TaskEvent();

  @override
  List<Object?> get props => [];
}

class LoadTasks extends TaskEvent {}

class TasksUpdated extends TaskEvent {
  final List<Task> tasks;
  const TasksUpdated(this.tasks);

  @override
  List<Object?> get props => [tasks];
}

class SearchTasks extends TaskEvent {
  final String query;
  const SearchTasks(this.query);

  @override
  List<Object?> get props => [query];
}

class FilterByStatus extends TaskEvent {
  final TaskStatus? status;
  const FilterByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class FilterByPriority extends TaskEvent {
  final Priority? priority;
  const FilterByPriority(this.priority);

  @override
  List<Object?> get props => [priority];
}

class RefreshTasks extends TaskEvent {}
