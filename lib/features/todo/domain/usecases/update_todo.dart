import 'package:dartz/dartz.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/error/failures.dart';

/// Use case for updating a todo
class UpdateTodo {
  final TodoRepository repository;

  UpdateTodo(this.repository);

  Future<Either<Failure, Todo>> call(Todo todo) async {
    if (todo.title.trim().isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }

    final updatedTodo = todo.copyWith(
      title: todo.title.trim(),
      description: todo.description?.trim(),
      updatedAt: DateTime.now(),
      version: todo.version + 1,
    );

    return await repository.updateTodo(updatedTodo);
  }
}
