import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    // Kanal für Android 8+
    const channel = AndroidNotificationChannel(
      'test_channel',
      'Testbenachrichtigungen',
      description: 'Zum Testen von lokalen Notifications',
      importance: Importance.high,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  /// Prüft und fordert Notification-Permission (nur Android 13+)
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final sdkInt = (await Permission.notification.status).isDenied;
      if (sdkInt) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
    }
    // iOS wird hier ignoriert, da keine extra permission nötig ist
    return true;
  }

  Future<void> showTestNotification() async {
    // Permission prüfen
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
      'Testbenachrichtigung',
      'Dies ist eine lokale Test-Notification.',
      details,
    );
  }
}
