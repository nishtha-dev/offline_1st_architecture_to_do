import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';

import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../models/todo_model.dart';
import '../datasources/todo_local_data_source.dart';
import '../datasources/todo_remote_data_source.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/network_info.dart';

/// Repository implementation following the Repository pattern
/// This implements offline-first approach with automatic sync
class TodoRepositoryImpl implements TodoRepository {
  final TodoLocalDataSource localDataSource;
  final TodoRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;
  final Uuid uuid;

  late StreamController<List<Todo>> _todosStreamController;
  Timer? _syncTimer;

  TodoRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.logger,
    required this.uuid,
  }) {
    _todosStreamController = StreamController<List<Todo>>.broadcast();
    _startListeningToRemoteUpdates();
  }

  void _startListeningToRemoteUpdates() {
    // Listen to real-time updates from other devices
    remoteDataSource.watchTodoUpdates().listen(
      (remoteTodo) async {
        logger.i('Received real-time update: ${remoteTodo.title}');

        // Check if we have this todo locally
        try {
          final localTodo = await localDataSource.getTodoById(remoteTodo.id);

          if (localTodo == null) {
            // New todo from another device
            await localDataSource.insertTodo(remoteTodo);
            logger.i('Inserted new todo from remote: ${remoteTodo.title}');
          } else {
            // Conflict resolution - use version numbers
            if (remoteTodo.version > localTodo.version) {
              await localDataSource.updateTodo(remoteTodo);
              logger.i('Updated todo with remote version: ${remoteTodo.title}');
            }
          }

          // Notify listeners of the change
          _notifyTodoChange(remoteTodo.userId);
        } catch (e) {
          logger.e('Error handling remote update: $e');
        }
      },
      onError: (error) {
        logger.e('Error in remote updates stream: $error');
      },
    );
  }

  @override
  Future<Either<Failure, List<Todo>>> getTodos(String userId) async {
    try {
      // Always return local data first (offline-first approach)
      final localTodos = await localDataSource.getAllTodos(userId);

      // Try to sync in background if connected
      _backgroundSync();

      return Right(localTodos.cast<Todo>());
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo?>> getTodoById(String id) async {
    try {
      final todo = await localDataSource.getTodoById(id);
      return Right(todo);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo>> createTodo({
    required String title,
    String? description,
    required String userId,
  }) async {
    try {
      final now = DateTime.now();
      final todo = TodoModel(
        id: uuid.v4(),
        title: title,
        description: description,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
        userId: userId,
        version: 1,
      );

      // Save locally first (offline-first)
      final savedTodo = await localDataSource.insertTodo(todo);

      // Try to sync to remote in background
      _backgroundSyncTodo(savedTodo);

      // Notify listeners
      _notifyTodoChange(userId);

      return Right(savedTodo);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo>> updateTodo(Todo todo) async {
    try {
      final todoModel = TodoModel.fromEntity(todo);

      // Update locally first
      final updatedTodo = await localDataSource.updateTodo(todoModel);

      // Try to sync to remote in background
      _backgroundSyncTodo(updatedTodo);

      // Notify listeners
      _notifyTodoChange(todo.userId);

      return Right(updatedTodo);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteTodo(String id) async {
    try {
      // Get the todo first to know the user
      final todo = await localDataSource.getTodoById(id);
      if (todo == null) {
        return const Left(ValidationFailure('Todo not found'));
      }

      // Soft delete locally (for sync purposes)
      await localDataSource.deleteTodo(id);

      // Try to sync deletion to remote in background
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.deleteTodo(id);
        } catch (e) {
          logger.w('Failed to delete remotely, will sync later: $e');
        }
      }

      // Notify listeners
      _notifyTodoChange(todo.userId);

      return const Right(null);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Todo>> toggleTodoCompletion(String id) async {
    try {
      final todo = await localDataSource.getTodoById(id);
      if (todo == null) {
        return const Left(ValidationFailure('Todo not found'));
      }

      final updatedTodo = todo.copyWith(
        isCompleted: !todo.isCompleted,
        updatedAt: DateTime.now(),
        version: todo.version + 1,
      );

      return await updateTodo(updatedTodo);
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, void>> syncTodos() async {
    try {
      if (!await networkInfo.isConnected) {
        return Left(NetworkFailure());
      }

      // Get all local todos
      final localTodos =
          await localDataSource.getAllTodos('user_1'); // Simplified user ID

      // Sync with remote
      await remoteDataSource.syncTodos(localTodos);

      return const Right(null);
    } on ServerException {
      return Left(ServerFailure());
    } on NetworkException {
      return Left(NetworkFailure());
    } on CacheException {
      return Left(CacheFailure());
    }
  }

  @override
  Stream<List<Todo>> watchTodos(String userId) async* {
    // Start with current local data
    try {
      final currentTodos = await localDataSource.getAllTodos(userId);
      yield currentTodos.cast<Todo>();
    } catch (e) {
      logger.e('Error getting initial todos: $e');
    }

    // Then yield updates
    yield* _todosStreamController.stream;
  }

  void _backgroundSync() {
    if (_syncTimer != null && _syncTimer!.isActive) return;

    _syncTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        if (await networkInfo.isConnected) {
          await syncTodos();
        }
      } catch (e) {
        logger.w('Background sync failed: $e');
      }
    });
  }

  void _backgroundSyncTodo(TodoModel todo) {
    if (networkInfo.isConnected case Future<bool> future) {
      future.then((connected) async {
        if (connected) {
          try {
            if (todo.version == 1) {
              await remoteDataSource.createTodo(todo);
            } else {
              await remoteDataSource.updateTodo(todo);
            }
          } catch (e) {
            logger.w('Background sync todo failed: $e');
          }
        }
      });
    }
  }

  void _notifyTodoChange(String userId) {
    localDataSource.getAllTodos(userId).then((todos) {
      _todosStreamController.add(todos.cast<Todo>());
    }).catchError((error) {
      logger.e('Error notifying todo change: $error');
    });
  }

  void dispose() {
    _todosStreamController.close();
    _syncTimer?.cancel();
  }
}
