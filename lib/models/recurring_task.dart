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

  // -----------------------------
  // NEU: Felder für Randomness
  // -----------------------------
  @HiveField(5)
  bool randomnessEnabled; // Standard: false (Abwärtskompatibilität)

  @HiveField(6)
  int randomChance; // 1–100, Standard: 0 (aus)

  /// Wird täglich beim ersten App-Start gesetzt (oder via Debug erzwungen)
  @HiveField(7)
  bool randomDueToday;

  RecurringTask({
    required this.title,
    required this.intervalDays,
    this.isDone = false,
    DateTime? lastDoneDate,
    String? iconName, // ← Optional für alte Datensätze
    bool? randomnessEnabled, // ← Optional, damit alte Datensätze funktionieren
    int? randomChance,       // ← Optional, damit alte Datensätze funktionieren
    bool? randomDueToday,    // ← Optional, damit alte Datensätze funktionieren
  })  : lastDoneDate = lastDoneDate ?? DateTime.now(),
        iconName = iconName ?? 'house.png', // Fallback
        randomnessEnabled = randomnessEnabled ?? false,
        randomChance = randomChance ?? 0,
        randomDueToday = randomDueToday ?? false;

  /// Prüft, ob die Aufgabe aktuell fällig ist
  /// Randomness: Wenn aktiviert, zählt NUR das Flag randomDueToday (vom Tages-Check)
  bool get isDue {
    if (randomnessEnabled) {
      // Nur das täglich gesetzte Flag entscheidet
      return randomDueToday && !isDone;
    }

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

  /// Hilfsfunktion: Tage bis zur nächsten Fälligkeit (nur für NICHT-Random)
  int daysUntilDueFrom(DateTime now) {
    final nextDueDate = lastDoneDate.add(Duration(days: intervalDays));
    final today = DateTime(now.year, now.month, now.day);
    final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return dueDate.difference(today).inDays;
  }
}
