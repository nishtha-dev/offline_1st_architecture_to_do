import 'package:dartz/dartz.dart';
import '../entities/todo.dart';
import '../../../../core/error/failures.dart';

/// Repository interface following the Repository pattern
/// This abstracts the data layer from the domain layer
abstract class TodoRepository {
  /// Get all todos for a specific user
  Future<Either<Failure, List<Todo>>> getTodos(String userId);

  /// Get a specific todo by id
  Future<Either<Failure, Todo?>> getTodoById(String id);

  /// Create a new todo
  Future<Either<Failure, Todo>> createTodo({
    required String title,
    String? description,
    required String userId,
  });

  /// Update an existing todo
  Future<Either<Failure, Todo>> updateTodo(Todo todo);

  /// Delete a todo (soft delete for sync purposes)
  Future<Either<Failure, void>> deleteTodo(String id);

  /// Toggle todo completion status
  Future<Either<Failure, Todo>> toggleTodoCompletion(String id);

  /// Sync todos with remote server
  Future<Either<Failure, void>> syncTodos();

  /// Stream of todos for real-time updates
  Stream<List<Todo>> watchTodos(String userId);
}
