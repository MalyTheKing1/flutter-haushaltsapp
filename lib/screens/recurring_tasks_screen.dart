import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recurring_task.dart';
import '../services/hive_service.dart';
import '../widgets/recurring_task_item.dart';

/// Bildschirm für wiederkehrende Aufgaben (Tab 1)
class RecurringTasksScreen extends StatelessWidget {
  const RecurringTasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<RecurringTask>(HiveService.recurringBoxName).listenable(),
      builder: (context, Box<RecurringTask> box, _) {
        final tasks = box.values.toList();

        // Erledigte Tasks automatisch zurücksetzen, wenn wieder fällig
        for (var task in tasks) {
          if (task.isDone && task.isDue) {
            task.isDone = false;
            task.save(); // Speichert die Änderung in Hive
          }
        }

        // Aufteilen in offene und erledigte Tasks
        final openTasks = tasks.where((t) => !t.isDone).toList();
        final doneTasks = tasks.where((t) => t.isDone).toList();

        // Offene Tasks nach Intervall (kleinster zuerst) sortieren
        openTasks.sort((a, b) => a.intervalDays.compareTo(b.intervalDays));

        // Erledigte Tasks nach nächster Fälligkeit sortieren (früheste zuerst)
        doneTasks.sort((a, b) {
          final aDueDate = a.lastDoneDate.add(Duration(days: a.intervalDays));
          final bDueDate = b.lastDoneDate.add(Duration(days: b.intervalDays));
          return aDueDate.compareTo(bDueDate);
        });

        // Kombinierte Liste (offen oben, erledigt unten)
        final sortedTasks = [...openTasks, ...doneTasks];

        return Scaffold(
          appBar: AppBar(title: const Text('Wiederkehrende Aufgaben')),
          body: ListView.builder(
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              return RecurringTaskItem(task: sortedTasks[index]);
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

  /// Dialog zum Hinzufügen einer neuen Aufgabe (bleibt unverändert)
  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final intervalController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neue wiederkehrende Aufgabe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration:
                    const InputDecoration(labelText: 'Aufgabenname'),
              ),
              TextField(
                controller: intervalController,
                decoration:
                    const InputDecoration(labelText: 'Intervall (Tage)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final interval = int.tryParse(intervalController.text.trim());
                if (title.isNotEmpty && interval != null && interval > 0) {
                  final box = Hive.box<RecurringTask>(
                      HiveService.recurringBoxName);
                  box.add(RecurringTask(title: title, intervalDays: interval));
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Hinzufügen'),
            ),
          ],
        );
      },
    );
  }
}
