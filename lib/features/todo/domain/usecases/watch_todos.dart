import '../entities/todo.dart';
import '../repositories/todo_repository.dart';

/// Use case for watching todos in real-time
class WatchTodos {
  final TodoRepository repository;

  WatchTodos(this.repository);

  Stream<List<Todo>> call(String userId) {
    return repository.watchTodos(userId);
  }
}
