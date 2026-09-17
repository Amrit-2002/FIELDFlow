import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../../domain/usecases/get_task_details_usecase.dart';
import '../../domain/usecases/update_task_status_usecase.dart';

// Events
abstract class TaskDetailsEvent extends Equatable {
  const TaskDetailsEvent();
  @override
  List<Object?> get props => [];
}

class LoadTaskDetails extends TaskDetailsEvent {
  final String taskId;
  const LoadTaskDetails(this.taskId);
  @override
  List<Object?> get props => [taskId];
}

class TaskUpdatedFromStream extends TaskDetailsEvent {
  final Task? task;
  const TaskUpdatedFromStream(this.task);
  @override
  List<Object?> get props => [task];
}

class TransitionTaskStatus extends TaskDetailsEvent {
  final String taskId;
  final TaskStatus targetStatus;
  final int currentVersion;
  final double? latitude;
  final double? longitude;

  const TransitionTaskStatus({
    required this.taskId,
    required this.targetStatus,
    required this.currentVersion,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [taskId, targetStatus, currentVersion, latitude, longitude];
}

class ResolveConflictAction extends TaskDetailsEvent {
  final String taskId;
  final bool keepLocal;
  final Map<String, dynamic>? serverData;

  const ResolveConflictAction({
    required this.taskId,
    required this.keepLocal,
    this.serverData,
  });

  @override
  List<Object?> get props => [taskId, keepLocal, serverData];
}

// States
abstract class TaskDetailsState extends Equatable {
  const TaskDetailsState();
  @override
  List<Object?> get props => [];
}

class TaskDetailsLoading extends TaskDetailsState {}

class TaskDetailsLoaded extends TaskDetailsState {
  final Task task;
  final bool isUpdating;

  const TaskDetailsLoaded(this.task, {this.isUpdating = false});

  @override
  List<Object?> get props => [task, isUpdating];
}

class TaskConflictDetected extends TaskDetailsState {
  final Task localTask;
  final Map<String, dynamic>? serverData;
  final String message;

  const TaskConflictDetected({
    required this.localTask,
    this.serverData,
    required this.message,
  });

  @override
  List<Object?> get props => [localTask, serverData, message];
}

class TaskDetailsError extends TaskDetailsState {
  final String message;
  const TaskDetailsError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class TaskDetailsBloc extends Bloc<TaskDetailsEvent, TaskDetailsState> {
  final GetTaskDetailsUseCase _getTaskDetailsUseCase;
  final UpdateTaskStatusUseCase _updateTaskStatusUseCase;
  final TaskRepository _taskRepository;
  StreamSubscription? _subscription;

  TaskDetailsBloc({
    required GetTaskDetailsUseCase getTaskDetailsUseCase,
    required UpdateTaskStatusUseCase updateTaskStatusUseCase,
    required TaskRepository taskRepository,
  })  : _getTaskDetailsUseCase = getTaskDetailsUseCase,
        _updateTaskStatusUseCase = updateTaskStatusUseCase,
        _taskRepository = taskRepository,
        super(TaskDetailsLoading()) {
    on<LoadTaskDetails>(_onLoadTaskDetails);
    on<TaskUpdatedFromStream>(_onTaskUpdatedFromStream);
    on<TransitionTaskStatus>(_onTransitionTaskStatus);
    on<ResolveConflictAction>(_onResolveConflict);
  }

  void _onLoadTaskDetails(LoadTaskDetails event, Emitter<TaskDetailsState> emit) {
    emit(TaskDetailsLoading());
    _subscription?.cancel();
    _subscription = _getTaskDetailsUseCase.watch(event.taskId).listen((task) {
      add(TaskUpdatedFromStream(task));
    });
  }

  void _onTaskUpdatedFromStream(TaskUpdatedFromStream event, Emitter<TaskDetailsState> emit) {
    if (event.task != null) {
      if (event.task!.syncStatus == SyncStatus.conflict) {
        emit(TaskConflictDetected(
          localTask: event.task!,
          message: 'Task version conflict detected on server.',
        ));
      } else {
        emit(TaskDetailsLoaded(event.task!));
      }
    } else {
      emit(const TaskDetailsError('Task not found in workstation'));
    }
  }

  Future<void> _onTransitionTaskStatus(TransitionTaskStatus event, Emitter<TaskDetailsState> emit) async {
    try {
      await _updateTaskStatusUseCase(
        taskId: event.taskId,
        newStatus: event.targetStatus,
        currentVersion: event.currentVersion,
        latitude: event.latitude,
        longitude: event.longitude,
      );
    } on ConflictException catch (e) {
      final task = await _taskRepository.getTaskById(event.taskId);
      if (task != null) {
        emit(TaskConflictDetected(
          localTask: task,
          serverData: e.serverData,
          message: e.message,
        ));
      }
    } catch (e) {
      // Local optimistic update was performed; if error was not conflict, local DB still updated
    }
  }

  Future<void> _onResolveConflict(ResolveConflictAction event, Emitter<TaskDetailsState> emit) async {
    try {
      await _taskRepository.resolveConflict(
        taskId: event.taskId,
        keepLocal: event.keepLocal,
        serverData: event.serverData,
      );
    } catch (e) {
      emit(TaskDetailsError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
