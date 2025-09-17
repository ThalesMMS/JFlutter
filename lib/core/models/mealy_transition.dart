import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';

/// Transition for Mealy machines
class MealyTransition extends Transition {
  /// Input symbol that triggers this transition
  final String inputSymbol;
  
  /// Output symbol produced by this transition
  final String outputSymbol;

  MealyTransition({
    required super.id,
    required super.fromState,
    required super.toState,
    required super.label,
    super.controlPoint = Vector2.zero(),
    super.type,
    required this.inputSymbol,
    required this.outputSymbol,
  });

  /// Creates a copy of this Mealy transition with updated properties
  @override
  MealyTransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    String? inputSymbol,
    String? outputSymbol,
  }) {
    return MealyTransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      type: type ?? this.type,
      inputSymbol: inputSymbol ?? this.inputSymbol,
      outputSymbol: outputSymbol ?? this.outputSymbol,
    );
  }

  /// Converts the Mealy transition to a JSON representation
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
      'transitionType': 'mealy',
      'inputSymbol': inputSymbol,
      'outputSymbol': outputSymbol,
    };
  }

  /// Creates a Mealy transition from a JSON representation
  factory MealyTransition.fromJson(Map<String, dynamic> json) {
    return MealyTransition(
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
      inputSymbol: json['inputSymbol'] as String,
      outputSymbol: json['outputSymbol'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MealyTransition &&
        super == other &&
        other.inputSymbol == inputSymbol &&
        other.outputSymbol == outputSymbol;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      inputSymbol,
      outputSymbol,
    );
  }

  @override
  String toString() {
    return 'MealyTransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'input: $inputSymbol, output: $outputSymbol)';
  }

  /// Validates the Mealy transition properties
  @override
  List<String> validate() {
    final errors = super.validate();
    
    if (inputSymbol.isEmpty) {
      errors.add('Mealy transition must have input symbol');
    }
    
    if (outputSymbol.isEmpty) {
      errors.add('Mealy transition must have output symbol');
    }
    
    return errors;
  }

  /// Checks if this transition accepts the given input symbol
  bool acceptsInput(String symbol) {
    return inputSymbol == symbol;
  }

  /// Gets the output symbol produced by this transition
  String get producedOutput => outputSymbol;

  /// Creates a Mealy transition with input/output pair
  factory MealyTransition.inputOutput({
    required String id,
    required State fromState,
    required State toState,
    required String inputSymbol,
    required String outputSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return MealyTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$inputSymbol/$outputSymbol',
          controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: inputSymbol,
      outputSymbol: outputSymbol,
    );
  }
}
