import 'dart:async';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/database/tables/drift_tables.dart';
import '../../data/datasources/sync_manager.dart';

// Events
abstract class SyncEvent extends Equatable {
  const SyncEvent();
  @override
  List<Object?> get props => [];
}

class WatchSyncQueue extends SyncEvent {}

class SyncOperationsReceived extends SyncEvent {
  final List<SyncOperationsTableData> operations;
  const SyncOperationsReceived(this.operations);
  @override
  List<Object?> get props => [operations];
}

class TriggerManualSync extends SyncEvent {}

class RetryFailedSync extends SyncEvent {}

// States
class SyncState extends Equatable {
  final List<SyncOperationsTableData> operations;
  final bool isSyncing;

  const SyncState({
    this.operations = const [],
    this.isSyncing = false,
  });

  List<SyncOperationsTableData> get synced =>
      operations.where((o) => o.status == SyncStatusDb.synced).toList();

  List<SyncOperationsTableData> get pending =>
      operations.where((o) => o.status == SyncStatusDb.pending).toList();

  List<SyncOperationsTableData> get failed =>
      operations.where((o) => o.status == SyncStatusDb.failed).toList();

  List<SyncOperationsTableData> get conflicts =>
      operations.where((o) => o.status == SyncStatusDb.conflict).toList();

  bool get hasPendingOrFailed => pending.isNotEmpty || failed.isNotEmpty || conflicts.isNotEmpty;

  SyncState copyWith({
    List<SyncOperationsTableData>? operations,
    bool? isSyncing,
  }) {
    return SyncState(
      operations: operations ?? this.operations,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [operations, isSyncing];
}

// BLoC
class SyncBloc extends Bloc<SyncEvent, SyncState> {
  final AppDatabase _db;
  final SyncManager _syncManager;
  StreamSubscription? _subscription;

  SyncBloc({
    required AppDatabase db,
    required SyncManager syncManager,
  })  : _db = db,
        _syncManager = syncManager,
        super(const SyncState()) {
    on<WatchSyncQueue>(_onWatchSyncQueue);
    on<SyncOperationsReceived>(_onSyncOperationsReceived);
    on<TriggerManualSync>(_onTriggerManualSync);
    on<RetryFailedSync>(_onRetryFailedSync);
  }

  void _onWatchSyncQueue(WatchSyncQueue event, Emitter<SyncState> emit) {
    _subscription?.cancel();
    final query = _db.select(_db.syncOperationsTable)
      ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc)]);

    _subscription = query.watch().listen((ops) {
      add(SyncOperationsReceived(ops));
    });
  }

  void _onSyncOperationsReceived(SyncOperationsReceived event, Emitter<SyncState> emit) {
    emit(state.copyWith(operations: event.operations));
  }

  Future<void> _onTriggerManualSync(TriggerManualSync event, Emitter<SyncState> emit) async {
    emit(state.copyWith(isSyncing: true));
    try {
      await _syncManager.processQueue();
    } finally {
      emit(state.copyWith(isSyncing: false));
    }
  }

  Future<void> _onRetryFailedSync(RetryFailedSync event, Emitter<SyncState> emit) async {
    emit(state.copyWith(isSyncing: true));
    try {
      await _syncManager.retryFailedOperations();
    } finally {
      emit(state.copyWith(isSyncing: false));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
