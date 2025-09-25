import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';

part 'example_library.freezed.dart';
part 'example_library.g.dart';

/// Library of canonical examples for automaton types
@freezed
class ExampleLibrary with _$ExampleLibrary {
  const factory ExampleLibrary({
    required String id,
    required String name,
    required String description,
    required String version,
    required List<ExampleCategory> categories,
    required Map<String, dynamic> metadata,
    String? author,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExampleLibrary;

  factory ExampleLibrary.fromJson(Map<String, dynamic> json) =>
      _$ExampleLibraryFromJson(json);
}

/// Category of examples (e.g., basic, advanced, educational)
@freezed
class ExampleCategory with _$ExampleCategory {
  const factory ExampleCategory({
    required String id,
    required String name,
    required String description,
    required List<AutomatonExample> examples,
    required ExampleDifficulty difficulty,
    required List<String> tags,
    String? icon,
    Map<String, dynamic>? metadata,
  }) = _ExampleCategory;

  factory ExampleCategory.fromJson(Map<String, dynamic> json) =>
      _$ExampleCategoryFromJson(json);
}

/// Individual automaton example
@freezed
class AutomatonExample with _$AutomatonExample {
  const factory AutomatonExample({
    required String id,
    required String name,
    required String description,
    required ExampleType type,
    required Map<String, dynamic> data,
    required List<String> testCases,
    required List<String> expectedResults,
    String? hint,
    String? solution,
    required List<String> tags,
    required ExampleDifficulty difficulty,
    Map<String, dynamic>? metadata,
  }) = _AutomatonExample;

  factory AutomatonExample.fromJson(Map<String, dynamic> json) =>
      _$AutomatonExampleFromJson(json);
}

/// Example types supported
enum ExampleType {
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
  @JsonValue('algorithm_demo')
  algorithmDemo,
  @JsonValue('conversion_demo')
  conversionDemo,
}

/// Difficulty levels for examples
enum ExampleDifficulty {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('expert')
  expert,
}

/// Example test case
@freezed
class ExampleTestCase with _$ExampleTestCase {
  const factory ExampleTestCase({
    required String input,
    required bool expectedAccept,
    String? expectedOutput,
    String? description,
    Map<String, dynamic>? metadata,
  }) = _ExampleTestCase;

  factory ExampleTestCase.fromJson(Map<String, dynamic> json) =>
      _$ExampleTestCaseFromJson(json);
}

/// Example library search and filter options
@freezed
class ExampleSearchOptions with _$ExampleSearchOptions {
  const factory ExampleSearchOptions({
    String? query,
    List<ExampleType>? types,
    List<ExampleDifficulty>? difficulties,
    List<String>? tags,
    String? category,
    int? limit,
    int? offset,
  }) = _ExampleSearchOptions;

  factory ExampleSearchOptions.fromJson(Map<String, dynamic> json) =>
      _$ExampleSearchOptionsFromJson(json);
}

/// Example library search result
@freezed
class ExampleSearchResult with _$ExampleSearchResult {
  const factory ExampleSearchResult({
    required List<AutomatonExample> examples,
    required int totalCount,
    required int offset,
    required int limit,
    required bool hasMore,
  }) = _ExampleSearchResult;

  factory ExampleSearchResult.fromJson(Map<String, dynamic> json) =>
      _$ExampleSearchResultFromJson(json);
}
