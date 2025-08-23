import 'package:hive/hive.dart';

import '../models/settings.dart';
import '../models/recurring_task.dart';
import '../models/onetime_task.dart';
import '../models/note.dart'; // WICHTIG: neues Note-Model mit title/content/sortIndex

import '../services/notification_service.dart';

class HiveService {
  static const String settingsBoxName = 'settings';
  static const String recurringBoxName = 'recurring_tasks';
  static const String onetimeBoxName = 'onetime_tasks';
  static const String notesBoxName = 'notes'; // Box-Name für Notizen

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
    // 👉 WICHTIG: NoteAdapter (typeId = 2) registrieren
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(NoteAdapter());
    }
  }

  /// Hive-Boxen öffnen (und ggf. Beispiel-/Migration)
  static Future<void> openBoxes() async {
    final recurringBox = await Hive.openBox<RecurringTask>(recurringBoxName);
    /*
    if (recurringBox.isEmpty) {
      // Beispiel-Daten (optional)
    }
    */

    final onetimeBox = await Hive.openBox<OneTimeTask>(onetimeBoxName);
    /*
    if (onetimeBox.isEmpty) {
      // Beispiel-Daten (optional)
    }
    */

    // 👉 Notizen-Box öffnen und ggf. migrieren
    final notesBox = await Hive.openBox<Note>(notesBoxName);
    await _migrateNotesIfNeeded(notesBox);

    await _openSettingsBoxWithMigration();

    // 👉 Kleiner Sicherheitsschritt: Altdaten der Recurring-Tasks gegen Defaults absichern
    await _migrateRecurringTasksIfNeeded(recurringBox);
  }

  /// MIGRATION: Alte Notizen (nur "text") → neues Schema (title/content/sortIndex)
  static Future<void> _migrateNotesIfNeeded(Box<Note> box) async {
    for (var i = 0; i < box.length; i++) {
      final note = box.getAt(i);
      if (note == null) continue;

      bool dirty = false;

      // Falls noch kein Titel, aber Inhalt vorhanden → ersten Zeilenanfang als Titel
      if (note.title.isEmpty && note.content.isNotEmpty) {
        final firstLine = note.content.split('\n').first.trim();
        note.title = firstLine.isNotEmpty
            ? (firstLine.length > 30 ? '${firstLine.substring(0, 30)}…' : firstLine)
            : '(Ohne Titel)';
        dirty = true;
      }

      // sortIndex initialisieren, falls alles 0 ist
      if (note.sortIndex == 0 && i != 0) {
        note.sortIndex = i;
        dirty = true;
      }

      // 👉 NEU: isSecret-Default absichern (Abwärtskompatibilität)
      if (note.isSecret != true && note.isSecret != false) {
        note.isSecret = false;
        dirty = true;
      }

      if (dirty) {
        await note.save();
      }
    }
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
        // NEU: Debug + letzter Random-Check werden im Konstruktor sinnvoll vorbelegt
      );
      await settingsBox.add(settings);
      print("✅ Neue Settings-Box mit Defaults erstellt");
    } else {
      // Abwärtskompatibel: fehlende neue Felder sanft setzen
      final s = settingsBox.values.first;
      bool dirty = false;
      if (s.debugAlwaysTriggerRandom == null) {
        s.debugAlwaysTriggerRandom = false;
        dirty = true;
      }
      // lastRandomCheckDate darf null bleiben (bedeutet: noch nie geprüft)
      if (dirty) await s.save();
    }
  }

  /// MIGRATION: Absicherung der neuen Randomness-Felder bei Recurring-Tasks
  static Future<void> _migrateRecurringTasksIfNeeded(Box<RecurringTask> box) async {
    for (var i = 0; i < box.length; i++) {
      final t = box.getAt(i);
      if (t == null) continue;

      bool dirty = false;
      // Falls alte Datensätze ohne Felder
      if (t.randomnessEnabled != true && t.randomnessEnabled != false) {
        t.randomnessEnabled = false;
        dirty = true;
      }
      if (t.randomChance == 0 && t.randomnessEnabled == false) {
        // 0 ist Default, passt – keine Aktion nötig
      } else if (t.randomChance < 0 || t.randomChance > 100) {
        t.randomChance = 0;
        dirty = true;
      }
      if (t.randomDueToday != true && t.randomDueToday != false) {
        t.randomDueToday = false;
        dirty = true;
      }

      if (dirty) await t.save();
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
    if (Hive.isBoxOpen(notesBoxName)) {
      await Hive.box<Note>(notesBoxName).close();
    }

    // Dann die Dateien löschen
    await Hive.deleteBoxFromDisk(recurringBoxName);
    await Hive.deleteBoxFromDisk(onetimeBoxName);
    await Hive.deleteBoxFromDisk(settingsBoxName);
    await Hive.deleteBoxFromDisk(notesBoxName);
  }
}
