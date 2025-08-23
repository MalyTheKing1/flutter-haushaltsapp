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
  final now = DateTime.now();

  final randomOpen = <RecurringTask>[];       // NEU: alle Randoms, die offen sind
  final normalDueOpen = <RecurringTask>[];
  final normalNotDueOpen = <RecurringTask>[];
  final normalDone = <RecurringTask>[];
  final randomDone = <RecurringTask>[];       // NEU: alle Randoms, die erledigt sind

  for (final t in tasks) {
    if (t.randomnessEnabled) {
      if (t.isDone) {
        randomDone.add(t);           // ganz unten
      } else {
        randomOpen.add(t);           // ganz oben
      }
    } else {
      if (t.isDone) {
        normalDone.add(t);
      } else {
        if (t.isDue) {
          normalDueOpen.add(t);
        } else {
          normalNotDueOpen.add(t);
        }
      }
    }
  }

  // Sortierungen innerhalb der Buckets
  normalDueOpen.sort((a, b) => a.intervalDays.compareTo(b.intervalDays));
  int daysUntil(RecurringTask t) => t.daysUntilDueFrom(now);
  normalNotDueOpen.sort((a, b) => daysUntil(a).compareTo(daysUntil(b)));
  normalDone.sort((a, b) {
    final aDueDate = a.lastDoneDate.add(Duration(days: a.intervalDays));
    final bDueDate = b.lastDoneDate.add(Duration(days: b.intervalDays));
    return aDueDate.compareTo(bDueDate);
  });
  // Random-Buckets bleiben unsortiert (oder du sortierst optional nach Chance/Titel)

  return [
    ...randomOpen,       // GANZ oben
    ...normalDueOpen,
    ...normalNotDueOpen,
    ...normalDone,
    ...randomDone,       // GANZ unten
  ];
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
                  opacity: isRecentlyChanged ? 0.7 : (task.isDone ? 0.3 : 1.0),
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
    final randomChanceController = TextEditingController(text: '0'); // 0% default (aus)
    bool randomnessEnabled = false;

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
    String selectedIcon = 'house.png';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Neue wiederkehrende Aufgabe'),
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
                      enabled: !randomnessEnabled, // bei Zufälligkeit egal
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
                    final title = titleController.text.trim();
                    final interval = int.tryParse(intervalController.text.trim());
                    final chance = int.tryParse(randomChanceController.text.trim()) ?? 0;

                    if (title.isEmpty) return;

                    if (randomnessEnabled) {
                      // Für Randomness: Chance validieren
                      final safeChance = chance.clamp(1, 100);
                      final box = Hive.box<RecurringTask>(HiveService.recurringBoxName);
                      box.add(RecurringTask(
                        title: title,
                        intervalDays: 1, // irrelevant – aber gültig halten
                        iconName: selectedIcon,
                        randomnessEnabled: true,
                        randomChance: safeChance,
                        randomDueToday: false,
                      ));
                      Navigator.of(context).pop();
                    } else {
                      // Klassischer Fall
                      if (interval == null || interval <= 0) return;
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
      },
    );
  }
}
