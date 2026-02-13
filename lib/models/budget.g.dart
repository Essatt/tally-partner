// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BudgetAdapter extends TypeAdapter<Budget> {
  @override
  final int typeId = 8;

  @override
  Budget read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Budget(
      id: fields[0] as String,
      personId: fields[1] as String,
      name: fields[2] as String,
      budgetLimit: fields[3] as double,
      currentBalance: fields[4] as double,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Budget obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.budgetLimit)
      ..writeByte(4)
      ..write(obj.currentBalance)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BudgetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
