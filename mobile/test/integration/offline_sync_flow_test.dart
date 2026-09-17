import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:field_flow/core/database/app_database.dart';
import 'package:field_flow/core/database/tables/drift_tables.dart';
import 'package:field_flow/core/network/api_client.dart';
import 'package:field_flow/core/network/network_info.dart';
import 'package:field_flow/features/sync/data/datasources/sync_manager.dart';
import 'package:field_flow/features/tasks/data/datasources/task_local_datasource.dart';
import 'package:field_flow/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:field_flow/features/tasks/data/models/task_model.dart';
import 'package:field_flow/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:field_flow/features/tasks/domain/entities/priority.dart';
import 'package:field_flow/features/tasks/domain/entities/task.dart';
import 'package:field_flow/features/tasks/domain/entities/task_status.dart';

class MockApiClient extends Mock implements ApiClient {}
class MockTaskRemoteDataSource extends Mock implements TaskRemoteDataSource {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AppDatabase inMemoryDb;
  late TaskLocalDataSource localDataSource;
  late MockTaskRemoteDataSource mockRemoteDataSource;
  late MockNetworkInfo mockNetworkInfo;
  late MockApiClient mockApiClient;
  late TaskRepositoryImpl taskRepository;
  late SyncManager syncManager;

  const initialTaskId = 'task-integration-001';

  final initialTask = TaskModel(
    id: initialTaskId,
    title: 'Emergency Generator Air Intake Filter Check',
    description: 'Quarterly intake plenum check and oil change',
    customerName: 'St. Jude Community Hospital',
    customerPhone: '+1-555-4343',
    address: '262 Danny Thomas Place',
    latitude: 35.1495,
    longitude: -90.049,
    priority: Priority.urgent,
    status: TaskStatus.assigned,
    scheduledAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    serverVersion: 1,
    localUpdatedAt: DateTime.now(),
    syncStatus: SyncStatus.synced,
  );

  setUp(() async {
    // 1. Setup in-memory SQLite database
    inMemoryDb = AppDatabase.forTesting(NativeDatabase.memory());
    localDataSource = TaskLocalDataSourceImpl(inMemoryDb);
    mockRemoteDataSource = MockTaskRemoteDataSource();
    mockNetworkInfo = MockNetworkInfo();
    mockApiClient = MockApiClient();

    // Initially online
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockNetworkInfo.onConnectivityChanged).thenAnswer((_) => Stream.value(true));

    taskRepository = TaskRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: mockRemoteDataSource,
      networkInfo: mockNetworkInfo,
      db: inMemoryDb,
    );

    syncManager = SyncManager(
      db: inMemoryDb,
      apiClient: mockApiClient,
      networkInfo: mockNetworkInfo,
    );
  });

  tearDown(() async {
    syncManager.dispose();
    await inMemoryDb.close();
  });

  test('End-to-End Offline-First Lifecycle Integration Scenario', () async {
    // Step 1: Initial Sync while Online
    await localDataSource.upsertTask(initialTask);
    final storedTask = await localDataSource.getTaskById(initialTaskId);
    expect(storedTask, isNotNull);
    expect(storedTask!.status, TaskStatus.assigned);
    expect(storedTask.syncStatus, SyncStatus.synced);

    // Step 2: Technician goes into basement / dead zone (Device goes OFFLINE)
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

    // Step 3: Technician accepts job and transitions status to ACCEPTED
    await taskRepository.updateTaskStatus(
      taskId: initialTaskId,
      newStatus: TaskStatus.accepted,
      currentVersion: 1,
    );

    // Step 4: Verify Local Persistence & Optimistic UI
    final offlineUpdatedTask = await localDataSource.getTaskById(initialTaskId);
    expect(offlineUpdatedTask!.status, TaskStatus.accepted);
    expect(offlineUpdatedTask.syncStatus, SyncStatus.pending); // Flagged as PENDING in local SQLite!

    // Step 5: Verify sync_operations table contains the queued offline mutation
    final pendingOps = await inMemoryDb.select(inMemoryDb.syncOperationsTable).get();
    expect(pendingOps.length, 1);
    expect(pendingOps.first.entityId, initialTaskId);
    expect(pendingOps.first.status, SyncStatusDb.pending);

    final payload = jsonDecode(pendingOps.first.payload);
    expect(payload['status'], 'ACCEPTED');
    expect(payload['version'], 1);

    // Step 6: Technician emerges from basement (Connectivity is RESTORED)
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Mock Backend /sync response
    when(() => mockApiClient.post('/sync', data: any(named: 'data'))).thenAnswer((_) async => {
          'results': [
            {
              'operationId': pendingOps.first.id,
              'status': 'SYNCED',
              'entityType': 'TASK',
              'entityId': initialTaskId,
              'data': {'version': 2, 'status': 'ACCEPTED'},
            }
          ],
          'processedCount': 1,
          'conflictCount': 0,
          'failedCount': 0,
        });

    // Step 7: Trigger Background Synchronization
    await syncManager.processQueue();

    // Step 8: Verify Operation is marked SYNCED in SQLite
    final updatedOps = await inMemoryDb.select(inMemoryDb.syncOperationsTable).get();
    expect(updatedOps.first.status, SyncStatusDb.synced);

    // Step 9: Verify Task syncStatus is updated to SYNCED in SQLite
    final finalTask = await localDataSource.getTaskById(initialTaskId);
    expect(finalTask!.syncStatus, SyncStatus.synced);
    expect(finalTask.status, TaskStatus.accepted);
  });
}
