import 'package:flutter/material.dart';
import '../models/recurring_task.dart';

/// Einzelne Listeneinträge für wiederkehrende Aufgaben
class RecurringTaskItem extends StatefulWidget {
  final RecurringTask task;

  const RecurringTaskItem({super.key, required this.task});

  @override
  State<RecurringTaskItem> createState() => _RecurringTaskItemState();
}

class _RecurringTaskItemState extends State<RecurringTaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Beim Start prüfen, ob Haken entfernt werden muss (wie bisher)
    if (widget.task.isDone) {
      final dueDate =
          widget.task.lastDoneDate.add(Duration(days: widget.task.intervalDays));
      if (DateTime.now().isAfter(dueDate)) {
        widget.task.isDone = false;
        widget.task.save();
      }
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    // Tween für Skalierung von 1.0 bis 1.2 mit easeOut Kurve
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Berechnet die volle Anzahl Tage bis zur nächsten Fälligkeit
  int getDaysUntilDue() {
    final nextDueDate =
        widget.task.lastDoneDate.add(Duration(days: widget.task.intervalDays));

    // Wir vergleichen nur volle Tage (Datum ohne Zeit)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);

    return dueDate.difference(today).inDays;
  }

  void _onCheckboxChanged(bool? value) {
    if (value == true) {
      _controller.forward();
    }
    setState(() {
      widget.task.isDone = value ?? false;
      if (widget.task.isDone) {
        widget.task.lastDoneDate = DateTime.now();
      }
      widget.task.save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;

    String subtitleText = '';
    Widget? extraSubtitle;

    if (!task.isDone) {
      subtitleText = 'Intervall: ${task.intervalDays} Tage';
    } else {
      final daysUntilDue = getDaysUntilDue();

      if (daysUntilDue == 1) {
        subtitleText = '';
        extraSubtitle = Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            'Morgen fällig',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
          ),
        );
      } else {
        subtitleText = 'Fällig in $daysUntilDue Tagen';
      }
    }

    return ListTile(
      title: Text(task.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitleText.isNotEmpty)
            Text(
              subtitleText,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            ),
          if (extraSubtitle != null) extraSubtitle,
        ],
      ),
      trailing: ScaleTransition(
        scale: _scaleAnimation,
        child: Transform.scale(
          scale: 1.4, // Checkbox größer machen (ohne Animation)
          child: Checkbox(
            value: task.isDone,
            onChanged: _onCheckboxChanged,
          ),
        ),
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
