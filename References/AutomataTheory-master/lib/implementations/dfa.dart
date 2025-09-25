import '../abstractions/automatons.dart';
import '../abstractions/states.dart';

class DFA extends DeterministicAutomaton {
  DFA({required super.states, required super.alphabet});

  @override
  bool evaluate(String input) {
    if (!hasValidInput(input)) return false;
    final state = extendedTransition(initialState, input);
    return finalStates.contains(state);
  }

  @override
  DeterministicState extendedTransition(
    DeterministicState state,
    String input,
  ) {
    if (input.isEmpty) return state;
    return extendedTransition(
      state.executeTransition(input[0]),
      input.substring(1),
    );
  }
}
