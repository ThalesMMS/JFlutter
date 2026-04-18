part of 'pda_simulator.dart';

/// Validates the input PDA and string
Result<void> _validateInput(PDA pda, String inputString) {
  if (pda.states.isEmpty) {
    return const Failure('PDA must have at least one state');
  }

  if (pda.initialState == null) {
    return const Failure('PDA must have an initial state');
  }

  if (!pda.states.contains(pda.initialState)) {
    return const Failure('Initial state must be in the states set');
  }

  for (final acceptingState in pda.acceptingStates) {
    if (!pda.states.contains(acceptingState)) {
      return const Failure('Accepting state must be in the states set');
    }
  }

  // Do not hard-reject unknown input symbols here; allow the
  // simulation to proceed and naturally reject if no transitions
  // match. This aligns with reference semantics and tests.

  return const Success(null);
}
