import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_datasource.dart';
import '../datasources/task_remote_datasource.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource _localDataSource;
  final TaskRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  TaskRepositoryImpl({
    required TaskLocalDataSource localDataSource,
    required TaskRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required AppDatabase db,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _db = db;

  @override
  Stream<List<Task>> watchTasks({String? search, TaskStatus? status, Priority? priority}) {
    return _localDataSource.watchTasks(search: search, status: status, priority: priority);
  }

  @override
  Future<List<Task>> getTasks({int page = 1, int limit = 20, String? search, TaskStatus? status, Priority? priority}) async {
    // If online, refresh from remote first
    if (await _networkInfo.isConnected) {
      try {
        final remoteTasks = await _remoteDataSource.getTasks(page: page, limit: limit, search: search, status: status, priority: priority);
        await _localDataSource.upsertTasks(remoteTasks);
      } catch (_) {
        // Fallback to local cache on transient network error
      }
    }
    return await _localDataSource.getTasks(search: search, status: status, priority: priority);
  }

  @override
  Future<Task?> getTaskById(String id) async {
    if (await _networkInfo.isConnected) {
      try {
        final remoteTask = await _remoteDataSource.getTaskById(id);
        await _localDataSource.upsertTask(remoteTask);
      } catch (_) {}
    }
    return await _localDataSource.getTaskById(id);
  }

  @override
  Stream<Task?> watchTaskById(String id) {
    return _localDataSource.watchTaskById(id);
  }

  @override
  Future<void> updateTaskStatus({
    required String taskId,
    required TaskStatus newStatus,
    required int currentVersion,
    double? latitude,
    double? longitude,
  }) async {
    final localTask = await _localDataSource.getTaskById(taskId);
    if (localTask == null) {
      throw const DatabaseException(message: 'Task not found in local database');
    }

    // 1. Client-side state transition validation
    if (!localTask.status.canTransitionTo(newStatus)) {
      throw ValidationException(
        message: 'Invalid status transition from ${localTask.status.displayName} to ${newStatus.displayName}',
      );
    }

    // 2. Optimistically update local database
    await _localDataSource.updateTaskStatusLocally(
      id: taskId,
      newStatus: newStatus,
      syncStatus: SyncStatus.pending,
    );

    // 3. Enqueue sync operation in local SQLite
    final operationId = _uuid.v4();
    final payload = {
      'status': newStatus.toServerString(),
      'version': currentVersion,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };

    await _db.into(_db.syncOperationsTable).insert(
          SyncOperationsTableCompanion.insert(
            id: operationId,
            operationType: OperationTypeDb.update,
            entityType: EntityTypeDb.task,
            entityId: taskId,
            payload: jsonEncode(payload),
            status: const Value(SyncStatusDb.pending),
            createdAt: Value(DateTime.now()),
            updatedAt: Value(DateTime.now()),
          ),
        );

    // 4. If online, attempt direct execution
    if (await _networkInfo.isConnected) {
      try {
        final updatedRemote = await _remoteDataSource.updateTaskStatus(
          id: taskId,
          status: newStatus,
          version: currentVersion,
          latitude: latitude,
          longitude: longitude,
        );

        // Update local task with incremented server version and SYNCED state
        await _localDataSource.upsertTask(updatedRemote);

        // Mark operation synced
        await (_db.update(_db.syncOperationsTable)..where((tbl) => tbl.id.equals(operationId))).write(
          const SyncOperationsTableCompanion(status: Value(SyncStatusDb.synced)),
        );
      } on ConflictException catch (conflict) {
        // Mark local task and operation as CONFLICT (409)
        await _localDataSource.markTaskConflict(taskId);
        await (_db.update(_db.syncOperationsTable)..where((tbl) => tbl.id.equals(operationId))).write(
          SyncOperationsTableCompanion(
            status: const Value(SyncStatusDb.conflict),
            lastError: Value(conflict.message),
          ),
        );
        rethrow;
      } catch (err) {
        // Remains PENDING for background SyncManager retry
      }
    }
  }

  @override
  Future<void> syncRemoteTasks() async {
    if (await _networkInfo.isConnected) {
      final tasks = await _remoteDataSource.getTasks(limit: 100);
      await _localDataSource.upsertTasks(tasks);
      try {
        final tasks = await _remoteDataSource.getTasks(limit: 100);
        await _localDataSource.upsertTasks(tasks);
      } catch (err) {
        // Offline-first fallback: if backend is unreachable or timed out,
        // log warning and continue serving cached SQLite tasks smoothly.
        appLogger.w('Background remote task sync skipped (backend unreachable): $err');
      }
    }
  }

  @override
  Future<void> resolveConflict({
    required String taskId,
    required bool keepLocal,
    Map<String, dynamic>? serverData,
  }) async {
    if (keepLocal) {
      // Overwrite server version with latest server version + 1
      if (serverData != null && serverData['version'] != null) {
        final serverVer = serverData['version'] as int;
        final localTask = await _localDataSource.getTaskById(taskId);
        if (localTask != null) {
          await updateTaskStatus(
            taskId: taskId,
            newStatus: localTask.status,
            currentVersion: serverVer,
          );
        }
      }
    } else {
      // Accept server version
      if (serverData != null) {
        final serverModel = TaskModel.fromJson(serverData);
        await _localDataSource.upsertTask(serverModel);
      } else {
        final remote = await _remoteDataSource.getTaskById(taskId);
        await _localDataSource.upsertTask(remote);
      }
    }
  }
}

