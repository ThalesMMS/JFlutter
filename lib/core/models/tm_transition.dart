import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';

import 'state.dart';
import 'transition.dart';

/// Transition for Turing Machines (TM)
class TMTransition extends Transition {
  TMTransition({
    required String id,
    required State fromState,
    required State toState,
    required String label,
    Vector2? controlPoint,
    TransitionType type = TransitionType.deterministic,
    List<TMTapeAction>? actions,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int tapeNumber = 0,
  })  : actions = List<TMTapeAction>.unmodifiable(
          _normaliseActions(
            actions: actions,
            readSymbol: readSymbol,
            writeSymbol: writeSymbol,
            direction: direction,
            tapeNumber: tapeNumber,
          ),
        ),
        super(
          id: id,
          fromState: fromState,
          toState: toState,
          label: label,
          controlPoint: controlPoint,
          type: type,
        );

  /// Actions executed by this transition, one per tape.
  final List<TMTapeAction> actions;

  /// Primary read symbol retained for backwards compatibility.
  String get readSymbol => actions.first.readSymbol;

  /// Primary write symbol retained for backwards compatibility.
  String get writeSymbol => actions.first.writeSymbol;

  /// Primary tape direction retained for backwards compatibility.
  TapeDirection get direction => actions.first.direction;

  /// Primary tape index retained for backwards compatibility.
  int get tapeNumber => actions.first.tape;

  /// Head position (alias for direction)
  TapeDirection get headPosition => direction;

  /// Whether this transition touches multiple tapes.
  bool get isMultiTape => actions.length > 1;

