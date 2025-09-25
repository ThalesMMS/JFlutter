import '../abstractions/automatons.dart';
import '../abstractions/states.dart';
import '../abstractions/utils.dart';

class NFA extends NonDeterministicAutomaton {
  NFA({required super.states, required super.alphabet});

  @override
  bool evaluate(String input) {
    if (!hasValidInput(input)) return false;
    final states = extendedTransition(initialState, input);
    return states.any(finalStates.contains);
  }

  @override
  Set<NonDeterministicState> extendedTransition(
    NonDeterministicState state,
    String input,
  ) {
    if (input.isEmpty) return {state};
    final possibleNextStates = state.executeTransition(input[0]);
    if (possibleNextStates.isEmpty) return {};
    return possibleNextStates
        .map((nextState) => extendedTransition(nextState, input.substring(1)))
        .expand(identity)
        .toSet();
  }
}
