import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTaskDetailsUseCase {
  final TaskRepository _repository;

  GetTaskDetailsUseCase(this._repository);

  Stream<Task?> watch(String id) {
    return _repository.watchTaskById(id);
  }

  Future<Task?> call(String id) async {
    return await _repository.getTaskById(id);
  }
}