  /// Creates a copy of this TM transition with updated properties
  @override
  TMTransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    List<TMTapeAction>? actions,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
  }) {
    final nextActions = actions != null
        ? List<TMTapeAction>.unmodifiable(_sortActions(actions))
        : (readSymbol != null ||
                writeSymbol != null ||
                direction != null ||
                tapeNumber != null)
            ? List<TMTapeAction>.unmodifiable(_updatePrimaryAction(
                readSymbol: readSymbol,
                writeSymbol: writeSymbol,
                direction: direction,
                tapeNumber: tapeNumber,
              ))
            : this.actions;

    return TMTransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      type: type ?? this.type,
      actions: nextActions,
    );
  }

  /// Converts the TM transition to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromState': fromState.id,
      'toState': toState.id,
      'label': label,
      'controlPoint': {
        'x': controlPoint.x,
        'y': controlPoint.y,
      },
      'type': type.name,
      'transitionType': 'tm',
      'actions': actions.map((a) => a.toJson()).toList(),
      'readSymbol': readSymbol,
      'writeSymbol': writeSymbol,
      'direction': direction.name,
      'tapeNumber': tapeNumber,
    };
  }

  /// Creates a TM transition from a JSON representation
  factory TMTransition.fromJson(Map<String, dynamic> json) {
    final controlPointJson = json['controlPoint'] as Map<String, dynamic>?;
    final actionsJson = json['actions'] as List?;
    final actions = actionsJson != null && actionsJson.isNotEmpty
        ? actionsJson
            .map((action) =>
                TMTapeAction.fromJson(action as Map<String, dynamic>))
            .toList()
        : _normaliseActions(
            readSymbol: json['readSymbol'] as String?,
            writeSymbol: json['writeSymbol'] as String?,
            direction: json['direction'] != null
                ? TapeDirectionParser.parse(json['direction'] as String)
                : null,
            tapeNumber: json['tapeNumber'] as int? ?? 0,
          );

    return TMTransition(
      id: json['id'] as String,
      fromState: _decodeState(json['fromState']),
      toState: _decodeState(json['toState']),
      label: json['label'] as String,
      controlPoint: controlPointJson != null
          ? Vector2(
              controlPointJson['x'] as double,
              controlPointJson['y'] as double,
            )
          : null,
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.deterministic,
      ),
      actions: actions,
    );
  }

  static State _decodeState(dynamic data) {
    if (data is Map<String, dynamic>) {
      return State.fromJson(data);
    }
    throw ArgumentError('TMTransition expects state objects in JSON');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TMTransition &&
        super == other &&
        const DeepCollectionEquality().equals(other.actions, actions);
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, const DeepCollectionEquality().hash(actions));
  }

  @override
  String toString() {
    return 'TMTransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, actions: $actions)';
  }

  /// Validates the TM transition properties
  @override
  List<String> validate() {
    final errors = super.validate();

    if (actions.isEmpty) {
      errors.add('TM transition must define at least one tape action');
    }

    for (final action in actions) {
      errors.addAll(action.validate());
    }

    return errors;
  }

  /// Checks if this transition can read the given symbol on the primary tape
  bool canRead(String symbol) {
    return readSymbol == symbol;
  }

  /// Returns the action associated with a specific tape.
  TMTapeAction actionForTape(int tape) {
    return actions.firstWhere((action) => action.tape == tape);
  }

  /// Verifies that the current tape reads satisfy the transition.
  bool matchesReadVector(List<String> readVector) {
    for (final action in actions) {
      if (action.tape >= readVector.length) {
        return false;
      }
      if (readVector[action.tape] != action.readSymbol) {
        return false;
      }
    }
    return true;
  }

  /// Creates a transition that reads and writes the same symbol
  factory TMTransition.readWrite({
    required String id,
    required State fromState,
    required State toState,
    required String symbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$symbol→$symbol,${direction.name.toUpperCase()}',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      readSymbol: symbol,
      writeSymbol: symbol,
      direction: direction,
      tapeNumber: tapeNumber,
    );
  }

  /// Creates a transition that changes the symbol on the tape
  factory TMTransition.changeSymbol({
    required String id,
    required State fromState,
    required State toState,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$readSymbol→$writeSymbol,${direction.name.toUpperCase()}',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      readSymbol: readSymbol,
      writeSymbol: writeSymbol,
      direction: direction,
      tapeNumber: tapeNumber,
    );
  }

  /// Creates a transition that only moves the tape head
  factory TMTransition.moveOnly({
    required String id,
    required State fromState,
    required State toState,
    required String symbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$symbol→$symbol,${direction.name.toUpperCase()}',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      readSymbol: symbol,
      writeSymbol: symbol,
      direction: direction,
      tapeNumber: tapeNumber,
    );
  }

  /// Parses a label formatted action specification into tape actions.
  static List<TMTapeAction> parseActions(String label) {
    return TMTapeAction.parseLabel(label);
  }

  List<TMTapeAction> _updatePrimaryAction({
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
  }) {
    final updated = List<TMTapeAction>.from(actions);
    final primary = updated.first;
    updated[0] = primary.copyWith(
      tape: tapeNumber ?? primary.tape,
      readSymbol: readSymbol ?? primary.readSymbol,
      writeSymbol: writeSymbol ?? primary.writeSymbol,
      direction: direction ?? primary.direction,
    );
    return _sortActions(updated);
  }

  static List<TMTapeAction> _normaliseActions({
    List<TMTapeAction>? actions,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
  }) {
    if (actions != null && actions.isNotEmpty) {
      return _sortActions(actions);
    }

    if (readSymbol == null || writeSymbol == null || direction == null) {
      throw ArgumentError(
        'TMTransition requires explicit actions or read/write/direction parameters',
      );
    }

    return _sortActions([
      TMTapeAction(
        tape: tapeNumber ?? 0,
        readSymbol: readSymbol,
        writeSymbol: writeSymbol,
        direction: direction,
      ),
    ]);
  }

  static List<TMTapeAction> _sortActions(List<TMTapeAction> actions) {
    final sorted = List<TMTapeAction>.from(actions);
    sorted.sort((a, b) => a.tape.compareTo(b.tape));
    return sorted;
  }
}

/// Action performed over a specific tape by a TM transition.
class TMTapeAction {
  const TMTapeAction({
    required this.tape,
    required this.readSymbol,
    required this.writeSymbol,
    required this.direction,
  });

  final int tape;
  final String readSymbol;
  final String writeSymbol;
  final TapeDirection direction;

