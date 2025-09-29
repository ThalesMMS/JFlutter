import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';
import 'fsa_transition.dart';
import 'automaton.dart';

/// Finite State Automaton (FSA) implementation
class FSA extends Automaton {
  FSA({
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
    String? description,
  }) : super(type: AutomatonType.fsa);

  /// Creates a copy of this FSA with updated properties
  @override
  FSA copyWith({
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
  }) {
    return FSA(
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
    );
  }

  /// Converts the FSA to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': 'FSA',
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
    };
  }

  /// Creates an FSA from a JSON representation
  factory FSA.fromJson(Map<String, dynamic> json) {
    return FSA(
      id: json['id'] as String,
      name: json['name'] as String,
      states: (json['states'] as List)
          .map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      transitions: (json['transitions'] as List)
          .map((t) => FSATransition.fromJson(t as Map<String, dynamic>))
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
    );
  }

  /// Validates the FSA properties
  @override
  List<String> validate() {
    final errors = super.validate();

    // Validate FSA-specific properties
    for (final transition in transitions) {
      if (transition is! FSATransition) {
        errors.add('FSA can only contain FSA transitions');
      } else {
        final fsaTransition = transition as FSATransition;
        final transitionErrors = fsaTransition.validate();
        errors.addAll(
            transitionErrors.map((e) => 'Transition ${fsaTransition.id}: $e'));
      }
    }

    // Check for deterministic transitions
    for (final state in states) {
      final outgoingTransitions = getTransitionsFrom(state);
      final inputSymbols = <String>{};

      for (final transition in outgoingTransitions) {
        if (transition is FSATransition) {
          for (final symbol in transition.inputSymbols) {
            if (inputSymbols.contains(symbol)) {
              errors.add(
                  'Non-deterministic transition from state ${state.id} on symbol $symbol');
            }
            inputSymbols.add(symbol);
          }
        }
      }
    }

    return errors;
  }

  /// Gets all FSA transitions
  Set<FSATransition> get fsaTransitions {
    return transitions.whereType<FSATransition>().toSet();
  }

  /// Gets all epsilon transitions
  Set<FSATransition> get epsilonTransitions {
    return fsaTransitions.where((t) => t.isEpsilonTransition).toSet();
  }

  /// Gets all deterministic transitions
  Set<FSATransition> get deterministicTransitions {
    return fsaTransitions.where((t) => t.isDeterministic).toSet();
  }

  /// Gets all non-deterministic transitions
  Set<FSATransition> get nondeterministicTransitions {
    return fsaTransitions.where((t) => t.isNondeterministic).toSet();
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

  /// Checks if the language recognized by this FSA is finite.
  ///
  /// For DFAs, the language is infinite iff there exists a cycle reachable
  /// from the initial state that can also reach an accepting state.
  /// For NFAs, the same condition suffices as an over-approximation.
  bool get isFiniteLanguage {
    if (initialState == null) return true;

    // Build graph adjacency for symbol transitions only (ignore epsilon).
    final adjacency = <State, Set<State>>{};
    for (final s in states) {
      adjacency[s] = <State>{};
    }
    for (final t in fsaTransitions) {
      if (t.isEpsilonTransition) continue;
      adjacency[t.fromState]!.add(t.toState);
    }

    // Compute states reachable from initial.
    final reachable = <State>{};
    final queue = <State>[];
    if (initialState != null) {
      reachable.add(initialState!);
      queue.add(initialState!);
    }
    while (queue.isNotEmpty) {
      final u = queue.removeAt(0);
      for (final v in adjacency[u]!) {
        if (reachable.add(v)) queue.add(v);
      }
    }

    if (reachable.isEmpty) return true;

    // Compute states that can reach some accepting state (reverse graph).
    final reverse = <State, Set<State>>{};
    for (final s in states) {
      reverse[s] = <State>{};
    }
    for (final t in fsaTransitions) {
      if (t.isEpsilonTransition) continue;
      reverse[t.toState]!.add(t.fromState);
    }
    final coReach = <State>{...acceptingStates};
    final stack = <State>[...acceptingStates];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      for (final p in reverse[u]!) {
        if (coReach.add(p)) stack.add(p);
      }
    }

    // Restrict to states both reachable and co-reachable.
    final core = states
        .where((s) => reachable.contains(s) && coReach.contains(s))
        .toSet();
    if (core.isEmpty) return true;

    // Detect cycle in core subgraph via DFS with recursion stack.
    final color = <State, int>{}; // 0=unvisited, 1=visiting, 2=done
    bool hasCycle = false;

    bool dfs(State u) {
      color[u] = 1;
      for (final v in adjacency[u]!.where(core.contains)) {
        final c = color[v] ?? 0;
        if (c == 0) {
          if (dfs(v)) return true;
        } else if (c == 1) {
          return true; // back-edge found
        }
      }
      color[u] = 2;
      return false;
    }

    for (final s in core) {
      if ((color[s] ?? 0) == 0) {
        if (dfs(s)) {
          hasCycle = true;
          break;
        }
      }
    }

    return !hasCycle;
  }

  /// Gets all transitions from a state that accept a specific symbol
  Set<FSATransition> getTransitionsFromStateOnSymbol(
      State state, String symbol) {
    return fsaTransitions
        .where((t) => t.fromState == state && t.acceptsSymbol(symbol))
        .toSet();
  }

  /// Gets all epsilon transitions from a state
  Set<FSATransition> getEpsilonTransitionsFromState(State state) {
    return fsaTransitions
        .where((t) => t.fromState == state && t.isEpsilonTransition)
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
  Set<State> getStatesReachableOnSymbolFromSet(
      Set<State> states, String symbol) {
    final reachable = <State>{};

    for (final state in states) {
      reachable.addAll(getStatesReachableOnSymbol(state, symbol));
    }

    return reachable;
  }

  /// Creates an empty FSA
  factory FSA.empty({
    required String id,
    required String name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    return FSA(
      id: id,
      name: name,
      states: {},
      transitions: {},
      alphabet: {},
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Creates a simple FSA with one state
  factory FSA.singleState({
    required String id,
    required String name,
    required String stateId,
    required String stateLabel,
    required Vector2 position,
    bool isInitial = false,
    bool isAccepting = false,
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

    return FSA(
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
    );
  }

  /// Creates a simple FSA with two states and one transition
  factory FSA.twoState({
    required String id,
    required String name,
    required String fromStateId,
    required String toStateId,
    required String symbol,
    required Vector2 fromPosition,
    required Vector2 toPosition,
    bool toStateAccepting = true,
    math.Rectangle? bounds,
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

    final transition = FSATransition.deterministic(
      id: 't1',
      fromState: fromState,
      toState: toState,
      symbol: symbol,
    );

    return FSA(
      id: id,
      name: name,
      states: {fromState, toState},
      transitions: {transition},
      alphabet: {symbol},
      initialState: fromState,
      acceptingStates: toStateAccepting ? {toState} : {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }
}
