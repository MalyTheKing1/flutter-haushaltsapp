import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:flutter/services.dart'; // <-- für SystemNavigator.pop()

import '../services/notification_service.dart';
import '../models/settings.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<Settings> settingsBox;
  late Settings settings;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box<Settings>(HiveService.settingsBoxName);
    settings = settingsBox.values.first;
  }

  void _toggleDarkMode(bool value) {
    setState(() {
      settings.isDarkMode = value;
      settings.save();
    });
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      settings.notificationsEnabled = value;
      settings.save();
    });

    if (value) {
      await NotificationService().scheduleDailyNotification(
        settings.notificationHour,
        settings.notificationMinute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tägliche Erinnerung um ${settings.notificationHour}:${settings.notificationMinute.toString().padLeft(2, '0')} Uhr aktiviert',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      await NotificationService().cancelDailyNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tägliche Erinnerung deaktiviert'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _selectNotificationTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        settings.notificationHour = picked.hour;
        settings.notificationMinute = picked.minute;
        settings.save();
      });

      if (settings.notificationsEnabled) {
        await NotificationService().scheduleDailyNotification(
          picked.hour,
          picked.minute,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erinnerungszeit geändert auf ${picked.hour}:${picked.minute.toString().padLeft(2, '0')} Uhr',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  /// Debug-Button: Löscht alle Hive-Daten und beendet die App nach Bestätigung!
  Future<void> _deleteAllHiveDataAndRestart() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alle Daten löschen?'),
        content: const Text(
          '⚠️ Das löscht ALLE gespeicherten Aufgaben und Einstellungen unwiderruflich.\n\nDie App wird danach geschlossen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ja, löschen!'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Die eigene Settings-Box schließen, falls offen
    if (settingsBox.isOpen) {
      await settingsBox.close();
    }

    // Alle Boxen löschen
    await HiveService.deleteAllData();

    // Notifications stoppen
    await NotificationService().cancelAllNotifications();

    // App nach kurzem Hinweis schließen
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alle Daten gelöscht! App wird jetzt geschlossen...')),
      );
      await Future.delayed(const Duration(milliseconds: 700));
      SystemNavigator.pop(); // <-- App schließen (Android/iOS)
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👉 Dynamisches Bottom-Padding: SafeArea + etwas extra Luft
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const extraBottom = 24.0; // ein bisschen Luft über der Android-Bar

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: SafeArea(
        bottom: true, // schützt vor Überdeckung durch System-UI
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + bottomSafe + extraBottom, // 👈 mehr Platz unten
          ),
          children: [
            ListTile(
              title: const Text('Dark Mode'),
              trailing: Switch(
                value: settings.isDarkMode,
                onChanged: _toggleDarkMode,
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Benachrichtigungen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ListTile(
              title: const Text('Tägliche Erinnerung'),
              subtitle: const Text('Erinnert dich jeden Tag ans Aufräumen'),
              trailing: Switch(
                value: settings.notificationsEnabled,
                onChanged: _toggleNotifications,
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: settings.notificationsEnabled
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: ListTile(
                title: const Text('Erinnerungszeit'),
                subtitle: Text(
                  '${settings.notificationHour}:${settings.notificationMinute.toString().padLeft(2, '0')} Uhr',
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _selectNotificationTime,
              ),
              secondChild: const SizedBox.shrink(),
            ),
            const Divider(),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService().showTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test-Benachrichtigung gesendet'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.notifications_outlined),
              label: const Text('Test: Benachrichtigung senden'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService().testNotificationIn10SecondsWithCatch();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Benachrichtungstest (10 Sek.) geplant!'),
                      duration: Duration(seconds: 10),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.timer_10),
              label: const Text('Test: Benachrichtigung in 10 Sek.'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final pendingNotifications = await NotificationService().getPendingNotifications();
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Geplante Benachrichtigungen'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (pendingNotifications.isEmpty)
                              const Text('Keine Benachrichtigungen geplant')
                            else
                              ...pendingNotifications.map((notification) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ID: ${notification.id}',
                                            style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text('Titel: ${notification.title ?? "Kein Titel"}'),
                                        Text('Text: ${notification.body ?? "Kein Text"}'),
                                        Text('Payload: ${notification.payload ?? "Kein Payload"}'),
                                        const Divider(),
                                      ],
                                    ),
                                  )),
                            const SizedBox(height: 8),
                            Text(
                              'Anzahl geplant: ${pendingNotifications.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (settings.notificationsEnabled)
                              Text(
                                'Soll-Zeit: ${settings.notificationHour}:${settings.notificationMinute.toString().padLeft(2, '0')} Uhr',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bug_report),
              label: const Text('Debug: Geplante Benachrichtigungen'),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await NotificationService().cancelAllNotifications();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alle Notifications gestoppt'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.cancel),
              label: const Text('Alle Notifications stoppen'),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Hinweis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Diese App befindet sich noch in der Entwicklung.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            // NEU: Debug-Button zum Löschen ALLER Hive-Daten und Schließen der App
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 132, 123),
              ),
              onPressed: _deleteAllHiveDataAndRestart,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Debug: ALLE Daten löschen'),
            ),
          ],
        ),
      ),
    );
  }
}
