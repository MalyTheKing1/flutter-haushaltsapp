import 'package:hive/hive.dart';

part 'recurring_task.g.dart';

/// Modell für wiederkehrende Aufgaben
@HiveType(typeId: 0)
class RecurringTask extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  int intervalDays;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  DateTime lastDoneDate;

  RecurringTask({
    required this.title,
    required this.intervalDays,
    this.isDone = false,
    DateTime? lastDoneDate,
  }) : lastDoneDate = lastDoneDate ?? DateTime.now();

  /// Prüfen, ob Aufgabe fällig ist
  bool get isDue {
    final nextDueDate = lastDoneDate.add(Duration(days: intervalDays));
    return DateTime.now().isAfter(nextDueDate);
  }
}
