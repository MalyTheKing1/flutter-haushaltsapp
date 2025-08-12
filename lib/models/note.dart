// lib/models/note.dart
import 'package:hive/hive.dart';

/// Einfache Notiz mit Titel + Inhalt, Timestamps, optional "pinned" und sortIndex.
/// MANUELLER Hive-Adapter (kein build_runner nötig).
class Note extends HiveObject {
  String title;         // Überschrift
  String content;       // Inhalt (ersetzt früher "text")
  DateTime createdAt;
  DateTime updatedAt;
  bool pinned;
  int sortIndex;        // Benutzerdefinierte Reihenfolge (Drag & Drop)

  Note({
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pinned = false,
    this.sortIndex = 0,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Aktualisiert Textfelder + updatedAt
  void updateText({String? newTitle, String? newContent}) {
    if (newTitle != null) title = newTitle;
    if (newContent != null) content = newContent;
    updatedAt = DateTime.now();
  }

  @override
  String toString() => 'Note(title: $title, pinned: $pinned, sortIndex: $sortIndex)';
}

/// Adapter: typeId = 2 (muss mit HiveService.registerAdapters() übereinstimmen)
/// Abwärtskompatibel zum alten Format (nur "text").
class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 2;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Altformat erkennen: (0..3) vorhanden, aber 4/5 (title/content) fehlen
    final isOldFormat = fields.containsKey(0) && !fields.containsKey(4) && !fields.containsKey(5);

    if (isOldFormat) {
      final String oldText = fields[0] as String? ?? '';
      return Note(
        title: '',
        content: oldText,
        createdAt: fields[1] as DateTime? ?? DateTime.now(),
        updatedAt: fields[2] as DateTime? ?? DateTime.now(),
        pinned: fields[3] as bool? ?? false,
        sortIndex: 0,
      );
    }

    // Neues Format
    return Note(
      title: fields[4] as String? ?? '',
      content: fields[5] as String? ?? '',
      createdAt: fields[1] as DateTime? ?? DateTime.now(),
      updatedAt: fields[2] as DateTime? ?? DateTime.now(),
      pinned: fields[3] as bool? ?? false,
      sortIndex: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(7) // Anzahl Felder im neuen Format
      ..writeByte(0) // (Altformat-Kompatibilität – schreiben content hierhin)
      ..write(obj.content)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.pinned)
      ..writeByte(4) // title
      ..write(obj.title)
      ..writeByte(5) // content
      ..write(obj.content)
      ..writeByte(6) // sortIndex
      ..write(obj.sortIndex);
  }
}
