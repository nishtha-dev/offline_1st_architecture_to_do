import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

import 'core/database/database_helper.dart';
import 'core/network/network_info.dart';
import 'core/sync/sync_service.dart';
import 'features/todo/data/datasources/todo_local_data_source.dart';
import 'features/todo/data/datasources/todo_remote_data_source.dart';
import 'features/todo/data/repositories/todo_repository_impl.dart';
import 'features/todo/domain/repositories/todo_repository.dart';
import 'features/todo/domain/usecases/create_todo.dart';
import 'features/todo/domain/usecases/delete_todo.dart';
import 'features/todo/domain/usecases/get_todos.dart';
import 'features/todo/domain/usecases/sync_todos.dart';
import 'features/todo/domain/usecases/toggle_todo_completion.dart';
import 'features/todo/domain/usecases/update_todo.dart';
import 'features/todo/domain/usecases/watch_todos.dart';
import 'features/todo/presentation/bloc/todo_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // External dependencies
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => const Uuid());
  sl.registerLazySingleton(() => Logger());
  sl.registerLazySingleton(() => DatabaseHelper.instance);

  // Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<TodoLocalDataSource>(
    () => TodoLocalDataSourceImpl(databaseHelper: sl()),
  );

  sl.registerLazySingleton<TodoRemoteDataSource>(
    () => TodoRemoteDataSourceImpl(
      dio: sl(),
      baseUrl: 'https://api.todo-app.com', // Mock URL
      logger: sl(),
    ),
  );

  // Repository
  sl.registerLazySingleton<TodoRepository>(
    () => TodoRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
      uuid: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetTodos(sl()));
  sl.registerLazySingleton(() => CreateTodo(sl()));
  sl.registerLazySingleton(() => UpdateTodo(sl()));
  sl.registerLazySingleton(() => DeleteTodo(sl()));
  sl.registerLazySingleton(() => ToggleTodoCompletion(sl()));
  sl.registerLazySingleton(() => SyncTodos(sl()));
  sl.registerLazySingleton(() => WatchTodos(sl()));

  // Sync Service
  sl.registerLazySingleton(
    () => SyncService(
      localDataSource: sl(),
      remoteDataSource: sl(),
      networkInfo: sl(),
      logger: sl(),
    ),
  );

  // BLoC
  sl.registerFactory(
    () => TodoBloc(
      getTodos: sl(),
      createTodo: sl(),
      updateTodo: sl(),
      deleteTodo: sl(),
      toggleTodoCompletion: sl(),
      syncTodos: sl(),
      watchTodos: sl(),
    ),
  );
}
