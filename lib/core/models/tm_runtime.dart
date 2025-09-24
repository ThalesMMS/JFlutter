import 'dart:collection';

import 'state.dart';
import 'tm_transition.dart';

/// Immutable representation of a TM tape with unbounded cells in both
/// directions.
class TMTape {
  TMTape({
    required String blankSymbol,
    Map<int, String>? cells,
    int headPosition = 0,
  })  : blankSymbol = blankSymbol,
        _cells = UnmodifiableMapView(Map<int, String>.from(cells ?? const {})),
        headPosition = headPosition;

  /// Creates a tape initialised with an input string positioned at the head.
  factory TMTape.fromInput({
    required String input,
    required String blankSymbol,
  }) {
    final cells = <int, String>{};
    for (var i = 0; i < input.length; i++) {
      cells[i] = input[i];
    }
    if (cells.isEmpty) {
      cells[0] = blankSymbol;
    }
    return TMTape(blankSymbol: blankSymbol, cells: cells, headPosition: 0);
  }

  /// Blank symbol used by the tape when reading uninitialised cells.
  final String blankSymbol;

  /// Head position relative to the origin cell.
  final int headPosition;

  final Map<int, String> _cells;

  /// Returns the symbol currently under the head.
  String read() => _cells[headPosition] ?? blankSymbol;

  /// Produces a new tape reflecting a write on the current head position.
  TMTape write(String symbol) {
    final next = Map<int, String>.from(_cells);
    if (symbol == blankSymbol) {
      next.remove(headPosition);
    } else {
      next[headPosition] = symbol;
    }
    return TMTape(
      blankSymbol: blankSymbol,
      cells: next,
      headPosition: headPosition,
    );
  }

  /// Produces a new tape after moving the head.
  TMTape move(TapeDirection direction) {
    if (direction == TapeDirection.stay) {
      return this;
    }
    final offset = direction == TapeDirection.right ? 1 : -1;
    return TMTape(
      blankSymbol: blankSymbol,
      cells: _cells,
      headPosition: headPosition + offset,
    );
  }

  /// Generates a human friendly snapshot around the head position.
  String render({int radius = 8}) {
    final buffer = StringBuffer();
    final minIndex = headPosition - radius;
    final maxIndex = headPosition + radius;
    for (var i = minIndex; i <= maxIndex; i++) {
      final symbol = _cells[i] ?? blankSymbol;
      if (i == headPosition) {
        buffer.write('[${symbol.isEmpty ? blankSymbol : symbol}]');
      } else {
        buffer.write(symbol.isEmpty ? blankSymbol : symbol);
      }
    }
    return buffer.toString();
  }

  /// Returns a compact signature used to detect repeated configurations.
  String signature({int radius = 4}) {
    final buffer = StringBuffer()
      ..write(headPosition)
      ..write(':');
    final minIndex = headPosition - radius;
    final maxIndex = headPosition + radius;
    for (var i = minIndex; i <= maxIndex; i++) {
      buffer.write(_cells[i] ?? blankSymbol);
      buffer.write('|');
    }
    return buffer.toString();
  }

  /// Access to the raw populated cells (mostly for diagnostics).
  Map<int, String> get populatedCells => _cells;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TMTape &&
        other.blankSymbol == blankSymbol &&
        other.headPosition == headPosition &&
        _mapsEqual(other._cells, _cells);
  }

  @override
  int get hashCode => Object.hash(blankSymbol, headPosition, _mapHash(_cells));

  @override
  String toString() => 'TMTape(head: $headPosition, cells: $_cells)';

  static bool _mapsEqual(Map<int, String> a, Map<int, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static int _mapHash(Map<int, String> map) {
    var result = 0;
    for (final entry in map.entries) {
      result = Object.hash(result, entry.key, entry.value);
    }
    return result;
  }
}

/// Immutable snapshot of a TM configuration.
class TMConfigurationSnapshot {
  TMConfigurationSnapshot({
    required this.state,
    required this.tapes,
    required this.step,
    this.transition,
  });

  final State state;
  final List<TMTape> tapes;
  final int step;
  final TMTransition? transition;

  /// Generates a summary of the transition that led to this configuration.
  String describeTransition() {
    if (transition == null) {
      return 'start';
    }
    final actions = transition!.actions
        .map((action) =>
            't${action.tape}:${action.readSymbol}/${action.writeSymbol},${action.direction.name[0].toUpperCase()}')
        .join(' | ');
    return '${transition!.fromState.id}→${transition!.toState.id} [$actions]';
  }

  List<String> renderTapes({int radius = 8}) =>
      tapes.map((tape) => tape.render(radius: radius)).toList(growable: false);

  String signature({int radius = 4}) {
    final buffer = StringBuffer(state.id);
    for (final tape in tapes) {
      buffer
        ..write('|')
        ..write(tape.signature(radius: radius));
    }
    return buffer.toString();
  }
}

/// Enumerates the reasons that may halt a branch during simulation.
enum TMHaltReason { accepted, rejected, timeout, exceededLimit }

/// Full execution trace for a single branch explored during simulation.
class TMBranchTrace {
  TMBranchTrace({
    required this.configurations,
    required this.reason,
    required this.accepted,
  });

  final List<TMConfigurationSnapshot> configurations;
  final TMHaltReason reason;
  final bool accepted;

  TMConfigurationSnapshot get terminalConfiguration => configurations.last;

  int get steps => configurations.length - 1;
}

/// Details about deterministic conflicts detected for a TM.
class TMDeterminismConflict {
  TMDeterminismConflict({
    required this.state,
    required this.readVector,
    required this.transitions,
  });

  final State state;
  final List<String> readVector;
  final List<TMTransition> transitions;
}
