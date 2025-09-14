part of 'todo_bloc.dart';

/// Base class for all todo states
abstract class TodoState extends Equatable {
  const TodoState();

  @override
  List<Object> get props => [];
}

/// Initial state
class TodoInitial extends TodoState {}

/// Loading state
class TodoLoading extends TodoState {}

/// Loaded state with todos
class TodoLoaded extends TodoState {
  final List<Todo> todos;

  const TodoLoaded(this.todos);

  @override
  List<Object> get props => [todos];
}

/// Error state
class TodoError extends TodoState {
  final String message;

  const TodoError(this.message);

  @override
  List<Object> get props => [message];
}

/// Sync error state (still shows todos but with error message)
class TodoSyncError extends TodoLoaded {
  final String errorMessage;

  const TodoSyncError(super.todos, this.errorMessage);

  @override
  List<Object> get props => [todos, errorMessage];
}
