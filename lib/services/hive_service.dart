import 'package:hive/hive.dart';

import '../models/recurring_task.dart';
import '../models/onetime_task.dart';

class HiveService {
  static const String recurringBoxName = 'recurring_tasks';
  static const String onetimeBoxName = 'onetime_tasks';

  /// Hive-Adapter registrieren
  static Future<void> registerAdapters() async {
    Hive.registerAdapter(RecurringTaskAdapter());
    Hive.registerAdapter(OneTimeTaskAdapter());
  }

  /// Hive-Boxen öffnen und Beispiel-Daten hinzufügen, falls leer
  static Future<void> openBoxes() async {
    final recurringBox = await Hive.openBox<RecurringTask>(recurringBoxName);
    if (recurringBox.isEmpty) {
      recurringBox.addAll([
        RecurringTask(title: 'Müll rausbringen', intervalDays: 2),
        RecurringTask(title: 'Staubsaugen', intervalDays: 7),
      ]);
    }

    final onetimeBox = await Hive.openBox<OneTimeTask>(onetimeBoxName);
    if (onetimeBox.isEmpty) {
      onetimeBox.addAll([
        OneTimeTask(title: 'Fenster putzen'),
        OneTimeTask(title: 'Garage aufräumen'),
      ]);
    }
  }
}
