import 'dart:collection';

import 'automaton.dart';
import 'algo_log.dart';
import '../presentation/widgets/layout_tools.dart';

// Export the main conversion function
automatonToDfa(Automaton nfa) => nfaToDfa(nfa);

typedef StepCallback = void Function(
  String title, 
  String description, 
  {Automaton? automaton, 
   List<Map<String, dynamic>>? partitions,
   Map<String, dynamic>? metadata,
  });

/// Converts an NFA to an equivalent DFA using the subset construction algorithm.
/// 
/// This implementation follows these steps:
/// 1. Compute the epsilon-closure of the initial state
/// 2. For each symbol in the alphabet, compute the set of states reachable from the current set
/// 3. Create new states in the DFA for each new set of NFA states
/// 4. Repeat until no new states can be created
/// 5. Mark states containing any final NFA state as final in the DFA
///
/// The [onStep] callback is called at each major step of the algorithm to support visualization.
Automaton nfaToDfa(Automaton nfa, {StepCallback? onStep}) {
  onStep ??= (title, description, {automaton, partitions, metadata}) {};
  
  onStep('NFA Original', 'Este é o autômato não-determinístico original que será convertido.', automaton: nfa);
  
  // Create a new DFA
  final dfa = Automaton(
    alphabet: Set<String>.from(nfa.alphabet),
    states: [],
    transitions: {},
    initialId: '',
    nextId: 0,
  );
  
  // Step 1: Get the initial state
  if (nfa.initialId == null) {
    throw StateError('NFA has no initial state');
  }
  final initialState = nfa.getState(nfa.initialId!);
  if (initialState == null) {
    throw StateError('Initial state not found in NFA');
  }
  
  final initialStateClosure = epsilonClosure(initialState, nfa);
  
  // Create initial DFA state
  final dfaInitialState = _createDfaState(dfa, initialStateClosure, nfa);
  dfa.initialId = dfaInitialState.id;
  
  // Keep track of unprocessed DFA states (sets of NFA states)
  final unprocessedStates = Queue<StateNode>();
  unprocessedStates.add(dfaInitialState);
  
  // Map from DFA state ID to set of NFA states it represents
  final dfaStateMap = <String, Set<StateNode>>{};
  dfaStateMap[dfaInitialState.id] = initialStateClosure;
  
  // Process each state in the DFA
  while (unprocessedStates.isNotEmpty) {
    final currentDfaState = unprocessedStates.removeFirst();
    final currentNfaStates = dfaStateMap[currentDfaState.id]!;
    
    onStep(
      'Processando estado ${currentDfaState.id}', 
      'Calculando transições para o estado ${currentDfaState.id} que representa os estados NFA: ${getStateNames(currentNfaStates)}',
      metadata: {
        'currentDfaState': currentDfaState.id,
        'nfaStates': currentNfaStates.map((s) => s.id).toList(),
      },
    );
    
    // For each symbol in the alphabet
    for (final symbol in dfa.alphabet) {
      final nextNfaStates = <StateNode>{};
      
      // Find all states reachable via this symbol
      for (final nfaState in currentNfaStates) {
        final transitionKey = '${nfaState.id}|$symbol';
        if (nfa.transitions.containsKey(transitionKey)) {
          for (final nextStateId in nfa.transitions[transitionKey]!) {
            final nextState = nfa.getState(nextStateId);
            if (nextState != null) {
              nextNfaStates.add(nextState);
            }
          }
        }
      }
      
      // Take epsilon-closure of all reachable states
      final reachableStates = <StateNode>{};
      for (final state in nextNfaStates) {
        reachableStates.addAll(epsilonClosure(state, nfa));
      }
      
      if (reachableStates.isNotEmpty) {
        // Check if we've seen this set of states before
        var existingDfaState = findDfaStateForNfaStates(dfa, dfaStateMap, reachableStates);
        
        if (existingDfaState == null) {
          // Create a new DFA state for this set of NFA states
          existingDfaState = _createDfaState(dfa, reachableStates, nfa);
          dfaStateMap[existingDfaState.id] = reachableStates;
          unprocessedStates.add(existingDfaState);
          
          onStep(
            'Novo estado criado', 
            'Criado estado ${existingDfaState.id} representando os estados NFA: ${getStateNames(reachableStates)}',
            metadata: {
              'newDfaState': existingDfaState.id,
              'nfaStates': reachableStates.map((s) => s.id).toList(),
            },
          );
        }
        
        // Add transition in the DFA
        final transitionKey = '${currentDfaState.id}|$symbol';
        dfa.transitions[transitionKey] = [existingDfaState.id];
        
        onStep(
          'Transição adicionada', 
          'Adicionada transição de ${currentDfaState.id} para ${existingDfaState.id} com símbolo $symbol',
          metadata: {
            'from': currentDfaState.id,
            'to': existingDfaState.id,
            'symbol': symbol,
          },
        );
      }
    }
  }
  
  onStep(
    'Conversão concluída', 
    'Conversão de NFA para DFA concluída com sucesso! O DFA resultante tem ${dfa.states.length} estados.',
    automaton: dfa,
  );
  
  return dfa;
}

