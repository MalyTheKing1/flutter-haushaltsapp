import 'package:flutter/material.dart';
import '../models/recurring_task.dart';

/// Einzelne Listeneinträge für wiederkehrende Aufgaben
class RecurringTaskItem extends StatefulWidget {
  final RecurringTask task;

  const RecurringTaskItem({super.key, required this.task});

  @override
  State<RecurringTaskItem> createState() => _RecurringTaskItemState();
}

class _RecurringTaskItemState extends State<RecurringTaskItem> {
  @override
  void initState() {
    super.initState();
    // Beim Start prüfen, ob Haken entfernt werden muss
    if (widget.task.isDone) {
      final dueDate = widget.task.lastDoneDate
          .add(Duration(days: widget.task.intervalDays));
      if (DateTime.now().isAfter(dueDate)) {
        widget.task.isDone = false;
        widget.task.save();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    return ListTile(
      title: Text(task.title),
      subtitle: Text('Intervall: ${task.intervalDays} Tage'),
      trailing: Checkbox(
        value: task.isDone,
        onChanged: (value) {
          setState(() {
            task.isDone = value ?? false;
            if (task.isDone) {
              task.lastDoneDate = DateTime.now();
            }
            task.save();
          });
        },
      ),
      onLongPress: () => _showEditDialog(context, task),
    );
  }

  /// Dialog zum Bearbeiten der Aufgabe
  void _showEditDialog(BuildContext context, RecurringTask task) {
    final titleController = TextEditingController(text: task.title);
    final intervalController =
        TextEditingController(text: task.intervalDays.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Aufgabe bearbeiten'),
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
                final newTitle = titleController.text.trim();
                final newInterval = int.tryParse(intervalController.text.trim());
                if (newTitle.isNotEmpty && newInterval != null && newInterval > 0) {
                  task.title = newTitle;
                  task.intervalDays = newInterval;
                  task.save();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Speichern'),
            ),
            TextButton(
              onPressed: () {
                task.delete();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Löschen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
