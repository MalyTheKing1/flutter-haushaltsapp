// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsAdapter extends TypeAdapter<Settings> {
  @override
  final int typeId = 3;

  @override
  Settings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Settings(
      isDarkMode: fields[0] as bool,
      notificationsEnabled: fields[1] as bool?,
      notificationHour: fields[2] as int?,
      notificationMinute: fields[3] as int?,
      debugAlwaysTriggerRandom: fields[4] as bool?,
      lastRandomCheckDate: fields[5] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Settings obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.isDarkMode)
      ..writeByte(1)
      ..write(obj.notificationsEnabled)
      ..writeByte(2)
      ..write(obj.notificationHour)
      ..writeByte(3)
      ..write(obj.notificationMinute)
      ..writeByte(4)
      ..write(obj.debugAlwaysTriggerRandom)
      ..writeByte(5)
      ..write(obj.lastRandomCheckDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
