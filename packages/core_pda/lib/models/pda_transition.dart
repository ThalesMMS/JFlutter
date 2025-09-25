import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:core_fa/core_fa.dart';

part 'pda_transition.freezed.dart';
part 'pda_transition.g.dart';

/// Transition for Pushdown Automata (PDA) using freezed
@freezed
class PDATransition with _$PDATransition {
  const factory PDATransition({
    required String id,
    required State fromState,
    required State toState,
    required String label,
    @Default(null) Vector2? controlPoint,
    @Default(TransitionType.deterministic) TransitionType type,
    required String inputSymbol,
    required String popSymbol,
    required String pushSymbol,
    @Default(false) bool isLambdaInput,
    @Default(false) bool isLambdaPop,
    @Default(false) bool isLambdaPush,
  }) = _PDATransition;

  factory PDATransition.fromJson(Map<String, dynamic> json) => _$PDATransitionFromJson(json);
}

/// Extension methods for PDATransition to provide PDA-specific functionality
extension PDATransitionExtension on PDATransition {
  /// Read symbol (alias for inputSymbol)
  String get readSymbol => inputSymbol;
  
  /// Stack pop symbol (alias for popSymbol)
  String get stackPop => popSymbol;
  
  /// Stack push symbol (alias for pushSymbol)
  String get stackPush => pushSymbol;

  /// Checks if this is an epsilon transition
  bool get isEpsilonTransition => isLambdaInput && isLambdaPop;

  /// Checks if this transition accepts the given input symbol
  bool acceptsInput(String symbol) {
    if (isLambdaInput) {
      return symbol == inputSymbol;
    }
    return inputSymbol == symbol;
  }

  /// Checks if this transition can pop the given stack symbol
  bool canPop(String stackSymbol) {
    if (isLambdaPop) {
      return stackSymbol == popSymbol;
    }
    return popSymbol == stackSymbol;
  }

  /// Checks if this transition can push the given symbol
  bool canPush(String symbol) {
    if (isLambdaPush) {
      return symbol == pushSymbol;
    }
    return pushSymbol == symbol;
  }

  /// Gets the stack operation description
  String get stackOperationDescription {
    if (isLambdaPop && isLambdaPush) {
      return 'λ/λ';
    } else if (isLambdaPop) {
      return 'λ/$pushSymbol';
    } else if (isLambdaPush) {
      return '$popSymbol/λ';
    } else {
      return '$popSymbol/$pushSymbol';
    }
  }

  /// Gets the complete transition description
  String get transitionDescription {
    final input = isLambdaInput ? 'λ' : inputSymbol;
    return '$input,${stackOperationDescription}';
  }

  /// Validates the PDA transition properties
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Transition ID cannot be empty');
    }
    
    if (label.isEmpty) {
      errors.add('Transition label cannot be empty');
    }
    
    if (inputSymbol.isEmpty && !isLambdaInput) {
      errors.add('Input symbol cannot be empty unless it is a lambda input');
    }
    
    if (popSymbol.isEmpty && !isLambdaPop) {
      errors.add('Pop symbol cannot be empty unless it is a lambda pop');
    }
    
    if (pushSymbol.isEmpty && !isLambdaPush) {
      errors.add('Push symbol cannot be empty unless it is a lambda push');
    }
    
    if (isLambdaInput && inputSymbol.isNotEmpty) {
      errors.add('Lambda input should have empty input symbol');
    }
    
    if (isLambdaPop && popSymbol.isNotEmpty) {
      errors.add('Lambda pop should have empty pop symbol');
    }
    
    if (isLambdaPush && pushSymbol.isNotEmpty) {
      errors.add('Lambda push should have empty push symbol');
    }
    
    return errors;
  }

  /// Checks if the transition is valid
  bool get isValid => validate().isEmpty;
}

/// Factory methods for creating common PDA transition patterns
class PDATransitionFactory {
  /// Creates a transition that reads input and operates on the stack
  static PDATransition readAndStack({
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
      label: label ?? '$inputSymbol,$popSymbol/$pushSymbol',
      controlPoint: controlPoint,
      inputSymbol: inputSymbol,
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      isLambdaInput: false,
      isLambdaPop: false,
      isLambdaPush: false,
    );
  }

  /// Creates an epsilon transition (no input, stack operations only)
  static PDATransition epsilon({
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
      label: label ?? 'λ,$popSymbol/$pushSymbol',
      controlPoint: controlPoint,
      inputSymbol: '',
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      isLambdaInput: true,
      isLambdaPop: false,
      isLambdaPush: false,
    );
  }

  /// Creates a transition that only reads input (no stack operations)
  static PDATransition readOnly({
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
      label: label ?? inputSymbol,
      controlPoint: controlPoint,
      inputSymbol: inputSymbol,
      popSymbol: '',
      pushSymbol: '',
      isLambdaInput: false,
      isLambdaPop: true,
      isLambdaPush: true,
    );
  }

  /// Creates a transition that only operates on the stack (no input)
  static PDATransition stackOnly({
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
      label: label ?? 'λ,$popSymbol/$pushSymbol',
      controlPoint: controlPoint,
      inputSymbol: '',
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      isLambdaInput: true,
      isLambdaPop: false,
      isLambdaPush: false,
    );
  }

  /// Creates a transition that pops from stack without reading input
  static PDATransition popOnly({
    required String id,
    required State fromState,
    required State toState,
    required String popSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'λ,$popSymbol/λ',
      controlPoint: controlPoint,
      inputSymbol: '',
      popSymbol: popSymbol,
      pushSymbol: '',
      isLambdaInput: true,
      isLambdaPop: false,
      isLambdaPush: true,
    );
  }

  /// Creates a transition that pushes to stack without reading input
  static PDATransition pushOnly({
    required String id,
    required State fromState,
    required State toState,
    required String pushSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'λ,λ/$pushSymbol',
      controlPoint: controlPoint,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: pushSymbol,
      isLambdaInput: true,
      isLambdaPop: true,
      isLambdaPush: false,
    );
  }
}
