import 'package:dartz/dartz.dart';
import '../repositories/todo_repository.dart';
import '../../../../core/error/failures.dart';

/// Use case for syncing todos with remote server
class SyncTodos {
  final TodoRepository repository;

  SyncTodos(this.repository);

  Future<Either<Failure, void>> call() async {
    return await repository.syncTodos();
  }
}
