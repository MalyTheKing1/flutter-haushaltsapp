import 'package:flutter/material.dart';
import '../models/chore.dart';

/// Widget für einen Haushaltsaufgaben-Eintrag
class ChoreItem extends StatelessWidget {
  final Chore chore;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const ChoreItem({
    super.key,
    required this.chore,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(chore.title),
      leading: Checkbox(
        value: chore.isDone,
        onChanged: (_) => onToggle(),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDelete,
      ),
    );
  }
}