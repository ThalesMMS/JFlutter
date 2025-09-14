import 'dart:collection';
import 'automaton.dart';
import 'algo_log.dart';
import '../presentation/widgets/layout_tools.dart';

typedef StepCallback = void Function(String title, String description, {Automaton? automaton, List<Map<String, dynamic>>? partitions});

/// Helper class to manage partitions of states during DFA minimization.
class _Partition {
  final Set<String> states;
  final bool isFinal;

  _Partition(this.states, this.isFinal);

  @override
  String toString() => '{${states.join(', ')}}';
}

/// Minimizes a DFA using the table-filling (Myhill-Nerode) algorithm.
/// 
/// This implementation follows these steps:
/// 1. Remove unreachable states
/// 2. Partition states into final and non-final
/// 3. Iteratively split partitions until no more splits are possible
/// 4. Merge equivalent states
Automaton minimizeDfa(Automaton dfa, {StepCallback? onStep}) {
  onStep ??= (title, description, {automaton, partitions}) {};
  AlgoLog.startAlgo('minimizeDfa', 'Minimização de AFD');
  
  // Validate input
  if (dfa.states.isEmpty) {
    throw ArgumentError('Cannot minimize empty automaton');
  }
  if (dfa.initialId == null) {
    throw ArgumentError('DFA must have an initial state');
  }
  
  onStep('AFD Original', 'Este é o autômato original que será minimizado.', automaton: dfa);
  
  // 1. Ensure the input is a complete DFA
  onStep('Completando AFD', 'Adicionando estado armadilha, se necessário...');
  final completeDfa = _completeDfa(dfa);
  
  // 2. Remove unreachable states
  onStep('Removendo estados inalcançáveis', 'Identificando e removendo estados que não são alcançáveis a partir do estado inicial.');
  final reachable = _findReachableStates(completeDfa);
  final reachableDfa = completeDfa.clone();
  reachableDfa.states.removeWhere((s) => !reachable.contains(s.id));
  
  // 3. Initialize partitions: separate final and non-final states
  onStep('Inicializando partições', 'Separando estados finais e não-finais em partições iniciais.');
  final partitions = <_Partition>[];
  final finalStates = reachableDfa.states.where((s) => s.isFinal).map((s) => s.id).toSet();
  final nonFinalStates = reachableDfa.stateIds.toSet().difference(finalStates);
  
  if (finalStates.isNotEmpty) {
    partitions.add(_Partition(finalStates, true));
  }
  if (nonFinalStates.isNotEmpty) {
    partitions.add(_Partition(nonFinalStates, false));
  }
  
  // Show initial partitions
  onStep(
    'Partições Iniciais', 
    'Estados foram divididos em partições iniciais baseadas em estados finais e não-finais.',
    partitions: partitions.map((p) => {
      'states': p.states.toList(),
      'isFinal': p.isFinal,
    }).toList(),
  );
  AlgoLog.step('minimizeDfa', 'initPartitions', data: {
    'finals': finalStates.toList(),
    'nonFinals': nonFinalStates.toList(),
  });
  
  // 4. Refine partitions until no more splits are possible
  int iteration = 1;
  bool changed;
  do {
    changed = false;
    final newPartitions = <_Partition>[];
    
    for (final p in partitions) {
      if (p.states.length == 1) {
        newPartitions.add(p);
        continue;
      }
      
      final split = _splitPartition(p, partitions, reachableDfa);
      if (split.length > 1) {
        changed = true;
        newPartitions.addAll(split);
      } else {
        newPartitions.add(p);
      }
    }
    
    if (changed) {
      onStep(
        'Refinamento #$iteration', 
        'Partições foram refinadas com base nas transições dos estados.',
        partitions: newPartitions.map((p) => {
          'states': p.states.toList(),
          'isFinal': p.isFinal,
        }).toList(),
      );
      AlgoLog.step('minimizeDfa', 'refined', data: {
        'iteration': iteration,
        'parts': newPartitions.map((p) => p.states.toList()).toList(),
      });
      iteration++;
    }
    
    partitions.clear();
    partitions.addAll(newPartitions);
  } while (changed);
  
  // 5. Build the minimized DFA
  onStep('Construindo AFD minimizado', 'Criando o autômato minimizado a partir das partições finais.');
  final minimizedDfa = _buildMinimizedDfa(reachableDfa, partitions);
  
  onStep(
    'AFD Minimizado', 
    'O autômato foi minimizado com sucesso!',
    automaton: minimizedDfa,
  );
  AlgoLog.step('minimizeDfa', 'final', data: {
    'states': minimizedDfa.states.length,
    'transitions': minimizedDfa.transitions.length,
  });
  
  return minimizedDfa;
}

