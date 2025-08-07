import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recurring_task.dart';
import '../services/hive_service.dart';
import '../widgets/recurring_task_item.dart';

class RecurringTasksScreen extends StatefulWidget {
  const RecurringTasksScreen({super.key});

  @override
  State<RecurringTasksScreen> createState() => _RecurringTasksScreenState();
}

class _RecurringTasksScreenState extends State<RecurringTasksScreen> {
  Timer? _sortDelayTimer;
  String? _recentlyCheckedTaskKey;

  @override
  void dispose() {
    _sortDelayTimer?.cancel();
    super.dispose();
  }

  List<RecurringTask> _getSortedTasks(List<RecurringTask> tasks) {
    for (var task in tasks) {
      if (task.isDone && task.isDue) {
        task.isDone = false;
        task.save();
      }
    }

    final openTasks = tasks.where((t) => !t.isDone).toList();
    final doneTasks = tasks.where((t) => t.isDone).toList();

    openTasks.sort((a, b) => a.intervalDays.compareTo(b.intervalDays));

    doneTasks.sort((a, b) {
      final aDueDate = a.lastDoneDate.add(Duration(days: a.intervalDays));
      final bDueDate = b.lastDoneDate.add(Duration(days: b.intervalDays));
      return aDueDate.compareTo(bDueDate);
    });

    return [...openTasks, ...doneTasks];
  }

  void _onTaskCheckChanged(RecurringTask task) {
    setState(() {
      _recentlyCheckedTaskKey = task.key.toString();
    });

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
      valueListenable: Hive.box<RecurringTask>(HiveService.recurringBoxName).listenable(),
      builder: (context, Box<RecurringTask> box, _) {
        final tasks = box.values.toList();
        final sortedTasks = _getSortedTasks(tasks);

        return Scaffold(
          appBar: AppBar(title: const Text('Wiederkehrende Aufgaben')),
          body: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: sortedTasks.length,
            itemBuilder: (context, index) {
              final task = sortedTasks[index];
              final isRecentlyChanged = _recentlyCheckedTaskKey == task.key.toString();

              return AnimatedContainer(
                duration: Duration(milliseconds: isRecentlyChanged ? 600 : 300),
                curve: Curves.easeInOut,
                transform: isRecentlyChanged
                    ? (Matrix4.identity()..scale(0.98)..translate(8.0, 0.0))
                    : Matrix4.identity(),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: isRecentlyChanged ? 400 : 200),
                  opacity: isRecentlyChanged
                      ? 0.7
                      : (task.isDone ? 0.3 : 1.0),
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

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final intervalController = TextEditingController();
    final iconOptions = [
      'broom.png',
      'house.png',
      'oven.png',
      'plant.png',
      'toilet.png',
      'trash.png',
      'vacuum.png',
    ];
    String selectedIcon = 'house.png';

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
                decoration: const InputDecoration(labelText: 'Aufgabenname'),
              ),
              TextField(
                controller: intervalController,
                decoration: const InputDecoration(labelText: 'Intervall (Tage)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedIcon,
                items: iconOptions.map((icon) {
                  return DropdownMenuItem(
                    value: icon,
                    child: Row(
                      children: [
                        Image.asset('assets/icons/$icon', width: 24, height: 24),
                        const SizedBox(width: 8),
                        Text(icon.replaceAll('.png', '')),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedIcon = value;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Icon'),
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
                  final box = Hive.box<RecurringTask>(HiveService.recurringBoxName);
                  box.add(RecurringTask(
                    title: title,
                    intervalDays: interval,
                    iconName: selectedIcon,
                  ));
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
