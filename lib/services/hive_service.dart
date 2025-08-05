import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/recurring_task.dart';
import '../models/onetime_task.dart';

class HiveService {
  static const String recurringBoxName = 'recurring_tasks';
  static const String onetimeBoxName = 'onetime_tasks';

  /// Adapter registrieren
  static Future<void> registerAdapters() async {
    Hive.registerAdapter(RecurringTaskAdapter());
    Hive.registerAdapter(OneTimeTaskAdapter());
  }

  /// Hive-Boxen öffnen
  static Future<void> openBoxes() async {
    await Hive.openBox<RecurringTask>(recurringBoxName);
    await Hive.openBox<OneTimeTask>(onetimeBoxName);

    // Beispielaufgaben hinzufügen, falls leer
    final recurringBox = Hive.box<RecurringTask>(recurringBoxName);
    if (recurringBox.isEmpty) {
      recurringBox.addAll([
        RecurringTask(title: 'Müll rausbringen', intervalDays: 2),
        RecurringTask(title: 'Staubsaugen', intervalDays: 7),
      ]);
    }

    final onetimeBox = Hive.box<OneTimeTask>(onetimeBoxName);
    if (onetimeBox.isEmpty) {
      onetimeBox.addAll([
        OneTimeTask(title: 'Fenster putzen'),
        OneTimeTask(title: 'Garage aufräumen'),
      ]);
    }
  }
}
