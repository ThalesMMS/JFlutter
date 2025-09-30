import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';

/// Transition for Pushdown Automata (PDA)
class PDATransition extends Transition {
  /// Input symbol that triggers this transition
  final String inputSymbol;

  /// Symbol to pop from the stack
  final String popSymbol;

  /// Symbol to push onto the stack
  final String pushSymbol;

  /// Whether the input is lambda (epsilon)
  final bool isLambdaInput;

  /// Whether the pop operation is lambda (epsilon)
  final bool isLambdaPop;

  /// Whether the push operation is lambda (epsilon)
  final bool isLambdaPush;

  /// Read symbol (alias for inputSymbol)
  String get readSymbol => inputSymbol;

  /// Stack pop symbol (alias for popSymbol)
  String get stackPop => popSymbol;

  /// Stack push symbol (alias for pushSymbol)
  String get stackPush => pushSymbol;

  PDATransition({
    required super.id,
    required super.fromState,
    required super.toState,
    required super.label,
    super.controlPoint,
    super.type,
    required this.inputSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    this.isLambdaInput = false,
    this.isLambdaPop = false,
    this.isLambdaPush = false,
  });

  /// Creates a copy of this PDA transition with updated properties
  @override
  PDATransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    String? inputSymbol,
    String? popSymbol,
    String? pushSymbol,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
  }) {
    return PDATransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      type: type ?? this.type,
      inputSymbol: inputSymbol ?? this.inputSymbol,
      popSymbol: popSymbol ?? this.popSymbol,
      pushSymbol: pushSymbol ?? this.pushSymbol,
      isLambdaInput: isLambdaInput ?? this.isLambdaInput,
      isLambdaPop: isLambdaPop ?? this.isLambdaPop,
      isLambdaPush: isLambdaPush ?? this.isLambdaPush,
    );
  }

  /// Converts the PDA transition to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromState': fromState.id,
      'toState': toState.id,
      'label': label,
      'controlPoint': {'x': controlPoint.x, 'y': controlPoint.y},
      'type': type.name,
      'transitionType': 'pda',
      'inputSymbol': inputSymbol,
      'popSymbol': popSymbol,
      'pushSymbol': pushSymbol,
      'isLambdaInput': isLambdaInput,
      'isLambdaPop': isLambdaPop,
      'isLambdaPush': isLambdaPush,
    };
  }

  /// Creates a PDA transition from a JSON representation
  factory PDATransition.fromJson(Map<String, dynamic> json) {
    final controlPointData =
        (json['controlPoint'] as Map?)?.cast<String, dynamic>();
    final controlPointX = (controlPointData?['x'] as num?)?.toDouble() ?? 0.0;
    final controlPointY = (controlPointData?['y'] as num?)?.toDouble() ?? 0.0;

    return PDATransition(
      id: json['id'] as String,
      fromState: State.fromJson(json['fromState'] as Map<String, dynamic>),
      toState: State.fromJson(json['toState'] as Map<String, dynamic>),
      label: json['label'] as String,
      controlPoint: Vector2(controlPointX, controlPointY),
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.deterministic,
      ),
      inputSymbol: json['inputSymbol'] as String,
      popSymbol: json['popSymbol'] as String,
      pushSymbol: json['pushSymbol'] as String,
      isLambdaInput: json['isLambdaInput'] as bool? ?? false,
      isLambdaPop: json['isLambdaPop'] as bool? ?? false,
      isLambdaPush: json['isLambdaPush'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PDATransition &&
        super == other &&
        other.inputSymbol == inputSymbol &&
        other.popSymbol == popSymbol &&
        other.pushSymbol == pushSymbol &&
        other.isLambdaInput == isLambdaInput &&
        other.isLambdaPop == isLambdaPop &&
        other.isLambdaPush == isLambdaPush;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      inputSymbol,
      popSymbol,
      pushSymbol,
      isLambdaInput,
      isLambdaPop,
      isLambdaPush,
    );
  }

  @override
  String toString() {
    return 'PDATransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'input: $inputSymbol, pop: $popSymbol, push: $pushSymbol)';
  }

  /// Validates the PDA transition properties
  @override
  List<String> validate() {
    final errors = super.validate();

    if (inputSymbol.isEmpty && !isLambdaInput) {
      errors.add('PDA transition must have input symbol or be lambda input');
    }

    if (popSymbol.isEmpty && !isLambdaPop) {
      errors.add('PDA transition must have pop symbol or be lambda pop');
    }

    if (pushSymbol.isEmpty && !isLambdaPush) {
      errors.add('PDA transition must have push symbol or be lambda push');
    }

    if (isLambdaInput && inputSymbol.isNotEmpty) {
      errors.add(
        'PDA transition cannot have both input symbol and lambda input',
      );
    }

    if (isLambdaPop && popSymbol.isNotEmpty) {
      errors.add('PDA transition cannot have both pop symbol and lambda pop');
    }

    if (isLambdaPush && pushSymbol.isNotEmpty) {
      errors.add('PDA transition cannot have both push symbol and lambda push');
    }

    return errors;
  }

  /// Checks if this transition accepts the given input symbol
  bool acceptsInput(String symbol) {
    return isLambdaInput || inputSymbol == symbol;
  }

  /// Checks if this transition can pop the given symbol from the stack
  bool canPop(String symbol) {
    return isLambdaPop || popSymbol == symbol;
  }

  /// Gets the symbol to push onto the stack (empty string for lambda push)
  String get symbolToPush {
    return isLambdaPush ? '' : pushSymbol;
  }

  /// Gets the symbol to pop from the stack (empty string for lambda pop)
  String get symbolToPop {
    return isLambdaPop ? '' : popSymbol;
  }

  /// Gets the input symbol (empty string for lambda input)
  String get effectiveInputSymbol {
    return isLambdaInput ? '' : inputSymbol;
  }

  /// Checks if this is an epsilon transition (all operations are lambda)
  bool get isEpsilonTransition {
    return isLambdaInput && isLambdaPop && isLambdaPush;
  }

  /// Creates an epsilon transition
  factory PDATransition.epsilon({
    required String id,
    required State fromState,
    required State toState,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'ε,ε→ε',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.epsilon,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      isLambdaInput: true,
      isLambdaPop: true,
      isLambdaPush: true,
    );
  }

  /// Creates a transition that reads input and pops/pushes stack symbols
  factory PDATransition.readAndStack({
    required String id,
    required State fromState,
    required State toState,
    required String inputSymbol,
    required String popSymbol,
    required String pushSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$inputSymbol,$popSymbol→$pushSymbol',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: inputSymbol,
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
    );
  }

  /// Creates a transition that only reads input (no stack operations)
  factory PDATransition.readOnly({
    required String id,
    required State fromState,
    required State toState,
    required String inputSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$inputSymbol,ε→ε',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: inputSymbol,
      popSymbol: '',
      pushSymbol: '',
      isLambdaPop: true,
      isLambdaPush: true,
    );
  }

  /// Creates a transition that only operates on the stack (no input)
  factory PDATransition.stackOnly({
    required String id,
    required State fromState,
    required State toState,
    required String popSymbol,
    required String pushSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'ε,$popSymbol→$pushSymbol',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: '',
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      isLambdaInput: true,
    );
  }
}
