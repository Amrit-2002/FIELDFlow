import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

class UpdateTaskStatusUseCase {
  final TaskRepository _repository;

  UpdateTaskStatusUseCase(this._repository);

  Future<void> call({
    required String taskId,
    required TaskStatus newStatus,
    required int currentVersion,
    double? latitude,
    double? longitude,
  }) async {
    await _repository.updateTaskStatus(
      taskId: taskId,
      newStatus: newStatus,
      currentVersion: currentVersion,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