  TMTapeAction copyWith({
    int? tape,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
  }) {
    return TMTapeAction(
      tape: tape ?? this.tape,
      readSymbol: readSymbol ?? this.readSymbol,
      writeSymbol: writeSymbol ?? this.writeSymbol,
      direction: direction ?? this.direction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tape': tape,
      'readSymbol': readSymbol,
      'writeSymbol': writeSymbol,
      'direction': direction.name,
    };
  }

  factory TMTapeAction.fromJson(Map<String, dynamic> json) {
    return TMTapeAction(
      tape: json['tape'] as int? ?? 0,
      readSymbol: json['readSymbol'] as String? ?? '',
      writeSymbol: json['writeSymbol'] as String? ?? '',
      direction: TapeDirectionParser.parse(json['direction'] as String? ?? 'right'),
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (tape < 0) {
      errors.add('Tape number must be non-negative');
    }
    if (readSymbol.isEmpty) {
      errors.add('Read symbol cannot be empty');
    }
    if (writeSymbol.isEmpty) {
      errors.add('Write symbol cannot be empty');
    }
    return errors;
  }

  /// Parses a label with syntax like `0->1,R | 1:1->0,L`.
  static List<TMTapeAction> parseLabel(String label) {
    final parts = label.split('|');
    final actions = <TMTapeAction>[];
    var implicitTape = 0;
    for (final raw in parts) {
      final segment = raw.trim();
      if (segment.isEmpty) continue;
      final parsed = _parseSegment(segment, implicitTape);
      actions.add(parsed.action);
      implicitTape = parsed.nextImplicitTape;
    }
    if (actions.isEmpty) {
      throw FormatException('No actions found in TM transition label: $label');
    }
    return actions;
  }

  static _ParsedAction _parseSegment(String segment, int implicitTape) {
    final tapeSplit = segment.split(':');
    int tapeIndex = implicitTape;
    String payload;
    if (tapeSplit.length == 2 && _isInteger(tapeSplit.first.trim())) {
      tapeIndex = int.parse(tapeSplit.first.trim());
      payload = tapeSplit[1].trim();
    } else {
      payload = segment.trim();
    }

    final arrowSplit = payload.split('->');
    if (arrowSplit.length != 2) {
      throw FormatException('Invalid TM action segment: $segment');
    }
    final read = arrowSplit.first.trim();
    final rest = arrowSplit[1].trim();

    final moveSplit = rest.split(',');
    final write = moveSplit.first.trim();
    final directionToken = moveSplit.length > 1 ? moveSplit[1].trim() : 'S';
    final direction = TapeDirectionParser.parse(directionToken);

    return _ParsedAction(
      action: TMTapeAction(
        tape: tapeIndex,
        readSymbol: read,
        writeSymbol: write,
        direction: direction,
      ),
      nextImplicitTape: tapeIndex + 1,
    );
  }

  static bool _isInteger(String value) {
    return int.tryParse(value) != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TMTapeAction &&
        other.tape == tape &&
        other.readSymbol == readSymbol &&
        other.writeSymbol == writeSymbol &&
        other.direction == direction;
  }

  @override
  int get hashCode => Object.hash(tape, readSymbol, writeSymbol, direction);

  @override
  String toString() =>
      'TMTapeAction(tape: $tape, read: $readSymbol, write: $writeSymbol, dir: ${direction.name})';
}

class _ParsedAction {
  _ParsedAction({required this.action, required this.nextImplicitTape});

  final TMTapeAction action;
  final int nextImplicitTape;
}

/// Directions for the tape head movement.
enum TapeDirection { left, right, stay }

/// Utilities for parsing tape direction tokens.
class TapeDirectionParser {
  static TapeDirection parse(String value) {
    final normalised = value.trim().toLowerCase();
    switch (normalised) {
      case 'l':
      case 'left':
        return TapeDirection.left;
      case 'r':
      case 'right':
        return TapeDirection.right;
      case 's':
      case 'stay':
      case 'n':
      case 'none':
        return TapeDirection.stay;
      default:
        throw FormatException('Unknown tape direction token: $value');
    }
  }
}

extension TapeDirectionLabel on TapeDirection {
  String get shortLabel {
    switch (this) {
      case TapeDirection.left:
        return 'L';
      case TapeDirection.right:
        return 'R';
      case TapeDirection.stay:
        return 'S';
    }
  }
}
