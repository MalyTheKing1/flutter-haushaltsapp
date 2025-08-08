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

  @HiveField(4)
  String iconName; // ← NEU

  RecurringTask({
    required this.title,
    required this.intervalDays,
    this.isDone = false,
    DateTime? lastDoneDate,
    String? iconName, // ← Optional für alte Datensätze
  })  : lastDoneDate = lastDoneDate ?? DateTime.now(),
        iconName = iconName ?? 'house.png'; // Fallback

  /// Prüft, ob die Aufgabe aktuell fällig ist
  bool get isDue {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final nextDueDate = lastDoneDate.add(Duration(days: intervalDays));
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);

    print("🧪 isDue-Check für '${title}':");
    print("   - lastDoneDate: $lastDoneDate");
    print("   - intervalDays: $intervalDays");
    print("   - berechnetes nextDueDate (ohne Uhrzeit): $dueDate");
    print("   - heute: $todayDate");
    print("   - isDue = ${!todayDate.isBefore(dueDate)}");

    return !todayDate.isBefore(dueDate);
  }
}
