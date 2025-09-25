// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Configuration.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConfigurationAdapter extends TypeAdapter<Configuration> {
  @override
  final int typeId = 2;

  @override
  Configuration read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Configuration(
      m_config: fields[0] as String,
      symbol: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Configuration obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.m_config)
      ..writeByte(1)
      ..write(obj.symbol);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigurationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Configuration _$ConfigurationFromJson(Map<String, dynamic> json) =>
    Configuration(
      m_config: json['m_config'] as String,
      symbol: json['symbol'] as String,
    );

Map<String, dynamic> _$ConfigurationToJson(Configuration instance) =>
    <String, dynamic>{
      'm_config': instance.m_config,
      'symbol': instance.symbol,
    };
