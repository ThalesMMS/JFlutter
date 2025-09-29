import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';
import 'pda_transition.dart';
import 'automaton.dart';

/// Pushdown Automaton (PDA) implementation
class PDA extends Automaton {
  /// Stack alphabet symbols
  final Set<String> stackAlphabet;

  /// Initial stack symbol
  final String initialStackSymbol;

  PDA({
    required super.id,
    required super.name,
    required super.states,
    required super.transitions,
    required super.alphabet,
    super.initialState,
    required super.acceptingStates,
    required super.created,
    required super.modified,
    required super.bounds,
    super.zoomLevel,
    super.panOffset,
    required this.stackAlphabet,
    this.initialStackSymbol = 'Z',
  }) : super(type: AutomatonType.pda);

  /// Creates a copy of this PDA with updated properties
  @override
  PDA copyWith({
    String? id,
    String? name,
    Set<State>? states,
    Set<Transition>? transitions,
    Set<String>? alphabet,
    State? initialState,
    Set<State>? acceptingStates,
    AutomatonType? type,
    DateTime? created,
    DateTime? modified,
    math.Rectangle? bounds,
    double? zoomLevel,
    Vector2? panOffset,
    Set<String>? stackAlphabet,
    String? initialStackSymbol,
  }) {
    return PDA(
      id: id ?? this.id,
      name: name ?? this.name,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
      alphabet: alphabet ?? this.alphabet,
      initialState: initialState ?? this.initialState,
      acceptingStates: acceptingStates ?? this.acceptingStates,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      bounds: bounds ?? this.bounds,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      stackAlphabet: stackAlphabet ?? this.stackAlphabet,
      initialStackSymbol: initialStackSymbol ?? this.initialStackSymbol,
    );
  }

