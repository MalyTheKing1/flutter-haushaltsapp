import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../models/recurring_task.dart';
import '../services/hive_service.dart';

/// UI-Element für wiederkehrende Aufgaben
class RecurringTaskItem extends StatelessWidget {
  final RecurringTask task;

  const RecurringTaskItem({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text('Alle ${task.intervalDays} Tage'),
        trailing: Checkbox(
          value: task.isDone,
          onChanged: (value) {
            task.isDone = value ?? false;
            if (task.isDone) {
              task.lastDoneDate = DateTime.now();
            }
            task.save();
          },
        ),
        onLongPress: () {
          Hive.box<RecurringTask>(HiveService.recurringBoxName)
              .delete(task.key);
        },
      ),
    );
  }
}
