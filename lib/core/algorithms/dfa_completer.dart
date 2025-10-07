//
//  dfa_completer.dart
//  JFlutter
//
//  Fornece rotina para completar autômatos finitos determinísticos, garantindo
//  transições definidas para todo símbolo do alfabeto a partir de cada estado.
//  Cria estado armadilha quando necessário e copia metadados relevantes, mantendo
//  coerência visual e temporal ao gerar um DFA plenamente definido.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';

class DFACompleter {
  static FSA complete(FSA dfa) {
    final alphabet = dfa.alphabet;
    final states = Set<State>.from(dfa.states);
    final transitions = Set<FSATransition>.from(dfa.fsaTransitions);

    State? trapState;

    for (final state in states) {
      for (final symbol in alphabet) {
        final hasTransition = transitions.any(
          (t) => t.fromState == state && t.inputSymbols.contains(symbol),
        );
        if (!hasTransition) {
          trapState ??= State(
            id: 'q_trap',
            label: 'Trap',
            position: Vector2(0, 0), // Position can be adjusted later
            isInitial: false,
            isAccepting: false,
          );
          transitions.add(
            FSATransition.deterministic(
              id: 't_${state.id}_${symbol}_trap',
              fromState: state,
              toState: trapState,
              symbol: symbol,
            ),
          );
        }
      }
    }

    if (trapState != null) {
      states.add(trapState);
      for (final symbol in alphabet) {
        transitions.add(
          FSATransition.deterministic(
            id: 't_trap_${symbol}_trap',
            fromState: trapState,
            toState: trapState,
            symbol: symbol,
          ),
        );
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
      bounds: dfa.bounds,
      zoomLevel: dfa.zoomLevel,
      panOffset: dfa.panOffset,
    );
  }
}
