import 'grammar.dart';
import 'production.dart';

/// Parse table for grammar parsing algorithms
class ParseTable {
  /// Action table for parsing decisions
  final Map<String, Map<String, ParseAction>> actionTable;
  
  /// Grammar this parse table is for
  final Grammar grammar;
  
  /// Type of parsing (LL or LR)
  final ParseType type;

  const ParseTable({
    required this.actionTable,
    required this.grammar,
    required this.type,
  });

  /// Creates a copy of this parse table with updated properties
  ParseTable copyWith({
    Map<String, Map<String, ParseAction>>? actionTable,
    Grammar? grammar,
    ParseType? type,
  }) {
    return ParseTable(
      actionTable: actionTable ?? this.actionTable,
      grammar: grammar ?? this.grammar,
      type: type ?? this.type,
    );
  }

  /// Converts the parse table to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'actionTable': actionTable.map((state, terminals) => MapEntry(
            state,
            terminals.map((terminal, action) => MapEntry(terminal, action.toJson())),
          )),
      'grammar': grammar.toJson(),
      'type': type.name,
    };
  }

  /// Creates a parse table from a JSON representation
  factory ParseTable.fromJson(Map<String, dynamic> json) {
    return ParseTable(
      actionTable: (json['actionTable'] as Map<String, dynamic>).map(
          (state, terminals) => MapEntry(
                state,
                (terminals as Map<String, dynamic>).map((terminal, action) =>
                    MapEntry(
                      terminal,
                      ParseAction.fromJson(action as Map<String, dynamic>),
                    )),
              )),
      grammar: Grammar.fromJson(json['grammar'] as Map<String, dynamic>),
      type: ParseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ParseType.ll,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseTable &&
        other.actionTable == actionTable &&
        other.grammar == grammar &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(actionTable, grammar, type);
  }

  @override
  String toString() {
    return 'ParseTable(type: $type, states: ${actionTable.length}, grammar: ${grammar.name})';
  }

  /// Gets the number of states in the parse table
  int get stateCount => actionTable.length;

  /// Gets the number of terminals in the parse table
  int get terminalCount => actionTable.values.first.keys.length;

  /// Gets all states in the parse table
  Set<String> get states => actionTable.keys.toSet();

  /// Gets the action for a specific state and terminal
  ParseAction? getAction(String state, String terminal) {
    return actionTable[state]?[terminal];
  }

  /// Checks if the parse table is valid
  bool get isValid {
    return actionTable.isNotEmpty;
  }

  /// Gets the parse table as a formatted string
  String get formattedTable {
    final buffer = StringBuffer();
    
    buffer.writeln('Parse Table ($type):');
    buffer.writeln('Grammar: ${grammar.name}');
    buffer.writeln('States: $stateCount');
    buffer.writeln('Terminals: $terminalCount');
    buffer.writeln();
    
    // Action table
    buffer.writeln('Action Table:');
    for (final state in states) {
      buffer.writeln('State $state:');
      for (final terminal in actionTable[state]!.keys) {
        final action = getAction(state, terminal);
        if (action != null) {
          buffer.writeln('  $terminal: ${action.type.name}');
        }
      }
    }
    
    return buffer.toString();
  }

  /// Creates an empty parse table
  factory ParseTable.empty({
    required Grammar grammar,
    required ParseType type,
  }) {
    return ParseTable(
      actionTable: {},
      grammar: grammar,
      type: type,
    );
  }
}

/// Types of parsing
enum ParseType {
  /// LL parsing
  ll,
}

/// Extension methods for ParseType
extension ParseTypeExtension on ParseType {
  /// Returns a human-readable description of the parse type
  String get description {
    switch (this) {
      case ParseType.ll:
        return 'LL Parsing';
    }
  }

  /// Returns the short name of the parse type
  String get shortName {
    switch (this) {
      case ParseType.ll:
        return 'LL';
    }
  }
}

/// Parse action in a parse table
class ParseAction {
  /// Type of the action
  final ParseActionType type;
  
  /// Production for reduce actions
  final Production? production;
  
  /// Error message for error actions
  final String? errorMessage;

  const ParseAction({
    required this.type,
    this.production,
    this.errorMessage,
  });

  /// Creates a copy of this parse action with updated properties
  ParseAction copyWith({
    ParseActionType? type,
    Production? production,
    String? errorMessage,
  }) {
    return ParseAction(
      type: type ?? this.type,
      production: production ?? this.production,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Converts the parse action to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'production': production?.toJson(),
      'errorMessage': errorMessage,
    };
  }

  /// Creates a parse action from a JSON representation
  factory ParseAction.fromJson(Map<String, dynamic> json) {
    return ParseAction(
      type: ParseActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ParseActionType.error,
      ),
      production: json['production'] != null
          ? Production.fromJson(json['production'] as Map<String, dynamic>)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseAction &&
        other.type == type &&
        other.production == production &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(type, production, errorMessage);
  }

  @override
  String toString() {
    return 'ParseAction(type: $type, production: $production)';
  }

  /// Creates a reduce action
  factory ParseAction.reduce(Production production) {
    return ParseAction(
      type: ParseActionType.reduce,
      production: production,
    );
  }

  /// Creates an accept action
  factory ParseAction.accept() {
    return const ParseAction(
      type: ParseActionType.accept,
    );
  }

  /// Creates an error action
  factory ParseAction.error(String errorMessage) {
    return ParseAction(
      type: ParseActionType.error,
      errorMessage: errorMessage,
    );
  }
}

/// Types of parse actions
enum ParseActionType {
  /// Reduce action
  reduce,
  
  /// Accept action
  accept,
  
  /// Error action
  error,
}

/// Extension methods for ParseActionType
extension ParseActionTypeExtension on ParseActionType {
  /// Returns a human-readable description of the action type
  String get description {
    switch (this) {
      case ParseActionType.reduce:
        return 'Reduce';
      case ParseActionType.accept:
        return 'Accept';
      case ParseActionType.error:
        return 'Error';
    }
  }

  /// Returns the symbol used to represent this action type
  String get symbol {
    switch (this) {
      case ParseActionType.reduce:
        return 'r';
      case ParseActionType.accept:
        return 'acc';
      case ParseActionType.error:
        return 'err';
    }
  }
}
