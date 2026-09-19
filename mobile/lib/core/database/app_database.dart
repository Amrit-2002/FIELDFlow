import 'package:drift/drift.dart';
import 'connection/connection.dart' as conn;
import 'tables/drift_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  UsersTable,
  TasksTable,
  TaskNotesTable,
  TaskPhotosTable,
  LocationsTable,
  SyncOperationsTable,
  NotificationsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? conn.openConnection());

  @override
  int get schemaVersion => 1;

  // Helper constructors for testing with in-memory database
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase(executor);
  }
}

