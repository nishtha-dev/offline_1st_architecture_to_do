import '../models/todo_model.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/error/exceptions.dart';
import 'package:sqflite/sqflite.dart';

/// Local data source using SQLite for offline storage
abstract class TodoLocalDataSource {
  Future<List<TodoModel>> getAllTodos(String userId);
  Future<TodoModel?> getTodoById(String id);
  Future<TodoModel> insertTodo(TodoModel todo);
  Future<TodoModel> updateTodo(TodoModel todo);
  Future<void> deleteTodo(String id);
  Future<void> clearAllTodos();
  Stream<List<TodoModel>> watchTodos(String userId);
}

class TodoLocalDataSourceImpl implements TodoLocalDataSource {
  final DatabaseHelper databaseHelper;

  TodoLocalDataSourceImpl({required this.databaseHelper});

  @override
  Future<List<TodoModel>> getAllTodos(String userId) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.todoTable,
        where:
            '${DatabaseHelper.columnUserId} = ? AND ${DatabaseHelper.columnDeleted} = ?',
        whereArgs: [userId, 0],
        orderBy: '${DatabaseHelper.columnUpdatedAt} DESC',
      );

      return List.generate(maps.length, (i) => TodoModel.fromMap(maps[i]));
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<TodoModel?> getTodoById(String id) async {
    try {
      final db = await databaseHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.todoTable,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return TodoModel.fromMap(maps.first);
      }
      return null;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<TodoModel> insertTodo(TodoModel todo) async {
    try {
      final db = await databaseHelper.database;
      await db.insert(
        DatabaseHelper.todoTable,
        todo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return todo;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.todoTable,
        todo.toMap(),
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [todo.id],
      );
      return todo;
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> deleteTodo(String id) async {
    try {
      final db = await databaseHelper.database;
      await db.update(
        DatabaseHelper.todoTable,
        {
          DatabaseHelper.columnDeleted: 1,
          DatabaseHelper.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Future<void> clearAllTodos() async {
    try {
      final db = await databaseHelper.database;
      await db.delete(DatabaseHelper.todoTable);
    } catch (e) {
      throw CacheException();
    }
  }

  @override
  Stream<List<TodoModel>> watchTodos(String userId) async* {
    // For SQLite, we'll poll every second (in a real app, you might use database triggers or other mechanisms)
    while (true) {
      try {
        yield await getAllTodos(userId);
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        throw CacheException();
      }
    }
  }
}
