// lib/widgets/note_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';

/// Kompakte Darstellung einer Notiz in der Liste.
/// Bietet Aktionen: Bearbeiten, Löschen.
/// ANZEIGE:
///  - Erste Zeile: Titel fett
///  - Direkt darunter: Änderungsdatum in kleiner, hellerer Schrift mit Stift-Icon (✎)
///  - Danach: kompletter Inhalt in normaler Schrift (kein maxLines)
class NoteTile extends StatelessWidget { // ← Achte auf den Namen: NoteTile
  final Note note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const NoteTile({
    super.key,
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final dateFmt = DateFormat.yMMMd().add_Hm(); // z.B. "12. Aug. 2025 14:30"
    final timestampText = '✎ ${dateFmt.format(note.updatedAt)}'; // Stift, keine Klammern

    return Material(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.notes),
        title: Text(
          note.title.isEmpty ? '(Ohne Titel)' : note.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timestampText,
                style: textTheme.bodySmall?.copyWith(
                  color: (textTheme.bodySmall?.color ?? Theme.of(context).colorScheme.onSurface)
                      .withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(note.content),
            ],
          ),
        ),
        onTap: onEdit,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: onEdit,
            ),
            IconButton(
              tooltip: 'Löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}