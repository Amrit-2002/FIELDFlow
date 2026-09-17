import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';
import '../models/task_model.dart';

abstract class TaskLocalDataSource {
  Stream<List<TaskModel>> watchTasks({String? search, TaskStatus? status, Priority? priority});
  Future<List<TaskModel>> getTasks({String? search, TaskStatus? status, Priority? priority});
  Future<TaskModel?> getTaskById(String id);
  Stream<TaskModel?> watchTaskById(String id);
  Future<void> upsertTask(TaskModel task);
  Future<void> upsertTasks(List<TaskModel> tasks);
  Future<void> updateTaskStatusLocally({
    required String id,
    required TaskStatus newStatus,
    required SyncStatus syncStatus,
  });
  Future<void> markTaskConflict(String id);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final AppDatabase _db;

  TaskLocalDataSourceImpl(this._db);

  @override
  Stream<List<TaskModel>> watchTasks({String? search, TaskStatus? status, Priority? priority}) {
    final query = _db.select(_db.tasksTable);

    if (status != null) {
      query.where((tbl) => tbl.status.equals(status.index));
    }
    if (priority != null) {
      query.where((tbl) => tbl.priority.equals(priority.index));
    }
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim().toLowerCase()}%';
      query.where((tbl) =>
          tbl.title.lower().like(term) |
          tbl.customerName.lower().like(term) |
          tbl.address.lower().like(term));
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.scheduledAt, mode: OrderingMode.asc),
    ]);

    return query.watch().map((rows) => rows.map(TaskModel.fromDrift).toList());
  }

  @override
  Future<List<TaskModel>> getTasks({String? search, TaskStatus? status, Priority? priority}) async {
    final query = _db.select(_db.tasksTable);

    if (status != null) {
      query.where((tbl) => tbl.status.equals(status.index));
    }
    if (priority != null) {
      query.where((tbl) => tbl.priority.equals(priority.index));
    }
    if (search != null && search.trim().isNotEmpty) {
      final term = '%${search.trim().toLowerCase()}%';
      query.where((tbl) =>
          tbl.title.lower().like(term) |
          tbl.customerName.lower().like(term) |
          tbl.address.lower().like(term));
    }

    final rows = await query.get();
    return rows.map(TaskModel.fromDrift).toList();
  }

  @override
  Future<TaskModel?> getTaskById(String id) async {
    final query = _db.select(_db.tasksTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return TaskModel.fromDrift(row);
  }

  @override
  Stream<TaskModel?> watchTaskById(String id) {
    final query = _db.select(_db.tasksTable)..where((tbl) => tbl.id.equals(id));
    return query.watchSingleOrNull().map((row) => row != null ? TaskModel.fromDrift(row) : null);
  }

  @override
  Future<void> upsertTask(TaskModel task) async {
    await _db.into(_db.tasksTable).insertOnConflictUpdate(task.toDriftCompanion());
  }

  @override
  Future<void> upsertTasks(List<TaskModel> tasks) async {
    await _db.batch((batch) {
      for (final t in tasks) {
        batch.insert(_db.tasksTable, t.toDriftCompanion(), mode: InsertMode.insertOrReplace);
      }
    });
  }

  @override
  Future<void> updateTaskStatusLocally({
    required String id,
    required TaskStatus newStatus,
    required SyncStatus syncStatus,
  }) async {
    final companion = TasksTableCompanion(
      status: Value(TaskStatusDb.values[newStatus.index]),
      syncStatus: Value(SyncStatusDb.values[syncStatus.index]),
      localUpdatedAt: Value(DateTime.now()),
    );

    await (_db.update(_db.tasksTable)..where((tbl) => tbl.id.equals(id))).write(companion);
  }

  @override
  Future<void> markTaskConflict(String id) async {
    final companion = TasksTableCompanion(
      syncStatus: Value(SyncStatusDb.conflict),
      localUpdatedAt: Value(DateTime.now()),
    );

    await (_db.update(_db.tasksTable)..where((tbl) => tbl.id.equals(id))).write(companion);
  }
}
