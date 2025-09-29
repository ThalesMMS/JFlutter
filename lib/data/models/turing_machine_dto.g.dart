// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'turing_machine_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TuringMachineDto _$TuringMachineDtoFromJson(Map json) => _TuringMachineDto(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  inputAlphabet: (json['inputAlphabet'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tapeAlphabet: (json['tapeAlphabet'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  states: (json['states'] as List<dynamic>).map((e) => e as String).toList(),
  initialState: json['initialState'] as String,
  finalStates: (json['finalStates'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  blankSymbol: json['blankSymbol'] as String,
  transitions: (json['transitions'] as Map).map(
    (k, e) => MapEntry(
      k as String,
      (e as Map).map(
        (k, e) => MapEntry(
          k as String,
          TuringTransitionDto.fromJson(Map<String, dynamic>.from(e as Map)),
        ),
      ),
    ),
  ),
);

Map<String, dynamic> _$TuringMachineDtoToJson(_TuringMachineDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'inputAlphabet': instance.inputAlphabet,
      'tapeAlphabet': instance.tapeAlphabet,
      'states': instance.states,
      'initialState': instance.initialState,
      'finalStates': instance.finalStates,
      'blankSymbol': instance.blankSymbol,
      'transitions': instance.transitions.map(
        (k, e) => MapEntry(k, e.map((k, e) => MapEntry(k, e.toJson()))),
      ),
    };

_TuringTransitionDto _$TuringTransitionDtoFromJson(Map json) =>
    _TuringTransitionDto(
      newState: json['newState'] as String,
      writeSymbol: json['writeSymbol'] as String,
      direction: json['direction'] as String,
    );

Map<String, dynamic> _$TuringTransitionDtoToJson(
  _TuringTransitionDto instance,
) => <String, dynamic>{
  'newState': instance.newState,
  'writeSymbol': instance.writeSymbol,
  'direction': instance.direction,
};

_JflapTuringMachineDto _$JflapTuringMachineDtoFromJson(Map json) =>
    _JflapTuringMachineDto(
      type: json['type'] as String,
      structure: JflapTuringStructureDto.fromJson(
        Map<String, dynamic>.from(json['structure'] as Map),
      ),
    );

Map<String, dynamic> _$JflapTuringMachineDtoToJson(
  _JflapTuringMachineDto instance,
) => <String, dynamic>{
  'type': instance.type,
  'structure': instance.structure.toJson(),
};

_JflapTuringStructureDto _$JflapTuringStructureDtoFromJson(
  Map json,
) => _JflapTuringStructureDto(
  states: (json['states'] as List<dynamic>).map((e) => e as String).toList(),
  inputAlphabet: (json['inputAlphabet'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  tapeAlphabet: (json['tapeAlphabet'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  initialState: json['initialState'] as String,
  finalStates: (json['finalStates'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  blankSymbol: json['blankSymbol'] as String,
  transitions: (json['transitions'] as List<dynamic>)
      .map(
        (e) => JflapTuringTransitionDto.fromJson(
          Map<String, dynamic>.from(e as Map),
        ),
      )
      .toList(),
);

Map<String, dynamic> _$JflapTuringStructureDtoToJson(
  _JflapTuringStructureDto instance,
) => <String, dynamic>{
  'states': instance.states,
  'inputAlphabet': instance.inputAlphabet,
  'tapeAlphabet': instance.tapeAlphabet,
  'initialState': instance.initialState,
  'finalStates': instance.finalStates,
  'blankSymbol': instance.blankSymbol,
  'transitions': instance.transitions.map((e) => e.toJson()).toList(),
};

_JflapTuringTransitionDto _$JflapTuringTransitionDtoFromJson(Map json) =>
    _JflapTuringTransitionDto(
      from: json['from'] as String,
      to: json['to'] as String,
      read: json['read'] as String,
      write: json['write'] as String,
      direction: json['direction'] as String,
    );

Map<String, dynamic> _$JflapTuringTransitionDtoToJson(
  _JflapTuringTransitionDto instance,
) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'read': instance.read,
  'write': instance.write,
  'direction': instance.direction,
};
