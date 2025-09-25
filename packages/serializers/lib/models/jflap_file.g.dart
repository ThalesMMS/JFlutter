// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jflap_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$JFLAPFileImpl _$$JFLAPFileImplFromJson(Map<String, dynamic> json) =>
    _$JFLAPFileImpl(
      version: json['version'] as String,
      structure:
          JFLAPStructure.fromJson(json['structure'] as Map<String, dynamic>),
      comment: json['comment'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$JFLAPFileImplToJson(_$JFLAPFileImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'structure': instance.structure,
      'comment': instance.comment,
      'metadata': instance.metadata,
    };

_$JFLAPStructureImpl _$$JFLAPStructureImplFromJson(Map<String, dynamic> json) =>
    _$JFLAPStructureImpl(
      type: $enumDecode(_$JFLAPTypeEnumMap, json['type']),
      id: json['id'] as String,
      name: json['name'] as String,
      states: (json['states'] as List<dynamic>)
          .map((e) => JFLAPState.fromJson(e as Map<String, dynamic>))
          .toList(),
      transitions: (json['transitions'] as List<dynamic>)
          .map((e) => JFLAPTransition.fromJson(e as Map<String, dynamic>))
          .toList(),
      alphabet:
          (json['alphabet'] as List<dynamic>).map((e) => e as String).toList(),
      startState: json['startState'] as String?,
      finalStates: (json['finalStates'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$JFLAPStructureImplToJson(
        _$JFLAPStructureImpl instance) =>
    <String, dynamic>{
      'type': _$JFLAPTypeEnumMap[instance.type]!,
      'id': instance.id,
      'name': instance.name,
      'states': instance.states,
      'transitions': instance.transitions,
      'alphabet': instance.alphabet,
      'startState': instance.startState,
      'finalStates': instance.finalStates,
      'properties': instance.properties,
    };

const _$JFLAPTypeEnumMap = {
  JFLAPType.finiteAutomaton: 'fa',
  JFLAPType.pushdownAutomaton: 'pda',
  JFLAPType.turingMachine: 'tm',
  JFLAPType.contextFreeGrammar: 'grammar',
  JFLAPType.regularExpression: 'regex',
};

_$JFLAPStateImpl _$$JFLAPStateImplFromJson(Map<String, dynamic> json) =>
    _$JFLAPStateImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      isInitial: json['isInitial'] as bool,
      isFinal: json['isFinal'] as bool,
      label: json['label'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$JFLAPStateImplToJson(_$JFLAPStateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'x': instance.x,
      'y': instance.y,
      'isInitial': instance.isInitial,
      'isFinal': instance.isFinal,
      'label': instance.label,
      'properties': instance.properties,
    };

_$JFLAPTransitionImpl _$$JFLAPTransitionImplFromJson(
        Map<String, dynamic> json) =>
    _$JFLAPTransitionImpl(
      from: json['from'] as String,
      to: json['to'] as String,
      label: json['label'] as String,
      stackSymbol: json['stackSymbol'] as String?,
      stackAction: json['stackAction'] as String?,
      properties: json['properties'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$JFLAPTransitionImplToJson(
        _$JFLAPTransitionImpl instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'label': instance.label,
      'stackSymbol': instance.stackSymbol,
      'stackAction': instance.stackAction,
      'properties': instance.properties,
    };

_$JFLAPResultImpl _$$JFLAPResultImplFromJson(Map<String, dynamic> json) =>
    _$JFLAPResultImpl(
      success: json['success'] as bool,
      error: json['error'] as String?,
      file: JFLAPFile.fromJson(json['file'] as Map<String, dynamic>),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$JFLAPResultImplToJson(_$JFLAPResultImpl instance) =>
    <String, dynamic>{
      'success': instance.success,
      'error': instance.error,
      'file': instance.file,
      'metadata': instance.metadata,
    };
