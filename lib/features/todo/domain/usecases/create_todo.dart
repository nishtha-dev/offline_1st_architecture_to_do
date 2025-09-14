import 'package:dartz/dartz.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/error/failures.dart';

/// Use case for creating a new todo
class CreateTodo {
  final TodoRepository repository;

  CreateTodo(this.repository);

  Future<Either<Failure, Todo>> call({
    required String title,
    String? description,
    required String userId,
  }) async {
    if (title.trim().isEmpty) {
      return const Left(ValidationFailure('Title cannot be empty'));
    }

    return await repository.createTodo(
      title: title.trim(),
      description: description?.trim(),
      userId: userId,
    );
  }
}
