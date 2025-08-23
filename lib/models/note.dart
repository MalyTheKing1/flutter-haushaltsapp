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

  // 👉 NEU: geheime Notiz (Standard false, damit Alt-Daten kompatibel bleiben)
  bool isSecret;

  Note({
    required this.title,
    required this.content,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.pinned = false,
    this.sortIndex = 0,
    this.isSecret = false, // default
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Aktualisiert Textfelder + updatedAt
  void updateText({String? newTitle, String? newContent}) {
    if (newTitle != null) title = newTitle;
    if (newContent != null) content = newContent;
    updatedAt = DateTime.now();
  }

  @override
  String toString() =>
      'Note(title: $title, pinned: $pinned, sortIndex: $sortIndex, isSecret: $isSecret)';
}

/// Adapter: typeId = 2 (muss mit HiveService.registerAdapters() übereinstimmen)
/// Abwärtskompatibel zum alten Format (nur "text") + neuem Feld isSecret.
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
    final isOldFormat =
        fields.containsKey(0) && !fields.containsKey(4) && !fields.containsKey(5);

    if (isOldFormat) {
      final String oldText = fields[0] as String? ?? '';
      return Note(
        title: '',
        content: oldText,
        createdAt: fields[1] as DateTime? ?? DateTime.now(),
        updatedAt: fields[2] as DateTime? ?? DateTime.now(),
        pinned: fields[3] as bool? ?? false,
        sortIndex: 0,
        isSecret: false, // 👈 Alt-Daten sind nie geheim
      );
    }

    // Neues Format (mit title/content/sortIndex) + optional isSecret (Feld 7)
    return Note(
      title: fields[4] as String? ?? '',
      content: fields[5] as String? ?? '',
      createdAt: fields[1] as DateTime? ?? DateTime.now(),
      updatedAt: fields[2] as DateTime? ?? DateTime.now(),
      pinned: fields[3] as bool? ?? false,
      sortIndex: fields[6] as int? ?? 0,
      isSecret: fields[7] as bool? ?? false, // 👈 falls nicht vorhanden → false
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(8) // Anzahl Felder im *aktuellen* Format (7 + neues Feld 7)
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
      ..write(obj.sortIndex)
      ..writeByte(7) // 👉 NEU: isSecret
      ..write(obj.isSecret);
  }
}
