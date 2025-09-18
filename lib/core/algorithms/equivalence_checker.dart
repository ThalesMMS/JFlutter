
import '../models/fsa.dart';
import '../models/state.dart';

class EquivalenceChecker {
  static bool areEquivalent(FSA a, FSA b) {
    final alphabet = a.alphabet.union(b.alphabet);
    final initialStateA = a.initialState;
    final initialStateB = b.initialState;

    if (initialStateA == null || initialStateB == null) {
      return false;
    }

    final visited = <String>{};
    final queue = <List<State>>[];

    queue.add([initialStateA, initialStateB]);
    visited.add('${initialStateA.id},${initialStateB.id}');

    while (queue.isNotEmpty) {
      final currentPair = queue.removeAt(0);
      final stateA = currentPair[0];
      final stateB = currentPair[1];

      if (a.acceptingStates.contains(stateA) != b.acceptingStates.contains(stateB)) {
        return false;
      }

      for (final symbol in alphabet) {
        final nextStateA = a.getTransitionsFromStateOnSymbol(stateA, symbol).firstOrNull?.toState;
        final nextStateB = b.getTransitionsFromStateOnSymbol(stateB, symbol).firstOrNull?.toState;

        if (nextStateA != null && nextStateB != null) {
          final pairKey = '${nextStateA.id},${nextStateB.id}';
          if (!visited.contains(pairKey)) {
            queue.add([nextStateA, nextStateB]);
            visited.add(pairKey);
          }
        } else if (nextStateA != null || nextStateB != null) {
          // One automaton has a transition and the other doesn't.
          // This can only happen if one of the DFAs is not complete.
          // Assuming complete DFAs for equivalence checking.
          // If they are not complete, they should be completed first.
          return false;
        }
      }
    }

    return true;
  }
}
