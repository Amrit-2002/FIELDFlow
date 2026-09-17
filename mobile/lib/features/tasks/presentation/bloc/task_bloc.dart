import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_tasks_usecase.dart';
import 'task_event.dart';
import 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  final GetTasksUseCase _getTasksUseCase;
  StreamSubscription? _tasksSubscription;

  TaskBloc({required GetTasksUseCase getTasksUseCase})
      : _getTasksUseCase = getTasksUseCase,
        super(TaskLoading()) {
    on<LoadTasks>(_onLoadTasks);
    on<TasksUpdated>(_onTasksUpdated);
    on<SearchTasks>(_onSearchTasks);
    on<FilterByStatus>(_onFilterByStatus);
    on<FilterByPriority>(_onFilterByPriority);
    on<RefreshTasks>(_onRefreshTasks);
  }

  void _onLoadTasks(LoadTasks event, Emitter<TaskState> emit) {
    emit(TaskLoading());
    _tasksSubscription?.cancel();
    _tasksSubscription = _getTasksUseCase.watch().listen(
      (tasks) => add(TasksUpdated(tasks)),
      onError: (err) => emit(TaskError(err.toString())),
    );
    // Trigger remote sync
    _getTasksUseCase.refresh();
  }

  void _onTasksUpdated(TasksUpdated event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final current = state as TaskLoaded;
      emit(current.copyWith(tasks: event.tasks));
    } else {
      emit(TaskLoaded(tasks: event.tasks));
    }
  }

  void _onSearchTasks(SearchTasks event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final current = state as TaskLoaded;
      emit(current.copyWith(searchQuery: event.query));
    }
  }

  void _onFilterByStatus(FilterByStatus event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final current = state as TaskLoaded;
      emit(current.copyWith(selectedStatus: event.status, clearStatus: event.status == null));
    }
  }

  void _onFilterByPriority(FilterByPriority event, Emitter<TaskState> emit) {
    if (state is TaskLoaded) {
      final current = state as TaskLoaded;
      emit(current.copyWith(selectedPriority: event.priority, clearPriority: event.priority == null));
    }
  }

  Future<void> _onRefreshTasks(RefreshTasks event, Emitter<TaskState> emit) async {
    try {
      await _getTasksUseCase.refresh();
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _tasksSubscription?.cancel();
    return super.close();
  }
}
