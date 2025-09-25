import 'dart:math' as math;
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:core_fa/core_fa.dart';
import 'tm_transition.dart';
import 'tm_tape_action.dart';

part 'turing_machine.freezed.dart';
part 'turing_machine.g.dart';

/// Turing Machine (TM) implementation using freezed
@freezed
class TuringMachine with _$TuringMachine {
  const factory TuringMachine({
    required String id,
    required String name,
    required Set<State> states,
    required Set<TMTransition> transitions,
    required Alphabet inputAlphabet,
    required Alphabet tapeAlphabet,
    State? initialState,
    required Set<State> acceptingStates,
    required AutomatonMetadata metadata,
    required math.Rectangle bounds,
    @Default(1.0) double zoomLevel,
    @Default(Vector2.zero()) Vector2 panOffset,
    @Default('B') String blankSymbol,
    @Default(1) int tapeCount,
    String? description,
  }) = _TuringMachine;

  factory TuringMachine.fromJson(Map<String, dynamic> json) => _$TuringMachineFromJson(json);
}

/// Extension methods for TuringMachine to provide TM-specific functionality
extension TuringMachineExtension on TuringMachine {
  /// Gets all TM transitions
  Set<TMTransition> get tmTransitions {
    return transitions.whereType<TMTransition>().toSet();
  }

  /// Gets all single-tape transitions
  Set<TMTransition> get singleTapeTransitions {
    return transitions.where((t) => !t.isMultiTape).toSet();
  }

  /// Gets all multi-tape transitions
  Set<TMTransition> get multiTapeTransitions {
    return transitions.where((t) => t.isMultiTape).toSet();
  }

  /// Gets all transitions from a state that read a specific symbol
  Set<TMTransition> getTransitionsFromStateOnSymbol(State state, String symbol) {
    return transitions
        .where((t) => t.fromState == state && t.readSymbol == symbol)
        .toSet();
  }

  /// Gets all transitions from a state that read a specific symbol on a specific tape
  Set<TMTransition> getTransitionsFromStateOnSymbolAndTape(
    State state,
    String symbol,
    int tapeNumber,
  ) {
    return transitions
        .where((t) => 
            t.fromState == state &&
            t.getActionForTape(tapeNumber)?.readSymbol == symbol)
        .toSet();
  }

  /// Gets the transition from a state on a specific symbol and tape
  TMTransition? getTransitionFromStateOnSymbolAndTape(
    State state,
    String symbol,
    int tapeNumber,
  ) {
    for (final transition in transitions) {
      if (transition.fromState == state) {
        final action = transition.getActionForTape(tapeNumber);
        if (action != null && action.readSymbol == symbol) {
          return transition;
        }
      }
    }
    return null;
  }

  /// Validates the TM properties
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
    
    // Validate TM-specific properties
    if (tapeAlphabet.symbols.isEmpty) {
      errors.add('TM must have a non-empty tape alphabet');
    }
    
    if (blankSymbol.isEmpty) {
      errors.add('TM must have a blank symbol');
    }
    
    if (!tapeAlphabet.symbols.contains(blankSymbol)) {
      errors.add('Blank symbol must be in the tape alphabet');
    }
    
    if (tapeCount < 1) {
      errors.add('TM must have at least one tape');
    }
    
    for (final transition in transitions) {
      final transitionErrors = transition.validate();
      errors.addAll(transitionErrors.map((e) => 'Transition ${transition.id}: $e'));
      
      if (transition.actions.length != tapeCount) {
        errors.add(
          'Transition ${transition.id} must define actions for each of the $tapeCount tapes',
        );
      }
      
      for (final action in transition.actions) {
        if (action.tape >= tapeCount) {
          errors.add(
            'Transition ${transition.id} references invalid tape number ${action.tape}',
          );
        }
        
        if (!tapeAlphabet.symbols.contains(action.readSymbol)) {
          errors.add(
            'Transition ${transition.id} references invalid read symbol ${action.readSymbol}',
          );
        }
        
        if (!tapeAlphabet.symbols.contains(action.writeSymbol)) {
          errors.add(
            'Transition ${transition.id} references invalid write symbol ${action.writeSymbol}',
          );
        }
      }
    }
    
