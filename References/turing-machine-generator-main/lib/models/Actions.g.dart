// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Actions.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActionsAdapter extends TypeAdapter<Actions> {
  @override
  final int typeId = 4;

  @override
  Actions read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Actions(
      type: fields[1] as ActionType,
      symbol: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Actions obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.symbol)
      ..writeByte(1)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActionTypeAdapter extends TypeAdapter<ActionType> {
  @override
  final int typeId = 5;

  @override
  ActionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActionType.P;
      case 1:
        return ActionType.R;
      case 2:
        return ActionType.L;
      case 3:
        return ActionType.E;
      case 4:
        return ActionType.NONE;
      default:
        return ActionType.P;
    }
  }

  @override
  void write(BinaryWriter writer, ActionType obj) {
    switch (obj) {
      case ActionType.P:
        writer.writeByte(0);
        break;
      case ActionType.R:
        writer.writeByte(1);
        break;
      case ActionType.L:
        writer.writeByte(2);
        break;
      case ActionType.E:
        writer.writeByte(3);
        break;
      case ActionType.NONE:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Actions _$ActionsFromJson(Map<String, dynamic> json) => Actions(
      type: $enumDecode(_$ActionTypeEnumMap, json['type']),
      symbol: json['symbol'] as String? ?? "",
    );

Map<String, dynamic> _$ActionsToJson(Actions instance) => <String, dynamic>{
      'symbol': instance.symbol,
      'type': _$ActionTypeEnumMap[instance.type]!,
    };

const _$ActionTypeEnumMap = {
  ActionType.P: 'P',
  ActionType.R: 'R',
  ActionType.L: 'L',
  ActionType.E: 'E',
  ActionType.NONE: 'NONE',
};
