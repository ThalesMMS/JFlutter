// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'grammar_transformation_step.dart';

GrammarTransformationStep _$GrammarTransformationStepFromJson(
  Map<String, dynamic> json,
) =>
    _GrammarTransformationStep(
      id: json['id'] as String,
      operation: json['operation'] as String,
      rationale: json['rationale'] as String,
      before: Grammar.fromJson(json['before'] as Map<String, dynamic>),
      after: Grammar.fromJson(json['after'] as Map<String, dynamic>),
      changedSymbols:
          (json['changedSymbols'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e as String)
              .toSet(),
      changedProductionIds:
          (json['changedProductionIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e as String)
              .toSet(),
    );

Map<String, dynamic> _$GrammarTransformationStepToJson(
  _GrammarTransformationStep instance,
) =>
    <String, dynamic>{
      'id': instance.id,
      'operation': instance.operation,
      'rationale': instance.rationale,
      'before': instance.before.toJson(),
      'after': instance.after.toJson(),
      'changedSymbols': instance.changedSymbols.toList(),
      'changedProductionIds': instance.changedProductionIds.toList(),
    };
