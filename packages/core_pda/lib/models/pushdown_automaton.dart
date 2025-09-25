import 'dart:math' as math;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:core_fa/core_fa.dart';

part 'pushdown_automaton.freezed.dart';
part 'pushdown_automaton.g.dart';

/// Available acceptance modes for a PDA simulation
enum PDAAcceptanceMode {
  /// Accept when the automaton consumes the input and lands on an accepting state
  finalState,

  /// Accept when the automaton consumes the input and fully empties its stack
  emptyStack,

  /// Accept when either reaching an accepting state or emptying the stack after
  /// consuming the input
  either,

  /// Accept only when both reaching an accepting state and emptying the stack
  /// after consuming the input
  both,
}

/// Pushdown Automaton (PDA) implementation using freezed
@freezed
class PushdownAutomaton with _$PushdownAutomaton {
  const factory PushdownAutomaton({
    required String id,
    required String name,
    required Set<State> states,
    required Set<PDATransition> transitions,
    required Alphabet inputAlphabet,
    required Alphabet stackAlphabet,
    State? initialState,
    required Set<State> acceptingStates,
    required AutomatonMetadata metadata,
    required math.Rectangle bounds,
    @Default(1.0) double zoomLevel,
    @Default(Vector2.zero()) Vector2 panOffset,
    @Default('Z') String initialStackSymbol,
    @Default(PDAAcceptanceMode.finalState) PDAAcceptanceMode acceptanceMode,
    String? description,
  }) = _PushdownAutomaton;

  factory PushdownAutomaton.fromJson(Map<String, dynamic> json) => _$PushdownAutomatonFromJson(json);
}

/// Extension methods for PushdownAutomaton to provide PDA-specific functionality
extension PushdownAutomatonExtension on PushdownAutomaton {
  /// Gets all epsilon transitions
  Set<PDATransition> get epsilonTransitions {
    return transitions.where((t) => t.isEpsilonTransition).toSet();
  }

  /// Gets all transitions that read input
  Set<PDATransition> get inputTransitions {
    return transitions.where((t) => !t.isLambdaInput).toSet();
  }

  /// Gets all transitions that only operate on the stack
  Set<PDATransition> get stackOnlyTransitions {
    return transitions.where((t) => t.isLambdaInput).toSet();
  }

  /// Gets all transitions from a state that accept a specific input symbol
  Set<PDATransition> getTransitionsFromStateOnInput(State state, String inputSymbol) {
    return transitions
        .where((t) => t.fromState == state && t.acceptsInput(inputSymbol))
        .toSet();
  }

  /// Gets all transitions from a state that can pop a specific stack symbol
  Set<PDATransition> getTransitionsFromStateOnStack(State state, String stackSymbol) {
    return transitions
        .where((t) => t.fromState == state && t.canPop(stackSymbol))
        .toSet();
  }

  /// Gets all transitions from a state that accept input and can pop stack symbol
  Set<PDATransition> getTransitionsFromStateOnInputAndStack(
    State state,
    String inputSymbol,
    String stackSymbol,
  ) {
    return transitions
        .where((t) => 
            t.fromState == state &&
            t.acceptsInput(inputSymbol) &&
            t.canPop(stackSymbol))
        .toSet();
  }

