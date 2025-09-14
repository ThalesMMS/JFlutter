import 'dart:collection';
import 'automaton.dart';
import 'algo_log.dart';

/// Result of automaton analysis
class AnalysisResult {
  final String type;
  final String description;
  final List<String> states;
  final Map<String, dynamic> additionalData;
  
  AnalysisResult({
    required this.type,
    required this.description,
    required this.states,
    this.additionalData = const {},
  });
}

/// Analyzes an automaton for various properties
class AutomatonAnalyzer {
  
  /// Finds unreachable states (states not reachable from initial state)
  static AnalysisResult findUnreachableStates(Automaton automaton) {
    AlgoLog.startAlgo('unreachableStates', 'Análise de Estados Inalcançáveis');
    
    if (automaton.initialId == null) {
      AlgoLog.add('Nenhum estado inicial definido');
      return AnalysisResult(
        type: 'unreachable',
        description: 'Nenhum estado inicial definido',
        states: automaton.states.map((s) => s.id).toList(),
      );
    }
    
    final reachable = _findReachableStates(automaton);
    final unreachable = automaton.states
        .where((s) => !reachable.contains(s.id))
        .map((s) => s.id)
        .toList();
    
    AlgoLog.add('Estados alcançáveis: ${reachable.join(', ')}');
    AlgoLog.add('Estados inalcançáveis: ${unreachable.join(', ')}');
    
    AlgoLog.step('unreachableStates', 'result', data: {
      'reachable': reachable.toList(),
      'unreachable': unreachable,
    });
    
    return AnalysisResult(
      type: 'unreachable',
      description: 'Estados que não são alcançáveis a partir do estado inicial',
      states: unreachable,
      additionalData: {
        'reachable': reachable.toList(),
        'totalStates': automaton.states.length,
      },
    );
  }
  
  /// Finds useless states (states that cannot reach a final state)
  static AnalysisResult findUselessStates(Automaton automaton) {
    AlgoLog.startAlgo('uselessStates', 'Análise de Estados Inúteis');
    
    final finalStates = automaton.states.where((s) => s.isFinal).map((s) => s.id).toSet();
    
    if (finalStates.isEmpty) {
      AlgoLog.add('Nenhum estado final definido - todos os estados são inúteis');
      return AnalysisResult(
        type: 'useless',
        description: 'Nenhum estado final definido',
        states: automaton.states.map((s) => s.id).toList(),
      );
    }
    
    final useful = _findStatesReachingFinal(automaton, finalStates);
    final useless = automaton.states
        .where((s) => !useful.contains(s.id))
        .map((s) => s.id)
        .toList();
    
    AlgoLog.add('Estados úteis: ${useful.join(', ')}');
    AlgoLog.add('Estados inúteis: ${useless.join(', ')}');
    
    AlgoLog.step('uselessStates', 'result', data: {
      'useful': useful.toList(),
      'useless': useless,
    });
    
    return AnalysisResult(
      type: 'useless',
      description: 'Estados que não podem alcançar um estado final',
      states: useless,
      additionalData: {
        'useful': useful.toList(),
        'finalStates': finalStates.toList(),
      },
    );
  }
  
  /// Detects nondeterminism in the automaton
  static AnalysisResult detectNondeterminism(Automaton automaton) {
    AlgoLog.startAlgo('nondeterminism', 'Detecção de Não-Determinismo');
    
    final nondeterministic = <String>[];
    final details = <String, List<String>>{};
    
    for (final state in automaton.states) {
      for (final sym in automaton.alphabet) {
        final key = '${state.id}|$sym';
        final transitions = automaton.transitions[key] ?? [];
        
        if (transitions.length > 1) {
          nondeterministic.add(state.id);
          details[state.id] = transitions;
          AlgoLog.add('Estado ${state.id} é não-determinístico no símbolo $sym: ${transitions.join(', ')}');
        }
      }
    }
    
    if (nondeterministic.isEmpty) {
      AlgoLog.add('O autômato é determinístico');
    } else {
      AlgoLog.add('Estados não-determinísticos: ${nondeterministic.join(', ')}');
    }
    
    AlgoLog.step('nondeterminism', 'result', data: {
      'nondeterministic': nondeterministic,
      'details': details,
    });
    
    return AnalysisResult(
      type: 'nondeterminism',
      description: 'Estados com transições não-determinísticas',
      states: nondeterministic,
      additionalData: {
        'details': details,
        'isDeterministic': nondeterministic.isEmpty,
      },
    );
  }
  
  /// Checks if the automaton is complete (has transitions for all state-symbol pairs)
  static AnalysisResult checkCompleteness(Automaton automaton) {
    AlgoLog.startAlgo('completeness', 'Verificação de Completude');
    
    final missing = <String>[];
    final totalTransitions = automaton.states.length * automaton.alphabet.length;
    var actualTransitions = 0;
    
    for (final state in automaton.states) {
      for (final sym in automaton.alphabet) {
        final key = '${state.id}|$sym';
        if (automaton.transitions.containsKey(key) && 
            automaton.transitions[key]!.isNotEmpty) {
          actualTransitions++;
        } else {
          missing.add('${state.id}|$sym');
        }
      }
    }
    
    final isComplete = missing.isEmpty;
    AlgoLog.add('Transições presentes: $actualTransitions de $totalTransitions');
    AlgoLog.add('Transições ausentes: ${missing.length}');
    
    if (!isComplete) {
      AlgoLog.add('Transições ausentes: ${missing.join(', ')}');
    }
    
    AlgoLog.step('completeness', 'result', data: {
      'isComplete': isComplete,
      'missing': missing,
      'totalTransitions': totalTransitions,
      'actualTransitions': actualTransitions,
    });
    
    return AnalysisResult(
      type: 'completeness',
      description: 'Verificação se o autômato é completo',
      states: missing,
      additionalData: {
        'isComplete': isComplete,
        'totalTransitions': totalTransitions,
        'actualTransitions': actualTransitions,
      },
    );
  }
  
