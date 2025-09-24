import 'exceptions.dart';
import 'states.dart';

sealed class Automaton<StateType extends State> {
  final Set<StateType> _states;
  final Set<String> _alphabet;
  late final StateType initialState;

  Automaton({
    required Set<StateType> states,
    required Set<String> alphabet,
  })  : _alphabet = alphabet,
        _states = states {
    try {
      initialState = _states.singleWhere((state) => state.isInitial);
    } catch (_) {
      throw InvalidInitialStateException();
    }
  }

  Set<StateType> get finalStates =>
      _states.where((state) => state.isFinal).toSet();

  Set<StateType> get states => _states.toSet();

  Set<String> get alphabet => _alphabet.toSet();

  bool hasValidInput(String input) {
    final symbols = input.split('');
    return symbols.every(_alphabet.contains);
  }

  bool evaluate(String input);

  List<List<int>> get adjacencyMatrix {
    final matrix = <List<int>>[];

    for (var idxA = 0; idxA < _states.length; idxA++) {
      final row = <int>[];

      final stateA = _states.elementAt(idxA);
      final transitions = switch (this) {
        DeterministicAutomaton() => stateA.transitions.values,
        NonDeterministicAutomaton() =>
          stateA.transitions.values.expand((values) => values),
      };

      for (var idxB = 0; idxB < _states.length; idxB++) {
        final stateB = _states.elementAt(idxB);
        final quantity = transitions.where((state) => state == stateB).length;

        row.add(quantity);
      }

      matrix.add(row);
    }

    return matrix;
  }
}

abstract class DeterministicAutomaton extends Automaton<DeterministicState> {
  DeterministicAutomaton({required super.states, required super.alphabet});

  DeterministicState extendedTransition(DeterministicState state, String input);
}

abstract class NonDeterministicAutomaton
    extends Automaton<NonDeterministicState> {
  NonDeterministicAutomaton({required super.states, required super.alphabet});

  Set<NonDeterministicState> extendedTransition(
    NonDeterministicState state,
    String input,
  );
}

abstract class EpsilonNonDeterministicAutomaton
    extends NonDeterministicAutomaton {
  EpsilonNonDeterministicAutomaton({
    required super.states,
    required super.alphabet,
  });

  Set<NonDeterministicState> epsilonClosure(NonDeterministicState state);
}
