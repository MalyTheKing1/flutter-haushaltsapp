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

        // 👉 NEU: Dynamisches Bottom-Padding berechnen, damit der FAB keine Items verdeckt
        const double fabHeight = 56.0;     // Standardgröße des FAB
        const double fabMargin = 16.0;     // Standardabstand vom Rand
        const double extraSpacing = 12.0;  // etwas Luft darüber
        final double bottomSafe = MediaQuery.of(context).padding.bottom;
        final double bottomPadding = fabHeight + fabMargin + extraSpacing + bottomSafe;

        return Scaffold(
          appBar: AppBar(title: const Text('To-Do Liste')),
          body: ReorderableListView.builder(
            itemCount: tasks.length,
            onReorder: _onReorder,
            // ⚠️ Eigene Drag-Handles verwenden, damit Long-Press-Delay greift
            buildDefaultDragHandles: false,
            // 👉 NEU: Padding unten, damit der FAB die letzten Einträge nicht überlappt
            padding: EdgeInsets.only(top: 8, bottom: bottomPadding),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Container(
                key: ValueKey(task.key), // stabiler Key für Reorder
                child: OnetimeTaskItem(
                  // ➕ Kompaktes Drag-Handle: etwas größer, aber schmaler Abstand
                  leading: ReorderableDragStartListener(
                    index: index, // Reorder startet nach ~0,5s Hold auf dem Icon
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2.0), // schmaler
                      child: Icon(Icons.drag_handle, size: 22), // größer
                    ),
                  ),
                  task: task,
                  onDelete: () => _deleteTask(index),
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
    final deletedTask = _box.getAt(index);
    if (deletedTask == null) return;

    _box.deleteAt(index);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Aufgabe "${deletedTask.title}" erledigt'),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: () async {
            final oldTasks = _box.values.toList();
            oldTasks.insert(index, deletedTask);

            await _box.clear();
            for (final task in oldTasks) {
              await _box.add(OneTimeTask(title: task.title));
            }
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
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
