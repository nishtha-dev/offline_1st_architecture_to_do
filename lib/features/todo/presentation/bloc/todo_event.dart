part of 'todo_bloc.dart';

/// Base class for all todo events
abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load todos
class LoadTodos extends TodoEvent {}

/// Event to create a new todo
class CreateTodoEvent extends TodoEvent {
  final String title;
  final String? description;

  const CreateTodoEvent({
    required this.title,
    this.description,
  });

  @override
  List<Object?> get props => [title, description];
}

/// Event to update a todo
class UpdateTodoEvent extends TodoEvent {
  final Todo todo;

  const UpdateTodoEvent(this.todo);

  @override
  List<Object> get props => [todo];
}

/// Event to delete a todo
class DeleteTodoEvent extends TodoEvent {
  final String id;

  const DeleteTodoEvent(this.id);

  @override
  List<Object> get props => [id];
}

/// Event to toggle todo completion
class ToggleTodoCompletionEvent extends TodoEvent {
  final String id;

  const ToggleTodoCompletionEvent(this.id);

  @override
  List<Object> get props => [id];
}

/// Event to sync todos
class SyncTodosEvent extends TodoEvent {}

/// Event to start watching todos
class WatchTodosEvent extends TodoEvent {}

/// Event when todos are updated (from real-time updates)
class TodosUpdated extends TodoEvent {
  final List<Todo> todos;

  const TodosUpdated(this.todos);

  @override
  List<Object> get props => [todos];
}
