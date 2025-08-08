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

  Settings({
    required this.isDarkMode,
    bool? notificationsEnabled,
    int? notificationHour,
    int? notificationMinute,
  })  : notificationsEnabled = notificationsEnabled ?? false,
        notificationHour = notificationHour ?? 18,
        notificationMinute = notificationMinute ?? 0;
}