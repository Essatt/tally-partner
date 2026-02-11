// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tally_event.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TallyEventAdapter extends TypeAdapter<TallyEvent> {
  @override
  final int typeId = 5;

  @override
  TallyEvent read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TallyEvent(
      id: fields[0] as String,
      name: fields[1] as String,
      icon: fields[2] as String?,
      color: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      type: fields[5] as TallyType,
    );
  }

  @override
  void write(BinaryWriter writer, TallyEvent obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.color)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TallyEventAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TallyTypeAdapter extends TypeAdapter<TallyType> {
  @override
  final int typeId = 6;

  @override
  TallyType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TallyType.standard;
      case 1:
        return TallyType.partnerPositive;
      case 2:
        return TallyType.partnerNegative;
      default:
        return TallyType.standard;
    }
  }

  @override
  void write(BinaryWriter writer, TallyType obj) {
    switch (obj) {
      case TallyType.standard:
        writer.writeByte(0);
        break;
      case TallyType.partnerPositive:
        writer.writeByte(1);
        break;
      case TallyType.partnerNegative:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TallyTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
