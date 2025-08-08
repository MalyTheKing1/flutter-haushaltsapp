import 'package:hive/hive.dart';

import '../models/settings.dart';
import '../models/recurring_task.dart';
import '../models/onetime_task.dart';
import '../services/notification_service.dart';

class HiveService {
  static const String settingsBoxName = 'settings';
  static const String recurringBoxName = 'recurring_tasks';
  static const String onetimeBoxName = 'onetime_tasks';

  /// Hive-Adapter registrieren
  static Future<void> registerAdapters() async {
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(RecurringTaskAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(OneTimeTaskAdapter());
    }
  }

  /// Hive-Boxen öffnen und Beispiel-Daten hinzufügen, falls leer
  static Future<void> openBoxes() async {
    final recurringBox = await Hive.openBox<RecurringTask>(recurringBoxName);
    /*
    if (recurringBox.isEmpty) {
      recurringBox.addAll([
        RecurringTask(
          title: 'Müll rausbringen',
          intervalDays: 2,
          lastDoneDate: DateTime.now().subtract(const Duration(days: 2)),
          iconName: 'trash.png',
        ),
        RecurringTask(
          title: 'Staubsaugen',
          intervalDays: 7,
          lastDoneDate: DateTime.now().subtract(const Duration(days: 7)),
          iconName: 'vacuum.png',
        ),
      ]);
    }
    */

    final onetimeBox = await Hive.openBox<OneTimeTask>(onetimeBoxName);
    /*
    if (onetimeBox.isEmpty) {
      onetimeBox.addAll([
        OneTimeTask(title: 'Fenster putzen'),
        OneTimeTask(title: 'Garage aufräumen'),
      ]);
    }
    */

    await _openSettingsBoxWithMigration();
  }

  static Future<void> _openSettingsBoxWithMigration() async {
    if (!Hive.isBoxOpen(settingsBoxName)) {
      await Hive.openBox<Settings>(settingsBoxName);
    }

    final settingsBox = Hive.box<Settings>(settingsBoxName);

    // Wenn leer, mit Defaults befüllen
    if (settingsBox.isEmpty) {
      final settings = Settings(
        isDarkMode: false,
        notificationsEnabled: false,
        notificationHour: 18,
        notificationMinute: 0,
      );
      await settingsBox.add(settings);
      print("✅ Neue Settings-Box mit Defaults erstellt");
    }
  }

  /// Löscht alle Hive-Boxen und deren gespeicherte Daten von der Disk.
  static Future<void> deleteAllData() async {
    // Erst alle Boxen sauber schließen!
    if (Hive.isBoxOpen(recurringBoxName)) {
      await Hive.box<RecurringTask>(recurringBoxName).close();
    }
    if (Hive.isBoxOpen(onetimeBoxName)) {
      await Hive.box<OneTimeTask>(onetimeBoxName).close();
    }
    if (Hive.isBoxOpen(settingsBoxName)) {
      await Hive.box<Settings>(settingsBoxName).close();
    }

    // Dann die Dateien löschen
    await Hive.deleteBoxFromDisk(recurringBoxName);
    await Hive.deleteBoxFromDisk(onetimeBoxName);
    await Hive.deleteBoxFromDisk(settingsBoxName);
  }
}
