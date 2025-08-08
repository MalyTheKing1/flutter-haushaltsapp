// Datei: lib/services/notification_service.dart

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static const int dailyNotificationId = 1;

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    const dailyChannel = AndroidNotificationChannel(
      'daily_tasks',
      'Tägliche Aufgaben',
      description: 'Erinnerung an offene Haushaltsaufgaben',
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(dailyChannel);

    const testChannel = AndroidNotificationChannel(
      'test_channel',
      'Testbenachrichtigungen',
      description: 'Zum Testen von lokalen Notifications',
      importance: Importance.high,
    );
    await androidPlugin?.createNotificationChannel(testChannel);
  }

  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return status.isGranted;
    }
    return true;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (Platform.isAndroid) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        final result = await Permission.scheduleExactAlarm.request();
        return result.isGranted;
      }
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true;
  }

  /// Tägliche geplante Notification – IMMER statischer Text!
  Future<void> scheduleDailyNotification(int hour, int minute) async {
    final granted = await requestNotificationPermission();
    if (!granted) {
      print("⚠️ Keine Berechtigung für Benachrichtigungen");
      return;
    }
    final alarmGranted = await requestExactAlarmPermission();
    if (!alarmGranted) {
      print("❗️ Keine Berechtigung für exakte Alarme");
      return;
    }

    await cancelDailyNotification();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    print("🕐 Plane Notification für: ${scheduledDate.toString()}");

    const androidDetails = AndroidNotificationDetails(
      'daily_tasks',
      'Tägliche Aufgaben',
      channelDescription: 'Erinnerung an offene Haushaltsaufgaben',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        dailyNotificationId,
        'Daily Reminder',
        'Haushalt erledigen',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      print("✅ Tägliche Notification geplant für $hour:${minute.toString().padLeft(2, '0')} Uhr");
    } catch (e) {
      print("❌ Fehler beim Planen der Notification: $e");
    }
  }

  Future<void> cancelDailyNotification() async {
    await _plugin.cancel(dailyNotificationId);
    print("🚫 Tägliche Notification gelöscht");
  }

  /// NEU: Stopp ALLE geplanten Notifications (auch periodische!)
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
    print("🚫 Alle Notifications gelöscht");
  }

  /// Test-Notification mit statischem Text
  Future<void> testNotificationIn10SecondsWithCatch() async {
    final granted = await requestNotificationPermission();
    if (!granted) {
      print("⚠️ Keine Berechtigung für Benachrichtigungen");
      return;
    }
    final alarmGranted = await requestExactAlarmPermission();
    if (!alarmGranted) {
      print("❗️ Keine Berechtigung für exakte Alarme");
      return;
    }

    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Testbenachrichtigungen',
      channelDescription: 'Zum Testen von lokalen Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    try {
      await _plugin.zonedSchedule(
        999,
        'Daily Reminder',
        'Haushalt erledigen',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print("✅ Test-Benachrichtigung geplant für 10 Sekunden");
    } catch (e, stacktrace) {
      print("❌ Fehler beim Planen der Test-Benachrichtigung: $e");
      print("📋 Stacktrace: $stacktrace");
    }
  }

  /// Debug: Zeigt alle geplanten Notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pendingNotifications = await _plugin.pendingNotificationRequests();

    print("🔍 Debug: ${pendingNotifications.length} Notifications geplant");
    for (var notification in pendingNotifications) {
      print("  - ID: ${notification.id}, Titel: ${notification.title}, Text: ${notification.body}");
    }

    return pendingNotifications;
  }

  /// Test: Sofortige Test-Benachrichtigung (immer statisch)
  Future<void> showTestNotification() async {
    final granted = await requestNotificationPermission();
    if (!granted) {
      print("⚠️ Keine Berechtigung für Benachrichtigungen");
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Testbenachrichtigungen',
      channelDescription: 'Zum Testen von lokalen Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(
      0,
      'Daily Reminder',
      'Haushalt erledigen',
      details,
    );
  }
}
