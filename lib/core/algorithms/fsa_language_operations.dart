import 'dart:collection';
import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';

import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';
import '../result.dart';
import 'dfa_completer.dart';
import 'nfa_to_dfa_converter.dart';

/// High level language operations for FSAs inspired by Automata Theory toolkits.
///
/// All algorithms return brand new automata without mutating the inputs in
/// accordance with the immutable core recommended in the reference projects.
class FSALanguageOperations {
  /// Concatenates two finite automata using ε-transitions between accepting
  /// states of [first] and the initial state of [second].
  static Result<FSA> concatenate(FSA first, FSA second) {
    try {
      if (first.initialState == null || second.initialState == null) {
        return ResultFactory.failure(
          'Both automata must have an initial state defined.',
        );
      }

      final firstClone = _cloneWithPrefix(first, prefix: 'a');
      final secondClone = _cloneWithPrefix(second, prefix: 'b');

      final states = <State>{
        ...firstClone.states,
        ...secondClone.states,
      };

      final transitions = <FSATransition>{
        ...firstClone.transitions,
        ...secondClone.transitions,
      };

      final acceptingStates = secondClone.states
          .where((state) => secondClone.acceptingIds.contains(state.id))
          .toSet();

      final secondInitial =
          secondClone.originalIdToState[second.initialState!.id]!;
      for (final accepting in firstClone.states.where(
        (state) => firstClone.acceptingIds.contains(state.id),
      )) {
        transitions.add(
          FSATransition.epsilon(
            id: 't_concat_${accepting.id}_${secondInitial.id}',
            fromState: accepting,
            toState: secondInitial,
          ),
        );
      }

      final alphabet = {...first.alphabet, ...second.alphabet};

      final automaton = _buildAutomaton(
        id: '${first.id}_concat_${second.id}',
        name: '${first.name} · ${second.name}',
        states: states,
        transitions: transitions,
        alphabet: alphabet,
        initialState: firstClone.originalIdToState[first.initialState!.id],
        acceptingStates: acceptingStates,
        created: first.created.isBefore(second.created)
            ? first.created
            : second.created,
        modified: DateTime.now(),
        bounds: _mergeBounds(first.bounds, second.bounds),
        zoomLevel: first.zoomLevel,
        panOffset: first.panOffset,
      );

      return ResultFactory.success(automaton);
    } catch (error) {
      return ResultFactory.failure('Error concatenating FSAs: $error');
    }
  }

  /// Computes the Kleene star of [automaton] producing an ε-accepting initial
  /// state and looping ε-transitions from the old accepting states.
  static Result<FSA> kleeneStar(FSA automaton) {
    try {
      if (automaton.initialState == null) {
        return ResultFactory.failure(
          'O autômato precisa de estado inicial para aplicar estrela de Kleene.',
        );
      }

      final clone = _cloneWithPrefix(automaton, prefix: 'k');
      final initialPosition =
          automaton.initialState?.position ?? Vector2.zero();
      final startState = State(
        id: '${automaton.id}_star_start',
        label: 'start*',
        position: initialPosition + Vector2(-80, -80),
        isInitial: true,
        isAccepting: true,
      );

      final states = <State>{startState, ...clone.states};
      final transitions = <FSATransition>{...clone.transitions};

      final clonedInitial =
          clone.originalIdToState[automaton.initialState!.id]!;
      transitions.add(
        FSATransition.epsilon(
          id: 't_star_${startState.id}_${clonedInitial.id}',
          fromState: startState,
          toState: clonedInitial,
        ),
      );

      for (final accepting in clone.states.where(
        (state) => clone.acceptingIds.contains(state.id),
      )) {
        transitions.add(
          FSATransition.epsilon(
            id: 't_star_${accepting.id}_${clonedInitial.id}',
            fromState: accepting,
            toState: clonedInitial,
          ),
        );
      }

      final acceptingStates = {
        startState,
        ...clone.states.where(
          (state) => clone.acceptingIds.contains(state.id),
        ),
      };

      final starred = _buildAutomaton(
        id: '${automaton.id}_star',
        name: '${automaton.name}*',
        states: states,
        transitions: transitions,
        alphabet: automaton.alphabet,
        initialState: startState,
        acceptingStates: acceptingStates,
        created: automaton.created,
        modified: DateTime.now(),
        bounds: automaton.bounds,
        zoomLevel: automaton.zoomLevel,
        panOffset: automaton.panOffset,
      );

      return ResultFactory.success(starred);
    } catch (error) {
      return ResultFactory.failure('Erro ao aplicar estrela de Kleene: $error');
    }
  }

