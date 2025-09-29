import 'production.dart';

/// Represents a parsing action in grammar parsing algorithms
class ParseAction {
  /// Type of parsing action
  final ParseActionType type;

  /// State number for the action
  final int state;

  /// Symbol for the action (can be null for some actions)
  final String? symbol;

  /// Production rule for reduce actions
  final Production? production;

  /// Next state for shift actions
  final int? nextState;

  const ParseAction({
    required this.type,
    required this.state,
    this.symbol,
    this.production,
    this.nextState,
  });

  /// Creates a shift action
  factory ParseAction.shift({
    required int state,
    required String symbol,
    required int nextState,
  }) {
    return ParseAction(
      type: ParseActionType.shift,
      state: state,
      symbol: symbol,
      nextState: nextState,
    );
  }

  /// Creates a reduce action
  factory ParseAction.reduce({
    required int state,
    required String symbol,
    required Production production,
  }) {
    return ParseAction(
      type: ParseActionType.reduce,
      state: state,
      symbol: symbol,
      production: production,
    );
  }

  /// Creates an accept action
  factory ParseAction.accept({
    required int state,
    required String symbol,
  }) {
    return ParseAction(
      type: ParseActionType.accept,
      state: state,
      symbol: symbol,
    );
  }

  /// Creates an error action
  factory ParseAction.error({
    required int state,
    required String symbol,
  }) {
    return ParseAction(
      type: ParseActionType.error,
      state: state,
      symbol: symbol,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseAction &&
        other.type == type &&
        other.state == state &&
        other.symbol == symbol &&
        other.production == production &&
        other.nextState == nextState;
  }

  @override
  int get hashCode {
    return Object.hash(type, state, symbol, production, nextState);
  }

  @override
  String toString() {
    switch (type) {
      case ParseActionType.shift:
        return 'Shift($state, $symbol) -> $nextState';
      case ParseActionType.reduce:
        return 'Reduce($state, $symbol) -> $production';
      case ParseActionType.accept:
        return 'Accept($state, $symbol)';
      case ParseActionType.error:
        return 'Error($state, $symbol)';
    }
  }
}

/// Types of parsing actions
enum ParseActionType {
  /// Shift action - move to next state
  shift,

  /// Reduce action - apply production rule
  reduce,

  /// Accept action - parsing successful
  accept,

  /// Error action - parsing failed
  error,
}
