// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onetime_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OneTimeTaskAdapter extends TypeAdapter<OneTimeTask> {
  @override
  final int typeId = 1;

  @override
  OneTimeTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OneTimeTask(
      title: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OneTimeTask obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OneTimeTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