  /// Reverses the language of [automaton] by flipping transitions and swapping
  /// initial/accepting states.
  static Result<FSA> reverse(FSA automaton) {
    try {
      if (automaton.initialState == null) {
        return ResultFactory.failure(
          'O autômato precisa de estado inicial para a reversão.',
        );
      }

      final clone = _cloneWithPrefix(automaton, prefix: 'r');
      final newInitial = State(
        id: '${automaton.id}_rev_start',
        label: 'rev_start',
        position:
            automaton.initialState!.position + Vector2(60, -60),
        isInitial: true,
        isAccepting: automaton.acceptingStates.contains(automaton.initialState),
      );

      final stateCopies = <String, State>{};
      for (final state in clone.states) {
        final originalId = clone.prefixedToOriginalId[state.id]!;
        final shouldBeAccepting =
            automaton.initialState?.id == originalId || state.isAccepting;
        stateCopies[state.id] = state.copyWith(
          isInitial: false,
          isAccepting: shouldBeAccepting,
        );
      }

      final transitions = <FSATransition>{};
      for (final transition in clone.transitions) {
        final from = stateCopies[transition.toState.id]!;
        final to = stateCopies[transition.fromState.id]!;
        transitions.add(
          FSATransition(
            id: 't_rev_${transition.id}',
            fromState: from,
            toState: to,
            label: transition.label,
            inputSymbols: transition.inputSymbols,
            lambdaSymbol: transition.lambdaSymbol,
            type: transition.type,
          ),
        );
      }

      for (final accepting in automaton.acceptingStates) {
        final mapped = clone.originalIdToState[accepting.id]!;
        final target = stateCopies[mapped.id]!;
        transitions.add(
          FSATransition.epsilon(
            id: 't_rev_${newInitial.id}_${target.id}',
            fromState: newInitial,
            toState: target,
          ),
        );
      }

      final states = {newInitial, ...stateCopies.values};
      final acceptingStates =
          states.where((state) => state.isAccepting).toSet();

      final reversed = _buildAutomaton(
        id: '${automaton.id}_rev',
        name: '${automaton.name}^R',
        states: states,
        transitions: transitions,
        alphabet: automaton.alphabet,
        initialState: newInitial,
        acceptingStates: acceptingStates,
        created: automaton.created,
        modified: DateTime.now(),
        bounds: automaton.bounds,
        zoomLevel: automaton.zoomLevel,
        panOffset: automaton.panOffset,
      );

      return ResultFactory.success(reversed);
    } catch (error) {
      return ResultFactory.failure('Erro ao reverter o FSA: $error');
    }
  }

