// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringTaskAdapter extends TypeAdapter<RecurringTask> {
  @override
  final int typeId = 0;

  @override
  RecurringTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringTask(
      title: fields[0] as String,
      intervalDays: fields[1] as int,
      isDone: fields[2] as bool,
      lastDoneDate: fields[3] as DateTime?,
      iconName: fields[4] as String?,
      randomnessEnabled: fields[5] as bool?,
      randomChance: fields[6] as int?,
      randomDueToday: fields[7] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringTask obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.intervalDays)
      ..writeByte(2)
      ..write(obj.isDone)
      ..writeByte(3)
      ..write(obj.lastDoneDate)
      ..writeByte(4)
      ..write(obj.iconName)
      ..writeByte(5)
      ..write(obj.randomnessEnabled)
      ..writeByte(6)
      ..write(obj.randomChance)
      ..writeByte(7)
      ..write(obj.randomDueToday);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
