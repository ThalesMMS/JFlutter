import 'package:core_fa/core_fa.dart';
import 'package:core_regex/core_regex.dart';

/// Regex to NFA conversion using Thompson's construction
class RegexToNFAConverter {
  /// Convert regular expression to NFA using Thompson's construction
  static FiniteAutomaton convert(RegularExpression regex) {
    final nfa = _buildNFAFromAST(regex.ast);
    
    return FiniteAutomaton(
      id: 'nfa_${regex.id}',
      name: 'NFA(${regex.name})',
      states: nfa.states,
      transitions: nfa.transitions,
      alphabet: nfa.alphabet,
      initialState: nfa.initialState,
      finalStates: nfa.finalStates,
      metadata: AutomatonMetadata(
        type: 'regex_nfa',
        description: 'NFA from regex ${regex.pattern}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Build NFA from AST using Thompson's construction
  static FiniteAutomaton _buildNFAFromAST(RegexAST ast) {
    switch (ast.type) {
      case RegexASTType.symbol:
        return _buildSymbolNFA(ast.symbol!);
      case RegexASTType.epsilon:
        return _buildEpsilonNFA();
      case RegexASTType.union:
        return _buildUnionNFA(
          _buildNFAFromAST(ast.left!),
          _buildNFAFromAST(ast.right!),
        );
      case RegexASTType.concatenation:
        return _buildConcatenationNFA(
          _buildNFAFromAST(ast.left!),
          _buildNFAFromAST(ast.right!),
        );
      case RegexASTType.kleeneStar:
        return _buildKleeneStarNFA(_buildNFAFromAST(ast.child!));
      case RegexASTType.plus:
        return _buildPlusNFA(_buildNFAFromAST(ast.child!));
      case RegexASTType.question:
        return _buildQuestionNFA(_buildNFAFromAST(ast.child!));
      default:
        throw ArgumentError('Unsupported AST type: ${ast.type}');
    }
  }

  /// Build NFA for a single symbol
  static FiniteAutomaton _buildSymbolNFA(String symbol) {
    final state1 = State(
      id: 'q0',
      name: 'q0',
      isInitial: true,
      isFinal: false,
    );
    
    final state2 = State(
      id: 'q1',
      name: 'q1',
      isInitial: false,
      isFinal: true,
    );
    
    final transition = Transition(
      from: state1.id,
      to: state2.id,
      symbol: symbol,
    );
    
    return FiniteAutomaton(
      id: 'symbol_$symbol',
      name: 'Symbol($symbol)',
      states: [state1, state2],
      transitions: [transition],
      alphabet: Alphabet(symbols: {symbol}),
      initialState: state1,
      finalStates: [state2],
      metadata: AutomatonMetadata(
        type: 'symbol_nfa',
        description: 'NFA for symbol $symbol',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Build NFA for epsilon
  static FiniteAutomaton _buildEpsilonNFA() {
    final state = State(
      id: 'q0',
      name: 'q0',
      isInitial: true,
      isFinal: true,
    );
    
    return FiniteAutomaton(
      id: 'epsilon',
      name: 'Epsilon',
      states: [state],
      transitions: [],
      alphabet: Alphabet(symbols: {}),
      initialState: state,
      finalStates: [state],
      metadata: AutomatonMetadata(
        type: 'epsilon_nfa',
        description: 'NFA for epsilon',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Build NFA for union (A | B)
  static FiniteAutomaton _buildUnionNFA(FiniteAutomaton nfa1, FiniteAutomaton nfa2) {
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add new initial state
    final initialState = State(
      id: 'union_initial',
      name: 'q0',
      isInitial: true,
      isFinal: false,
    );
    newStates.add(initialState);
    
    // Add states from nfa1 with prefixed IDs
    for (final state in nfa1.states) {
      newStates.add(State(
        id: 'nfa1_${state.id}',
        name: '${state.name}_1',
        isInitial: false,
        isFinal: state.isFinal,
      ));
    }
    
    // Add states from nfa2 with prefixed IDs
    for (final state in nfa2.states) {
      newStates.add(State(
        id: 'nfa2_${state.id}',
        name: '${state.name}_2',
        isInitial: false,
        isFinal: state.isFinal,
      ));
    }
    
    // Add new final state
    final finalState = State(
      id: 'union_final',
      name: 'qf',
      isInitial: false,
      isFinal: true,
    );
    newStates.add(finalState);
    
    // Add epsilon transitions from initial state to both NFAs
    if (nfa1.initialState != null) {
      newTransitions.add(Transition(
        from: initialState.id,
        to: 'nfa1_${nfa1.initialState!.id}',
        symbol: Alphabet.epsilon,
      ));
    }
    
    if (nfa2.initialState != null) {
      newTransitions.add(Transition(
        from: initialState.id,
        to: 'nfa2_${nfa2.initialState!.id}',
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Add all transitions from nfa1
    for (final transition in nfa1.transitions) {
      newTransitions.add(Transition(
        from: 'nfa1_${transition.from}',
        to: 'nfa1_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add all transitions from nfa2
    for (final transition in nfa2.transitions) {
      newTransitions.add(Transition(
        from: 'nfa2_${transition.from}',
        to: 'nfa2_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add epsilon transitions from final states to new final state
    for (final state in nfa1.states.where((s) => s.isFinal)) {
      newTransitions.add(Transition(
        from: 'nfa1_${state.id}',
        to: finalState.id,
        symbol: Alphabet.epsilon,
      ));
    }
    
    for (final state in nfa2.states.where((s) => s.isFinal)) {
      newTransitions.add(Transition(
        from: 'nfa2_${state.id}',
        to: finalState.id,
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Create combined alphabet
    final combinedAlphabet = Alphabet(
      symbols: {...nfa1.alphabet.symbols, ...nfa2.alphabet.symbols},
    );
    
    return FiniteAutomaton(
      id: 'union_${nfa1.id}_${nfa2.id}',
      name: 'Union(${nfa1.name}, ${nfa2.name})',
      states: newStates,
      transitions: newTransitions,
      alphabet: combinedAlphabet,
      initialState: initialState,
      finalStates: [finalState],
      metadata: AutomatonMetadata(
        type: 'union_nfa',
        description: 'Union of ${nfa1.name} and ${nfa2.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Build NFA for concatenation (A · B)
  static FiniteAutomaton _buildConcatenationNFA(FiniteAutomaton nfa1, FiniteAutomaton nfa2) {
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add states from nfa1 with prefixed IDs
    for (final state in nfa1.states) {
      newStates.add(State(
        id: 'nfa1_${state.id}',
        name: '${state.name}_1',
        isInitial: state.isInitial,
        isFinal: false, // No final states from nfa1
      ));
    }
    
    // Add states from nfa2 with prefixed IDs
    for (final state in nfa2.states) {
      newStates.add(State(
        id: 'nfa2_${state.id}',
        name: '${state.name}_2',
        isInitial: false, // No initial states from nfa2
        isFinal: state.isFinal,
      ));
    }
    
    // Add all transitions from nfa1
    for (final transition in nfa1.transitions) {
      newTransitions.add(Transition(
        from: 'nfa1_${transition.from}',
        to: 'nfa1_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add all transitions from nfa2
    for (final transition in nfa2.transitions) {
      newTransitions.add(Transition(
        from: 'nfa2_${transition.from}',
        to: 'nfa2_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add epsilon transitions from nfa1 final states to nfa2 initial state
    if (nfa2.initialState != null) {
      for (final state in nfa1.states.where((s) => s.isFinal)) {
        newTransitions.add(Transition(
          from: 'nfa1_${state.id}',
          to: 'nfa2_${nfa2.initialState!.id}',
          symbol: Alphabet.epsilon,
        ));
      }
    }
    
    // Create combined alphabet
    final combinedAlphabet = Alphabet(
      symbols: {...nfa1.alphabet.symbols, ...nfa2.alphabet.symbols},
    );
    
    return FiniteAutomaton(
      id: 'concat_${nfa1.id}_${nfa2.id}',
      name: 'Concat(${nfa1.name}, ${nfa2.name})',
      states: newStates,
      transitions: newTransitions,
      alphabet: combinedAlphabet,
      initialState: newStates.firstWhere((s) => s.isInitial),
      finalStates: newStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'concat_nfa',
        description: 'Concatenation of ${nfa1.name} and ${nfa2.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Build NFA for Kleene star (A*)
  static FiniteAutomaton _buildKleeneStarNFA(FiniteAutomaton nfa) {
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add new initial state
    final initialState = State(
      id: 'star_initial',
      name: 'q0',
      isInitial: true,
      isFinal: true, // Accept empty string
    );
    newStates.add(initialState);
    
    // Add states from original NFA with prefixed IDs
    for (final state in nfa.states) {
      newStates.add(State(
        id: 'star_${state.id}',
        name: '${state.name}',
        isInitial: false,
        isFinal: state.isFinal,
      ));
    }
    
    // Add all transitions from original NFA
    for (final transition in nfa.transitions) {
      newTransitions.add(Transition(
        from: 'star_${transition.from}',
        to: 'star_${transition.to}',
        symbol: transition.symbol,
      ));
    }
    
    // Add epsilon transition from initial state to original initial state
    if (nfa.initialState != null) {
      newTransitions.add(Transition(
        from: initialState.id,
        to: 'star_${nfa.initialState!.id}',
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Add epsilon transitions from original final states to original initial state
    if (nfa.initialState != null) {
      for (final state in nfa.states.where((s) => s.isFinal)) {
        newTransitions.add(Transition(
          from: 'star_${state.id}',
          to: 'star_${nfa.initialState!.id}',
          symbol: Alphabet.epsilon,
        ));
      }
    }
    
    return FiniteAutomaton(
      id: 'star_${nfa.id}',
      name: 'Star(${nfa.name})',
      states: newStates,
      transitions: newTransitions,
      alphabet: nfa.alphabet,
      initialState: initialState,
      finalStates: newStates.where((s) => s.isFinal).toList(),
      metadata: AutomatonMetadata(
        type: 'star_nfa',
        description: 'Kleene star of ${nfa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Build NFA for plus (A+)
  static FiniteAutomaton _buildPlusNFA(FiniteAutomaton nfa) {
    // A+ = A · A*
    final starNFA = _buildKleeneStarNFA(nfa);
    return _buildConcatenationNFA(nfa, starNFA);
  }

  /// Build NFA for question (A?)
  static FiniteAutomaton _buildQuestionNFA(FiniteAutomaton nfa) {
    // A? = A | ε
    final epsilonNFA = _buildEpsilonNFA();
    return _buildUnionNFA(nfa, epsilonNFA);
  }
}
