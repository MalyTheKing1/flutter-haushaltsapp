import 'package:flutter/material.dart';
import '../models/todo.dart';

/// Widget für einen To-Do-Eintrag
class TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onDelete;

  const TodoItem({
    super.key,
    required this.todo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(todo.title),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}