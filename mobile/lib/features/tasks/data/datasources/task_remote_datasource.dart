import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task_status.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks({int page = 1, int limit = 50, String? search, TaskStatus? status, Priority? priority});
  Future<TaskModel> getTaskById(String id);
  Future<TaskModel> updateTaskStatus({
    required String id,
    required TaskStatus status,
    required int version,
    double? latitude,
    double? longitude,
  });
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final ApiClient _apiClient;

  TaskRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<TaskModel>> getTasks({
    int page = 1,
    int limit = 50,
    String? search,
    TaskStatus? status,
    Priority? priority,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    if (status != null) queryParams['status'] = status.toServerString();
    if (priority != null) queryParams['priority'] = priority.toServerString();

    final response = await _apiClient.get(
      ApiConstants.tasks,
      queryParameters: queryParams,
    );

    // Response pagination: data: { items: [...], page, limit, total }
    final items = response['items'] as List<dynamic>;
    return items.map((i) => TaskModel.fromJson(i as Map<String, dynamic>)).toList();
  }

  @override
  Future<TaskModel> getTaskById(String id) async {
    final response = await _apiClient.get(ApiConstants.taskDetails(id));
    return TaskModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<TaskModel> updateTaskStatus({
    required String id,
    required TaskStatus status,
    required int version,
    double? latitude,
    double? longitude,
  }) async {
    final data = <String, dynamic>{
      'status': status.toServerString(),
      'version': version,
    };
    if (latitude != null && longitude != null) {
      data['latitude'] = latitude;
      data['longitude'] = longitude;
    }

    final response = await _apiClient.patch(
      ApiConstants.taskStatus(id),
      data: data,
    );

    return TaskModel.fromJson(response as Map<String, dynamic>);
  }
}

