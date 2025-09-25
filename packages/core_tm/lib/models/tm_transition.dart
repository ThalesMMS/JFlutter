import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:collection/collection.dart';
import 'package:core_fa/core_fa.dart';
import 'tm_tape_action.dart';

part 'tm_transition.freezed.dart';
part 'tm_transition.g.dart';

/// Transition for Turing Machines (TM) using freezed
@freezed
class TMTransition with _$TMTransition {
  const factory TMTransition({
    required String id,
    required State fromState,
    required State toState,
    required String label,
    @Default(null) Vector2? controlPoint,
    @Default(TransitionType.deterministic) TransitionType type,
    @Default([]) List<TMTapeAction> actions,
  }) = _TMTransition;

  factory TMTransition.fromJson(Map<String, dynamic> json) => _$TMTransitionFromJson(json);
}

/// Extension methods for TMTransition to provide TM-specific functionality
extension TMTransitionExtension on TMTransition {
  /// Primary read symbol retained for backwards compatibility
  String get readSymbol => actions.isNotEmpty ? actions.first.readSymbol : '';

  /// Primary write symbol retained for backwards compatibility
  String get writeSymbol => actions.isNotEmpty ? actions.first.writeSymbol : '';

  /// Primary tape direction retained for backwards compatibility
  TapeDirection get direction => actions.isNotEmpty ? actions.first.direction : TapeDirection.stay;

  /// Primary tape index retained for backwards compatibility
  int get tapeNumber => actions.isNotEmpty ? actions.first.tape : 0;

  /// Head position (alias for direction)
  TapeDirection get headPosition => direction;

  /// Whether this transition touches multiple tapes
  bool get isMultiTape => actions.length > 1;

  /// Validates the TM transition properties
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Transition ID cannot be empty');
    }
    
    if (label.isEmpty) {
      errors.add('Transition label cannot be empty');
    }
    
    if (actions.isEmpty) {
      errors.add('TM transition must have at least one tape action');
    }
    
    // Check for duplicate tape numbers
    final tapeNumbers = actions.map((a) => a.tape).toList();
    final uniqueTapeNumbers = tapeNumbers.toSet();
    if (tapeNumbers.length != uniqueTapeNumbers.length) {
      errors.add('TM transition cannot have duplicate tape numbers');
    }
    
    for (final action in actions) {
      final actionErrors = action.validate();
      errors.addAll(actionErrors.map((e) => 'Tape ${action.tape}: $e'));
    }
    
    return errors;
  }

  /// Checks if the transition is valid
  bool get isValid => validate().isEmpty;

  /// Gets the action for a specific tape
  TMTapeAction? getActionForTape(int tapeNumber) {
    try {
      return actions.firstWhere((a) => a.tape == tapeNumber);
    } catch (e) {
      return null;
    }
  }

  /// Gets all tape numbers used by this transition
  List<int> get tapeNumbers => actions.map((a) => a.tape).toList();

  /// Gets the maximum tape number used by this transition
  int get maxTapeNumber => actions.isEmpty ? 0 : actions.map((a) => a.tape).reduce((a, b) => a > b ? a : b);

  /// Gets the transition description
  String get transitionDescription {
    if (actions.isEmpty) return '';
    
    if (actions.length == 1) {
      final action = actions.first;
      return '${action.readSymbol}/${action.writeSymbol},${action.direction.name}';
    }
    
    return actions.map((a) => '${a.readSymbol}/${a.writeSymbol},${a.direction.name}').join(';');
  }
}

/// Factory methods for creating common TM transition patterns
class TMTransitionFactory {
  /// Creates a simple single-tape transition
  static TMTransition singleTape({
    required String id,
    required State fromState,
    required State toState,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$readSymbol/$writeSymbol,${direction.name}',
      controlPoint: controlPoint,
      actions: [
        TMTapeAction(
          tape: 0,
          readSymbol: readSymbol,
          writeSymbol: writeSymbol,
          direction: direction,
        ),
      ],
    );
  }

  /// Creates a multi-tape transition
  static TMTransition multiTape({
    required String id,
    required State fromState,
    required State toState,
    required List<TMTapeAction> actions,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? actions.map((a) => '${a.readSymbol}/${a.writeSymbol},${a.direction.name}').join(';'),
      controlPoint: controlPoint,
      actions: actions,
    );
  }

  /// Creates a transition that only moves the head (no write)
  static TMTransition moveOnly({
    required String id,
    required State fromState,
    required State toState,
    required String readSymbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$readSymbol/$readSymbol,${direction.name}',
      controlPoint: controlPoint,
      actions: [
        TMTapeAction(
          tape: tapeNumber,
          readSymbol: readSymbol,
          writeSymbol: readSymbol, // Same as read (no write)
          direction: direction,
        ),
      ],
    );
  }

  /// Creates a transition that only writes (no move)
  static TMTransition writeOnly({
    required String id,
    required State fromState,
    required State toState,
    required String readSymbol,
    required String writeSymbol,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$readSymbol/$writeSymbol,stay',
      controlPoint: controlPoint,
      actions: [
        TMTapeAction(
          tape: tapeNumber,
          readSymbol: readSymbol,
          writeSymbol: writeSymbol,
          direction: TapeDirection.stay,
        ),
      ],
    );
  }

  /// Creates a transition that reads and writes but doesn't move
  static TMTransition readWrite({
    required String id,
    required State fromState,
    required State toState,
    required String readSymbol,
    required String writeSymbol,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$readSymbol/$writeSymbol,stay',
      controlPoint: controlPoint,
      actions: [
        TMTapeAction(
          tape: tapeNumber,
          readSymbol: readSymbol,
          writeSymbol: writeSymbol,
          direction: TapeDirection.stay,
        ),
      ],
    );
  }
}
