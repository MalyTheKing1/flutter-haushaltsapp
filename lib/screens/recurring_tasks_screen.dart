import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recurring_task.dart';
import '../services/hive_service.dart';
import '../widgets/recurring_task_item.dart';

/// Bildschirm für wiederkehrende Aufgaben (Tab 1)
class RecurringTasksScreen extends StatefulWidget {
  const RecurringTasksScreen({super.key});

  @override
  State<RecurringTasksScreen> createState() => _RecurringTasksScreenState();
}

class _RecurringTasksScreenState extends State<RecurringTasksScreen> {
  // Timer für verzögerte Sortierung nach Checkbox-Änderung
  Timer? _sortDelayTimer;
  // Key für die abgehakte Task, um Animation zu steuern
  String? _recentlyCheckedTaskKey;
  
  @override
  void dispose() {
    _sortDelayTimer?.cancel();
    super.dispose();
  }

  /// Sortiert Tasks 
  List<RecurringTask> _getSortedTasks(List<RecurringTask> tasks) {
    // Erledigte Tasks automatisch zurücksetzen, wenn wieder fällig
    for (var task in tasks) {
      if (task.isDone && task.isDue) {
        task.isDone = false;
        task.save();
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
    return [...openTasks, ...doneTasks];
  }

  /// Callback für RecurringTaskItem wenn Checkbox geändert wird
  void _onTaskCheckChanged(RecurringTask task) {
    // Merke dir welche Task gerade geändert wurde
    setState(() {
      _recentlyCheckedTaskKey = task.key.toString();
    });
    
    // Nach kurzer Zeit die Sortierung wieder normal laufen lassen
    _sortDelayTimer?.cancel();
    _sortDelayTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted) {
        setState(() {
          _recentlyCheckedTaskKey = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<RecurringTask>(HiveService.recurringBoxName).listenable(),
      builder: (context, Box<RecurringTask> box, _) {
        final tasks = box.values.toList();
        final sortedTasks = _getSortedTasks(tasks);

        return Scaffold(
          appBar: AppBar(title: const Text('Wiederkehrende Aufgaben')),
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80), // Platz für FAB
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final task = sortedTasks[index];
              final isRecentlyChanged = _recentlyCheckedTaskKey == task.key.toString();
              
              return AnimatedContainer(
                duration: Duration(milliseconds: isRecentlyChanged ? 600 : 300),
                curve: Curves.easeInOut,
                // Sanfte Transformation für die kürzlich geänderte Task
                transform: isRecentlyChanged 
                  ? (Matrix4.identity()..scale(0.98)..translate(8.0, 0.0))
                  : Matrix4.identity(),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: isRecentlyChanged ? 400 : 200),
                  opacity: isRecentlyChanged
                      ? 0.7 // kurz nach Änderung etwas blasser
                      : (task.isDone ? 0.3 : 1.0), // erledigte Aufgaben dauerhaft blasser
                  child: RecurringTaskItem(
                    task: task,
                    onCheckChanged: () => _onTaskCheckChanged(task),
                  ),
                ),
              );
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