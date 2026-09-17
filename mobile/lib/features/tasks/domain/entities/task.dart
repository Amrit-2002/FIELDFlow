import 'package:equatable/equatable.dart';
import 'priority.dart';
import 'task_status.dart';

enum SyncStatus {
  synced,
  pending,
  failed,
  conflict;

  static SyncStatus fromString(String val) {
    switch (val.toUpperCase()) {
      case 'SYNCED':
        return SyncStatus.synced;
      case 'PENDING':
        return SyncStatus.pending;
      case 'FAILED':
        return SyncStatus.failed;
      case 'CONFLICT':
        return SyncStatus.conflict;
      default:
        return SyncStatus.synced;
    }
  }

  String toServerString() {
    switch (this) {
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.pending:
        return 'PENDING';
      case SyncStatus.failed:
        return 'FAILED';
      case SyncStatus.conflict:
        return 'CONFLICT';
    }
  }
}

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final String customerName;
  final String customerPhone;
  final String address;
  final double latitude;
  final double longitude;
  final Priority priority;
  final TaskStatus status;
  final DateTime scheduledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int serverVersion;
  final DateTime localUpdatedAt;
  final SyncStatus syncStatus;
  final String? assignedToId;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.customerName,
    required this.customerPhone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.priority,
    required this.status,
    required this.scheduledAt,
    required this.createdAt,
    required this.updatedAt,
    this.serverVersion = 1,
    required this.localUpdatedAt,
    this.syncStatus = SyncStatus.synced,
    this.assignedToId,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? customerName,
    String? customerPhone,
    String? address,
    double? latitude,
    double? longitude,
    Priority? priority,
    TaskStatus? status,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? serverVersion,
    DateTime? localUpdatedAt,
    SyncStatus? syncStatus,
    String? assignedToId,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      serverVersion: serverVersion ?? this.serverVersion,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      assignedToId: assignedToId ?? this.assignedToId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        customerName,
        customerPhone,
        address,
        latitude,
        longitude,
        priority,
        status,
        scheduledAt,
        createdAt,
        updatedAt,
        serverVersion,
        localUpdatedAt,
        syncStatus,
        assignedToId,
      ];
}
