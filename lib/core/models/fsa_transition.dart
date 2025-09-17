import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';

/// Transition for Finite State Automata (FSA)
class FSATransition extends Transition {
  /// Set of input symbols that trigger this transition
  final Set<String> inputSymbols;
  
  /// Lambda symbol for epsilon transitions (null if not an epsilon transition)
  final String? lambdaSymbol;
  
  /// Primary symbol for this transition (first symbol from inputSymbols or lambdaSymbol)
  String get symbol {
    if (lambdaSymbol != null) return lambdaSymbol!;
    return inputSymbols.isNotEmpty ? inputSymbols.first : '';
  }

  FSATransition({
    required super.id,
    required super.fromState,
    required super.toState,
    required super.label,
    super.controlPoint = Vector2.zero(),
    super.type,
    required this.inputSymbols,
    this.lambdaSymbol,
    String? symbol,
  });

  /// Creates a copy of this FSA transition with updated properties
  @override
  FSATransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    Set<String>? inputSymbols,
    String? lambdaSymbol,
  }) {
    return FSATransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      type: type ?? this.type,
      inputSymbols: inputSymbols ?? this.inputSymbols,
      lambdaSymbol: lambdaSymbol ?? this.lambdaSymbol,
    );
  }

  /// Converts the FSA transition to a JSON representation
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
      'transitionType': 'fsa',
      'inputSymbols': inputSymbols.toList(),
      'lambdaSymbol': lambdaSymbol,
    };
  }

  /// Creates an FSA transition from a JSON representation
  factory FSATransition.fromJson(Map<String, dynamic> json) {
    return FSATransition(
      id: json['id'] as String,
      fromState: State.fromJson(json['fromState'] as Map<String, dynamic>),
      toState: State.fromJson(json['toState'] as Map<String, dynamic>),
      label: json['label'] as String,
      controlPoint: Vector2(
        (json['controlPoint'] as Map<String, dynamic>)['x'] as double,
        (json['controlPoint'] as Map<String, dynamic>)['y'] as double,
      ),
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.deterministic,
      ),
      inputSymbols: Set<String>.from(json['inputSymbols'] as List),
      lambdaSymbol: json['lambdaSymbol'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FSATransition &&
        super == other &&
        other.inputSymbols == inputSymbols &&
        other.lambdaSymbol == lambdaSymbol;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      inputSymbols,
      lambdaSymbol,
    );
  }

  @override
  String toString() {
    return 'FSATransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'inputSymbols: $inputSymbols, lambdaSymbol: $lambdaSymbol)';
  }

  /// Validates the FSA transition properties
  @override
  List<String> validate() {
    final errors = super.validate();
    
    if (inputSymbols.isEmpty && lambdaSymbol == null) {
      errors.add('FSA transition must have input symbols or be an epsilon transition');
    }
    
    if (lambdaSymbol != null && inputSymbols.isNotEmpty) {
      errors.add('FSA transition cannot have both input symbols and lambda symbol');
    }
    
    if (lambdaSymbol != null && lambdaSymbol!.isEmpty) {
      errors.add('Lambda symbol cannot be empty');
    }
    
    for (final symbol in inputSymbols) {
      if (symbol.isEmpty) {
        errors.add('Input symbol cannot be empty');
      }
    }
    
    return errors;
  }

  /// Checks if this is an epsilon transition
  bool get isEpsilonTransition => lambdaSymbol != null;

  /// Checks if this transition accepts the given symbol
  bool acceptsSymbol(String symbol) {
    if (isEpsilonTransition) {
      return symbol == lambdaSymbol;
    }
    return inputSymbols.contains(symbol);
  }

  /// Checks if this transition accepts any of the given symbols
  bool acceptsAnySymbol(Set<String> symbols) {
    if (isEpsilonTransition) {
      return symbols.contains(lambdaSymbol);
    }
    return inputSymbols.intersection(symbols).isNotEmpty;
  }

  /// Gets all symbols that this transition accepts
  Set<String> get acceptedSymbols {
    if (isEpsilonTransition) {
      return {lambdaSymbol!};
    }
    return inputSymbols;
  }

  /// Checks if this transition is deterministic
  bool get isDeterministic {
    return inputSymbols.length == 1 && lambdaSymbol == null;
  }

  /// Checks if this transition is non-deterministic
  bool get isNondeterministic {
    return inputSymbols.length > 1 || isEpsilonTransition;
  }

  /// Creates an epsilon transition
  factory FSATransition.epsilon({
    required String id,
    required State fromState,
    required State toState,
    String? label,
    Vector2? controlPoint,
  }) {
    return FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'ε',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.epsilon,
      inputSymbols: const {},
      lambdaSymbol: 'ε',
    );
  }

  /// Creates a deterministic transition
  factory FSATransition.deterministic({
    required String id,
    required State fromState,
    required State toState,
    required String symbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? symbol,
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbols: {symbol},
      lambdaSymbol: null,
    );
  }

  /// Creates a non-deterministic transition
  factory FSATransition.nondeterministic({
    required String id,
    required State fromState,
    required State toState,
    required Set<String> symbols,
    String? label,
    Vector2? controlPoint,
  }) {
    return FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? symbols.join(','),
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.nondeterministic,
      inputSymbols: symbols,
      lambdaSymbol: null,
    );
  }
}
