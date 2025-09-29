// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grammar_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GrammarDto _$GrammarDtoFromJson(Map json) => _GrammarDto(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] as String,
  terminals: (json['terminals'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  variables: (json['variables'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  initialSymbol: json['initialSymbol'] as String,
  productions: (json['productions'] as Map).map(
    (k, e) => MapEntry(
      k as String,
      (e as List<dynamic>).map((e) => e as String).toList(),
    ),
  ),
);

Map<String, dynamic> _$GrammarDtoToJson(_GrammarDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'terminals': instance.terminals,
      'variables': instance.variables,
      'initialSymbol': instance.initialSymbol,
      'productions': instance.productions,
    };

_JflapGrammarDto _$JflapGrammarDtoFromJson(Map json) => _JflapGrammarDto(
  type: json['type'] as String,
  structure: JflapGrammarStructureDto.fromJson(
    Map<String, dynamic>.from(json['structure'] as Map),
  ),
);

Map<String, dynamic> _$JflapGrammarDtoToJson(_JflapGrammarDto instance) =>
    <String, dynamic>{
      'type': instance.type,
      'structure': instance.structure.toJson(),
    };

_JflapGrammarStructureDto _$JflapGrammarStructureDtoFromJson(Map json) =>
    _JflapGrammarStructureDto(
      terminals: (json['terminals'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      variables: (json['variables'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      startVariable: json['startVariable'] as String,
      productions: (json['productions'] as List<dynamic>)
          .map(
            (e) => JflapProductionDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );

Map<String, dynamic> _$JflapGrammarStructureDtoToJson(
  _JflapGrammarStructureDto instance,
) => <String, dynamic>{
  'terminals': instance.terminals,
  'variables': instance.variables,
  'startVariable': instance.startVariable,
  'productions': instance.productions.map((e) => e.toJson()).toList(),
};

_JflapProductionDto _$JflapProductionDtoFromJson(Map json) =>
    _JflapProductionDto(
      left: json['left'] as String,
      right: json['right'] as String,
    );

Map<String, dynamic> _$JflapProductionDtoToJson(_JflapProductionDto instance) =>
    <String, dynamic>{'left': instance.left, 'right': instance.right};
