import 'dart:async';
import 'package:logger/logger.dart';
import '../../../features/todo/data/models/todo_model.dart';
import '../../../features/todo/data/datasources/todo_local_data_source.dart';
import '../../../features/todo/data/datasources/todo_remote_data_source.dart';
import '../network/network_info.dart';

/// Sync service responsible for coordinating offline-first synchronization
/// This service implements the Offline-First pattern
class SyncService {
  final TodoLocalDataSource localDataSource;
  final TodoRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  Timer? _syncTimer;
  final StreamController<SyncStatus> _syncStatusController =
      StreamController.broadcast();

  SyncService({
    required this.localDataSource,
    required this.remoteDataSource,
    required this.networkInfo,
    required this.logger,
  });

  Stream<SyncStatus> get syncStatusStream => _syncStatusController.stream;

  /// Start periodic synchronization
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _syncTimer = Timer.periodic(interval, (_) async {
      await performSync();
    });

    // Also listen to network changes to sync when coming back online
    _listenToNetworkChanges();
  }

  /// Perform synchronization between local and remote data
  Future<void> performSync() async {
    if (!await networkInfo.isConnected) {
      logger.w('No internet connection, skipping sync');
      _syncStatusController.add(SyncStatus.offline);
      return;
    }

    try {
      _syncStatusController.add(SyncStatus.syncing);
      logger.i('Starting synchronization...');

      // Get all local todos (including deleted ones for proper sync)
      final localTodos = await _getAllLocalTodosIncludingDeleted();

      // Sync with remote
      await remoteDataSource.syncTodos(localTodos);

      // In a real implementation, you would:
      // 1. Get server todos
      // 2. Compare versions and resolve conflicts
      // 3. Apply changes to local database

      _syncStatusController.add(SyncStatus.completed);
      logger.i('Synchronization completed successfully');
    } catch (e) {
      logger.e('Synchronization failed: $e');
      _syncStatusController.add(SyncStatus.failed);
    }
  }

  Future<List<TodoModel>> _getAllLocalTodosIncludingDeleted() async {
    // This is a simplified version - in reality, you'd need to modify
    // the local data source to get deleted items too for proper sync
    return await localDataSource.getAllTodos('user_1');
  }

  void _listenToNetworkChanges() {
    // Listen to connectivity changes and sync when coming back online
    Timer.periodic(const Duration(seconds: 10), (timer) async {
      final wasConnected = await networkInfo.isConnected;
      if (wasConnected) {
        await performSync();
      }
    });
  }

  /// Handle conflict resolution when the same todo is modified on multiple devices
  TodoModel resolveConflict(TodoModel localTodo, TodoModel remoteTodo) {
    // Last-write-wins conflict resolution based on version and timestamp
    if (remoteTodo.version > localTodo.version) {
      logger
          .i('Resolving conflict: Remote version wins for ${localTodo.title}');
      return remoteTodo;
    } else if (localTodo.version > remoteTodo.version) {
      logger.i('Resolving conflict: Local version wins for ${localTodo.title}');
      return localTodo;
    } else {
      // Same version, use timestamp
      if (remoteTodo.updatedAt.isAfter(localTodo.updatedAt)) {
        logger.i(
            'Resolving conflict: Remote timestamp wins for ${localTodo.title}');
        return remoteTodo;
      } else {
        logger.i(
            'Resolving conflict: Local timestamp wins for ${localTodo.title}');
        return localTodo;
      }
    }
  }

  void stopSync() {
    _syncTimer?.cancel();
  }

  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController.close();
  }
}

enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
  offline,
}
