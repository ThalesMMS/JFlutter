import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';

part 'automaton_schema.freezed.dart';
part 'automaton_schema.g.dart';

/// Schema definition for automaton serialization and validation
@freezed
class AutomatonSchema with _$AutomatonSchema {
  const factory AutomatonSchema({
    required String id,
    required String name,
    required AutomatonType type,
    required String version,
    required Map<String, dynamic> metadata,
    required List<String> requiredFields,
    required List<String> optionalFields,
    required Map<String, dynamic> validationRules,
    String? description,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AutomatonSchema;

  factory AutomatonSchema.fromJson(Map<String, dynamic> json) =>
      _$AutomatonSchemaFromJson(json);
}

/// Supported automaton types for schema validation
enum AutomatonType {
  @JsonValue('finite_automaton')
  finiteAutomaton,
  @JsonValue('pushdown_automaton')
  pushdownAutomaton,
  @JsonValue('turing_machine')
  turingMachine,
  @JsonValue('context_free_grammar')
  contextFreeGrammar,
  @JsonValue('regular_expression')
  regularExpression,
}

/// Schema validation result
@freezed
class SchemaValidationResult with _$SchemaValidationResult {
  const factory SchemaValidationResult({
    required bool isValid,
    required List<String> errors,
    required List<String> warnings,
    required Map<String, dynamic> validatedData,
  }) = _SchemaValidationResult;

  factory SchemaValidationResult.fromJson(Map<String, dynamic> json) =>
      _$SchemaValidationResultFromJson(json);
}

/// Schema registry for managing multiple automaton schemas
@freezed
class SchemaRegistry with _$SchemaRegistry {
  const factory SchemaRegistry({
    @Default({}) Map<String, AutomatonSchema> schemas,
    @Default([]) List<String> supportedTypes,
    String? defaultSchema,
  }) = _SchemaRegistry;

  factory SchemaRegistry.fromJson(Map<String, dynamic> json) =>
      _$SchemaRegistryFromJson(json);
}
