import 'package:core_fa/core_fa.dart';
import 'package:core_regex/core_regex.dart';

/// FA to Regex conversion using state elimination method
class FAToRegexConverter {
  /// Convert finite automaton to regular expression
  static RegularExpression convert(FiniteAutomaton fa) {
    // Step 1: Ensure DFA
    final dfa = _ensureDFA(fa);
    
    // Step 2: Add new initial and final states
    final augmentedFA = _augmentFA(dfa);
    
    // Step 3: Eliminate states one by one
    final regex = _eliminateStates(augmentedFA);
    
    return RegularExpression(
      id: 'regex_${fa.id}',
      name: 'Regex(${fa.name})',
      pattern: regex,
      alphabet: fa.alphabet,
      metadata: AutomatonMetadata(
        type: 'converted_regex',
        description: 'Regex converted from ${fa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Ensure the automaton is a DFA
  static FiniteAutomaton _ensureDFA(FiniteAutomaton fa) {
    // Check if it's already a DFA
    if (_isDFA(fa)) {
      return fa;
    }
    
    // Convert NFA to DFA using subset construction
    // This would use the NFAToDFAConverter from the previous task
    // For now, return the original FA
    return fa;
  }

  /// Check if automaton is a DFA
  static bool _isDFA(FiniteAutomaton fa) {
    // Check for epsilon transitions
    final hasEpsilonTransitions = fa.transitions.any(
      (t) => t.symbol == Alphabet.epsilon,
    );
    
    if (hasEpsilonTransitions) {
      return false;
    }
    
    // Check for non-deterministic transitions
    final transitionMap = <String, Map<String, String>>{};
    
    for (final transition in fa.transitions) {
      transitionMap.putIfAbsent(transition.from, () => {});
      
      if (transitionMap[transition.from]!.containsKey(transition.symbol)) {
        return false; // Non-deterministic
      }
      
      transitionMap[transition.from]![transition.symbol] = transition.to;
    }
    
    return true;
  }

  /// Augment FA with new initial and final states
  static FiniteAutomaton _augmentFA(FiniteAutomaton fa) {
    final newStates = <State>[];
    final newTransitions = <Transition>[];
    
    // Add new initial state
    final newInitialState = State(
      id: 'new_initial',
      name: 'q0',
      isInitial: true,
      isFinal: false,
    );
    newStates.add(newInitialState);
    
    // Add all original states (remove initial/final flags)
    for (final state in fa.states) {
      newStates.add(State(
        id: state.id,
        name: state.name,
        isInitial: false,
        isFinal: false,
      ));
    }
    
    // Add new final state
    final newFinalState = State(
      id: 'new_final',
      name: 'qf',
      isInitial: false,
      isFinal: true,
    );
    newStates.add(newFinalState);
    
    // Add all original transitions
    newTransitions.addAll(fa.transitions);
    
    // Add epsilon transition from new initial to original initial
    if (fa.initialState != null) {
      newTransitions.add(Transition(
        from: newInitialState.id,
        to: fa.initialState!.id,
        symbol: Alphabet.epsilon,
      ));
    }
    
    // Add epsilon transitions from original final states to new final state
    for (final state in fa.finalStates) {
      newTransitions.add(Transition(
        from: state.id,
        to: newFinalState.id,
        symbol: Alphabet.epsilon,
      ));
    }
    
    return FiniteAutomaton(
      id: 'augmented_${fa.id}',
      name: 'Augmented ${fa.name}',
      states: newStates,
      transitions: newTransitions,
      alphabet: fa.alphabet,
      initialState: newInitialState,
      finalStates: [newFinalState],
      metadata: AutomatonMetadata(
        type: 'augmented_fa',
        description: 'Augmented FA from ${fa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Eliminate states using state elimination method
  static String _eliminateStates(FiniteAutomaton fa) {
    final states = List<String>.from(fa.states.map((s) => s.id));
    final transitions = <String, Map<String, String>>{};
    
    // Initialize transition map
    for (final state in states) {
      transitions[state] = {};
    }
    
    // Add transitions
    for (final transition in fa.transitions) {
      final from = transition.from;
      final to = transition.to;
      final symbol = transition.symbol;
      
      if (transitions[from]!.containsKey(to)) {
        // Multiple transitions between same states
        final existing = transitions[from]![to]!;
        transitions[from]![to] = '($existing|$symbol)';
      } else {
        transitions[from]![to] = symbol;
      }
    }
    
    // Eliminate states one by one (except initial and final)
    final initialState = fa.initialState?.id;
    final finalState = fa.finalStates.first.id;
    
    for (final state in states) {
      if (state == initialState || state == finalState) {
        continue;
      }
      
      _eliminateState(transitions, state);
    }
    
    // Get the final regex
    return transitions[initialState]![finalState] ?? '';
  }

  /// Eliminate a specific state
  static void _eliminateState(Map<String, Map<String, String>> transitions, String state) {
    // Find all incoming and outgoing transitions
    final incoming = <String>[];
    final outgoing = <String>[];
    
    for (final fromState in transitions.keys) {
      if (transitions[fromState]!.containsKey(state)) {
        incoming.add(fromState);
      }
    }
    
    for (final toState in transitions[state]!.keys) {
      outgoing.add(toState);
    }
    
    // Add self-loop if exists
    final selfLoop = transitions[state]![state];
    final selfLoopRegex = selfLoop != null ? '($selfLoop)*' : '';
    
    // Create new transitions
    for (final fromState in incoming) {
      for (final toState in outgoing) {
        final fromToState = transitions[fromState]![state]!;
        final stateToTo = transitions[state]![toState]!;
        
        final newTransition = '$fromToState$selfLoopRegex$stateToTo';
        
        if (transitions[fromState]!.containsKey(toState)) {
          // Multiple paths between same states
          final existing = transitions[fromState]![toState]!;
          transitions[fromState]![toState] = '($existing|$newTransition)';
        } else {
          transitions[fromState]![toState] = newTransition;
        }
      }
    }
    
    // Remove the eliminated state
    transitions.remove(state);
    for (final stateTransitions in transitions.values) {
      stateTransitions.remove(state);
    }
  }

  /// Convert FA to regex using Arden's method
  static RegularExpression convertUsingArdensMethod(FiniteAutomaton fa) {
    // This is an alternative method using Arden's lemma
    // For now, return a placeholder
    return RegularExpression(
      id: 'regex_arden_${fa.id}',
      name: 'Regex(Arden)(${fa.name})',
      pattern: 'placeholder',
      alphabet: fa.alphabet,
      metadata: AutomatonMetadata(
        type: 'arden_regex',
        description: 'Regex using Arden\'s method from ${fa.name}',
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Simplify regex expression
  static String simplifyRegex(String regex) {
    // Remove unnecessary parentheses
    String result = regex;
    
    // Remove empty string concatenations
    result = result.replaceAll('ε', '');
    result = result.replaceAll('∅', '');
    
    // Simplify union with empty string
    result = result.replaceAll('(|', '(');
    result = result.replaceAll('|)', ')');
    
    // Remove redundant parentheses
    result = _removeRedundantParentheses(result);
    
    return result;
  }

  /// Remove redundant parentheses from regex
  static String _removeRedundantParentheses(String regex) {
    // This is a simplified implementation
    // In practice, you would need a more sophisticated parser
    String result = regex;
    
    // Remove outer parentheses if they wrap the entire expression
    if (result.startsWith('(') && result.endsWith(')')) {
      final inner = result.substring(1, result.length - 1);
      if (_isBalanced(inner)) {
        result = inner;
      }
    }
    
    return result;
  }

  /// Check if parentheses are balanced
  static bool _isBalanced(String str) {
    int count = 0;
    for (int i = 0; i < str.length; i++) {
      if (str[i] == '(') {
        count++;
      } else if (str[i] == ')') {
        count--;
        if (count < 0) return false;
      }
    }
    return count == 0;
  }

  /// Get regex statistics
  static RegexStats getStats(FiniteAutomaton fa, String regex) {
    return RegexStats(
      originalStateCount: fa.states.length,
      originalTransitionCount: fa.transitions.length,
      regexLength: regex.length,
      alphabetSize: fa.alphabet.symbols.length,
    );
  }
}

/// Statistics about FA to regex conversion
class RegexStats {
  final int originalStateCount;
  final int originalTransitionCount;
  final int regexLength;
  final int alphabetSize;

  const RegexStats({
    required this.originalStateCount,
    required this.originalTransitionCount,
    required this.regexLength,
    required this.alphabetSize,
  });

  @override
  String toString() {
    return 'RegexStats('
        'states: $originalStateCount, '
        'transitions: $originalTransitionCount, '
        'regexLength: $regexLength, '
        'alphabetSize: $alphabetSize)';
  }
}