  /// Computes the shuffle product between [a] and [b], interleaving symbols of
  /// both automata using a standard product construction.
  static Result<FSA> shuffleProduct(FSA a, FSA b) {
    try {
      if (a.initialState == null || b.initialState == null) {
        return ResultFactory.failure(
          'Ambos os autômatos precisam ter estado inicial definido.',
        );
      }

      final completedA = _ensureDeterministic(a);
      if (completedA.isFailure) {
        return ResultFactory.failure(completedA.error!);
      }
      final completedB = _ensureDeterministic(b);
      if (completedB.isFailure) {
        return ResultFactory.failure(completedB.error!);
      }
      final dfaA = completedA.data!;
      final dfaB = completedB.data!;

      final queue = Queue<(State, State)>();
      final stateMap = <String, State>{};
      final transitions = <FSATransition>{};

      State getOrCreate(State stateA, State stateB, {required bool isInitial}) {
        final key = '${stateA.id}|${stateB.id}';
        final existing = stateMap[key];
        if (existing != null) {
          return existing;
        }
        final combined = State(
          id: key,
          label: '(${stateA.label},${stateB.label})',
          position: (stateA.position + stateB.position) / 2,
          isInitial: isInitial,
          isAccepting: dfaA.acceptingStates.contains(stateA) &&
              dfaB.acceptingStates.contains(stateB),
        );
        stateMap[key] = combined;
        queue.add((stateA, stateB));
        return combined;
      }

      final initial = getOrCreate(
        dfaA.initialState!,
        dfaB.initialState!,
        isInitial: true,
      );

      int transitionCounter = 0;

      while (queue.isNotEmpty) {
        final (stateA, stateB) = queue.removeFirst();
        final fromState = stateMap['${stateA.id}|${stateB.id}']!;

      final transitionsA =
          dfaA.getTransitionsFrom(stateA).whereType<FSATransition>();
        for (final transition in transitionsA) {
          final target = getOrCreate(
            transition.toState,
            stateB,
            isInitial: false,
          );
          transitions.add(
            FSATransition(
              id: 't_shuffle_${transitionCounter++}',
              fromState: fromState,
              toState: target,
              label: transition.label,
              inputSymbols: transition.inputSymbols,
              lambdaSymbol: transition.lambdaSymbol,
              type: transition.type,
            ),
          );
        }

      final transitionsB =
          dfaB.getTransitionsFrom(stateB).whereType<FSATransition>();
        for (final transition in transitionsB) {
          final target = getOrCreate(
            stateA,
            transition.toState,
            isInitial: false,
          );
          transitions.add(
            FSATransition(
              id: 't_shuffle_${transitionCounter++}',
              fromState: fromState,
              toState: target,
              label: transition.label,
              inputSymbols: transition.inputSymbols,
              lambdaSymbol: transition.lambdaSymbol,
              type: transition.type,
            ),
          );
        }
      }

      final shuffle = _buildAutomaton(
        id: '${a.id}_shuffle_${b.id}',
        name: '${a.name} ⧢ ${b.name}',
        states: stateMap.values.toSet(),
        transitions: transitions,
        alphabet: {...a.alphabet, ...b.alphabet},
        initialState: initial,
        acceptingStates:
            stateMap.values.where((state) => state.isAccepting).toSet(),
        created: a.created.isBefore(b.created) ? a.created : b.created,
        modified: DateTime.now(),
        bounds: a.bounds,
        zoomLevel: a.zoomLevel,
        panOffset: a.panOffset,
      );

      return ResultFactory.success(shuffle);
    } catch (error) {
      return ResultFactory.failure('Erro ao calcular o shuffle: $error');
    }
  }

  /// Checks whether the language recognised by [automaton] is empty.
  static Result<bool> isLanguageEmpty(FSA automaton) {
    try {
      final initial = automaton.initialState;
      if (initial == null) {
        return ResultFactory.success(true);
      }

      final visited = <State>{};
      final queue = Queue<State>();
      void enqueueClosure(State state) {
        for (final closureState in automaton.getEpsilonClosure(state)) {
          if (visited.add(closureState)) {
            queue.add(closureState);
          }
        }
      }

      enqueueClosure(initial);

      while (queue.isNotEmpty) {
        final state = queue.removeFirst();
        if (automaton.acceptingStates.contains(state)) {
          return ResultFactory.success(false);
        }
        final transitions =
            automaton.getTransitionsFrom(state).whereType<FSATransition>();
        for (final transition in transitions) {
          if (transition.isEpsilonTransition) {
            enqueueClosure(transition.toState);
          } else {
            if (visited.add(transition.toState)) {
              queue.add(transition.toState);
            }
          }
        }
      }

      return ResultFactory.success(true);
    } catch (error) {
      return ResultFactory.failure('Erro ao verificar linguagem vazia: $error');
    }
  }

  /// Checks whether the language recognised by [automaton] is finite.
  static Result<bool> isLanguageFinite(FSA automaton) {
    try {
      final deterministic = _ensureDeterministic(automaton);
      if (deterministic.isFailure) {
        return ResultFactory.failure(deterministic.error!);
      }
      final dfa = deterministic.data!;
      final initial = dfa.initialState;
      if (initial == null) {
        return ResultFactory.success(true);
      }

      final reachable = _reachableStates(dfa, initial);
      if (reachable.isEmpty) {
        return ResultFactory.success(true);
      }

      final reverseMap = <String, Set<State>>{};
      final adjacency = <String, Set<State>>{};

      for (final state in reachable) {
        final transitions =
            dfa.getTransitionsFrom(state).whereType<FSATransition>();
        for (final transition in transitions) {
          adjacency
              .putIfAbsent(state.id, () => <State>{})
              .add(transition.toState);
          reverseMap
              .putIfAbsent(transition.toState.id, () => <State>{})
              .add(state);
        }
      }

      final canReachAccepting = <State>{};
      final stack = Queue<State>();
      for (final accepting in dfa.acceptingStates) {
        if (reachable.contains(accepting)) {
          canReachAccepting.add(accepting);
          stack.add(accepting);
        }
      }

      while (stack.isNotEmpty) {
        final current = stack.removeFirst();
        for (final predecessor in reverseMap[current.id] ?? const <State>{}) {
          if (canReachAccepting.add(predecessor)) {
            stack.add(predecessor);
          }
        }
      }

      final candidateStates =
          reachable.where(canReachAccepting.contains).toSet();
      if (candidateStates.isEmpty) {
        return ResultFactory.success(true);
      }

      final visited = <String>{};
      final onStack = <String>{};

      bool hasCycle(State state) {
        if (!candidateStates.contains(state)) return false;
        if (!visited.add(state.id)) {
          return onStack.contains(state.id);
        }
        onStack.add(state.id);
        for (final next in adjacency[state.id] ?? const <State>{}) {
          if (hasCycle(next)) {
            return true;
          }
        }
        onStack.remove(state.id);
        return false;
      }

      for (final state in candidateStates) {
        if (hasCycle(state)) {
          return ResultFactory.success(false);
        }
      }

      return ResultFactory.success(true);
    } catch (error) {
      return ResultFactory.failure('Erro ao verificar finitude da linguagem: $error');
    }
  }