/// Completes a DFA by adding a trap state if necessary.
Automaton _completeDfa(Automaton dfa) {
  final completeDfa = dfa.clone();
  final alphabet = completeDfa.alphabet;
  bool needsTrap = false;
  
  // Check if we need a trap state
  for (final state in completeDfa.states) {
    for (final sym in alphabet) {
      final key = '${state.id}|$sym';
      if (!completeDfa.transitions.containsKey(key) || 
          completeDfa.transitions[key]!.isEmpty) {
        needsTrap = true;
        break;
      }
    }
    if (needsTrap) break;
  }
  
  if (!needsTrap) return completeDfa;
  
  // Add trap state
  final trapId = 'trap';
  completeDfa.states.add(StateNode(
    id: trapId,
    name: trapId,
    x: 0,
    y: 0,
    isInitial: false,
    isFinal: false,
  ));
  
  // Add transitions to trap state
  for (final state in completeDfa.states) {
    for (final sym in alphabet) {
      final key = '${state.id}|$sym';
      if (!completeDfa.transitions.containsKey(key) || 
          completeDfa.transitions[key]!.isEmpty) {
        completeDfa.transitions[key] = [trapId];
      }
    }
  }
  
  // Add self-loops for trap state
  for (final sym in alphabet) {
    completeDfa.transitions['$trapId|$sym'] = [trapId];
  }
  
  return completeDfa;
}

/// Finds all reachable states from the initial state.
Set<String> _findReachableStates(Automaton dfa) {
  if (dfa.initialId == null) return {};
  
  final reached = <String>{};
  final queue = Queue<String>();
  queue.add(dfa.initialId!);
  
  while (queue.isNotEmpty) {
    final state = queue.removeFirst();
    if (reached.contains(state)) continue;
    
    reached.add(state);
    
    // Follow all transitions from this state
    for (final sym in dfa.alphabet) {
      final key = '$state|$sym';
      if (dfa.transitions.containsKey(key)) {
        for (final dest in dfa.transitions[key]!) {
          if (!reached.contains(dest)) {
            queue.add(dest);
          }
        }
      }
    }
  }
  
  return reached;
}

/// Splits a partition based on transition behavior.
List<_Partition> _splitPartition(
  _Partition partition, 
  List<_Partition> allPartitions, 
  Automaton dfa
) {
  if (partition.states.length <= 1) return [partition];
  
  final groups = <String, Set<String>>{};
  
  for (final state in partition.states) {
    final signature = <String>[];
    
    // For each symbol, find which partition the transition leads to
    for (final sym in dfa.alphabet) {
      final key = '$state|$sym';
      String? targetPartitionId;
      
      if (dfa.transitions.containsKey(key) && dfa.transitions[key]!.isNotEmpty) {
        final dest = dfa.transitions[key]!.first;
        
        // Find which partition contains the destination state
        for (int i = 0; i < allPartitions.length; i++) {
          if (allPartitions[i].states.contains(dest)) {
            // Use a more robust partition identifier
            final partitionStates = allPartitions[i].states.toList()..sort();
            targetPartitionId = 'p_${partitionStates.join('_')}';
            break;
          }
        }
      } else {
        // No transition on this symbol - goes to trap state
        targetPartitionId = 'trap';
      }
      
      signature.add('$sym:$targetPartitionId');
    }
    
    final sigKey = signature.join(';');
    groups.putIfAbsent(sigKey, () => <String>{}).add(state);
  }
  
  if (groups.length <= 1) return [partition];
  
  return groups.values
      .map((states) => _Partition(states, partition.isFinal))
      .toList();
}

/// Builds the minimized DFA from the final partitions.
Automaton _buildMinimizedDfa(Automaton dfa, List<_Partition> partitions) {
  final minimized = Automaton(alphabet: dfa.alphabet);
  final stateMap = <String, String>{}; // old state ID -> new state ID
  
  // Create new states with consistent naming
  for (int i = 0; i < partitions.length; i++) {
    final part = partitions[i];
    final sortedStates = part.states.toList()..sort();
    final newId = sortedStates.length == 1 
        ? sortedStates.first 
        : '{${sortedStates.join(',')}}';
    final containsInitial = part.states.any((s) => s == dfa.initialId);
    
    minimized.states.add(StateNode(
      id: newId,
      name: newId,
      x: 0, // Position will be set by the UI
      y: 0,
      isInitial: containsInitial,
      isFinal: part.isFinal,
    ));
    
    if (containsInitial) {
      minimized.initialId = newId;
    }
    
    // Map all old states in this partition to the new state
    for (final oldId in part.states) {
      stateMap[oldId] = newId;
    }
    
    AlgoLog.add('Novo estado $newId representa os estados: ${part.states.join(', ')}');
    AlgoLog.step('minimizeDfa', 'newState', data: {
      'id': newId,
      'represents': part.states.toList(),
      'isFinal': part.isFinal,
      'isInitial': containsInitial,
    });
  }
  
  // Add transitions
  for (int i = 0; i < partitions.length; i++) {
    final part = partitions[i];
    final sortedStates = part.states.toList()..sort();
    final newStateId = sortedStates.length == 1 
        ? sortedStates.first 
        : '{${sortedStates.join(',')}}';
    final sampleState = part.states.first;
    
    for (final sym in dfa.alphabet) {
      final key = '$sampleState|$sym';
      if (dfa.transitions.containsKey(key) && dfa.transitions[key]!.isNotEmpty) {
        final oldTarget = dfa.transitions[key]!.first;
        final newTarget = stateMap[oldTarget]!;
        
        minimized.transitions['$newStateId|$sym'] = [newTarget];
        AlgoLog.step('minimizeDfa', 'transition', data: {
          'from': newStateId,
          'sym': sym,
          'to': newTarget,
        });
      }
    }
  }
  
  return minimized;
}
