import 'package:flutter/material.dart';
import '../models/recurring_task.dart';

/// Einzelne Listeneinträge für wiederkehrende Aufgaben
class RecurringTaskItem extends StatefulWidget {
  final RecurringTask task;
  final VoidCallback? onCheckChanged; // Callback für Parent Screen

  const RecurringTaskItem({
    super.key,
    required this.task,
    this.onCheckChanged,
  });

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

    if (widget.task.isDone) {
      if (!widget.task.randomnessEnabled) {
        final dueDate =
            widget.task.lastDoneDate.add(Duration(days: widget.task.intervalDays));
        if (DateTime.now().isAfter(dueDate)) {
          widget.task.isDone = false;
          widget.task.save();
        }
      } else {
        // Random: wenn erledigt, entfernen wir die heutige Fälligkeit (falls gesetzt)
        if (widget.task.randomDueToday) {
          widget.task.randomDueToday = false;
          widget.task.save();
        }
      }
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

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

  int getDaysUntilDue() {
    return widget.task.daysUntilDueFrom(DateTime.now());
  }

  void _onCheckboxChanged(bool? value) {
    if (value == true) {
      _controller.forward();
    }

    setState(() {
      widget.task.isDone = value ?? false;
      if (widget.task.isDone) {
        widget.task.lastDoneDate = DateTime.now();
        // Random: Häkchen entfernt die heutige Fälligkeit
        if (widget.task.randomnessEnabled) {
          widget.task.randomDueToday = false;
        }
      }
      widget.task.save();
    });

    widget.onCheckChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final iconPath = 'assets/icons/${task.iconName.isNotEmpty ? task.iconName : 'house.png'}';

    String subtitleText = '';
    Widget? extraSubtitle;

    if (task.randomnessEnabled) {
      // NEU: bei Randomness immer Chance zeigen – unabhängig von isDone
      subtitleText = 'Chance: ${task.randomChance}%';
      extraSubtitle = null;
    } else if (!task.isDone) {
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

    final titleStyle = task.randomnessEnabled
        ? const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          )
        : null;

    return ListTile(
      leading: Image.asset(
        iconPath,
        width: 32,
        height: 32,
      ),
      title: Text(task.title, style: titleStyle),
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
          scale: 1.4,
          child: Checkbox(
            value: task.isDone,
            onChanged: _onCheckboxChanged,
          ),
        ),
      ),
      onLongPress: () => _showEditDialog(context, task),
    );
  }

  void _showEditDialog(BuildContext context, RecurringTask task) {
    final titleController = TextEditingController(text: task.title);
    final intervalController = TextEditingController(text: task.intervalDays.toString());
    final randomChanceController =
        TextEditingController(text: (task.randomChance).toString());
    bool randomnessEnabled = task.randomnessEnabled;

    final iconOptions = [
      'house.png',
      'broom.png',
      'oven.png',
      'plant.png',
      'toilet.png',
      'trash.png',
      'vacuum.png',
      'bottle.png',
      'pill.png',
      'shower.png',
      'shirt.png',
      'fridge.png',
      'bed.png',
      'window.png',
      'tools.png',
      'car.png',
      'dog.png',
      'bag.png',
      'heart.png',
      'paper.png',
      'cleaning.png',
      'cuttlery.png',
      'question.png',
    ];

    String selectedIcon = task.iconName;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Aufgabe bearbeiten'),
              content: SingleChildScrollView(
                child: Column(
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
                      enabled: !randomnessEnabled,
                    ),
                    const SizedBox(height: 12),
                    Text('Icon auswählen:', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: iconOptions.map((icon) {
                        final isSelected = selectedIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Image.asset('assets/icons/$icon', width: 40, height: 40),
                          ),
                        );
                      }).toList(),
                    ),
                    // ↓↓↓ NEU: Zufälligkeit-UI ans Ende verschoben ↓↓↓
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Zufälligkeit'),
                      value: randomnessEnabled,
                      onChanged: (v) {
                        setState(() {
                          randomnessEnabled = v;
                        });
                      },
                    ),
                    TextField(
                      controller: randomChanceController,
                      decoration: const InputDecoration(labelText: 'Chance (1–100 %)'),
                      keyboardType: TextInputType.number,
                      enabled: randomnessEnabled,
                    ),
                  ],
                ),
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
                    final newChance = int.tryParse(randomChanceController.text.trim()) ?? 0;

                    if (newTitle.isEmpty) return;

                    task.title = newTitle;
                    task.iconName = selectedIcon;

                    if (randomnessEnabled) {
                      task.randomnessEnabled = true;
                      task.randomChance = newChance.clamp(1, 100);
                      task.intervalDays = task.intervalDays <= 0 ? 1 : task.intervalDays; // gültig lassen
                    } else {
                      // Randomness aus → normaler Intervall nötig
                      if (newInterval == null || newInterval <= 0) return;
                      task.randomnessEnabled = false;
                      task.randomChance = 0;
                      task.randomDueToday = false;
                      task.intervalDays = newInterval;
                    }

                    task.save();
                    Navigator.of(context).pop();
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
      },
    );
  }
}
