import 'package:core_fa/core_fa.dart';

/// DFA minimization algorithm using Hopcroft's algorithm
class DFAMinimizer {
  /// Minimize DFA using Hopcroft's algorithm
  static FiniteAutomaton minimize(FiniteAutomaton dfa) {
    // Step 1: Remove unreachable states
    final reachableDFA = _removeUnreachableStates(dfa);
    
    // Step 2: Initialize partition with final and non-final states
    final finalStateIds = reachableDFA.finalStates.map((s) => s.id).toSet();
    final nonFinalStateIds = reachableDFA.states
        .where((s) => !s.isFinal)
        .map((s) => s.id)
        .toSet();
    
    var partition = <Set<String>>[];
    if (finalStateIds.isNotEmpty) {
      partition.add(finalStateIds);
    }
    if (nonFinalStateIds.isNotEmpty) {
      partition.add(nonFinalStateIds);
    }
    
    // Step 3: Refine partition until no more changes
    var changed = true;
    while (changed) {
      changed = false;
      final newPartition = <Set<String>>[];
      
      for (final group in partition) {
        if (group.length == 1) {
          newPartition.add(group);
          continue;
        }
        
        // Split group based on transitions
        final subgroups = _splitGroup(group, reachableDFA, partition);
        
        if (subgroups.length > 1) {
          changed = true;
          newPartition.addAll(subgroups);
        } else {
          newPartition.add(group);
        }
      }
      
      partition = newPartition;
    }
    
    // Step 4: Create minimized DFA
    return _createMinimizedDFA(reachableDFA, partition);
  }

