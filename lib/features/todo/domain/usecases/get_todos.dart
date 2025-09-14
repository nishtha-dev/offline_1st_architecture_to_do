import 'package:dartz/dartz.dart';
import '../entities/todo.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/error/failures.dart';

/// Use case for getting all todos for a user
class GetTodos {
  final TodoRepository repository;

  GetTodos(this.repository);

  Future<Either<Failure, List<Todo>>> call(String userId) async {
    return await repository.getTodos(userId);
  }
}
