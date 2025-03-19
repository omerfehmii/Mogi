// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comparison_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ComparisonHistoryModelAdapter
    extends TypeAdapter<ComparisonHistoryModel> {
  @override
  final int typeId = 10;

  @override
  ComparisonHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ComparisonHistoryModel(
      id: fields[0] as String,
      locations: (fields[1] as List).cast<String>(),
      result: fields[2] as String,
      createdAt: fields[3] as DateTime,
      title: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ComparisonHistoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.locations)
      ..writeByte(2)
      ..write(obj.result)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComparisonHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
