import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/settings.dart';
import '../services/hive_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box<Settings>(HiveService.settingsBoxName);
    final settings = settingsBox.values.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListTile(
        title: const Text('Dunkler Modus'),
        trailing: Switch(
          value: settings.isDarkMode,
          onChanged: (value) {
            settings.isDarkMode = value;
            settings.save();
          },
        ),
      ),
    );
  }
}
