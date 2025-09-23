
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';

/// Completes a deterministic finite automaton by ensuring every state has a
/// transition for each symbol in the alphabet, introducing a trap state when
/// necessary to absorb missing transitions.
class DFACompleter {
  static FSA complete(FSA dfa) {
    final alphabet = dfa.alphabet;
    final states = Set<State>.from(dfa.states);
    final transitions = Set<FSATransition>.from(dfa.fsaTransitions);

    State? trapState;

    // Track, for each state, the set of symbols that already have outgoing
    // transitions. This allows the algorithm to identify the missing symbols
    // that need to be completed.
    final existingSymbolsByState = <State, Set<String>>{};
    for (final transition in transitions) {
      final existingSymbols =
          existingSymbolsByState.putIfAbsent(transition.fromState, () => <String>{});
      existingSymbols.addAll(transition.inputSymbols);
    }

    for (final state in states) {
      for (final symbol in alphabet) {
        final existingSymbols =
            existingSymbolsByState.putIfAbsent(state, () => <String>{});
        final hasTransition = existingSymbols.contains(symbol);
        if (!hasTransition) {
          // Lazily create a single trap state that can be reused for every
          // missing transition. The same instance is kept and recycled so that
          // all unmatched symbols across the DFA share the same non-accepting
          // sink.
          trapState ??= State(
            id: 'q_trap',
            label: 'Trap',
            position: Vector2(0, 0), // Position can be adjusted later
            isInitial: false,
            isAccepting: false,
          );
          // Use deterministic transitions so that every missing symbol is
          // explicitly mapped to the trap state while respecting the DFA's
          // semantics of one target per symbol.
          transitions.add(FSATransition.deterministic(
            id: 't_${state.id}_${symbol}_trap',
            fromState: state,
            toState: trapState,
            symbol: symbol,
          ));
          existingSymbols.add(symbol);
          existingSymbolsByState
              .putIfAbsent(trapState, () => <String>{})
              .add(symbol);
        }
      }
    }

    if (trapState != null) {
      states.add(trapState);
      final trapSymbols =
          existingSymbolsByState.putIfAbsent(trapState, () => <String>{});
      for (final symbol in alphabet) {
        // Create self-loop transitions on the trap state for all symbols, using
        // the deterministic constructor to emphasize that the trap absorbs
        // every possible input without introducing nondeterminism.
        transitions.add(FSATransition.deterministic(
          id: 't_trap_${symbol}_trap',
          fromState: trapState,
          toState: trapState,
          symbol: symbol,
        ));
        trapSymbols.add(symbol);
      }
    }

    return FSA(
      id: dfa.id,
      name: dfa.name,
      states: states,
      transitions: transitions,
      alphabet: alphabet,
      initialState: dfa.initialState,
      acceptingStates: dfa.acceptingStates,
      created: dfa.created,
      modified: DateTime.now(),
      // Preserve the visual metadata (bounds, zoom level, and pan offset) so
      // that completing the DFA does not disturb the user's canvas state.
      bounds: dfa.bounds,
      zoomLevel: dfa.zoomLevel,
      panOffset: dfa.panOffset,
    );
  }
}