  /// Gets all epsilon transitions from a state
  Set<PDATransition> getEpsilonTransitionsFromState(State state) {
    return transitions
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

  /// Gets PDA transition from state on symbol and stack top
  PDATransition? getPDATransitionFromStateOnSymbolAndStackTop(
    String stateId,
    String symbol,
    String stackTop,
  ) {
    for (final transition in transitions) {
      if (transition.fromState.id == stateId &&
          transition.inputSymbol == symbol &&
          transition.popSymbol == stackTop) {
        return transition;
      }
    }
    return null;
  }

  /// Validates the PDA properties
  List<String> validate() {
    final errors = <String>[];
    
    if (id.isEmpty) {
      errors.add('Automaton ID cannot be empty');
    }
    
    if (name.isEmpty) {
      errors.add('Automaton name cannot be empty');
    }
    
    if (states.isEmpty) {
      errors.add('Automaton must have at least one state');
    }
    
    if (initialState != null && !states.contains(initialState)) {
      errors.add('Initial state must be in the states set');
    }
    
    for (final acceptingState in acceptingStates) {
      if (!states.contains(acceptingState)) {
        errors.add('Accepting state ${acceptingState.id} must be in the states set');
      }
    }
    
    for (final transition in transitions) {
      if (!states.contains(transition.fromState)) {
        errors.add('Transition ${transition.id} references invalid fromState');
      }
      if (!states.contains(transition.toState)) {
        errors.add('Transition ${transition.id} references invalid toState');
      }
    }
    
    if (zoomLevel < 0.5 || zoomLevel > 3.0) {
      errors.add('Zoom level must be between 0.5 and 3.0');
    }
    
    // Validate PDA-specific properties
    if (stackAlphabet.symbols.isEmpty) {
      errors.add('PDA must have a non-empty stack alphabet');
    }
    
    if (initialStackSymbol.isEmpty) {
      errors.add('PDA must have an initial stack symbol');
    }
    
    if (!stackAlphabet.symbols.contains(initialStackSymbol)) {
      errors.add('Initial stack symbol must be in the stack alphabet');
    }
    
    for (final transition in transitions) {
      final transitionErrors = transition.validate();
      errors.addAll(transitionErrors.map((e) => 'Transition ${transition.id}: $e'));
      
      // Validate stack symbols
      if (!transition.isLambdaPop && !stackAlphabet.symbols.contains(transition.popSymbol)) {
        errors.add('Transition ${transition.id} references invalid pop symbol');
      }
      
      if (!transition.isLambdaPush && !stackAlphabet.symbols.contains(transition.pushSymbol)) {
        errors.add('Transition ${transition.id} references invalid push symbol');
      }
    }
    
    return errors;
  }

  /// Checks if the automaton is valid
  bool get isValid => validate().isEmpty;

  /// Gets all transitions from a specific state
  Set<PDATransition> getTransitionsFrom(State state) {
    return transitions.where((t) => t.fromState == state).toSet();
  }

  /// Gets all transitions to a specific state
  Set<PDATransition> getTransitionsTo(State state) {
    return transitions.where((t) => t.toState == state).toSet();
  }

  /// Gets all transitions between two states
  Set<PDATransition> getTransitionsBetween(State from, State to) {
    return transitions.where((t) => t.fromState == from && t.toState == to).toSet();
  }

  /// Gets all states reachable from a given state
  Set<State> getReachableStates(State startState) {
    final reachable = <State>{startState};
    final queue = <State>[startState];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final outgoingTransitions = getTransitionsFrom(current);
      
      for (final transition in outgoingTransitions) {
        if (!reachable.contains(transition.toState)) {
          reachable.add(transition.toState);
          queue.add(transition.toState);
        }
      }
    }
    
    return reachable;
  }

  /// Gets all states that can reach a given state
  Set<State> getStatesReaching(State targetState) {
    final reaching = <State>{targetState};
    final queue = <State>[targetState];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final incomingTransitions = getTransitionsTo(current);
      
      for (final transition in incomingTransitions) {
        if (!reaching.contains(transition.fromState)) {
          reaching.add(transition.fromState);
          queue.add(transition.fromState);
        }
      }
    }
    
