import 'automaton.dart';
import 'algorithms.dart' as algo;
import 'dfa_algorithms.dart';
import 'algo_log.dart';

/// Result of an equivalence check between two automata
class EquivalenceResult {
  final bool areEquivalent;
  final String method;
  final String explanation;
  final List<String> counterexampleWords;
  final Map<String, dynamic> additionalData;

  EquivalenceResult({
    required this.areEquivalent,
    required this.method,
    required this.explanation,
    this.counterexampleWords = const [],
    this.additionalData = const {},
  });
}

/// Advanced equivalence checking algorithms for automata
class EquivalenceChecker {
  /// Check if two automata are equivalent using multiple methods
  static EquivalenceResult checkEquivalence(Automaton a, Automaton b) {
    AlgoLog.startAlgo('equivalence', 'Verificação de Equivalência');
    
    // Method 1: Direct language comparison (for DFAs)
    if (a.isDfa && b.isDfa) {
      final directResult = _checkDfaEquivalenceDirect(a, b);
      if (directResult.areEquivalent) {
        return directResult;
      }
    }
    
    // Method 2: Minimization-based comparison
    final minimizationResult = _checkEquivalenceByMinimization(a, b);
    if (minimizationResult.areEquivalent) {
      return minimizationResult;
    }
    
    // Method 3: Structural isomorphism (for DFAs)
    if (a.isDfa && b.isDfa) {
      final isomorphismResult = _checkDfaIsomorphism(a, b);
      if (isomorphismResult.areEquivalent) {
        return isomorphismResult;
      }
    }
    
    // Method 4: Counterexample search
    return _checkEquivalenceByCounterexample(a, b);
  }

  /// Direct DFA equivalence check using product construction
  static EquivalenceResult _checkDfaEquivalenceDirect(Automaton a, Automaton b) {
    AlgoLog.add('Método: Comparação direta de AFDs');
    
    final ad = algo.completeDfa(a);
    final bd = algo.completeDfa(b);
    final sigma = {...ad.alphabet, ...bd.alphabet};
    
    final queue = <MapEntry<String, String>>[];
    final seen = <String>{};
    final counterexamples = <String>[];
    
    String pid(String x, String y) => '($x,$y)';
    
    bool isAccept(String x, String y) {
      final xf = ad.getState(x)?.isFinal ?? false;
      final yf = bd.getState(y)?.isFinal ?? false;
      return (xf && !yf) || (!xf && yf);
    }
    
    final start = MapEntry(ad.initialId ?? '', bd.initialId ?? '');
    queue.add(start);
    seen.add(pid(start.key, start.value));
    
    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      if (isAccept(cur.key, cur.value)) {
        AlgoLog.step('equivalence', 'counterexample', data: {
          'pair': pid(cur.key, cur.value),
        }, highlight: {pid(cur.key, cur.value)});
        
        return EquivalenceResult(
          areEquivalent: false,
          method: 'Comparação Direta de AFDs',
          explanation: 'Encontrado par de estados que diferem na aceitação',
          counterexampleWords: counterexamples,
          additionalData: {
            'distinguishing_pair': pid(cur.key, cur.value),
            'state_a': cur.key,
            'state_b': cur.value,
          },
        );
      }
      
      for (final sym in sigma) {
        final d1 = (ad.transitions['${cur.key}|$sym'] ?? const ['⊥']).first;
        final d2 = (bd.transitions['${cur.value}|$sym'] ?? const ['⊥']).first;
        final id = pid(d1, d2);
        if (seen.add(id)) {
          queue.add(MapEntry(d1, d2));
        }
      }
    }
    
