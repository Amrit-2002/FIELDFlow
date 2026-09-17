import '../entities/priority.dart';
import '../entities/task.dart';
import '../entities/task_status.dart';

abstract class TaskRepository {
  Stream<List<Task>> watchTasks({String? search, TaskStatus? status, Priority? priority});
  Future<List<Task>> getTasks({int page = 1, int limit = 20, String? search, TaskStatus? status, Priority? priority});
  Future<Task?> getTaskById(String id);
  Stream<Task?> watchTaskById(String id);
  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus newStatus,
    required int currentVersion,
    double? latitude,
    double? longitude,
  });
  Future<void> syncRemoteTasks();
  Future<void> resolveConflict({
    required String taskId,
    required bool keepLocal,
    Map<String, dynamic>? serverData,
  });
}
