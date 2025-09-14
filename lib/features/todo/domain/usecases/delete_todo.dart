import 'package:dartz/dartz.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/error/failures.dart';

/// Use case for deleting a todo
class DeleteTodo {
  final TodoRepository repository;

  DeleteTodo(this.repository);

  Future<Either<Failure, void>> call(String id) async {
    if (id.trim().isEmpty) {
      return const Left(ValidationFailure('Todo ID cannot be empty'));
    }

    return await repository.deleteTodo(id);
  }
}
