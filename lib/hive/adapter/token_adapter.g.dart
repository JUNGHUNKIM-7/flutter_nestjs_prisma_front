// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_adapter.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HiveTokensAdapter extends TypeAdapter<HiveTokens> {
  @override
  final int typeId = 1;

  @override
  HiveTokens read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveTokens()
      ..at = fields[0] as String?
      ..rt = fields[1] as String?
      ..updatedAt = fields[2] as String?;
  }

  @override
  void write(BinaryWriter writer, HiveTokens obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.at)
      ..writeByte(1)
      ..write(obj.rt)
      ..writeByte(2)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveTokensAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
