
import 'package:vector_math/vector_math_64.dart';
import '../models/fsa.dart';
import '../models/state.dart';
import '../models/fsa_transition.dart';

/// Completa um autômato finito determinístico garantindo que cada estado tenha
/// transições definidas para todo símbolo do alfabeto, recorrendo a um estado
/// armadilha quando necessário para absorver lacunas.
class DFACompleter {
  static FSA complete(FSA dfa) {
    final alphabet = dfa.alphabet;
    final states = Set<State>.from(dfa.states);
    final transitions = Set<FSATransition>.from(dfa.fsaTransitions);

    State? trapState;

    // Mapeia cada estado para o conjunto de símbolos já cobertos por suas
    // transições determinísticas. A estrutura permite identificar com rapidez
    // quais símbolos ainda precisam ser completados para cada estado.
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
          // Cria sob demanda um único estado armadilha reutilizável para todas
          // as transições ausentes. A mesma instância é reciclada para que
          // todo símbolo sem destino compartilhe o mesmo sumidouro não
          // aceitador.
          trapState ??= State(
            id: 'q_trap',
            label: 'Trap',
            position: Vector2(0, 0), // Position can be adjusted later
            isInitial: false,
            isAccepting: false,
          );
          // Usa transições determinísticas para mapear explicitamente cada
          // símbolo faltante ao estado armadilha, preservando a propriedade de
          // que um DFA possui exatamente um destino por símbolo.
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
        // Cria auto-loops determinísticos no estado armadilha para todo
        // símbolo, reforçando que ele absorve qualquer entrada sem introduzir
        // não determinismo.
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
      // Preserva os metadados visuais (bounds, zoomLevel e panOffset) para que
      // completar o DFA não altere a visualização atual do usuário.
      bounds: dfa.bounds,
      zoomLevel: dfa.zoomLevel,
      panOffset: dfa.panOffset,
    );
  }
}
