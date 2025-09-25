import 'dart:math' as math;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';
import 'alphabet.dart';
import 'automaton_metadata.dart';

part 'finite_automaton.freezed.dart';
part 'finite_automaton.g.dart';

/// Finite State Automaton (FSA) implementation using freezed
@freezed
class FiniteAutomaton with _$FiniteAutomaton {
  const factory FiniteAutomaton({
    required String id,
    required String name,
    required Set<State> states,
    required Set<Transition> transitions,
    required Alphabet alphabet,
    State? initialState,
    required Set<State> acceptingStates,
    required AutomatonMetadata metadata,
    required math.Rectangle bounds,
    @Default(1.0) double zoomLevel,
    @Default(Vector2.zero()) Vector2 panOffset,
    String? description,
  }) = _FiniteAutomaton;

  factory FiniteAutomaton.fromJson(Map<String, dynamic> json) => _$FiniteAutomatonFromJson(json);
}

/// Extension methods for FiniteAutomaton to provide FSA-specific functionality
extension FiniteAutomatonExtension on FiniteAutomaton {
  /// Gets all FSA transitions (filtered from general transitions)
  Set<Transition> get fsaTransitions {
    return transitions.whereType<Transition>().toSet();
  }

  /// Gets all epsilon transitions
  Set<Transition> get epsilonTransitions {
    return fsaTransitions.where((t) => t.type == TransitionType.epsilon).toSet();
  }

  /// Gets all deterministic transitions
  Set<Transition> get deterministicTransitions {
    return fsaTransitions.where((t) => t.type == TransitionType.deterministic).toSet();
  }

  /// Gets all non-deterministic transitions
  Set<Transition> get nondeterministicTransitions {
    return fsaTransitions.where((t) => t.type == TransitionType.nondeterministic).toSet();
  }

  /// Checks if the FSA is deterministic
  bool get isDeterministic {
    return nondeterministicTransitions.isEmpty;
  }

  /// Checks if the FSA is non-deterministic
  bool get isNondeterministic {
    return !isDeterministic;
  }

  /// Checks if the FSA has epsilon transitions
  bool get hasEpsilonTransitions {
    return epsilonTransitions.isNotEmpty;
  }

  /// Gets all transitions from a state that accept a specific symbol
  Set<Transition> getTransitionsFromStateOnSymbol(State state, String symbol) {
    return fsaTransitions
        .where((t) => t.fromState == state && t.label == symbol)
        .toSet();
  }

  /// Gets all epsilon transitions from a state
  Set<Transition> getEpsilonTransitionsFromState(State state) {
    return fsaTransitions
        .where((t) => t.fromState == state && t.type == TransitionType.epsilon)
        .toSet();
  }

  /// Gets the epsilon closure of a state
  Set<State> getEpsilonClosure(State state) {
    final closure = <State>{state};
    final queue = <State>[state];
    
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      final epsilonTransitions = getEpsilonTransitionsFromState(current);
      
      for (final transition in epsilonTransitions) {
        if (!closure.contains(transition.toState)) {
          closure.add(transition.toState);
          queue.add(transition.toState);
        }
      }
    }
    
    return closure;
  }

  /// Gets the epsilon closure of a set of states
  Set<State> getEpsilonClosureOfSet(Set<State> states) {
    final closure = <State>{};
    
    for (final state in states) {
      closure.addAll(getEpsilonClosure(state));
    }
    
    return closure;
  }

  /// Gets all states reachable from a state on a specific symbol
  Set<State> getStatesReachableOnSymbol(State state, String symbol) {
    final reachable = <State>{};
    final transitions = getTransitionsFromStateOnSymbol(state, symbol);
    
    for (final transition in transitions) {
      reachable.add(transition.toState);
    }
    
    return reachable;
  }

  /// Gets all states reachable from a set of states on a specific symbol
  Set<State> getStatesReachableOnSymbolFromSet(Set<State> states, String symbol) {
    final reachable = <State>{};
    
    for (final state in states) {
      reachable.addAll(getStatesReachableOnSymbol(state, symbol));
    }
    
    return reachable;
  }

  /// Validates the FSA properties
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
    
    // Check for deterministic transitions
    for (final state in states) {
      final outgoingTransitions = getTransitionsFrom(state);
      final inputSymbols = <String>{};
      
      for (final transition in outgoingTransitions) {
        if (inputSymbols.contains(transition.label)) {
          errors.add('Non-deterministic transition from state ${state.id} on symbol ${transition.label}');
        }
        inputSymbols.add(transition.label);
      }
    }
    
    return errors;
  }

  /// Checks if the automaton is valid
  bool get isValid => validate().isEmpty;

  /// Gets all transitions from a specific state
  Set<Transition> getTransitionsFrom(State state) {
    return transitions.where((t) => t.fromState == state).toSet();
  }

  /// Gets all transitions to a specific state
  Set<Transition> getTransitionsTo(State state) {
    return transitions.where((t) => t.toState == state).toSet();
  }

  /// Gets all transitions between two states
  Set<Transition> getTransitionsBetween(State from, State to) {
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

/// Factory methods for creating common FSA patterns
class FiniteAutomatonFactory {
  /// Creates an empty FSA
  static FiniteAutomaton empty({
    required String id,
    required String name,
    math.Rectangle? bounds,
    String? description,
  }) {
    final now = DateTime.now();
    return FiniteAutomaton(
      id: id,
      name: name,
      states: {},
      transitions: {},
      alphabet: const Alphabet(symbols: {}),
      acceptingStates: {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Creates a simple FSA with one state
  static FiniteAutomaton singleState({
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
    
    return FiniteAutomaton(
      id: id,
      name: name,
      states: {state},
      transitions: {},
      alphabet: const Alphabet(symbols: {}),
      initialState: isInitial ? state : null,
      acceptingStates: isAccepting ? {state} : {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Creates a simple FSA with two states and one transition
  static FiniteAutomaton twoState({
    required String id,
    required String name,
    required String fromStateId,
    required String toStateId,
    required String symbol,
    required Vector2 fromPosition,
    required Vector2 toPosition,
    bool toStateAccepting = true,
    math.Rectangle? bounds,
    String? description,
  }) {
    final now = DateTime.now();
    final fromState = State(
      id: fromStateId,
      label: fromStateId,
      position: fromPosition,
      isInitial: true,
      isAccepting: false,
    );
    final toState = State(
      id: toStateId,
      label: toStateId,
      position: toPosition,
      isInitial: false,
      isAccepting: toStateAccepting,
    );
    
    final transition = Transition(
      id: 't1',
      fromState: fromState,
      toState: toState,
      label: symbol,
      type: TransitionType.deterministic,
    );
    
    return FiniteAutomaton(
      id: id,
      name: name,
      states: {fromState, toState},
      transitions: {transition},
      alphabet: Alphabet(symbols: {symbol}),
      initialState: fromState,
      acceptingStates: toStateAccepting ? {toState} : {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }
}
