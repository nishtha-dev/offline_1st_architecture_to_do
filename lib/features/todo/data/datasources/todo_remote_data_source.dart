import 'dart:async';
import 'package:dio/dio.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:logger/logger.dart';
import '../models/todo_model.dart';
import '../../../../core/error/exceptions.dart';

/// Remote data source for syncing with server and real-time updates
abstract class TodoRemoteDataSource {
  Future<List<TodoModel>> getAllTodos(String userId);
  Future<TodoModel> createTodo(TodoModel todo);
  Future<TodoModel> updateTodo(TodoModel todo);
  Future<void> deleteTodo(String id);
  Stream<TodoModel> watchTodoUpdates();
  Future<void> syncTodos(List<TodoModel> localTodos);
}

class TodoRemoteDataSourceImpl implements TodoRemoteDataSource {
  final Dio dio;
  final String baseUrl;
  final Logger logger;
  WebSocketChannel? _channel;
  final StreamController<TodoModel> _todoUpdatesController =
      StreamController.broadcast();

  TodoRemoteDataSourceImpl({
    required this.dio,
    required this.baseUrl,
    required this.logger,
  });

  // Mock WebSocket connection for testing
  void _initializeWebSocket() {
    try {
      // In a real app, this would connect to your WebSocket server
      // For now, we'll create a mock WebSocket that simulates other users' changes
      _simulateWebSocketConnection();
    } catch (e) {
      logger.e('Failed to connect to WebSocket: $e');
    }
  }

  void _simulateWebSocketConnection() {
    // Simulate receiving updates from other devices/users
    Timer.periodic(const Duration(seconds: 10), (timer) {
      // Simulate a random update from another device
      if (_shouldSimulateUpdate()) {
        final mockUpdate = _generateMockTodoUpdate();
        _todoUpdatesController.add(mockUpdate);
        logger.i('Simulated update received: ${mockUpdate.title}');
      }
    });
  }

  bool _shouldSimulateUpdate() {
    // 30% chance of simulating an update every 10 seconds
    return DateTime.now().millisecond % 10 < 3;
  }

  TodoModel _generateMockTodoUpdate() {
    final now = DateTime.now();
    final mockTodos = [
      'Buy groceries - Updated by Device B',
      'Complete project report - Modified on Phone',
      'Call dentist - Changed by Tablet',
      'Review code - Updated by Laptop',
    ];

    return TodoModel(
      id: 'mock_${now.millisecondsSinceEpoch}',
      title: mockTodos[now.second % mockTodos.length],
      description: 'This todo was updated by another device/user',
      isCompleted: now.second % 2 == 0,
      createdAt: now.subtract(const Duration(hours: 1)),
      updatedAt: now,
      userId: 'user_1', // Mock user ID
      version: now.millisecond % 5 + 1,
    );
  }

  @override
  Future<List<TodoModel>> getAllTodos(String userId) async {
    try {
      // Mock API call - in real implementation, this would be a REST API call
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simulate network delay

      // Return mock data
      return _generateMockTodos(userId);
    } catch (e) {
      throw ServerException();
    }
  }

  List<TodoModel> _generateMockTodos(String userId) {
    final now = DateTime.now();
    return [
      TodoModel(
        id: 'remote_1',
        title: 'Sync from server',
        description: 'This todo came from the server',
        isCompleted: false,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        userId: userId,
        version: 1,
      ),
      TodoModel(
        id: 'remote_2',
        title: 'Multi-device todo',
        description: 'This todo was created on another device',
        isCompleted: true,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        userId: userId,
        version: 2,
      ),
    ];
  }

  @override
  Future<TodoModel> createTodo(TodoModel todo) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      logger.i('Created todo remotely: ${todo.title}');
      return todo;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      logger.i('Updated todo remotely: ${todo.title}');
      return todo;
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      logger.i('Deleted todo remotely: $id');
    } catch (e) {
      throw ServerException();
    }
  }

  @override
  Stream<TodoModel> watchTodoUpdates() {
    if (_channel == null) {
      _initializeWebSocket();
    }
    return _todoUpdatesController.stream;
  }

  @override
  Future<void> syncTodos(List<TodoModel> localTodos) async {
    try {
      logger.i('Syncing ${localTodos.length} todos with server...');

      // Simulate sync process
      await Future.delayed(const Duration(seconds: 1));

      // In a real implementation, this would:
      // 1. Send local changes to server
      // 2. Receive server changes
      // 3. Resolve conflicts using version numbers
      // 4. Return merged data

      logger.i('Sync completed successfully');
    } catch (e) {
      logger.e('Sync failed: $e');
      throw ServerException();
    }
  }

  void dispose() {
    _channel?.sink.close();
    _todoUpdatesController.close();
  }
}
