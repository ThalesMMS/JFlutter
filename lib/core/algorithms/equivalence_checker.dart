
import '../models/fsa.dart';
import '../models/state.dart';

/// Implements DFA equivalence checking by performing a breadth-first search
/// over pairs of states. The algorithm relies on the DFAs being complete, so
/// ensure both automata are completed (e.g., by adding sink states) before
/// invoking this checker to avoid spurious inequivalence results.
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

    // Track visited pairs by concatenating the state IDs. This creates a
    // deterministic identifier for each combination of states encountered
    // during the pairwise search, preventing the queue from processing the
    // same pair more than once.

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
          // If only one DFA defines a transition for this symbol, the search
          // observes different behaviours. This branch exists solely because
          // the algorithm assumes complete DFAs; a missing transition should
          // have been directed to an explicit sink state. Complete the
          // automata before comparing to ensure the equivalence result is
          // meaningful.
          return false;
        }
      }
    }

    return true;
  }
}
