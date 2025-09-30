import '../models/fsa.dart';
import '../models/state.dart';
import 'dfa_completer.dart';
import 'nfa_to_dfa_converter.dart';

class EquivalenceChecker {
  static bool areEquivalent(FSA a, FSA b) {
    // If either has no initial state, not equivalent per tests
    if (a.initialState == null || b.initialState == null) return false;

    // Enforce alphabet equality per tests (explicit requirement in suite)
    if (a.alphabet.isEmpty && b.alphabet.isEmpty) {
      // fall through; empty but equal
    } else if (a.alphabet.length != b.alphabet.length ||
        !a.alphabet.containsAll(b.alphabet)) {
      return false;
    }

    // Convert NFAs to DFAs if necessary
    final dfaA = a.isDeterministic ? a : (NFAToDFAConverter.convert(a).data ?? a);
    final dfaB = b.isDeterministic ? b : (NFAToDFAConverter.convert(b).data ?? b);

    // Use shared alphabet (after conversion) and complete both DFAs
    final sharedAlphabet = dfaA.alphabet.union(dfaB.alphabet);
    final completedA = DFACompleter.complete(dfaA.copyWith(alphabet: sharedAlphabet));
    final completedB = DFACompleter.complete(dfaB.copyWith(alphabet: sharedAlphabet));

    final initialA = completedA.initialState!;
    final initialB = completedB.initialState!;

    // BFS over product automaton; early-exit on differing acceptance
    final visited = <String>{'${initialA.id},${initialB.id}'};
    final queue = <List<State>>[[initialA, initialB]];

    while (queue.isNotEmpty) {
      final pair = queue.removeAt(0);
      final sA = pair[0];
      final sB = pair[1];

      final accA = completedA.acceptingStates.contains(sA);
      final accB = completedB.acceptingStates.contains(sB);
      if (accA != accB) return false;

      for (final symbol in sharedAlphabet) {
        final nextASet = completedA.getTransitionsFromStateOnSymbol(sA, symbol);
        final nextBSet = completedB.getTransitionsFromStateOnSymbol(sB, symbol);

        // DFAs completed → exactly one transition per symbol
        final nextA = nextASet.isNotEmpty ? nextASet.first.toState : null;
        final nextB = nextBSet.isNotEmpty ? nextBSet.first.toState : null;

        if (nextA == null || nextB == null) return false; // completion invariant broken
        final key = '${nextA.id},${nextB.id}';
        if (visited.add(key)) {
          queue.add([nextA, nextB]);
        }
      }
    }

    return true;
  }
}
