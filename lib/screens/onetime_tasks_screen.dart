import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/onetime_task.dart';
import '../services/hive_service.dart';
import '../widgets/onetime_task_item.dart';

/// Bildschirm für einmalige Aufgaben (Tab 2)
class OneTimeTasksScreen extends StatefulWidget {
  const OneTimeTasksScreen({super.key});

  @override
  State<OneTimeTasksScreen> createState() => _OneTimeTasksScreenState();
}

class _OneTimeTasksScreenState extends State<OneTimeTasksScreen> {
  late Box<OneTimeTask> _box;

  @override
  void initState() {
    super.initState();
    _box = Hive.box<OneTimeTask>(HiveService.onetimeBoxName);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _box.listenable(),
      builder: (context, Box<OneTimeTask> box, _) {
        final tasks = box.values.toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Einmalige To-Dos')),
          body: ReorderableListView.builder(
            itemCount: tasks.length,
            onReorder: _onReorder,
            buildDefaultDragHandles: true,
            itemBuilder: (context, index) {
              return OnetimeTaskItem(
                key: ValueKey(tasks[index].key),
                task: tasks[index],
                onDelete: () => _deleteTask(index),
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

  /// Neue Position speichern nach Drag-and-Drop
  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;

    // Lokale Kopie erstellen
    final tasks = _box.values.toList();

    // Element verschieben
    final movedTask = tasks.removeAt(oldIndex);
    tasks.insert(newIndex, movedTask);

    // Schrittweise aktualisieren, ohne alles zu löschen
    for (int i = 0; i < tasks.length; i++) {
      _box.putAt(i, OneTimeTask(title: tasks[i].title));
    }
  }

  /// Aufgabe löschen beim Abhaken
  void _deleteTask(int index) {
    _box.deleteAt(index);
  }

  /// Dialog zum Hinzufügen einer neuen einmaligen Aufgabe
  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Neue einmalige Aufgabe'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Aufgabenname'),
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
                if (title.isNotEmpty) {
                  _box.add(OneTimeTask(title: title));
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
