// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recently_viewed_location_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecentlyViewedLocationModelAdapter
    extends TypeAdapter<RecentlyViewedLocationModel> {
  @override
  final int typeId = 2;

  @override
  RecentlyViewedLocationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecentlyViewedLocationModel(
      name: fields[0] as String,
      description: fields[1] as String,
      imageUrl: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      type: fields[5] as String,
      viewedAt: fields[6] as DateTime,
      scores: (fields[7] as Map).cast<String, double>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecentlyViewedLocationModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.viewedAt)
      ..writeByte(7)
      ..write(obj.scores);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecentlyViewedLocationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
