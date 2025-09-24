// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TuringMachineModel.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TuringMachineModelAdapter extends TypeAdapter<TuringMachineModel> {
  @override
  final int typeId = 0;

  @override
  TuringMachineModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TuringMachineModel(
      initial_config: fields[0] as String,
      configs: (fields[1] as List).cast<Configuration>(),
      behaviours: (fields[2] as List).cast<Behaviour>(),
      description: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TuringMachineModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.initial_config)
      ..writeByte(1)
      ..write(obj.configs)
      ..writeByte(2)
      ..write(obj.behaviours)
      ..writeByte(3)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TuringMachineModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TuringMachineModel _$TuringMachineModelFromJson(Map<String, dynamic> json) =>
    TuringMachineModel(
      initial_config: json['initial_config'] as String,
      configs: (json['configs'] as List<dynamic>)
          .map((e) => Configuration.fromJson(e as Map<String, dynamic>))
          .toList(),
      behaviours: (json['behaviours'] as List<dynamic>)
          .map((e) => Behaviour.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
    );

Map<String, dynamic> _$TuringMachineModelToJson(TuringMachineModel instance) =>
    <String, dynamic>{
      'initial_config': instance.initial_config,
      'configs': instance.configs,
      'behaviours': instance.behaviours,
      'description': instance.description,
    };
