import '../entities/priority.dart';
import '../entities/task.dart';
import '../entities/task_status.dart';
import '../repositories/task_repository.dart';

class GetTasksUseCase {
  final TaskRepository _repository;

  GetTasksUseCase(this._repository);

  Stream<List<Task>> watch({String? search, TaskStatus? status, Priority? priority}) {
    return _repository.watchTasks(search: search, status: status, priority: priority);
  }

  Future<void> refresh() async {
    await _repository.syncRemoteTasks();
  }
}