  /// Converts the PDA to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': 'PDA',
      'states': states.map((s) => s.toJson()).toList(),
      'transitions': transitions.map((t) => t.toJson()).toList(),
      'alphabet': alphabet.toList(),
      'initialState': initialState?.toJson(),
      'acceptingStates': acceptingStates.map((s) => s.toJson()).toList(),
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
      'bounds': {
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
      },
      'zoomLevel': zoomLevel,
      'panOffset': {
        'x': panOffset.x,
        'y': panOffset.y,
      },
      'stackAlphabet': stackAlphabet.toList(),
      'initialStackSymbol': initialStackSymbol,
    };
  }

  /// Creates a PDA from a JSON representation
  factory PDA.fromJson(Map<String, dynamic> json) {
    return PDA(
      id: json['id'] as String,
      name: json['name'] as String,
      states: (json['states'] as List)
          .map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      transitions: (json['transitions'] as List)
          .map((t) => PDATransition.fromJson(t as Map<String, dynamic>))
          .toSet(),
      alphabet: Set<String>.from(json['alphabet'] as List),
      initialState: json['initialState'] != null
          ? State.fromJson(json['initialState'] as Map<String, dynamic>)
          : null,
      acceptingStates: (json['acceptingStates'] as List)
          .map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      bounds: math.Rectangle(
        (json['bounds'] as Map<String, dynamic>)['x'] as double,
        (json['bounds'] as Map<String, dynamic>)['y'] as double,
        (json['bounds'] as Map<String, dynamic>)['width'] as double,
        (json['bounds'] as Map<String, dynamic>)['height'] as double,
      ),
      zoomLevel: json['zoomLevel'] as double? ?? 1.0,
      panOffset: Vector2(
        (json['panOffset'] as Map<String, dynamic>)['x'] as double,
        (json['panOffset'] as Map<String, dynamic>)['y'] as double,
      ),
      stackAlphabet: Set<String>.from(json['stackAlphabet'] as List),
      initialStackSymbol: json['initialStackSymbol'] as String? ?? 'Z',
    );
  }

  /// Validates the PDA properties
  @override
  List<String> validate() {
    final errors = super.validate();

    // Validate PDA-specific properties
    if (stackAlphabet.isEmpty) {
      errors.add('PDA must have a non-empty stack alphabet');
    }

    if (initialStackSymbol.isEmpty) {
      errors.add('PDA must have an initial stack symbol');
    }

    if (!stackAlphabet.contains(initialStackSymbol)) {
      errors.add('Initial stack symbol must be in the stack alphabet');
    }

    for (final transition in transitions) {
      if (transition is! PDATransition) {
        errors.add('PDA can only contain PDA transitions');
      } else {
        final pdaTransition = transition as PDATransition;
        final transitionErrors = pdaTransition.validate();
        errors.addAll(
            transitionErrors.map((e) => 'Transition ${pdaTransition.id}: $e'));

        // Validate stack symbols
        if (!pdaTransition.isLambdaPop &&
            !stackAlphabet.contains(pdaTransition.popSymbol)) {
          errors.add(
              'Transition ${pdaTransition.id} references invalid pop symbol');
        }

        if (!pdaTransition.isLambdaPush &&
            !stackAlphabet.contains(pdaTransition.pushSymbol)) {
          errors.add(
              'Transition ${pdaTransition.id} references invalid push symbol');
        }
      }
    }

    return errors;
  }

  /// Gets all PDA transitions
  Set<PDATransition> get pdaTransitions {
    return transitions.whereType<PDATransition>().toSet();
  }

  /// Gets all epsilon transitions
  Set<PDATransition> get epsilonTransitions {
    return pdaTransitions.where((t) => t.isEpsilonTransition).toSet();
  }

  /// Gets all transitions that read input
  Set<PDATransition> get inputTransitions {
    return pdaTransitions.where((t) => !t.isLambdaInput).toSet();
  }

  /// Gets all transitions that only operate on the stack
  Set<PDATransition> get stackOnlyTransitions {
    return pdaTransitions.where((t) => t.isLambdaInput).toSet();
  }

  /// Gets all transitions from a state that accept a specific input symbol
  Set<PDATransition> getTransitionsFromStateOnInput(
      State state, String inputSymbol) {
    return pdaTransitions
        .where((t) => t.fromState == state && t.acceptsInput(inputSymbol))
        .toSet();
  }

  /// Gets all transitions from a state that can pop a specific stack symbol
  Set<PDATransition> getTransitionsFromStateOnStack(
      State state, String stackSymbol) {
    return pdaTransitions
        .where((t) => t.fromState == state && t.canPop(stackSymbol))
        .toSet();
  }

  /// Gets all transitions from a state that accept input and can pop stack symbol
  Set<PDATransition> getTransitionsFromStateOnInputAndStack(
    State state,
    String inputSymbol,
    String stackSymbol,
  ) {
    return pdaTransitions
        .where((t) =>
            t.fromState == state &&
            t.acceptsInput(inputSymbol) &&
            t.canPop(stackSymbol))
        .toSet();
  }

  /// Gets all epsilon transitions from a state
  Set<PDATransition> getEpsilonTransitionsFromState(State state) {
    return pdaTransitions
        .where((t) => t.fromState == state && t.isEpsilonTransition)
        .toSet();
  }

  /// Gets the epsilon closure of a state with a specific stack symbol
  Set<State> getEpsilonClosure(State state, String stackSymbol) {
    final closure = <State>{state};
    final queue = <State>[state];
    final stackSymbols = <String>{stackSymbol};

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final epsilonTransitions = getEpsilonTransitionsFromState(current);

      for (final transition in epsilonTransitions) {
        if (transition.canPop(stackSymbol)) {
          if (!closure.contains(transition.toState)) {
            closure.add(transition.toState);
            queue.add(transition.toState);
          }

          // Add new stack symbols from push operations
          if (!transition.isLambdaPush) {
            stackSymbols.add(transition.pushSymbol);
          }
        }
      }
    }

    return closure;
  }

  /// Creates an empty PDA
  factory PDA.empty({
    required String id,
    required String name,
    Set<String>? stackAlphabet,
    String? initialStackSymbol,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    return PDA(
      id: id,
      name: name,
      states: {},
      transitions: {},
      alphabet: {},
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: stackAlphabet ?? {'Z'},
      initialStackSymbol: initialStackSymbol ?? 'Z',
    );
  }

  /// Creates a simple PDA with one state
  factory PDA.singleState({
    required String id,
    required String name,
    required String stateId,
    required String stateLabel,
    required Vector2 position,
    bool isInitial = false,
    bool isAccepting = false,
    Set<String>? stackAlphabet,
    String? initialStackSymbol,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final state = State(
      id: stateId,
      label: stateLabel,
      position: position,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );

    return PDA(
      id: id,
      name: name,
      states: {state},
      transitions: {},
      alphabet: {},
      initialState: isInitial ? state : null,
      acceptingStates: isAccepting ? {state} : {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: stackAlphabet ?? {'Z'},
      initialStackSymbol: initialStackSymbol ?? 'Z',
    );
  }

  /// Creates a simple PDA for balanced parentheses
  factory PDA.balancedParentheses({
    required String id,
    required String name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(200, 100),
      isInitial: false,
      isAccepting: true,
    );

    final t1 = PDATransition.readAndStack(
      id: 't1',
      fromState: q0,
      toState: q0,
      inputSymbol: '(',
      popSymbol: 'Z',
      pushSymbol: 'Z(',
    );

    final t2 = PDATransition.readAndStack(
      id: 't2',
      fromState: q0,
      toState: q0,
      inputSymbol: '(',
      popSymbol: '(',
      pushSymbol: '((',
    );

    final t3 = PDATransition.readAndStack(
      id: 't3',
      fromState: q0,
      toState: q0,
      inputSymbol: ')',
      popSymbol: '(',
      pushSymbol: '',
    );

    final t4 = PDATransition.readAndStack(
      id: 't4',
      fromState: q0,
      toState: q1,
      inputSymbol: '',
      popSymbol: 'Z',
      pushSymbol: '',
    );

    return PDA(
      id: id,
      name: name,
      states: {q0, q1},
      transitions: {t1, t2, t3, t4},
      alphabet: {'(', ')'},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: {'Z', '('},
      initialStackSymbol: 'Z',
    );
  }

  /// Gets PDA transition from state on symbol and stack top
  PDATransition? getPDATransitionFromStateOnSymbolAndStackTop(
    String stateId,
    String symbol,
    String stackTop,
  ) {
    for (final transition in transitions) {
      if (transition is PDATransition) {
        if (transition.fromState.id == stateId &&
            transition.inputSymbol == symbol &&
            transition.popSymbol == stackTop) {
          return transition;
        }
      }
    }
    return null;
  }
}
