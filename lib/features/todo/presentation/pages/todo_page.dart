import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/todo_bloc.dart';
import '../widgets/todo_item.dart';
import '../widgets/add_todo_dialog.dart';
import '../../../../injection_container.dart';

class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TodoBloc>()
        ..add(LoadTodos())
        ..add(WatchTodosEvent()),
      child: const TodoView(),
    );
  }
}

class TodoView extends StatelessWidget {
  const TodoView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'My Todos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          BlocBuilder<TodoBloc, TodoState>(
            builder: (context, state) {
              return IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync todos',
                onPressed: () {
                  context.read<TodoBloc>().add(SyncTodosEvent());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing todos...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<TodoBloc, TodoState>(
        listener: (context, state) {
          if (state is TodoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    context.read<TodoBloc>().add(LoadTodos());
                  },
                ),
              ),
            );
          } else if (state is TodoSyncError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync error: ${state.errorMessage}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TodoLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TodoError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TodoBloc>().add(LoadTodos());
                    },
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (state is TodoLoaded || state is TodoSyncError) {
            final todos = state is TodoLoaded
                ? state.todos
                : (state as TodoSyncError).todos;

            if (todos.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No todos yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the + button to create your first todo',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Status indicator
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: state is TodoSyncError
                        ? Colors.orange[50]
                        : Colors.green[50],
                    border: Border(
                      bottom: BorderSide(
                        color: state is TodoSyncError
                            ? Colors.orange[200]!
                            : Colors.green[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        state is TodoSyncError
                            ? Icons.sync_problem
                            : Icons.sync,
                        color: state is TodoSyncError
                            ? Colors.orange[700]
                            : Colors.green[700],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state is TodoSyncError
                            ? 'Working offline - Changes will sync when online'
                            : 'All changes synchronized',
                        style: TextStyle(
                          color: state is TodoSyncError
                              ? Colors.orange[700]
                              : Colors.green[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Todos list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<TodoBloc>().add(SyncTodosEvent());
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: todos.length,
                      itemBuilder: (context, index) {
                        return TodoItem(
                          todo: todos[index],
                          onToggle: () {
                            context.read<TodoBloc>().add(
                                  ToggleTodoCompletionEvent(todos[index].id),
                                );
                          },
                          onDelete: () {
                            context.read<TodoBloc>().add(
                                  DeleteTodoEvent(todos[index].id),
                                );
                          },
                          onEdit: (updatedTodo) {
                            context.read<TodoBloc>().add(
                                  UpdateTodoEvent(updatedTodo),
                                );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        onPressed: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AddTodoDialog(
              onAdd: (title, description) {
                context.read<TodoBloc>().add(
                      CreateTodoEvent(
                        title: title,
                        description: description,
                      ),
                    );
                Navigator.of(dialogContext).pop();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
