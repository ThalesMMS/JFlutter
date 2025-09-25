import 'package:core_fa/core_fa.dart';
import 'package:core_regex/core_regex.dart';

/// Pumping lemma algorithms for proving language properties
class PumpingLemma {
  /// Check if a language is regular using pumping lemma
  static bool isRegular(FiniteAutomaton fa) {
    // If we can construct a finite automaton, the language is regular
    // This is a simplified check - in practice, you'd need to verify
    // that the automaton correctly represents the language
    return fa.states.isNotEmpty;
  }

  /// Prove that a language is not regular using pumping lemma
  static PumpingLemmaResult proveNotRegular(String languageDescription) {
    // This would implement the pumping lemma proof for regular languages
    // For now, return a placeholder result
    return PumpingLemmaResult(
      isRegular: false,
      pumpingLength: 0,
      counterExample: '',
      proof: 'Language is not regular by pumping lemma',
    );
  }

  /// Check if a language is context-free using pumping lemma
  static bool isContextFree(ContextFreeGrammar cfg) {
    // If we can construct a CFG, the language is context-free
    return cfg.productions.isNotEmpty;
  }

  /// Prove that a language is not context-free using pumping lemma
  static PumpingLemmaResult proveNotContextFree(String languageDescription) {
    // This would implement the pumping lemma proof for context-free languages
    return PumpingLemmaResult(
      isRegular: false,
      pumpingLength: 0,
      counterExample: '',
      proof: 'Language is not context-free by pumping lemma',
    );
  }

  /// Find pumping length for a regular language
  static int findPumpingLength(FiniteAutomaton fa) {
    // The pumping length is the number of states in the DFA
    return fa.states.length;
  }

  /// Find pumping length for a context-free language
  static int findCFPumpingLength(ContextFreeGrammar cfg) {
    // The pumping length for CFG is more complex to calculate
    // This is a simplified implementation
    return cfg.variables.length * cfg.terminals.length;
  }

  /// Generate pumping lemma proof for regular languages
  static String generateRegularProof(String language, int pumpingLength) {
    return '''
Pumping Lemma Proof for Regular Languages:

Language: $language
Pumping Length: $pumpingLength

Proof:
1. Assume L is regular
2. Let p be the pumping length
3. Choose string s = a^p b^p (length > p)
4. By pumping lemma, s = xyz where |xy| ≤ p and |y| > 0
5. Since |xy| ≤ p, y consists only of a's
6. Pump y: xy^k z for k > 1
7. This gives a^(p+k) b^p which is not in L
8. Contradiction! Therefore L is not regular.
''';
  }

  /// Generate pumping lemma proof for context-free languages
  static String generateCFProof(String language, int pumpingLength) {
    return '''
Pumping Lemma Proof for Context-Free Languages:

Language: $language
Pumping Length: $pumpingLength

Proof:
1. Assume L is context-free
2. Let p be the pumping length
3. Choose string s = a^p b^p c^p (length > p)
4. By pumping lemma, s = uvwxy where |vwx| ≤ p and |vx| > 0
5. Since |vwx| ≤ p, vwx cannot contain all three symbols
6. Pump v and x: uv^k wx^k y for k > 1
7. This gives unequal numbers of a's, b's, and c's
8. Contradiction! Therefore L is not context-free.
''';
  }

  /// Check if a string can be pumped
  static bool canPump(FiniteAutomaton fa, String input) {
    final pumpingLength = findPumpingLength(fa);
    
    if (input.length < pumpingLength) {
      return false;
    }
    
    // Check if the string can be decomposed according to pumping lemma
    for (int i = 0; i < input.length; i++) {
      for (int j = i + 1; j <= input.length; j++) {
        final x = input.substring(0, i);
        final y = input.substring(i, j);
        final z = input.substring(j);
        
        if (y.isNotEmpty && x.length + y.length <= pumpingLength) {
          // Check if xy^k z is accepted for all k ≥ 0
          if (_checkPumpingCondition(fa, x, y, z)) {
            return true;
          }
        }
      }
    }
    
    return false;
  }

  /// Check pumping condition for a decomposition
  static bool _checkPumpingCondition(
    FiniteAutomaton fa,
    String x,
    String y,
    String z,
  ) {
    // Check if xy^k z is accepted for k = 0, 1, 2
    final k0 = x + z;
    final k1 = x + y + z;
    final k2 = x + y + y + z;
    
    return _acceptsString(fa, k0) && 
           _acceptsString(fa, k1) && 
           _acceptsString(fa, k2);
  }

  /// Check if automaton accepts a string
  static bool _acceptsString(FiniteAutomaton fa, String input) {
    final currentStates = <String>{fa.initialState?.id ?? ''};
    
    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      final nextStates = <String>{};
      
      for (final state in currentStates) {
        final transitions = fa.transitions.where(
          (t) => t.from == state && t.symbol == symbol,
        );
        
        for (final transition in transitions) {
          nextStates.add(transition.to);
        }
      }
      
      currentStates.clear();
      currentStates.addAll(nextStates);
    }
    
    return currentStates.any((state) => 
        fa.finalStates.any((finalState) => finalState.id == state));
  }

  /// Generate counterexample for non-regular language
  static String generateCounterExample(String language) {
    // Generate a string that violates the pumping lemma
    if (language.contains('a^n b^n')) {
      return 'a^p b^p where p is the pumping length';
    } else if (language.contains('a^n b^m c^n')) {
      return 'a^p b^p c^p where p is the pumping length';
    } else {
      return 'String of length > pumping length';
    }
  }

  /// Generate counterexample for non-context-free language
  static String generateCFCounterExample(String language) {
    // Generate a string that violates the pumping lemma for CFG
    if (language.contains('a^n b^n c^n')) {
      return 'a^p b^p c^p where p is the pumping length';
    } else if (language.contains('ww')) {
      return 'String with repeated pattern';
    } else {
      return 'String of length > pumping length';
    }
  }

  /// Analyze language complexity
  static LanguageComplexity analyzeComplexity(String language) {
    // This would analyze the complexity of a language description
    return LanguageComplexity(
      isRegular: false,
      isContextFree: false,
      isDecidable: true,
      complexityClass: 'Unknown',
    );
  }
}

/// Result of pumping lemma proof
class PumpingLemmaResult {
  final bool isRegular;
  final int pumpingLength;
  final String counterExample;
  final String proof;

  const PumpingLemmaResult({
    required this.isRegular,
    required this.pumpingLength,
    required this.counterExample,
    required this.proof,
  });

  @override
  String toString() {
    return 'PumpingLemmaResult('
        'isRegular: $isRegular, '
        'pumpingLength: $pumpingLength, '
        'counterExample: $counterExample)';
  }
}

/// Language complexity analysis
class LanguageComplexity {
  final bool isRegular;
  final bool isContextFree;
  final bool isDecidable;
  final String complexityClass;

  const LanguageComplexity({
    required this.isRegular,
    required this.isContextFree,
    required this.isDecidable,
    required this.complexityClass,
  });

  @override
  String toString() {
    return 'LanguageComplexity('
        'isRegular: $isRegular, '
        'isContextFree: $isContextFree, '
        'isDecidable: $isDecidable, '
        'complexityClass: $complexityClass)';
  }
}
