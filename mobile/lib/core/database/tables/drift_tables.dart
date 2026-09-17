import 'package:drift/drift.dart';

enum TaskStatusDb {
  assigned,
  accepted,
  inProgress,
  completed,
  cancelled,
}

enum PriorityDb {
  low,
  medium,
  high,
  urgent,
}

enum SyncStatusDb {
  synced,
  pending,
  failed,
  conflict,
}

enum OperationTypeDb {
  create,
  update,
  delete,
}

enum EntityTypeDb {
  task,
  note,
  photo,
  location,
}

class UsersTable extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get role => text().withDefault(const Constant('FIELD_WORKER'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class TasksTable extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  TextColumn get customerName => text()();
  TextColumn get customerPhone => text()();
  TextColumn get address => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  IntColumn get priority => intEnum<PriorityDb>()();
  IntColumn get status => intEnum<TaskStatusDb>()();
  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get localUpdatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => intEnum<SyncStatusDb>().withDefault(const Constant(0))();
  TextColumn get assignedToId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskNotesTable extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get userId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => intEnum<SyncStatusDb>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskPhotosTable extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get userId => text()();
  TextColumn get localPath => text()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get type => text().withDefault(const Constant('ATTACHMENT'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => intEnum<SyncStatusDb>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text().nullable()();
  TextColumn get userId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracy => real().withDefault(const Constant(0.0))();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  IntColumn get syncStatus => intEnum<SyncStatusDb>().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncOperationsTable extends Table {
  TextColumn get id => text()();
  IntColumn get operationType => intEnum<OperationTypeDb>()();
  IntColumn get entityType => intEnum<EntityTypeDb>()();
  TextColumn get entityId => text()();
  TextColumn get payload => text()(); // JSON string
  IntColumn get status => intEnum<SyncStatusDb>().withDefault(const Constant(1))(); // default pending
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class NotificationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get type => text().withDefault(const Constant('SYSTEM'))();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
