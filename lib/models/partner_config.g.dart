// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'partner_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PartnerConfigAdapter extends TypeAdapter<PartnerConfig> {
  @override
  final int typeId = 3;

  @override
  PartnerConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PartnerConfig(
      id: fields[0] as String,
      budgetLimit: fields[1] as double,
      currentBalance: fields[2] as double,
      partnerName: fields[3] as String,
      isActive: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PartnerConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.budgetLimit)
      ..writeByte(2)
      ..write(obj.currentBalance)
      ..writeByte(3)
      ..write(obj.partnerName)
      ..writeByte(4)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PartnerConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
