
import '../models/fsa.dart';
import '../models/state.dart';

/// Implements DFA equivalence checking by exploring pairs of states in
/// breadth-first order. The algorithm assumes the provided automata are
/// complete; complete them explicitly before invoking this checker to avoid
/// false negatives.
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

    // Track visited pairs using the concatenated state IDs so that each
    // combination is processed only once, regardless of which automaton the
    // individual states belong to.

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
          // observes different behaviours. The checker expects complete DFAs,
          // where missing transitions would lead to an explicit sink state.
          // Complete both automata before comparing to prevent spurious
          // inequivalence results.
          return false;
        }
      }
    }

    return true;
  }
}