  /// Analyzes the automaton's language properties
  static AnalysisResult analyzeLanguage(Automaton automaton) {
    AlgoLog.startAlgo('languageAnalysis', 'Análise da Linguagem');
    
    final finalStates = automaton.states.where((s) => s.isFinal).toList();
    final initialState = automaton.initialId != null 
        ? automaton.getState(automaton.initialId!) 
        : null;
    
    // Check if language is empty
    final reachable = _findReachableStates(automaton);
    final reachableFinals = finalStates.where((s) => reachable.contains(s.id)).toList();
    final isEmpty = reachableFinals.isEmpty;
    
    // Check if language is finite
    final hasCycles = _hasCycles(automaton);
    final isFinite = !hasCycles;
    
    // Check if language contains epsilon
    final containsEpsilon = initialState?.isFinal ?? false;
    
    AlgoLog.add('Estados finais alcançáveis: ${reachableFinals.map((s) => s.id).join(', ')}');
    AlgoLog.add('Linguagem vazia: $isEmpty');
    AlgoLog.add('Linguagem finita: $isFinite');
    AlgoLog.add('Contém épsilon: $containsEpsilon');
    
    AlgoLog.step('languageAnalysis', 'result', data: {
      'isEmpty': isEmpty,
      'isFinite': isFinite,
      'containsEpsilon': containsEpsilon,
      'reachableFinals': reachableFinals.map((s) => s.id).toList(),
    });
    
    return AnalysisResult(
      type: 'language',
      description: 'Análise das propriedades da linguagem',
      states: reachableFinals.map((s) => s.id).toList(),
      additionalData: {
        'isEmpty': isEmpty,
        'isFinite': isFinite,
        'containsEpsilon': containsEpsilon,
        'hasCycles': hasCycles,
      },
    );
  }
  
  /// Runs comprehensive analysis on the automaton
  static Map<String, AnalysisResult> runFullAnalysis(Automaton automaton) {
    AlgoLog.startAlgo('fullAnalysis', 'Análise Completa do Autômato');
    
    final results = <String, AnalysisResult>{};
    
    results['unreachable'] = findUnreachableStates(automaton);
    results['useless'] = findUselessStates(automaton);
    results['nondeterminism'] = detectNondeterminism(automaton);
    results['completeness'] = checkCompleteness(automaton);
    results['language'] = analyzeLanguage(automaton);
    
    AlgoLog.add('Análise completa concluída');
    AlgoLog.step('fullAnalysis', 'complete', data: {
      'results': results.keys.toList(),
    });
    
    return results;
  }
  
  // Helper methods
  
  static Set<String> _findReachableStates(Automaton automaton) {
    if (automaton.initialId == null) return {};
    
    final reached = <String>{};
    final queue = Queue<String>();
    queue.add(automaton.initialId!);
    
    while (queue.isNotEmpty) {
      final state = queue.removeFirst();
      if (reached.contains(state)) continue;
      
      reached.add(state);
      
      // Follow all transitions from this state
      for (final sym in automaton.alphabet) {
        final key = '$state|$sym';
        if (automaton.transitions.containsKey(key)) {
          for (final dest in automaton.transitions[key]!) {
            if (!reached.contains(dest)) {
              queue.add(dest);
            }
          }
        }
      }
    }
    
    return reached;
  }
  
  static Set<String> _findStatesReachingFinal(Automaton automaton, Set<String> finalStates) {
    final useful = <String>{};
    final queue = Queue<String>();
    
    // Start from final states
    for (final finalState in finalStates) {
      queue.add(finalState);
      useful.add(finalState);
    }
    
    // Build reverse adjacency list
    final reverseAdj = <String, Set<String>>{};
    for (final state in automaton.states) {
      reverseAdj[state.id] = {};
    }
    
    for (final entry in automaton.transitions.entries) {
      final parts = entry.key.split('|');
      final from = parts[0];
      for (final to in entry.value) {
        reverseAdj[to]!.add(from);
      }
    }
    
    // BFS from final states
    while (queue.isNotEmpty) {
      final state = queue.removeFirst();
      
      for (final predecessor in reverseAdj[state]!) {
        if (!useful.contains(predecessor)) {
          useful.add(predecessor);
          queue.add(predecessor);
        }
      }
    }
    
    return useful;
  }
  
  static bool _hasCycles(Automaton automaton) {
    final visited = <String>{};
    final recursionStack = <String>{};
    
    for (final state in automaton.states) {
      if (!visited.contains(state.id)) {
        if (_hasCycleDFS(state.id, automaton, visited, recursionStack)) {
          return true;
        }
      }
    }
    
    return false;
  }
  
  static bool _hasCycleDFS(
    String state, 
    Automaton automaton, 
    Set<String> visited, 
    Set<String> recursionStack
  ) {
    visited.add(state);
    recursionStack.add(state);
    
    for (final sym in automaton.alphabet) {
      final key = '$state|$sym';
      if (automaton.transitions.containsKey(key)) {
        for (final dest in automaton.transitions[key]!) {
          if (!visited.contains(dest)) {
            if (_hasCycleDFS(dest, automaton, visited, recursionStack)) {
              return true;
            }
          } else if (recursionStack.contains(dest)) {
            return true;
          }
        }
      }
    }
    
    recursionStack.remove(state);
    return false;
  }
}
