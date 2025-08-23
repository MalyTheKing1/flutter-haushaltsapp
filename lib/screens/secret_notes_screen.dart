// lib/screens/secret_notes_screen.dart
import 'package:flutter/material.dart';
import 'notes_screen.dart';

/// Vollbild-Seite für geheime Notizen mit eigener AppBar (Zurück-Pfeil).
class SecretNotesScreen extends StatelessWidget {
  const SecretNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(), // ← Pfeil nach links
        title: const Text('Geheime Notizen'),
      ),
      body: const NotesScreen(isSecret: true),
    );
  }
}
