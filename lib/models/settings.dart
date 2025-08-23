import 'package:hive/hive.dart';

part 'settings.g.dart';

@HiveType(typeId: 3)
class Settings extends HiveObject {
  @HiveField(0)
  bool isDarkMode;
  
  @HiveField(1)
  bool notificationsEnabled;
  
  @HiveField(2)
  int notificationHour;
  
  @HiveField(3)
  int notificationMinute;

  // -----------------------------
  // NEU: Randomness-Debug + letzter Tagescheck
  // -----------------------------
  @HiveField(4)
  bool? debugAlwaysTriggerRandom; // nullable für Abwärtskompatibilität (wird nachgeladen)

  @HiveField(5)
  DateTime? lastRandomCheckDate;  // null = noch nie geprüft

  Settings({
    required this.isDarkMode,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
    bool? debugAlwaysTriggerRandom,
    DateTime? lastRandomCheckDate,
  })  : notificationsEnabled = notificationsEnabled ?? false,
        notificationHour = notificationHour ?? 18,
        notificationMinute = notificationMinute ?? 0,
        debugAlwaysTriggerRandom = debugAlwaysTriggerRandom ?? false,
        lastRandomCheckDate = lastRandomCheckDate;
}
