//
//  fa_algorithms.dart
//  JFlutter
//
//  Oferece uma fachada simplificada para algoritmos relacionados a autômatos
//  finitos determinísticos e não determinísticos, expondo conversão NFA→DFA,
//  minimização com rastreamento de passos, operações de linguagem e verificações
//  de propriedades como finitude e equivalência. Centraliza dependências de
//  módulos especializados para que camadas superiores acessem rotinas robustas
//  com chamadas diretas e documentadas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../models/fsa.dart';
import '../../result.dart';
import '../dfa_minimizer.dart';
import '../dfa_operations.dart';
import '../equivalence_checker.dart';
import '../nfa_to_dfa_converter.dart';

/// High-level FA algorithms façade for conversions, minimization, operations, and diagnostics.
class FAAlgorithms {
  /// NFA → DFA conversion
  static Result<FSA> nfaToDfa(FSA nfa) => NFAToDFAConverter.convert(nfa);

  /// NFA → DFA conversion with steps
  static Result<NFAToDFAConversionResult> nfaToDfaWithSteps(FSA nfa) =>
      NFAToDFAConverter.convertWithSteps(nfa);

  /// DFA minimization (Hopcroft)
  static Result<FSA> minimizeDfa(FSA dfa) => DFAMinimizer.minimize(dfa);

  /// DFA minimization (Hopcroft) with steps
  static Result<DFAMinimizationResult> minimizeDfaWithSteps(FSA dfa) =>
      DFAMinimizer.minimizeWithSteps(dfa);

  /// Language operations on DFAs
  static Result<FSA> union(FSA a, FSA b) => DFAOperations.union(a, b);
  static Result<FSA> intersection(FSA a, FSA b) =>
      DFAOperations.intersection(a, b);
  static Result<FSA> difference(FSA a, FSA b) => DFAOperations.difference(a, b);
  static Result<FSA> complement(FSA dfa) => DFAOperations.complement(dfa);
  static Result<FSA> prefixClosure(FSA dfa) => DFAOperations.prefixClosure(dfa);
  static Result<FSA> suffixClosure(FSA dfa) => DFAOperations.suffixClosure(dfa);

  /// Diagnostics
  static bool isEmpty(FSA dfa) {
    if (dfa.initialState == null) return true;
    final reachable = dfa.getReachableStates(dfa.initialState!);
    return reachable.intersection(dfa.acceptingStates).isEmpty;
  }

  static bool isFinite(FSA dfa) {
    // A DFA language is finite iff no cycle is both reachable from the initial
    // state and able to reach an accepting state.
    if (dfa.initialState == null) return true;

    final reachable = dfa.getReachableStates(dfa.initialState!);
    if (reachable.isEmpty) return true;

    // Build forward and reverse adjacency restricted to reachable states
    final forward = <String, Set<String>>{};
    final reverse = <String, Set<String>>{};
    for (final t in dfa.fsaTransitions) {
      if (!reachable.contains(t.fromState) || !reachable.contains(t.toState)) {
        continue;
      }
      forward.putIfAbsent(t.fromState.id, () => <String>{}).add(t.toState.id);
      reverse.putIfAbsent(t.toState.id, () => <String>{}).add(t.fromState.id);
    }

    // Compute states in reachable set that can reach an accepting state (via reverse BFS)
    final target = <String>{
      for (final s in dfa.acceptingStates.where(reachable.contains)) s.id,
    };
    if (target.isEmpty) {
      return true; // no accepting reachable → empty language → finite
    }
    final canReachAccepting = <String>{...target};
    final queue = List<String>.from(target);
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      for (final prev in reverse[cur] ?? const <String>{}) {
        if (canReachAccepting.add(prev)) {
          queue.add(prev);
        }
      }
    }

    // Induced subgraph on nodes that can reach accepting
    // Detect any cycle in this subgraph using DFS colors
    const int white = 0, gray = 1, black = 2;
    final color = <String, int>{for (final s in canReachAccepting) s: white};

    bool hasCycle = false;
    void dfs(String u) {
      if (hasCycle) return;
      color[u] = gray;
      for (final v in forward[u] ?? const <String>{}) {
        if (!canReachAccepting.contains(v)) continue;
        final c = color[v] ?? white;
        if (c == gray) {
          hasCycle = true;
          return;
        }
        if (c == white) dfs(v);
        if (hasCycle) return;
      }
      color[u] = black;
    }

    for (final s in canReachAccepting) {
      if (color[s] == white) {
        dfs(s);
        if (hasCycle) break;
      }
    }

    return !hasCycle;
  }

  static bool areEquivalent(FSA a, FSA b) =>
      EquivalenceChecker.areEquivalent(a, b);
}