    return errors;
  }

  /// Checks if the automaton is valid
  bool get isValid => validate().isEmpty;

  /// Gets all transitions from a specific state
  Set<TMTransition> getTransitionsFrom(State state) {
    return transitions.where((t) => t.fromState == state).toSet();
  }

  /// Gets all transitions to a specific state
  Set<TMTransition> getTransitionsTo(State state) {
    return transitions.where((t) => t.toState == state).toSet();
  }

  /// Gets all transitions between two states
  Set<TMTransition> getTransitionsBetween(State from, State to) {
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

/// Factory methods for creating common TM patterns
class TuringMachineFactory {
  /// Creates an empty TM
  static TuringMachine empty({
    required String id,
    required String name,
    math.Rectangle? bounds,
    String? description,
  }) {
    final now = DateTime.now();
    return TuringMachine(
      id: id,
      name: name,
      states: {},
      transitions: {},
      inputAlphabet: const Alphabet(symbols: {}),
      tapeAlphabet: const Alphabet(symbols: {'B'}),
      acceptingStates: {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      blankSymbol: 'B',
      tapeCount: 1,
    );
  }

  /// Creates a simple TM with one state
  static TuringMachine singleState({
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
    
    return TuringMachine(
      id: id,
      name: name,
      states: {state},
      transitions: {},
      inputAlphabet: const Alphabet(symbols: {}),
      tapeAlphabet: const Alphabet(symbols: {'B'}),
      initialState: isInitial ? state : null,
      acceptingStates: isAccepting ? {state} : {},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      blankSymbol: 'B',
      tapeCount: 1,
    );
  }

  /// Creates a simple TM that copies input
  static TuringMachine copyInput({
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
      isAccepting: false,
    );
    final q2 = State(
      id: 'q2',
      label: 'q2',
      position: Vector2(300, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    final t1 = TMTransitionFactory.singleTape(
      id: 't1',
      fromState: q0,
      toState: q0,
      readSymbol: '0',
      writeSymbol: '0',
      direction: TapeDirection.right,
    );
    
    final t2 = TMTransitionFactory.singleTape(
      id: 't2',
      fromState: q0,
      toState: q0,
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.right,
    );
    
    final t3 = TMTransitionFactory.singleTape(
      id: 't3',
      fromState: q0,
      toState: q1,
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.left,
    );
    
    final t4 = TMTransitionFactory.singleTape(
      id: 't4',
      fromState: q1,
      toState: q1,
      readSymbol: '0',
      writeSymbol: '0',
      direction: TapeDirection.left,
    );
    
    final t5 = TMTransitionFactory.singleTape(
      id: 't5',
      fromState: q1,
      toState: q1,
      readSymbol: '1',
      writeSymbol: '1',
      direction: TapeDirection.left,
    );
    
    final t6 = TMTransitionFactory.singleTape(
      id: 't6',
      fromState: q1,
      toState: q2,
      readSymbol: 'B',
      writeSymbol: 'B',
      direction: TapeDirection.right,
    );
    
    return TuringMachine(
      id: id,
      name: name,
      states: {q0, q1, q2},
      transitions: {t1, t2, t3, t4, t5, t6},
      inputAlphabet: const Alphabet(symbols: {'0', '1'}),
      tapeAlphabet: const Alphabet(symbols: {'0', '1', 'B'}),
      initialState: q0,
      acceptingStates: {q2},
      metadata: AutomatonMetadata(
        createdAt: now,
        createdBy: 'system',
        description: description,
      ),
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      blankSymbol: 'B',
      tapeCount: 1,
    );
  }
}