    AlgoLog.step('equivalence', 'equivalent', data: {'method': 'direct'});
    return EquivalenceResult(
      areEquivalent: true,
      method: 'Comparação Direta de AFDs',
      explanation: 'Os autômatos são equivalentes (nenhum par distinguível encontrado)',
    );
  }

  /// Check equivalence by minimizing both automata and comparing
  static EquivalenceResult _checkEquivalenceByMinimization(Automaton a, Automaton b) {
    AlgoLog.add('Método: Comparação por Minimização');
    
    try {
      // Convert to DFAs if needed
      final dfaA = a.isDfa ? a : algo.nfaToDfa(a);
      final dfaB = b.isDfa ? b : algo.nfaToDfa(b);
      
      // Minimize both DFAs
      final minimizedA = minimizeDfa(dfaA);
      final minimizedB = minimizeDfa(dfaB);
      
      AlgoLog.add('AFD A minimizado: ${minimizedA.states.length} estados');
      AlgoLog.add('AFD B minimizado: ${minimizedB.states.length} estados');
      
      // Check if minimized DFAs are isomorphic
      final isomorphismResult = _checkDfaIsomorphism(minimizedA, minimizedB);
      
      if (isomorphismResult.areEquivalent) {
        return EquivalenceResult(
          areEquivalent: true,
          method: 'Comparação por Minimização',
          explanation: 'Os autômatos minimizados são isomorfos',
          additionalData: {
            'minimized_states_a': minimizedA.states.length,
            'minimized_states_b': minimizedB.states.length,
          },
        );
      } else {
        return EquivalenceResult(
          areEquivalent: false,
          method: 'Comparação por Minimização',
          explanation: 'Os autômatos minimizados não são isomorfos',
          additionalData: {
            'minimized_states_a': minimizedA.states.length,
            'minimized_states_b': minimizedB.states.length,
          },
        );
      }
    } catch (e) {
      AlgoLog.add('Erro na minimização: $e');
      return EquivalenceResult(
        areEquivalent: false,
        method: 'Comparação por Minimização',
        explanation: 'Erro durante a minimização: $e',
      );
    }
  }

  /// Check if two DFAs are structurally isomorphic
  static EquivalenceResult _checkDfaIsomorphism(Automaton a, Automaton b) {
    AlgoLog.add('Método: Verificação de Isomorfismo Estrutural');
    
    if (a.states.length != b.states.length) {
      return EquivalenceResult(
        areEquivalent: false,
        method: 'Isomorfismo Estrutural',
        explanation: 'Número diferente de estados (${a.states.length} vs ${b.states.length})',
      );
    }
    
    if (a.alphabet.length != b.alphabet.length) {
      return EquivalenceResult(
        areEquivalent: false,
        method: 'Isomorfismo Estrutural',
        explanation: 'Alfabetos diferentes (${a.alphabet.length} vs ${b.alphabet.length} símbolos)',
      );
    }
    
    // Try to find an isomorphism
    final mapping = <String, String>{};
    final used = <String>{};
    
    bool tryIsomorphism(String stateA, String stateB) {
      if (mapping.containsKey(stateA)) {
        return mapping[stateA] == stateB;
      }
      
      if (used.contains(stateB)) {
        return false;
      }
      
      // Check if finality matches
      final finalA = a.getState(stateA)?.isFinal ?? false;
      final finalB = b.getState(stateB)?.isFinal ?? false;
      if (finalA != finalB) {
        return false;
      }
      
      // Check transitions
      for (final symbol in a.alphabet) {
        final nextA = (a.transitions['$stateA|$symbol'] ?? const []).firstOrNull;
        final nextB = (b.transitions['$stateB|$symbol'] ?? const []).firstOrNull;
        
        if (nextA != null && nextB != null) {
          if (!tryIsomorphism(nextA, nextB)) {
            return false;
          }
        } else if (nextA != null || nextB != null) {
          return false;
        }
      }
      
      mapping[stateA] = stateB;
      used.add(stateB);
      return true;
    }
    
    final initialA = a.initialId;
    final initialB = b.initialId;
    
    if (initialA == null || initialB == null) {
      return EquivalenceResult(
        areEquivalent: false,
        method: 'Isomorfismo Estrutural',
        explanation: 'Um dos autômatos não tem estado inicial',
      );
    }
    
    if (tryIsomorphism(initialA, initialB)) {
      AlgoLog.add('Isomorfismo encontrado: $mapping');
      return EquivalenceResult(
        areEquivalent: true,
        method: 'Isomorfismo Estrutural',
        explanation: 'Os autômatos são estruturalmente isomorfos',
        additionalData: {'isomorphism': mapping},
      );
    } else {
      return EquivalenceResult(
        areEquivalent: false,
        method: 'Isomorfismo Estrutural',
        explanation: 'Não foi possível encontrar um isomorfismo estrutural',
      );
    }
  }

  /// Check equivalence by searching for counterexamples
  static EquivalenceResult _checkEquivalenceByCounterexample(Automaton a, Automaton b) {
    AlgoLog.add('Método: Busca por Contraexemplos');
    
    // Generate test words and check acceptance
    final testWords = _generateTestWords(a, b);
    final counterexamples = <String>[];
    
    for (final word in testWords) {
      final resultA = algo.runWord(a, word);
      final resultB = algo.runWord(b, word);
      
      if (resultA.accepted != resultB.accepted) {
        counterexamples.add(word);
        AlgoLog.step('equivalence', 'counterexample', data: {
          'word': word,
          'accepted_a': resultA.accepted,
          'accepted_b': resultB.accepted,
        });
        
        if (counterexamples.length >= 5) break; // Limit counterexamples
      }
    }
    
    if (counterexamples.isNotEmpty) {
      return EquivalenceResult(
        areEquivalent: false,
        method: 'Busca por Contraexemplos',
        explanation: 'Encontrados ${counterexamples.length} contraexemplos',
        counterexampleWords: counterexamples,
      );
    } else {
      return EquivalenceResult(
        areEquivalent: true,
        method: 'Busca por Contraexemplos',
        explanation: 'Nenhum contraexemplo encontrado nos testes realizados',
        additionalData: {'tested_words': testWords.length},
      );
    }
  }

  /// Generate test words for counterexample search
  static List<String> _generateTestWords(Automaton a, Automaton b) {
    final alphabet = {...a.alphabet, ...b.alphabet};
    final words = <String>[];
    
    // Empty word
    words.add('');
    
    // Single symbols
    for (final symbol in alphabet) {
      words.add(symbol);
    }
    
    // Pairs of symbols
    for (final s1 in alphabet) {
      for (final s2 in alphabet) {
        words.add(s1 + s2);
      }
    }
    
    // Some longer words (up to length 4)
    final random = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < 20; i++) {
      var word = '';
      for (var j = 0; j < 4; j++) {
        final symbol = alphabet.elementAt((random + i + j) % alphabet.length);
        word += symbol;
        words.add(word);
      }
    }
    
    return words.take(100).toList(); // Limit to 100 test words
  }

  /// Check if two automata accept the same language (simplified interface)
  static bool areEquivalent(Automaton a, Automaton b) {
    return checkEquivalence(a, b).areEquivalent;
  }

  /// Get a detailed comparison report between two automata
  static Map<String, dynamic> getComparisonReport(Automaton a, Automaton b) {
    return {
      'automaton_a': {
        'states': a.states.length,
        'alphabet_size': a.alphabet.length,
        'is_dfa': a.isDfa,
        'has_lambda': a.hasLambda,
        'initial_state': a.initialId,
        'final_states': a.states.where((s) => s.isFinal).map((s) => s.id).toList(),
      },
      'automaton_b': {
        'states': b.states.length,
        'alphabet_size': b.alphabet.length,
        'is_dfa': b.isDfa,
        'has_lambda': b.hasLambda,
        'initial_state': b.initialId,
        'final_states': b.states.where((s) => s.isFinal).map((s) => s.id).toList(),
      },
      'equivalence_result': checkEquivalence(a, b),
    };
  }
}