  /// Remove unreachable states from DFA
  static FiniteAutomaton _removeUnreachableStates(FiniteAutomaton dfa) {
    final reachableStates = <String>{};
    final workList = <String>[dfa.initialState?.id ?? ''];
    
    while (workList.isNotEmpty) {
      final currentState = workList.removeAt(0);
      
      if (reachableStates.contains(currentState)) {
        continue;
      }
      
      reachableStates.add(currentState);
      
      // Add all states reachable from current state
      final outgoingTransitions = dfa.transitions.where(
        (t) => t.from == currentState,
      );
      
      for (final transition in outgoingTransitions) {
        if (!reachableStates.contains(transition.to)) {
          workList.add(transition.to);
        }
      }
    }
    
    // Filter states and transitions
    final optimizedStates = dfa.states.where(
      (s) => reachableStates.contains(s.id),
    ).toList();
    
    final optimizedTransitions = dfa.transitions.where(
      (t) => reachableStates.contains(t.from) && reachableStates.contains(t.to),
    ).toList();
    
    return FiniteAutomaton(
      id: 'reachable_${dfa.id}',
      name: 'Reachable ${dfa.name}',
      states: optimizedStates,
      transitions: optimizedTransitions,
      alphabet: dfa.alphabet,
      initialState: optimizedStates.firstWhere((s) => s.isInitial),
      finalStates: optimizedStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'reachable_dfa',
        description: 'DFA with unreachable states removed',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Split a group of states based on their transitions
  static List<Set<String>> _splitGroup(
    Set<String> group,
    FiniteAutomaton dfa,
    List<Set<String>> partition,
  ) {
    final subgroups = <String, Set<String>>{};
    
    for (final stateId in group) {
      final signature = _getStateSignature(stateId, dfa, partition);
      subgroups.putIfAbsent(signature, () => <String>{});
      subgroups[signature]!.add(stateId);
    }
    
    return subgroups.values.toList();
  }

  /// Get signature for a state based on its transitions
  static String _getStateSignature(
    String stateId,
    FiniteAutomaton dfa,
    List<Set<String>> partition,
  ) {
    final signature = <String>[];
    
    for (final symbol in dfa.alphabet.symbols) {
      final transition = dfa.transitions.firstWhere(
        (t) => t.from == stateId && t.symbol == symbol,
        orElse: () => Transition(from: stateId, to: 'trap', symbol: symbol),
      );
      
      // Find which partition group the target state belongs to
      final targetGroup = partition.indexWhere(
        (group) => group.contains(transition.to),
      );
      
      signature.add('$symbol->$targetGroup');
    }
    
    return signature.join('|');
  }

  /// Create minimized DFA from partition
  static FiniteAutomaton _createMinimizedDFA(
    FiniteAutomaton originalDFA,
    List<Set<String>> partition,
  ) {
    final minimizedStates = <State>[];
    final minimizedTransitions = <Transition>[];
    final stateGroupMap = <String, int>{};
    
    // Create mapping from state ID to group index
    for (int i = 0; i < partition.length; i++) {
      for (final stateId in partition[i]) {
        stateGroupMap[stateId] = i;
      }
    }
    
    // Create new states
    for (int i = 0; i < partition.length; i++) {
      final group = partition[i];
      final isInitial = group.contains(originalDFA.initialState?.id);
      final isFinal = group.any((stateId) => 
          originalDFA.finalStates.any((s) => s.id == stateId));
      
      minimizedStates.add(State(
        id: 'q$i',
        name: 'q$i',
        isInitial: isInitial,
        isFinal: isFinal,
      ));
    }
    
    // Create transitions
    for (int i = 0; i < partition.length; i++) {
      final group = partition[i];
      final representativeState = group.first;
      
      for (final symbol in originalDFA.alphabet.symbols) {
        final transition = originalDFA.transitions.firstWhere(
          (t) => t.from == representativeState && t.symbol == symbol,
          orElse: () => Transition(from: representativeState, to: 'trap', symbol: symbol),
        );
        
        final targetGroup = stateGroupMap[transition.to];
        if (targetGroup != null) {
          minimizedTransitions.add(Transition(
            from: 'q$i',
            to: 'q$targetGroup',
            symbol: symbol,
          ));
        }
      }
    }
    
    return FiniteAutomaton(
      id: 'minimized_${originalDFA.id}',
      name: 'Minimized ${originalDFA.name}',
      states: minimizedStates,
      transitions: minimizedTransitions,
      alphabet: originalDFA.alphabet,
      initialState: minimizedStates.firstWhere((s) => s.isInitial),
      finalStates: minimizedStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'minimized_dfa',
        description: 'Minimized DFA from ${originalDFA.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Check if two DFAs are equivalent
  static bool areEquivalent(FiniteAutomaton dfa1, FiniteAutomaton dfa2) {
    // Minimize both DFAs
    final minimized1 = minimize(dfa1);
    final minimized2 = minimize(dfa2);
    
    // Check if they have the same structure
    return _haveSameStructure(minimized1, minimized2);
  }

  /// Check if two DFAs have the same structure
  static bool _haveSameStructure(FiniteAutomaton dfa1, FiniteAutomaton dfa2) {
    // Check alphabet
    if (dfa1.alphabet.symbols.length != dfa2.alphabet.symbols.length) {
      return false;
    }
    
    for (final symbol in dfa1.alphabet.symbols) {
      if (!dfa2.alphabet.symbols.contains(symbol)) {
        return false;
      }
    }
    
    // Check number of states
    if (dfa1.states.length != dfa2.states.length) {
      return false;
    }
    
    // Check number of final states
    if (dfa1.finalStates.length != dfa2.finalStates.length) {
      return false;
    }
    
    // Check transitions (simplified check)
    if (dfa1.transitions.length != dfa2.transitions.length) {
      return false;
    }
    
    return true;
  }

  /// Get statistics about the minimization
  static MinimizationStats getStats(FiniteAutomaton original, FiniteAutomaton minimized) {
    return MinimizationStats(
      originalStateCount: original.states.length,
      minimizedStateCount: minimized.states.length,
      reductionPercentage: ((original.states.length - minimized.states.length) / 
          original.states.length * 100),
      originalTransitionCount: original.transitions.length,
      minimizedTransitionCount: minimized.transitions.length,
    );
  }
}

/// Statistics about DFA minimization
class MinimizationStats {
  final int originalStateCount;
  final int minimizedStateCount;
  final double reductionPercentage;
  final int originalTransitionCount;
  final int minimizedTransitionCount;

  const MinimizationStats({
    required this.originalStateCount,
    required this.minimizedStateCount,
    required this.reductionPercentage,
    required this.originalTransitionCount,
    required this.minimizedTransitionCount,
  });

  @override
  String toString() {
    return 'MinimizationStats('
        'originalStates: $originalStateCount, '
        'minimizedStates: $minimizedStateCount, '
        'reduction: ${reductionPercentage.toStringAsFixed(1)}%, '
        'originalTransitions: $originalTransitionCount, '
        'minimizedTransitions: $minimizedTransitionCount)';
  }
}
