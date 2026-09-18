import 'package:get_it/get_it.dart';
import '../core/database/app_database.dart';
import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/ai_assistant/data/datasources/ollama_datasource.dart';
import '../features/ai_assistant/data/repositories/ai_assistant_repository_impl.dart';
import '../features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import '../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../features/auth/data/datasources/auth_local_datasource.dart';
import '../features/auth/data/datasources/auth_remote_datasource.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../features/auth/domain/usecases/login_usecase.dart';
import '../features/auth/domain/usecases/logout_usecase.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/location/data/datasources/location_service.dart';
import '../features/notifications/data/datasources/notification_service.dart';
import '../features/sync/data/datasources/sync_manager.dart';
import '../features/sync/presentation/bloc/sync_bloc.dart';
import '../features/tasks/data/datasources/task_local_datasource.dart';
import '../features/tasks/data/datasources/task_remote_datasource.dart';
import '../features/tasks/data/repositories/task_repository_impl.dart';
import '../features/tasks/domain/repositories/task_repository.dart';
import '../features/tasks/domain/usecases/get_task_details_usecase.dart';
import '../features/tasks/domain/usecases/get_tasks_usecase.dart';
import '../features/tasks/domain/usecases/update_task_status_usecase.dart';
import '../features/tasks/presentation/bloc/task_bloc.dart';
import '../features/tasks/presentation/bloc/task_details_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // 1. Core Services & Database
  sl.registerLazySingleton<AppDatabase>(() => AppDatabase());
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<LocalNotificationService>(() => LocalNotificationService());

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      storage: sl<SecureStorageService>(),
      onSessionExpired: () {
        // Trigger unauthenticated event if session expires
      },
    ),
  );

  sl.registerLazySingleton<SyncManager>(
    () => SyncManager(
      db: sl<AppDatabase>(),
      apiClient: sl<ApiClient>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  // 2. Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      secureStorage: sl<SecureStorageService>(),
      db: sl<AppDatabase>(),
    ),
  );

  sl.registerLazySingleton<TaskLocalDataSource>(() => TaskLocalDataSourceImpl(sl<AppDatabase>()));
  sl.registerLazySingleton<TaskRemoteDataSource>(() => TaskRemoteDataSourceImpl(sl<ApiClient>()));
  sl.registerLazySingleton<OllamaDataSource>(() => OllamaDataSource());

  // 3. Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(
      localDataSource: sl<TaskLocalDataSource>(),
      remoteDataSource: sl<TaskRemoteDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      db: sl<AppDatabase>(),
    ),
  );

  sl.registerLazySingleton<AiAssistantRepository>(
    () => AiAssistantRepositoryImpl(
      ollamaDataSource: sl<OllamaDataSource>(),
    ),
  );

  // 4. Use Cases
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetTasksUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => GetTaskDetailsUseCase(sl<TaskRepository>()));
  sl.registerLazySingleton(() => UpdateTaskStatusUseCase(sl<TaskRepository>()));

  // 5. BLoCs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      getCurrentUserUseCase: sl<GetCurrentUserUseCase>(),
    ),
  );

  sl.registerFactory(() => TaskBloc(getTasksUseCase: sl<GetTasksUseCase>()));
  sl.registerFactory(
    () => TaskDetailsBloc(
      getTaskDetailsUseCase: sl<GetTaskDetailsUseCase>(),
      updateTaskStatusUseCase: sl<UpdateTaskStatusUseCase>(),
      taskRepository: sl<TaskRepository>(),
    ),
  );

  sl.registerFactory(
    () => SyncBloc(
      db: sl<AppDatabase>(),
      syncManager: sl<SyncManager>(),
    ),
  );

  sl.registerFactory(() => AiAssistantBloc(repository: sl<AiAssistantRepository>()));
}

