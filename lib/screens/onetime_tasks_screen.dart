import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/onetime_task.dart';
import '../services/hive_service.dart';
import '../widgets/onetime_task_item.dart';

/// Tab 2: Einmalige Aufgaben
class OneTimeTasksScreen extends StatefulWidget {
  const OneTimeTasksScreen({super.key});

  @override
  State<OneTimeTasksScreen> createState() => _OneTimeTasksScreenState();
}

class _OneTimeTasksScreenState extends State<OneTimeTasksScreen> {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable:
          Hive.box<OneTimeTask>(HiveService.onetimeBoxName).listenable(),
      builder: (context, Box<OneTimeTask> box, _) {
        final tasks = box.values.toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Einmalige Aufgaben')),
          body: ReorderableListView.builder(
            itemCount: tasks.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex--;
                final item = tasks.removeAt(oldIndex);
                tasks.insert(newIndex, item);
                box.clear();
                box.addAll(tasks);
              });
            },
            itemBuilder: (context, index) {
              return OneTimeTaskItem(
                key: ValueKey(tasks[index]),
                task: tasks[index],
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

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Neue Aufgabe'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: 'Titel'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Hive.box<OneTimeTask>(HiveService.onetimeBoxName).add(
                  OneTimeTask(title: titleController.text),
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
