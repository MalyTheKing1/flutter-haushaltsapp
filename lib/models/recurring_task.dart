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

  /// Prüft, ob die Aufgabe aktuell fällig ist
  bool get isDue {
    final nextDueDate = lastDoneDate.add(Duration(days: intervalDays));

    // Vergleiche nur das Datum (Jahr, Monat, Tag), ohne Zeit
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final nextDueDateOnly = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);

    return !todayDateOnly.isBefore(nextDueDateOnly);
  }
}
