// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automaton_schema.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AutomatonSchemaImpl _$$AutomatonSchemaImplFromJson(
        Map<String, dynamic> json) =>
    _$AutomatonSchemaImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$AutomatonTypeEnumMap, json['type']),
      version: json['version'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      requiredFields: (json['requiredFields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      optionalFields: (json['optionalFields'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      validationRules: json['validationRules'] as Map<String, dynamic>,
      description: json['description'] as String?,
      author: json['author'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$AutomatonSchemaImplToJson(
        _$AutomatonSchemaImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$AutomatonTypeEnumMap[instance.type]!,
      'version': instance.version,
      'metadata': instance.metadata,
      'requiredFields': instance.requiredFields,
      'optionalFields': instance.optionalFields,
      'validationRules': instance.validationRules,
      'description': instance.description,
      'author': instance.author,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$AutomatonTypeEnumMap = {
  AutomatonType.finiteAutomaton: 'finite_automaton',
  AutomatonType.pushdownAutomaton: 'pushdown_automaton',
  AutomatonType.turingMachine: 'turing_machine',
  AutomatonType.contextFreeGrammar: 'context_free_grammar',
  AutomatonType.regularExpression: 'regular_expression',
};

_$SchemaValidationResultImpl _$$SchemaValidationResultImplFromJson(
        Map<String, dynamic> json) =>
    _$SchemaValidationResultImpl(
      isValid: json['isValid'] as bool,
      errors:
          (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
      warnings:
          (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
      validatedData: json['validatedData'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$$SchemaValidationResultImplToJson(
        _$SchemaValidationResultImpl instance) =>
    <String, dynamic>{
      'isValid': instance.isValid,
      'errors': instance.errors,
      'warnings': instance.warnings,
      'validatedData': instance.validatedData,
    };

_$SchemaRegistryImpl _$$SchemaRegistryImplFromJson(Map<String, dynamic> json) =>
    _$SchemaRegistryImpl(
      schemas: (json['schemas'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
                k, AutomatonSchema.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      supportedTypes: (json['supportedTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      defaultSchema: json['defaultSchema'] as String?,
    );

Map<String, dynamic> _$$SchemaRegistryImplToJson(
        _$SchemaRegistryImpl instance) =>
    <String, dynamic>{
      'schemas': instance.schemas,
      'supportedTypes': instance.supportedTypes,
      'defaultSchema': instance.defaultSchema,
    };
