import 'package:flutter/material.dart';
import '../../domain/entities/todo.dart';

class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final Function(Todo) onEdit;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: Colors.green[600],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted ? Colors.grey[600] : Colors.grey[800],
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        subtitle: todo.description != null && todo.description!.isNotEmpty
            ? Text(
                todo.description!,
                style: TextStyle(
                  decoration:
                      todo.isCompleted ? TextDecoration.lineThrough : null,
                  color: todo.isCompleted ? Colors.grey[500] : Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show sync status indicator
            if (todo.version > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'v${todo.version}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey[600],
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(context);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(context);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: todo.title);
    final descriptionController =
        TextEditingController(text: todo.description ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final updatedTodo = todo.copyWith(
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                  updatedAt: DateTime.now(),
                  version: todo.version + 1,
                );
                onEdit(updatedTodo);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              onDelete();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