/// Computes the epsilon-closure of a state in an NFA.
/// Computes the epsilon-closure of a state in an NFA.
Set<StateNode> epsilonClosure(StateNode state, Automaton nfa) {
  final closure = <StateNode>{state};
  final stack = <StateNode>[state];
  
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    final transitionKey = '${current.id}|ε';
    
    if (nfa.transitions.containsKey(transitionKey)) {
      for (final nextStateId in nfa.transitions[transitionKey]!) {
        final nextState = nfa.getState(nextStateId);
        if (nextState != null && !closure.contains(nextState)) {
          closure.add(nextState);
          stack.add(nextState);
        }
      }
    }
  }
  
  return closure;
}

/// Creates a new DFA state representing the given set of NFA states.
StateNode _createDfaState(Automaton dfa, Set<StateNode> nfaStates, Automaton nfa) {
  // Generate a consistent name for the new state
  final stateIds = nfaStates.map((s) => s.id).toList()..sort();
  
  // Create a consistent state ID and name
  String stateId;
  String stateName;
  
  if (stateIds.isEmpty) {
    // Trap state (shouldn't normally happen)
    stateId = 'trap';
    stateName = 'Trap';
  } else if (stateIds.length == 1) {
    // Single state - use its ID directly
    stateId = stateIds.first;
    stateName = stateId;
  } else if (stateIds.length <= 3) {
    // For small sets, list all states in the name
    stateId = '{${stateIds.join(',')}}';
    stateName = stateId;
  } else {
    // For larger sets, use a more compact representation
    stateId = '{${stateIds.take(2).join(',')}...${stateIds.last}}';
    stateName = stateId;
  }
  
  // Make sure the ID is unique
  int counter = 1;
  String uniqueId = stateId;
  while (dfa.states.any((s) => s.id == uniqueId)) {
    uniqueId = '${stateId}_$counter';
    counter++;
  }
  
  // Check if this state already exists with the same NFA states
  final existingState = findDfaStateForNfaStates(dfa, {}, nfaStates);
  if (existingState != null) {
    return existingState;
  }
  
  // Create a new state
  final isFinal = nfaStates.any((s) => s.isFinal);
  final newState = StateNode(
    id: uniqueId,
    name: stateName,
    x: 0, // Will be positioned by the layout algorithm
    y: 0,
    isInitial: dfa.states.isEmpty, // First state is initial
    isFinal: isFinal,
  );
  
  dfa.states.add(newState);
  return newState;
}

/// Finds a DFA state that represents the given set of NFA states.
/// Finds a DFA state that represents the given set of NFA states.
StateNode? findDfaStateForNfaStates(
  Automaton dfa, 
  Map<String, Set<StateNode>> dfaStateMap, 
  Set<StateNode> nfaStates
) {
  final targetStateNames = nfaStates.map((s) => s.id).toSet();
  
  for (final entry in dfaStateMap.entries) {
    final dfaStateNames = entry.value.map((s) => s.id).toSet();
    
    if (targetStateNames.length == dfaStateNames.length &&
        targetStateNames.every((name) => dfaStateNames.contains(name))) {
      return dfa.getState(entry.key);
    }
  }
  
  return null;
}

/// Helper function to get a string representation of a set of states.
/// Helper function to get a string representation of a set of states.
String getStateNames(Iterable<StateNode> states) {
  final names = states.map((s) => s.id).toList()..sort();
  return '{${names.join(', ')}}';
}