  /// Generates sample words accepted by [automaton] up to [maxLength] symbols
  /// and limited to [maxWords] examples.
  static Result<Set<String>> generateWords(
    FSA automaton, {
    int maxLength = 6,
    int maxWords = 32,
  }) {
    try {
      final deterministic = _ensureDeterministic(automaton);
      if (deterministic.isFailure) {
        return ResultFactory.failure(deterministic.error!);
      }
      final dfa = deterministic.data!;
      final initial = dfa.initialState;
      if (initial == null) {
        return ResultFactory.success(<String>{});
      }

      final queue = Queue<_WordGenerationConfig>();
      queue.add(_WordGenerationConfig(state: initial, symbols: const []));
      final results = <String>{};

      while (queue.isNotEmpty && results.length < maxWords) {
        final config = queue.removeFirst();
        final currentWord = config.symbols.join();
        if (dfa.acceptingStates.contains(config.state)) {
          results.add(currentWord);
          if (results.length >= maxWords) break;
        }
        if (config.symbols.length >= maxLength) {
          continue;
        }

        for (final symbol in dfa.alphabet.whereNot(_isLambdaSymbol)) {
          final transitions = dfa
              .getTransitionsFromStateOnSymbol(config.state, symbol)
              .whereType<FSATransition>()
              .toList();
          if (transitions.isEmpty) continue;
          final nextState = transitions.first.toState;
          queue.add(
            _WordGenerationConfig(
              state: nextState,
              symbols: [...config.symbols, symbol],
            ),
          );
        }
      }

      return ResultFactory.success(results);
    } catch (error) {
      return ResultFactory.failure('Erro ao gerar palavras: $error');
    }
  }

  static _DeterministicResult _ensureDeterministic(FSA automaton) {
    if (automaton.isDeterministic && !automaton.hasEpsilonTransitions) {
      return _DeterministicResult.success(automaton);
    }
      final determinised = NFAToDFAConverter.convert(automaton);
      if (determinised.isFailure) {
        return _DeterministicResult.failure(determinised.error!);
      }
    final completed = DFACompleter.complete(
      determinised.data!.copyWith(alphabet: automaton.alphabet),
    );
    return _DeterministicResult.success(completed);
  }

  static _ClonedAutomaton _cloneWithPrefix(
    FSA automaton, {
    required String prefix,
  }) {
    final states = <State>{};
    final originalIdToState = <String, State>{};
    final prefixedIdToState = <String, State>{};
    final prefixedToOriginalId = <String, String>{};
    final acceptingIds = <String>{};

    for (final state in automaton.states) {
      final newState = state.copyWith(
        id: '${prefix}_${state.id}',
        label: state.label,
        isInitial: false,
        isAccepting: automaton.acceptingStates.contains(state),
      );
      states.add(newState);
      originalIdToState[state.id] = newState;
      prefixedIdToState[newState.id] = newState;
      prefixedToOriginalId[newState.id] = state.id;
      if (newState.isAccepting) {
        acceptingIds.add(newState.id);
      }
    }

    final transitions = <FSATransition>{};
    for (final transition in automaton.fsaTransitions) {
      final fromState = originalIdToState[transition.fromState.id]!;
      final toState = originalIdToState[transition.toState.id]!;
      transitions.add(
        FSATransition(
          id: '${prefix}_${transition.id}',
          fromState: fromState,
          toState: toState,
          label: transition.label,
          inputSymbols: transition.inputSymbols,
          lambdaSymbol: transition.lambdaSymbol,
          type: transition.type,
        ),
      );
    }

    return _ClonedAutomaton(
      states: states,
      transitions: transitions,
      originalIdToState: originalIdToState,
      prefixedIdToState: prefixedIdToState,
      prefixedToOriginalId: prefixedToOriginalId,
      acceptingIds: acceptingIds,
    );
  }