    return reaching;
  }

  /// Checks if a state is reachable from the initial state
  bool isStateReachable(State state) {
    if (initialState == null) return false;
    return getReachableStates(initialState!).contains(state);
  }

  /// Gets all unreachable states
  Set<State> get unreachableStates {
    if (initialState == null) return states;
    final reachable = getReachableStates(initialState!);
    return states.where((state) => !reachable.contains(state)).toSet();
  }

  /// Gets all dead states (states that cannot reach any accepting state)
  Set<State> get deadStates {
    final dead = <State>{};
    
    for (final state in states) {
      final reachable = getReachableStates(state);
      final canReachAccepting = reachable.intersection(acceptingStates).isNotEmpty;
      if (!canReachAccepting) {
        dead.add(state);
      }
    }
    
    return dead;
  }

  /// Calculates the center point of all states
  Vector2 get centerPoint {
    if (states.isEmpty) return Vector2.zero();
    
    double sumX = 0;
    double sumY = 0;
    
    for (final state in states) {
      sumX += state.position.x;
      sumY += state.position.y;
    }
    
    return Vector2(sumX / states.length, sumY / states.length);
  }

  /// Calculates the bounding box of all states
  math.Rectangle get statesBoundingBox {
    if (states.isEmpty) return const math.Rectangle(0, 0, 0, 0);
    
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (final state in states) {
      minX = minX < state.position.x ? minX : state.position.x;
      minY = minY < state.position.y ? minY : state.position.y;
      maxX = maxX > state.position.x ? maxX : state.position.x;
      maxY = maxY > state.position.y ? maxY : state.position.y;
    }
    
    return math.Rectangle(minX, minY, maxX - minX, maxY - minY);
  }

  /// Checks if the automaton is empty (no accepting states or no reachable accepting states)
  bool get isEmpty {
    if (acceptingStates.isEmpty) return true;
    if (initialState == null) return true;
    final reachable = getReachableStates(initialState!);
    return reachable.intersection(acceptingStates).isEmpty;
  }

  /// Checks if the automaton accepts all strings (universal language)
  bool get isUniversal {
    if (initialState == null) return false;
    final reachable = getReachableStates(initialState!);
    return reachable.every((state) => acceptingStates.contains(state));
  }

  /// Gets the number of states
  int get stateCount => states.length;

  /// Gets the number of transitions
  int get transitionCount => transitions.length;

  /// Gets the number of accepting states
  int get acceptingStateCount => acceptingStates.length;

  /// Checks if the automaton has an initial state
  bool get hasInitialState => initialState != null;

  /// Checks if the automaton has accepting states
  bool get hasAcceptingStates => acceptingStates.isNotEmpty;

  /// Gets all states that are not accepting
  Set<State> get nonAcceptingStates {
    return states.where((state) => !acceptingStates.contains(state)).toSet();
  }

  /// Gets all states that are not initial
  Set<State> get nonInitialStates {
    return states.where((state) => state != initialState).toSet();
  }
}

/// Factory methods for creating common PDA patterns
class PushdownAutomatonFactory {
  /// Creates an empty PDA
  static PushdownAutomaton empty({
    required String id,
    required String name,
    math.Rectangle? bounds,
    String? description,
  }) {
    final now = DateTime.now();
    return PushdownAutomaton(
      id: id,
      name: name,
      states: {},
      transitions: {},
      inputAlphabet: const Alphabet(symbols: {}),
      stackAlphabet: const Alphabet(symbols: {'Z'}),
      acceptingStates: {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      initialStackSymbol: 'Z',
    );
  }

  /// Creates a simple PDA with one state
  static PushdownAutomaton singleState({
    required String id,
    required String name,
    required String stateId,
    required String stateLabel,
    required Vector2 position,
    bool isInitial = false,
    bool isAccepting = false,
    math.Rectangle? bounds,
    String? description,
  }) {
    final now = DateTime.now();
    final state = State(
      id: stateId,
      label: stateLabel,
      position: position,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
    
    return PushdownAutomaton(
      id: id,
      name: name,
      states: {state},
      transitions: {},
      inputAlphabet: const Alphabet(symbols: {}),
      stackAlphabet: const Alphabet(symbols: {'Z'}),
      initialState: isInitial ? state : null,
      acceptingStates: isAccepting ? {state} : {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      initialStackSymbol: 'Z',
    );
  }

  /// Creates a simple PDA for balanced parentheses
  static PushdownAutomaton balancedParentheses({
    required String id,
    required String name,
    math.Rectangle? bounds,
    String? description,
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
    
    return PushdownAutomaton(
      id: id,
      name: name,
      states: {q0, q1},
      transitions: {t1, t2, t3, t4},
      inputAlphabet: const Alphabet(symbols: {'(', ')'}),
      stackAlphabet: const Alphabet(symbols: {'Z', '('}),
      initialState: q0,
      acceptingStates: {q1},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      initialStackSymbol: 'Z',
    );
  }
}
