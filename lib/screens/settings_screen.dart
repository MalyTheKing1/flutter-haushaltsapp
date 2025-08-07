import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
      settings.save(); // Speichern in Hive
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: settings.isDarkMode,
              onChanged: _toggleDarkMode,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              NotificationService().showTestNotification();
            },
            child: const Text('Test-Benachrichtigung senden'),
          ),
        ],
      ),
    );
  }
}
