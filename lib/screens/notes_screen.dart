// lib/screens/notes_screen.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/note.dart';
import '../services/hive_service.dart';
import '../widgets/note_tile.dart';

/// Simpler Notizen-Bildschirm:
/// - Liste aller Notizen in BENUTZERDEFINIERTER Reihenfolge (persistiert via sortIndex)
/// - Drag & Drop zum Neuordnen (ReorderableListView)
/// - Hinzufügen (FAB unten rechts – NUR Plus-Icon, kein Label)
/// - Bearbeiten per Tap/Schaltfläche
/// - Löschen per Icon
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late final Box<Note> _notesBox;

  @override
  void initState() {
    super.initState();
    _notesBox = Hive.box<Note>(HiveService.notesBoxName);
    _ensureSortIndexInitialized();
  }

  /// Migration/Initialisierung: Falls Notizen noch keinen sortIndex haben,
  /// weise ihnen aufsteigende Werte (0..n-1) in aktueller Box-Reihenfolge zu.
  Future<void> _ensureSortIndexInitialized() async {
    final notes = _notesBox.values.toList();
    bool needsSave = false;
    for (var i = 0; i < notes.length; i++) {
      if (notes[i].sortIndex == 0 && i != 0) {
        notes[i].sortIndex = i;
        needsSave = true;
        await notes[i].save();
      }
    }
    if (needsSave) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // KEIN eigenes Scaffold (AppBar/BottomNav kommt von MainPage)
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: _notesBox.listenable(),
          builder: (context, Box<Note> box, _) {
            final notes = box.values.toList();

            // Sortierung: NUR nach sortIndex (Drag & Drop definiert die Reihenfolge)
            notes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

            if (notes.isEmpty) {
              return const Center(
                child: Text('Keine Notizen vorhanden.\nTippe auf +, um eine zu erstellen.'),
              );
            }

            // ReorderableListView mit stabilen Keys (HiveObject.key)
            return ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 96, top: 8),
              itemCount: notes.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;

                final moved = notes.removeAt(oldIndex);
                notes.insert(newIndex, moved);

                // Persistiere neue sortIndex-Werte (0..n-1)
                for (var i = 0; i < notes.length; i++) {
                  if (notes[i].sortIndex != i) {
                    notes[i].sortIndex = i;
                    notes[i].updatedAt = DateTime.now();
                    await notes[i].save();
                  }
                }
                setState(() {});
              },
              buildDefaultDragHandles: false, // eigener Drag-Handle im Tile
              itemBuilder: (context, index) {
                final note = notes[index];

                return ReorderableDelayedDragStartListener(
                  key: ValueKey(note.key),
                  index: index,
                  child: NoteTile(
                    note: note,
                    onEdit: () => _showEditDialog(note),
                    onDelete: () async {
                      await note.delete();
                    },
                  ),
                );
              },
            );
          },
        ),

        // Floating Action Button unten rechts – NUR Plus (kein "Notiz"-Label)
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _showAddDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog() async {
    // Zwei Felder: title + content
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Neue Notiz'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titel-Feld
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Überschrift',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Inhalt-Feld (mehrzeilig)
              TextField(
                controller: contentCtrl,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();

                if (title.isNotEmpty || content.isNotEmpty) {
                  // sortIndex = nächster Index (am Ende einfügen)
                  final nextIndex = _notesBox.length;
                  await _notesBox.add(
                    Note(
                      title: title,
                      content: content,
                      sortIndex: nextIndex,
                    ),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(Note note) async {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Notiz bearbeiten'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Titel-Feld
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Überschrift',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              // Inhalt-Feld
              TextField(
                controller: contentCtrl,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final content = contentCtrl.text.trim();
                if (title.isNotEmpty || content.isNotEmpty) {
                  note.updateText(newTitle: title, newContent: content);
                  await note.save();
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }
}
