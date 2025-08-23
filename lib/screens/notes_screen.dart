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
  const NotesScreen({
    super.key,
    this.isSecret = false, // 👉 NEU: zeigt normale oder geheime Notizen
  });

  /// Steuert, ob normale (false) oder geheime (true) Notizen angezeigt werden.
  final bool isSecret;

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

  // ============================================================
  // NEU: Bestätigungsdialog vor dem Löschen einer Notiz
  // ============================================================
  Future<bool> _confirmDeleteNote() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notiz löschen?'),
        content: const Text('Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  // ============================================================
  // UI-Helfer: Gemeinsamer BottomSheet-Body mit sticky Button-Bar
  // (wird von _showAddDialog und _showEditDialog genutzt)
  // ============================================================
  Widget _buildNoteEditorSheet({
    required BuildContext ctx,
    required TextEditingController titleCtrl,
    required TextEditingController contentCtrl,
    required String sheetTitle,
    required VoidCallback onCancel,
    required Future<void> Function() onSave,
  }) {
    return Padding(
      // Platz für die Tastatur schaffen
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // kleiner "Griff"
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Theme.of(ctx).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titelzeile
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                sheetTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
          ),

          // Scrollbarer Inhalt (Expanded!)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
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
                    keyboardType: TextInputType.multiline,
                    maxLines: null, // beliebig viele Zeilen
                    decoration: const InputDecoration(
                      labelText: 'Inhalt',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 120), // etwas extra Luft fürs Scrollen
                ],
              ),
            ),
          ),

          // Sticky Button-Leiste unten (immer sichtbar)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Abbrechen'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async => onSave(),
                      child: const Text('Speichern'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Safe-Area-Unterkante (z. B. Gestenleiste Android / Home Indicator iOS)
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // KEIN eigenes Scaffold (AppBar/BottomNav kommt von MainPage)
    return Stack(
      children: [
        ValueListenableBuilder(
          valueListenable: _notesBox.listenable(),
          builder: (context, Box<Note> box, _) {
            // 👉 NEU: nur Notizen dieses Kanals (secret vs. normal)
            final notes = box.values.where((n) => n.isSecret == widget.isSecret).toList();

            // Sortierung: NUR nach sortIndex (Drag & Drop definiert die Reihenfolge)
            notes.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

            if (notes.isEmpty) {
              return Center(
                child: Text(
                  widget.isSecret
                      ? 'Keine geheimen Notizen vorhanden.\nTippe auf +, um eine zu erstellen.'
                      : 'Keine Notizen vorhanden.\nTippe auf +, um eine zu erstellen.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            // ReorderableListView mit stabilen Keys (HiveObject.key)
            return ReorderableListView.builder(
              padding: EdgeInsets.only(bottom: 96 + bottomInset, top: 8),
              itemCount: notes.length,
              onReorder: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex -= 1;

                final moved = notes.removeAt(oldIndex);
                notes.insert(newIndex, moved);

                // Persistiere neue sortIndex-Werte **innerhalb** dieser Teilmenge
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
                      // ❗️Neu: Bestätigungsabfrage vor dem Löschen
                      final ok = await _confirmDeleteNote();
                      if (!ok) return;
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
          bottom: 16 + bottomInset,
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

    // =======================
    // BottomSheet-Editor
    // =======================
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // volle Höhe + Tastatur-Handling
      useSafeArea: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _buildScaffoldedSheet(
          context: ctx, // ✅ wichtig: ctx, nicht context
          child: _buildNoteEditorSheet(
            ctx: ctx,
            titleCtrl: titleCtrl,
            contentCtrl: contentCtrl,
            sheetTitle: widget.isSecret ? 'Neue geheime Notiz' : 'Neue Notiz',
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: () async {
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text.trim();

              if (title.isNotEmpty || content.isNotEmpty) {
                // sortIndex = nächster Index **innerhalb** dieses Kanals
                final existing =
                    _notesBox.values.where((n) => n.isSecret == widget.isSecret).length;
                final nextIndex = existing;
                await _notesBox.add(
                  Note(
                    title: title,
                    content: content,
                    sortIndex: nextIndex,
                    isSecret: widget.isSecret, // 👉 WICHTIG
                  ),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(Note note) async {
    final titleCtrl = TextEditingController(text: note.title);
    final contentCtrl = TextEditingController(text: note.content);

    // =======================
    // BottomSheet-Editor
    // =======================
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return _buildScaffoldedSheet(
          context: ctx, // ✅ wichtig: ctx
          child: _buildNoteEditorSheet(
            ctx: ctx,
            titleCtrl: titleCtrl,
            contentCtrl: contentCtrl,
            sheetTitle: 'Notiz bearbeiten',
            onCancel: () => Navigator.of(ctx).pop(),
            onSave: () async {
              final title = titleCtrl.text.trim();
              final content = contentCtrl.text.trim();
              if (title.isNotEmpty || content.isNotEmpty) {
                note.updateText(newTitle: title, newContent: content);
                await note.save();
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------
  // KLEINER HILFSWRAPPER:
  // Sorgt dafür, dass der Sheet-Inhalt den verfügbaren Platz
  // gut nutzt (v. a. auf kleineren Geräten/mit Tastatur).
  // ---------------------------------------------
  Widget _buildScaffoldedSheet({
    required BuildContext context,
    required Widget child,
  }) {
    // Höhe begrenzen, damit der Sheet nicht "unendlich" groß wird,
    // sondern maximal bis zur Bildschirmhöhe geht.
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxHeight = MediaQuery.of(ctx).size.height * 0.92; // leicht unter voll
        return ConstrainedBox(
          constraints: BoxConstraints(
            // minHeight sorgt dafür, dass Expanded im Editor funktioniert
            minHeight: 200,
            maxHeight: maxHeight,
          ),
          child: Material(
            // eigener Material-Kontext (für Schatten/Farben)
            color: Theme.of(ctx).colorScheme.surface,
            child: child,
          ),
        );
      },
    );
  }
}
