import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/todo.dart';
import '../../domain/usecases/create_todo.dart';
import '../../domain/usecases/delete_todo.dart';
import '../../domain/usecases/get_todos.dart';
import '../../domain/usecases/sync_todos.dart';
import '../../domain/usecases/toggle_todo_completion.dart';
import '../../domain/usecases/update_todo.dart';
import '../../domain/usecases/watch_todos.dart';
import '../../../../core/error/failures.dart';

part 'todo_event.dart';
part 'todo_state.dart';

/// BLoC for managing todo state following the BLoC pattern
/// This separates business logic from UI following Clean Architecture
class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final GetTodos getTodos;
  final CreateTodo createTodo;
  final UpdateTodo updateTodo;
  final DeleteTodo deleteTodo;
  final ToggleTodoCompletion toggleTodoCompletion;
  final SyncTodos syncTodos;
  final WatchTodos watchTodos;

  static const String currentUserId = 'user_1'; // Simplified for demo

  TodoBloc({
    required this.getTodos,
    required this.createTodo,
    required this.updateTodo,
    required this.deleteTodo,
    required this.toggleTodoCompletion,
    required this.syncTodos,
    required this.watchTodos,
  }) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<CreateTodoEvent>(_onCreateTodo);
    on<UpdateTodoEvent>(_onUpdateTodo);
    on<DeleteTodoEvent>(_onDeleteTodo);
    on<ToggleTodoCompletionEvent>(_onToggleTodoCompletion);
    on<SyncTodosEvent>(_onSyncTodos);
    on<WatchTodosEvent>(_onWatchTodos);
    on<TodosUpdated>(_onTodosUpdated);
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoState> emit) async {
    emit(TodoLoading());

    final result = await getTodos(currentUserId);

    result.fold(
      (failure) => emit(TodoError(_mapFailureToMessage(failure))),
      (todos) => emit(TodoLoaded(todos)),
    );
  }

  Future<void> _onCreateTodo(
      CreateTodoEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      emit(TodoLoading());

      final result = await createTodo(
        title: event.title,
        description: event.description,
        userId: currentUserId,
      );

      result.fold(
        (failure) => emit(TodoError(_mapFailureToMessage(failure))),
        (newTodo) {
          final updatedTodos = List<Todo>.from(currentState.todos)
            ..insert(0, newTodo);
          emit(TodoLoaded(updatedTodos));
        },
      );
    }
  }

  Future<void> _onUpdateTodo(
      UpdateTodoEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      emit(TodoLoading());

      final result = await updateTodo(event.todo);

      result.fold(
        (failure) => emit(TodoError(_mapFailureToMessage(failure))),
        (updatedTodo) {
          final updatedTodos = currentState.todos
              .map((todo) => todo.id == updatedTodo.id ? updatedTodo : todo)
              .toList();
          emit(TodoLoaded(updatedTodos));
        },
      );
    }
  }

  Future<void> _onDeleteTodo(
      DeleteTodoEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      emit(TodoLoading());

      final result = await deleteTodo(event.id);

      result.fold(
        (failure) => emit(TodoError(_mapFailureToMessage(failure))),
        (_) {
          final updatedTodos =
              currentState.todos.where((todo) => todo.id != event.id).toList();
          emit(TodoLoaded(updatedTodos));
        },
      );
    }
  }

  Future<void> _onToggleTodoCompletion(
      ToggleTodoCompletionEvent event, Emitter<TodoState> emit) async {
    if (state is TodoLoaded) {
      final currentState = state as TodoLoaded;
      emit(TodoLoading());

      final result = await toggleTodoCompletion(event.id);

      result.fold(
        (failure) => emit(TodoError(_mapFailureToMessage(failure))),
        (updatedTodo) {
          final updatedTodos = currentState.todos
              .map((todo) => todo.id == updatedTodo.id ? updatedTodo : todo)
              .toList();
          emit(TodoLoaded(updatedTodos));
        },
      );
    }
  }

  Future<void> _onSyncTodos(
      SyncTodosEvent event, Emitter<TodoState> emit) async {
    // Don't show loading for sync as it should be background operation
    final result = await syncTodos();

    result.fold(
      (failure) {
        // For sync failures, we might want to show a snackbar instead of full error
        if (state is TodoLoaded) {
          final currentState = state as TodoLoaded;
          emit(
              TodoSyncError(currentState.todos, _mapFailureToMessage(failure)));
        }
      },
      (_) {
        // Refresh todos after successful sync
        add(LoadTodos());
      },
    );
  }

  Future<void> _onWatchTodos(
      WatchTodosEvent event, Emitter<TodoState> emit) async {
    await emit.forEach(
      watchTodos(currentUserId),
      onData: (todos) => TodoLoaded(todos),
      onError: (error, stackTrace) => TodoError(error.toString()),
    );
  }

  void _onTodosUpdated(TodosUpdated event, Emitter<TodoState> emit) {
    emit(TodoLoaded(event.todos));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return 'Server error occurred. Please try again later.';
      case CacheFailure:
        return 'Local storage error occurred.';
      case NetworkFailure:
        return 'No internet connection. Working offline.';
      case ValidationFailure:
        return (failure as ValidationFailure).message;
      case SyncFailure:
        return 'Sync failed: ${(failure as SyncFailure).message}';
      case ConflictFailure:
        return 'Conflict occurred: ${(failure as ConflictFailure).message}';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