  static Set<State> _reachableStates(FSA automaton, State initial) {
    final visited = <State>{};
    final queue = Queue<State>()..add(initial);
    visited.add(initial);

    while (queue.isNotEmpty) {
      final state = queue.removeFirst();
      final transitions =
          automaton.getTransitionsFrom(state).whereType<FSATransition>();
      for (final transition in transitions) {
        if (visited.add(transition.toState)) {
          queue.add(transition.toState);
        }
      }
    }

    return visited;
  }

  static bool _isLambdaSymbol(String symbol) {
    final normalized = symbol.trim().toLowerCase();
    return normalized == 'ε' ||
        normalized == 'λ' ||
        normalized == 'lambda' ||
        normalized == '£' ||
        normalized == '€';
  }

  static math.Rectangle _mergeBounds(
    math.Rectangle first,
    math.Rectangle second,
  ) {
    final left = math.min(first.left, second.left);
    final top = math.min(first.top, second.top);
    final right = math.max(first.right, second.right);
    final bottom = math.max(first.bottom, second.bottom);
    return math.Rectangle(left, top, right - left, bottom - top);
  }

  static FSA _buildAutomaton({
    required String id,
    required String name,
    required Set<State> states,
    required Set<FSATransition> transitions,
    required Set<String> alphabet,
    required State? initialState,
    required Set<State> acceptingStates,
    required DateTime created,
    required DateTime modified,
    required math.Rectangle bounds,
    required double zoomLevel,
    required Vector2 panOffset,
  }) {
    final stateCopies = <String, State>{};
    final acceptingIds = acceptingStates.map((state) => state.id).toSet();

    for (final state in states) {
      final isInitial = initialState != null && state.id == initialState.id;
      final isAccepting = acceptingIds.contains(state.id);
      stateCopies[state.id] = state.copyWith(
        isInitial: isInitial,
        isAccepting: isAccepting,
      );
    }

    final rebuiltTransitions = <FSATransition>{};
    for (final transition in transitions) {
      final fromState = stateCopies[transition.fromState.id]!;
      final toState = stateCopies[transition.toState.id]!;
      rebuiltTransitions.add(
        FSATransition(
          id: transition.id,
          fromState: fromState,
          toState: toState,
          label: transition.label,
          inputSymbols: transition.inputSymbols,
          lambdaSymbol: transition.lambdaSymbol,
          type: transition.type,
        ),
      );
    }

    final rebuiltStates = stateCopies.values.toSet();
    final rebuiltAccepting =
        rebuiltStates.where((state) => state.isAccepting).toSet();
    final rebuiltInitial = initialState != null
        ? stateCopies[initialState.id]
        : null;

    return FSA(
      id: id,
      name: name,
      states: rebuiltStates,
      transitions: rebuiltTransitions,
      alphabet: alphabet,
      initialState: rebuiltInitial,
      acceptingStates: rebuiltAccepting,
      created: created,
      modified: modified,
      bounds: bounds,
      zoomLevel: zoomLevel,
      panOffset: panOffset,
    );
  }
}

class _DeterministicResult {
  final FSA? automaton;
  final String? error;

  const _DeterministicResult._(this.automaton, this.error);

  bool get isFailure => error != null;
  bool get isSuccess => !isFailure;

  static _DeterministicResult success(FSA automaton) =>
      _DeterministicResult._(automaton, null);
  static _DeterministicResult failure(String error) =>
      _DeterministicResult._(null, error);

  FSA? get data => automaton;
}

class _ClonedAutomaton {
  final Set<State> states;
  final Set<FSATransition> transitions;
  final Map<String, State> originalIdToState;
  final Map<String, State> prefixedIdToState;
  final Map<String, String> prefixedToOriginalId;
  final Set<String> acceptingIds;

  const _ClonedAutomaton({
    required this.states,
    required this.transitions,
    required this.originalIdToState,
    required this.prefixedIdToState,
    required this.prefixedToOriginalId,
    required this.acceptingIds,
  });
}

class _WordGenerationConfig {
  final State state;
  final List<String> symbols;

  const _WordGenerationConfig({
    required this.state,
    required this.symbols,
  });
}
