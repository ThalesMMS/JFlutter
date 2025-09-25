import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:core_fa/core_fa.dart';
import 'package:core_pda/core_pda.dart';
import 'package:core_tm/core_tm.dart';
import 'package:core_regex/core_regex.dart';

part 'jflap_file.freezed.dart';
part 'jflap_file.g.dart';

/// JFLAP file format representation for import/export compatibility
@freezed
class JFLAPFile with _$JFLAPFile {
  const factory JFLAPFile({
    required String version,
    required JFLAPStructure structure,
    String? comment,
    Map<String, dynamic>? metadata,
  }) = _JFLAPFile;

  factory JFLAPFile.fromJson(Map<String, dynamic> json) =>
      _$JFLAPFileFromJson(json);
}

/// JFLAP file structure containing automaton data
@freezed
class JFLAPStructure with _$JFLAPStructure {
  const factory JFLAPStructure({
    required JFLAPType type,
    required String id,
    required String name,
    required List<JFLAPState> states,
    required List<JFLAPTransition> transitions,
    required List<String> alphabet,
    String? startState,
    required List<String> finalStates,
    Map<String, dynamic>? properties,
  }) = _JFLAPStructure;

  factory JFLAPStructure.fromJson(Map<String, dynamic> json) =>
      _$JFLAPStructureFromJson(json);
}

/// JFLAP state representation
@freezed
class JFLAPState with _$JFLAPState {
  const factory JFLAPState({
    required String id,
    required String name,
    required double x,
    required double y,
    required bool isInitial,
    required bool isFinal,
    String? label,
    Map<String, dynamic>? properties,
  }) = _JFLAPState;

  factory JFLAPState.fromJson(Map<String, dynamic> json) =>
      _$JFLAPStateFromJson(json);
}

/// JFLAP transition representation
@freezed
class JFLAPTransition with _$JFLAPTransition {
  const factory JFLAPTransition({
    required String from,
    required String to,
    required String label,
    String? stackSymbol,
    String? stackAction,
    Map<String, dynamic>? properties,
  }) = _JFLAPTransition;

  factory JFLAPTransition.fromJson(Map<String, dynamic> json) =>
      _$JFLAPTransitionFromJson(json);
}

/// JFLAP automaton types
enum JFLAPType {
  @JsonValue('fa')
  finiteAutomaton,
  @JsonValue('pda')
  pushdownAutomaton,
  @JsonValue('tm')
  turingMachine,
  @JsonValue('grammar')
  contextFreeGrammar,
  @JsonValue('regex')
  regularExpression,
}

/// JFLAP import/export result
@freezed
class JFLAPResult with _$JFLAPResult {
  const factory JFLAPResult({
    required bool success,
    String? error,
    required JFLAPFile file,
    required Map<String, dynamic> metadata,
  }) = _JFLAPResult;

  factory JFLAPResult.fromJson(Map<String, dynamic> json) =>
      _$JFLAPResultFromJson(json);
}

/// JFLAP conversion utilities
class JFLAPConverter {
  /// Convert JFLAP file to core automaton models
  static Map<String, dynamic> toCoreModel(JFLAPFile jflapFile) {
    // Implementation will be added based on specific automaton type
    return {
      'type': jflapFile.structure.type.name,
      'id': jflapFile.structure.id,
      'name': jflapFile.structure.name,
      'states': jflapFile.structure.states,
      'transitions': jflapFile.structure.transitions,
      'alphabet': jflapFile.structure.alphabet,
    };
  }

  /// Convert core automaton model to JFLAP file
  static JFLAPFile fromCoreModel(Map<String, dynamic> model) {
    // Implementation will be added based on specific automaton type
    return JFLAPFile(
      version: '1.0',
      structure: JFLAPStructure(
        type: JFLAPType.finiteAutomaton,
        id: model['id'] ?? '',
        name: model['name'] ?? '',
        states: [],
        transitions: [],
        alphabet: [],
        startState: null,
        finalStates: [],
      ),
    );
  }
}
