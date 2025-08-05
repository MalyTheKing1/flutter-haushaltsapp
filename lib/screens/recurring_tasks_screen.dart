import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recurring_task.dart';
import '../services/hive_service.dart';
import '../widgets/recurring_task_item.dart';

/// Tab 1: Wiederkehrende Aufgaben
class RecurringTasksScreen extends StatelessWidget {
  const RecurringTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<RecurringTask>(HiveService.recurringBoxName).listenable(),
      builder: (context, Box<RecurringTask> box, _) {
        final tasks = box.values.toList();

        // Sortieren: Fällige oben, erledigte unten
        tasks.sort((a, b) {
          if (a.isDue && !b.isDue) return -1;
          if (!a.isDue && b.isDue) return 1;
          if (a.isDone && !b.isDone) return 1;
          if (!a.isDone && b.isDone) return -1;
          return 0;
        });

        return Scaffold(
          appBar: AppBar(title: const Text('Wiederkehrende Aufgaben')),
          body: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              return RecurringTaskItem(task: tasks[index]);
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final intervalController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neue Aufgabe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            TextField(
              controller: intervalController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Intervall (Tage)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty &&
                  int.tryParse(intervalController.text) != null) {
                Hive.box<RecurringTask>(HiveService.recurringBoxName).add(
                  RecurringTask(
                    title: titleController.text,
                    intervalDays: int.parse(intervalController.text),
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}
