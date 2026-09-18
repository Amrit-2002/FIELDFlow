import 'package:drift/drift.dart' show Value;
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../domain/entities/priority.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    required super.description,
    required super.customerName,
    required super.customerPhone,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.priority,
    required super.status,
    required super.scheduledAt,
    required super.createdAt,
    required super.updatedAt,
    super.serverVersion = 1,
    required super.localUpdatedAt,
    super.syncStatus = SyncStatus.synced,
    super.assignedToId,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      priority: Priority.fromString(json['priority'] as String? ?? 'MEDIUM'),
      status: TaskStatus.fromString(json['status'] as String? ?? 'ASSIGNED'),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : DateTime.now(),
      serverVersion: (json['version'] as num?)?.toInt() ?? 1,
      localUpdatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
      assignedToId: json['assignedToId'] as String?,
    );
  }

  factory TaskModel.fromDrift(TasksTableData row) {
    return TaskModel(
      id: row.id,
      title: row.title,
      description: row.description,
      customerName: row.customerName,
      customerPhone: row.customerPhone,
      address: row.address,
      latitude: row.latitude,
      longitude: row.longitude,
      priority: Priority.values[row.priority.index],
      status: TaskStatus.values[row.status.index],
      scheduledAt: row.scheduledAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      serverVersion: row.serverVersion,
      localUpdatedAt: row.localUpdatedAt,
      syncStatus: SyncStatus.values[row.syncStatus.index],
      assignedToId: row.assignedToId,
    );
  }

  TasksTableCompanion toDriftCompanion() {
    return TasksTableCompanion.insert(
      id: id,
      title: title,
      description: description,
      customerName: customerName,
      customerPhone: customerPhone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      priority: PriorityDb.values[priority.index],
      status: TaskStatusDb.values[status.index],
      scheduledAt: scheduledAt,
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      serverVersion: Value(serverVersion),
      localUpdatedAt: Value(localUpdatedAt),
      syncStatus: Value(SyncStatusDb.values[syncStatus.index]),
      assignedToId: Value(assignedToId),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'priority': priority.toServerString(),
      'status': status.toServerString(),
      'scheduledAt': scheduledAt.toIso8601String(),
      'version': serverVersion,
      'assignedToId': assignedToId,
    };
  }
}

