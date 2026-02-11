// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tally_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TallyLogAdapter extends TypeAdapter<TallyLog> {
  @override
  final int typeId = 4;

  @override
  TallyLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TallyLog(
      id: fields[0] as String,
      eventId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      valueAdjustment: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, TallyLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.valueAdjustment);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TallyLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
