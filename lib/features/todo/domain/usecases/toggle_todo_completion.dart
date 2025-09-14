import 'package:dartz/dartz.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/error/failures.dart';

/// Use case for toggling todo completion status
class ToggleTodoCompletion {
  final TodoRepository repository;

  ToggleTodoCompletion(this.repository);

  Future<Either<Failure, Todo>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(ValidationFailure('Todo ID cannot be empty'));
    }

    return await repository.toggleTodoCompletion(id);
  }
}
