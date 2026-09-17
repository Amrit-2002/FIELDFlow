import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
  AppDatabase([QueryExecutor? e]) : super(e ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'fieldflow.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // Helper constructors for testing with in-memory database
  factory AppDatabase.forTesting(QueryExecutor executor) {
    return AppDatabase(executor);
  }
}
