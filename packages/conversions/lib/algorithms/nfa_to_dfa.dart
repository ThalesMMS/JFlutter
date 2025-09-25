import 'package:core_fa/core_fa.dart';

/// NFA to DFA conversion algorithm using subset construction
class NFAToDFAConverter {
  /// Convert NFA to DFA using subset construction
  static FiniteAutomaton convert(FiniteAutomaton nfa) {
    // Step 1: Compute epsilon closure of initial state
    final initialState = nfa.initialState;
    if (initialState == null) {
      throw ArgumentError('NFA must have an initial state');
    }
    
    final initialEpsilonClosure = _epsilonClosure(nfa, {initialState.id});
    
    // Step 2: Initialize work list with initial state set
    final workList = <Set<String>>[initialEpsilonClosure];
    final processedStates = <Set<String>>{};
    final dfaStates = <String, State>{};
    final dfaTransitions = <Transition>[];
    
    // Create initial DFA state
    final initialStateId = _stateSetToId(initialEpsilonClosure);
    dfaStates[initialStateId] = State(
      id: initialStateId,
      name: _stateSetToName(initialEpsilonClosure),
      isInitial: true,
      isFinal: _containsFinalState(nfa, initialEpsilonClosure),
    );
    
    // Step 3: Process each state set in work list
    while (workList.isNotEmpty) {
      final currentStateSet = workList.removeAt(0);
      
      if (processedStates.contains(currentStateSet)) {
        continue;
      }
      
      processedStates.add(currentStateSet);
      
      // For each symbol in alphabet (excluding epsilon)
      for (final symbol in nfa.alphabet.symbols.where((s) => s != Alphabet.epsilon)) {
        // Compute move(currentStateSet, symbol)
        final moveResult = _move(nfa, currentStateSet, symbol);
        
        if (moveResult.isNotEmpty) {
          // Compute epsilon closure of move result
          final epsilonClosure = _epsilonClosure(nfa, moveResult);
          
          if (epsilonClosure.isNotEmpty) {
            final newStateId = _stateSetToId(epsilonClosure);
            
            // Add new state if not already exists
            if (!dfaStates.containsKey(newStateId)) {
              dfaStates[newStateId] = State(
                id: newStateId,
                name: _stateSetToName(epsilonClosure),
                isInitial: false,
                isFinal: _containsFinalState(nfa, epsilonClosure),
              );
              
              // Add to work list
              workList.add(epsilonClosure);
            }
            
            // Add transition
            dfaTransitions.add(Transition(
              from: _stateSetToId(currentStateSet),
              to: newStateId,
              symbol: symbol,
            ));
          }
        }
      }
    }
    
    // Step 4: Create DFA
    return FiniteAutomaton(
      id: 'dfa_${nfa.id}',
      name: 'DFA(${nfa.name})',
      states: dfaStates.values.toList(),
      transitions: dfaTransitions,
      alphabet: Alphabet(
        symbols: nfa.alphabet.symbols.where((s) => s != Alphabet.epsilon).toSet(),
      ),
      initialState: dfaStates.values.firstWhere((s) => s.isInitial),
      finalStates: dfaStates.values.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'dfa',
        description: 'DFA converted from ${nfa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Compute epsilon closure of a set of states
  static Set<String> _epsilonClosure(FiniteAutomaton nfa, Set<String> stateIds) {
    final closure = <String>{...stateIds};
    final workList = <String>[...stateIds];
    
    while (workList.isNotEmpty) {
      final currentState = workList.removeAt(0);
      
      // Find all epsilon transitions from current state
      final epsilonTransitions = nfa.transitions.where(
        (t) => t.from == currentState && t.symbol == Alphabet.epsilon,
      );
      
      for (final transition in epsilonTransitions) {
        if (!closure.contains(transition.to)) {
          closure.add(transition.to);
          workList.add(transition.to);
        }
      }
    }
    
    return closure;
  }

  /// Compute move function for a set of states and symbol
  static Set<String> _move(FiniteAutomaton nfa, Set<String> stateIds, String symbol) {
    final result = <String>{};
    
    for (final stateId in stateIds) {
      final transitions = nfa.transitions.where(
        (t) => t.from == stateId && t.symbol == symbol,
      );
      
      for (final transition in transitions) {
        result.add(transition.to);
      }
    }
    
    return result;
  }

  /// Check if a state set contains any final state
  static bool _containsFinalState(FiniteAutomaton nfa, Set<String> stateIds) {
    final finalStateIds = nfa.finalStates.map((s) => s.id).toSet();
    return stateIds.any((id) => finalStateIds.contains(id));
  }

  /// Convert state set to unique ID
  static String _stateSetToId(Set<String> stateIds) {
    final sortedIds = stateIds.toList()..sort();
    return '{${sortedIds.join(',')}}';
  }

  /// Convert state set to readable name
  static String _stateSetToName(Set<String> stateIds) {
    if (stateIds.isEmpty) return '∅';
    if (stateIds.length == 1) return 'q${stateIds.first}';
    return 'q{${stateIds.join(',')}}';
  }

  /// Optimize DFA by removing unreachable states
  static FiniteAutomaton optimize(FiniteAutomaton dfa) {
    // Find reachable states
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
      id: 'optimized_${dfa.id}',
      name: 'Optimized ${dfa.name}',
      states: optimizedStates,
      transitions: optimizedTransitions,
      alphabet: dfa.alphabet,
      initialState: optimizedStates.firstWhere((s) => s.isInitial),
      finalStates: optimizedStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'optimized_dfa',
        description: 'Optimized DFA from ${dfa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }
}
