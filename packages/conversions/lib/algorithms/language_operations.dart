import 'package:core_fa/core_fa.dart';

/// Language operation algorithms for finite automata
class LanguageOperations {
  /// Union of two finite automata (L1 ∪ L2)
  static FiniteAutomaton union(
    FiniteAutomaton fa1,
    FiniteAutomaton fa2,
  ) {
    // Create new states with unique IDs
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add all states from both automata with prefixed IDs
    for (final state in fa1.states) {
      newStates.add(State(
        id: 'fa1_${state.id}',
        name: '${state.name}_1',
        isInitial: false,
        isFinal: state.isFinal,
      ));
    }
    
    for (final state in fa2.states) {
      newStates.add(State(
        id: 'fa2_${state.id}',
        name: '${state.name}_2',
        isInitial: false,
        isFinal: state.isFinal,
      ));
    }
    
    // Add new initial state
    final newInitialState = State(
      id: 'union_initial',
      name: 'q0',
      isInitial: true,
      isFinal: false,
    );
    newStates.add(newInitialState);
    
    // Add new final state
    final newFinalState = State(
      id: 'union_final',
      name: 'qf',
      isInitial: false,
      isFinal: true,
    );
    newStates.add(newFinalState);
    
    // Add transitions from new initial state to original initial states
    if (fa1.initialState != null) {
      newTransitions.add(Transition(
        from: newInitialState.id,
        to: 'fa1_${fa1.initialState!.id}',
        symbol: Alphabet.epsilon,
      ));
    }
    
    if (fa2.initialState != null) {
      newTransitions.add(Transition(
        from: newInitialState.id,
        to: 'fa2_${fa2.initialState!.id}',
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Add all original transitions with prefixed IDs
    for (final transition in fa1.transitions) {
      newTransitions.add(Transition(
        from: 'fa1_${transition.from}',
        to: 'fa1_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    for (final transition in fa2.transitions) {
      newTransitions.add(Transition(
        from: 'fa2_${transition.from}',
        to: 'fa2_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add transitions from original final states to new final state
    for (final state in fa1.states.where((s) => s.isFinal)) {
      newTransitions.add(Transition(
        from: 'fa1_${state.id}',
        to: newFinalState.id,
        symbol: Alphabet.epsilon,
      ));
    }
    
    for (final state in fa2.states.where((s) => s.isFinal)) {
      newTransitions.add(Transition(
        from: 'fa2_${state.id}',
        to: newFinalState.id,
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Create combined alphabet
    final combinedAlphabet = Alphabet(
      symbols: {...fa1.alphabet.symbols, ...fa2.alphabet.symbols},
    );
    
    return FiniteAutomaton(
      id: 'union_${fa1.id}_${fa2.id}',
      name: '${fa1.name} ∪ ${fa2.name}',
      states: newStates,
      transitions: newTransitions,
      alphabet: combinedAlphabet,
      initialState: newInitialState,
      finalStates: [newFinalState],
      metadata: AutomatonMetadata(
        type: 'union',
        description: 'Union of ${fa1.name} and ${fa2.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Intersection of two finite automata (L1 ∩ L2)
  static FiniteAutomaton intersection(
    FiniteAutomaton fa1,
    FiniteAutomaton fa2,
  ) {
    // Convert both automata to DFA first
    final dfa1 = _toDFA(fa1);
    final dfa2 = _toDFA(fa2);
    
    // Create product automaton
    final productStates = <String, State>{};
    final productTransitions = <Transition>[];
    final productAlphabet = Alphabet(
      symbols: {...dfa1.alphabet.symbols, ...dfa2.alphabet.symbols},
    );
    
    // Create states for all pairs (q1, q2) where q1 ∈ Q1, q2 ∈ Q2
    for (final state1 in dfa1.states) {
      for (final state2 in dfa2.states) {
        final stateId = '(${state1.id},${state2.id})';
        final isInitial = state1.isInitial && state2.isInitial;
        final isFinal = state1.isFinal && state2.isFinal;
        
        productStates[stateId] = State(
          id: stateId,
          name: '(${state1.name},${state2.name})',
          isInitial: isInitial,
          isFinal: isFinal,
        );
      }
    }
    
    // Create transitions for the product automaton
    for (final state1 in dfa1.states) {
      for (final state2 in dfa2.states) {
        final fromId = '(${state1.id},${state2.id})';
        
        for (final symbol in productAlphabet.symbols) {
          final transition1 = dfa1.transitions.firstWhere(
            (t) => t.from == state1.id && t.symbol == symbol,
            orElse: () => Transition(from: state1.id, to: 'trap', symbol: symbol),
          );
          
          final transition2 = dfa2.transitions.firstWhere(
            (t) => t.from == state2.id && t.symbol == symbol,
            orElse: () => Transition(from: state2.id, to: 'trap', symbol: symbol),
          );
          
          final toId = '(${transition1.to},${transition2.to})';
          productTransitions.add(Transition(
            from: fromId,
            to: toId,
            symbol: symbol,
          ));
        }
      }
    }
    
    return FiniteAutomaton(
      id: 'intersection_${fa1.id}_${fa2.id}',
      name: '${fa1.name} ∩ ${fa2.name}',
      states: productStates.values.toList(),
      transitions: productTransitions,
      alphabet: productAlphabet,
      initialState: productStates.values.firstWhere((s) => s.isInitial),
      finalStates: productStates.values.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'intersection',
        description: 'Intersection of ${fa1.name} and ${fa2.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Complement of a finite automaton (L̄)
  static FiniteAutomaton complement(FiniteAutomaton fa) {
    // Convert to DFA first
    final dfa = _toDFA(fa);
    
    // Create new states with complemented final states
    final newStates = dfa.states.map((state) => State(
      id: state.id,
      name: state.name,
      isInitial: state.isInitial,
      isFinal: !state.isFinal, // Complement final states
    )).toList();
    
    return FiniteAutomaton(
      id: 'complement_${fa.id}',
      name: '¬${fa.name}',
      states: newStates,
      transitions: dfa.transitions,
      alphabet: dfa.alphabet,
      initialState: newStates.firstWhere((s) => s.isInitial),
      finalStates: newStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'complement',
        description: 'Complement of ${fa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Concatenation of two finite automata (L1 · L2)
  static FiniteAutomaton concatenation(
    FiniteAutomaton fa1,
    FiniteAutomaton fa2,
  ) {
    // Create new states with unique IDs
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add all states from both automata with prefixed IDs
    for (final state in fa1.states) {
      newStates.add(State(
        id: 'fa1_${state.id}',
        name: '${state.name}_1',
        isInitial: state.isInitial,
        isFinal: false, // No final states from fa1
      ));
    }
    
    for (final state in fa2.states) {
      newStates.add(State(
        id: 'fa2_${state.id}',
        name: '${state.name}_2',
        isInitial: false, // No initial states from fa2
        isFinal: state.isFinal,
      ));
    }
    
    // Add all original transitions with prefixed IDs
    for (final transition in fa1.transitions) {
      newTransitions.add(Transition(
        from: 'fa1_${transition.from}',
        to: 'fa1_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    for (final transition in fa2.transitions) {
      newTransitions.add(Transition(
        from: 'fa2_${transition.from}',
        to: 'fa2_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add epsilon transitions from fa1 final states to fa2 initial state
    if (fa2.initialState != null) {
      for (final state in fa1.states.where((s) => s.isFinal)) {
        newTransitions.add(Transition(
          from: 'fa1_${state.id}',
          to: 'fa2_${fa2.initialState!.id}',
          symbol: Alphabet.epsilon,
        ));
      }
    }
    
    // Create combined alphabet
    final combinedAlphabet = Alphabet(
      symbols: {...fa1.alphabet.symbols, ...fa2.alphabet.symbols},
    );
    
    return FiniteAutomaton(
      id: 'concatenation_${fa1.id}_${fa2.id}',
      name: '${fa1.name} · ${fa2.name}',
      states: newStates,
      transitions: newTransitions,
      alphabet: combinedAlphabet,
      initialState: newStates.firstWhere((s) => s.isInitial),
      finalStates: newStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'concatenation',
        description: 'Concatenation of ${fa1.name} and ${fa2.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Kleene star of a finite automaton (L*)
  static FiniteAutomaton kleeneStar(FiniteAutomaton fa) {
    // Create new states with unique IDs
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add all original states
    for (final state in fa.states) {
      newStates.add(State(
        id: 'star_${state.id}',
        name: '${state.name}',
        isInitial: false,
        isFinal: state.isFinal,
      ));
    }
    
    // Add new initial state
    final newInitialState = State(
      id: 'star_initial',
      name: 'q0',
      isInitial: true,
      isFinal: true, // Accept empty string
    );
    newStates.add(newInitialState);
    
    // Add all original transitions with prefixed IDs
    for (final transition in fa.transitions) {
      newTransitions.add(Transition(
        from: 'star_${transition.from}',
        to: 'star_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add epsilon transition from new initial state to original initial state
    if (fa.initialState != null) {
      newTransitions.add(Transition(
        from: newInitialState.id,
        to: 'star_${fa.initialState!.id}',
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Add epsilon transitions from original final states to original initial state
    if (fa.initialState != null) {
      for (final state in fa.states.where((s) => s.isFinal)) {
        newTransitions.add(Transition(
          from: 'star_${state.id}',
          to: 'star_${fa.initialState!.id}',
          symbol: Alphabet.epsilon,
        ));
      }
    }
    
    return FiniteAutomaton(
      id: 'kleene_star_${fa.id}',
      name: '${fa.name}*',
      states: newStates,
      transitions: newTransitions,
      alphabet: fa.alphabet,
      initialState: newInitialState,
      finalStates: newStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'kleene_star',
        description: 'Kleene star of ${fa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Helper method to convert NFA to DFA (simplified version)
  static FiniteAutomaton _toDFA(FiniteAutomaton nfa) {
    // This is a simplified implementation
    // In practice, you would use the NFA to DFA conversion algorithm
    return nfa;
  }
}
