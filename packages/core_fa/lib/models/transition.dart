import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';

part 'transition.freezed.dart';
part 'transition.g.dart';

/// Base transition class for all automaton types
@freezed
class Transition with _$Transition {
  const factory Transition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    @Default(Vector2.zero()) Vector2 controlPoint,
    @Default(TransitionType.deterministic) TransitionType type,
  }) = _Transition;

  factory Transition.fromJson(Map<String, dynamic> json) => _$TransitionFromJson(json);
}

/// FSA-specific transition with input symbols
@freezed
class FSATransition with _$FSATransition {
  const factory FSATransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    @Default(Vector2.zero()) Vector2 controlPoint,
    @Default(TransitionType.deterministic) TransitionType type,
    required Set<String> inputSymbols,
    String? lambdaSymbol,
  }) = _FSATransition;

  factory FSATransition.fromJson(Map<String, dynamic> json) => _$FSATransitionFromJson(json);

  /// Primary symbol for this transition (first symbol from inputSymbols or lambdaSymbol)
  String get symbol {
    if (lambdaSymbol != null) return lambdaSymbol!;
    return inputSymbols.isNotEmpty ? inputSymbols.first : '';
  }

  /// Returns true if this is an epsilon transition
  bool get isEpsilonTransition {
    return lambdaSymbol != null || inputSymbols.contains('ε') || inputSymbols.contains('eps');
  }

  /// Returns true if this is a deterministic transition
  bool get isDeterministic {
    return inputSymbols.length == 1 && lambdaSymbol == null;
  }

  /// Returns true if this is a non-deterministic transition
  bool get isNondeterministic {
    return !isDeterministic;
  }

  /// Returns true if this transition accepts the given symbol
  bool acceptsSymbol(String symbol) {
    if (isEpsilonTransition) return false;
    return inputSymbols.contains(symbol);
  }
}

/// PDA-specific transition with stack operations
@freezed
class PDATransition with _$PDATransition {
  const factory PDATransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    @Default(Vector2.zero()) Vector2 controlPoint,
    @Default(TransitionType.deterministic) TransitionType type,
    required String inputSymbol,
    required String stackPop,
    required List<String> stackPush,
  }) = _PDATransition;

  factory PDATransition.fromJson(Map<String, dynamic> json) => _$PDATransitionFromJson(json);
}

/// TM-specific transition with tape operations
@freezed
class TMTransition with _$TMTransition {
  const factory TMTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    @Default(Vector2.zero()) Vector2 controlPoint,
    @Default(TransitionType.deterministic) TransitionType type,
    required String tapeRead,
    required String tapeWrite,
    required MoveDirection moveDirection,
  }) = _TMTransition;

  factory TMTransition.fromJson(Map<String, dynamic> json) => _$TMTransitionFromJson(json);
}

/// Types of transitions
enum TransitionType {
  deterministic,
  nondeterministic,
  epsilon,
}

/// Direction of tape head movement in Turing machines
enum MoveDirection {
  left,
  right,
  stay,
}
