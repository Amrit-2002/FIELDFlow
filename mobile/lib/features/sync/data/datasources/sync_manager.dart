import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:drift/drift.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';

class SyncManager {
  final AppDatabase _db;
  final ApiClient _apiClient;
  final NetworkInfo _networkInfo;

  bool _isProcessing = false;
  StreamSubscription? _connectivitySub;

  SyncManager({
    required AppDatabase db,
    required ApiClient apiClient,
    required NetworkInfo networkInfo,
  })  : _db = db,
        _apiClient = apiClient,
        _networkInfo = networkInfo {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySub = _networkInfo.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        appLogger.i('📡 Network connectivity restored. Triggering background sync engine...');
        processQueue();
      }
    });
  }

  Duration calculateBackoff(int retryCount) {
    // Exponential backoff: 2s, 4s, 8s, 16s with slight jitter
    final baseSeconds = pow(2, min(retryCount, 4)).toInt();
    return Duration(seconds: baseSeconds);
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;
    if (!await _networkInfo.isConnected) return;

    _isProcessing = true;
    appLogger.i('🔄 SyncManager: Checking pending sync operations...');

    try {
      final pendingOps = await (_db.select(_db.syncOperationsTable)
            ..where((tbl) => tbl.status.equals(SyncStatusDb.pending.index))
            ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc)]))
          .get();

      if (pendingOps.isEmpty) {
        appLogger.i('✓ SyncManager: All local operations are already synchronized.');
        return;
      }

      appLogger.i('📤 SyncManager: Found ${pendingOps.length} pending operations. Building batch payload...');

      final batchPayload = pendingOps.map((op) {
        final payloadMap = jsonDecode(op.payload) as Map<String, dynamic>;
        return {
          'id': op.id,
          'operationType': _operationTypeToString(op.operationType),
          'entityType': _entityTypeToString(op.entityType),
          'entityId': op.entityId,
          'payload': payloadMap,
          'clientTimestamp': op.createdAt.toIso8601String(),
        };
      }).toList();

      final response = await _apiClient.post(
        ApiConstants.sync,
        data: {'operations': batchPayload},
      );

      final results = response['results'] as List<dynamic>;

      for (final res in results) {
        final opId = res['operationId'] as String;
        final status = res['status'] as String;

        if (status == 'SYNCED') {
          await (_db.update(_db.syncOperationsTable)..where((tbl) => tbl.id.equals(opId))).write(
            SyncOperationsTableCompanion(
              status: const Value(SyncStatusDb.synced),
              updatedAt: Value(DateTime.now()),
            ),
          );

          // Update local entity syncStatus to SYNCED
          final entityType = res['entityType'] as String?;
          final entityId = res['entityId'] as String?;
          if (entityType == 'TASK' && entityId != null) {
            await (_db.update(_db.tasksTable)..where((tbl) => tbl.id.equals(entityId))).write(
              const TasksTableCompanion(syncStatus: Value(SyncStatusDb.synced)),
            );
          }
        } else if (status == 'CONFLICT') {
          appLogger.w('⚠️ SyncManager: Conflict detected on operation $opId');
          final errorMsg = res['error']?['message'] ?? 'Version conflict detected on server';

          await (_db.update(_db.syncOperationsTable)..where((tbl) => tbl.id.equals(opId))).write(
            SyncOperationsTableCompanion(
              status: const Value(SyncStatusDb.conflict),
              lastError: Value(errorMsg),
              updatedAt: Value(DateTime.now()),
            ),
          );

          final entityId = res['entityId'] as String?;
          if (entityId != null) {
            await (_db.update(_db.tasksTable)..where((tbl) => tbl.id.equals(entityId))).write(
              const TasksTableCompanion(syncStatus: Value(SyncStatusDb.conflict)),
            );
          }
        } else {
          // FAILED
          final op = pendingOps.firstWhere((o) => o.id == opId);
          final newRetryCount = op.retryCount + 1;
          final errorMsg = res['error']?['message'] ?? 'Sync failed';

          final shouldFailPermanently = newRetryCount >= 5;

          await (_db.update(_db.syncOperationsTable)..where((tbl) => tbl.id.equals(opId))).write(
            SyncOperationsTableCompanion(
              status: Value(shouldFailPermanently ? SyncStatusDb.failed : SyncStatusDb.pending),
              retryCount: Value(newRetryCount),
              lastError: Value(errorMsg),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
    } catch (e) {
      appLogger.e('SyncManager error processing queue', error: e);
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> retryFailedOperations() async {
    // Reset failed items back to pending
    await (_db.update(_db.syncOperationsTable)
          ..where((tbl) => tbl.status.equals(SyncStatusDb.failed.index)))
        .write(
      const SyncOperationsTableCompanion(
        status: Value(SyncStatusDb.pending),
        retryCount: Value(0),
      ),
    );
    await processQueue();
  }

  String _operationTypeToString(OperationTypeDb opType) {
    switch (opType) {
      case OperationTypeDb.create:
        return 'CREATE';
      case OperationTypeDb.update:
        return 'UPDATE';
      case OperationTypeDb.delete:
        return 'DELETE';
    }
  }

  String _entityTypeToString(EntityTypeDb entityType) {
    switch (entityType) {
      case EntityTypeDb.task:
        return 'TASK';
      case EntityTypeDb.note:
        return 'NOTE';
      case EntityTypeDb.photo:
        return 'PHOTO';
      case EntityTypeDb.location:
        return 'LOCATION';
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
  }
}
