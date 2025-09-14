import 'algorithms.dart' as algo;
import 'automaton.dart';

class RunDetail {
  RunDetail({
    required this.accepted,
    required this.visited,
    required this.messages,
    this.halt,
    this.stepIndex = 0,
  });

  final bool accepted;
  final List<Set<String>> visited; // includes t=0
  final List<String> messages; // human-readable log
  final String? halt; // HALT reason (if any)
  final int stepIndex; // current step for step-by-step mode
}

class StepByStepRun {
  StepByStepRun({
    required this.automaton,
    required this.word,
    required this.currentStates,
    required this.stepIndex,
    required this.messages,
    required this.isComplete,
    this.halt,
  });

  final Automaton automaton;
  final String word;
  final Set<String> currentStates;
  final int stepIndex;
  final List<String> messages;
  final bool isComplete;
  final String? halt;

  StepByStepRun copyWith({
    Set<String>? currentStates,
    int? stepIndex,
    List<String>? messages,
    bool? isComplete,
    String? halt,
  }) {
    return StepByStepRun(
      automaton: automaton,
      word: word,
      currentStates: currentStates ?? this.currentStates,
      stepIndex: stepIndex ?? this.stepIndex,
      messages: messages ?? this.messages,
      isComplete: isComplete ?? this.isComplete,
      halt: halt ?? this.halt,
    );
  }
}

String _namesOf(Automaton a, Set<String> ids) {
  return ids.map((id) => a.getState(id)?.name ?? id).join(', ');
}

RunDetail runDetailed(Automaton a, String word) {
  final sigma = a.alphabet;
  final msgs = <String>[];
  if (a.initialId == null) {
    return RunDetail(
      accepted: false,
      visited: const [<String>{}],
      messages: ['Defina um estado inicial.'],
      halt: 'Sem estado inicial',
    );
  }
  if (sigma.isEmpty) {
    return RunDetail(
      accepted: false,
      visited: const [<String>{}],
      messages: ['Defina Σ.'],
      halt: 'Σ vazia',
    );
  }

  // Use ε-fecho para suportar NFA/ε-NFA
  Set<String> current = algo.epsilonClosure(a, {a.initialId!});
  msgs.add('Início em {${_namesOf(a, current)}}');
  final visited = <Set<String>>[current];

  for (final c in word.split('')) {
    if (!sigma.contains(c)) {
      final alphaStr = a.alphabet.join(', ');
      final halt = 'HALT: símbolo "$c" não pertence a Σ = { $alphaStr }.';
      msgs.add(halt);
      return RunDetail(accepted: false, visited: visited, messages: msgs, halt: halt);
    }
    final next = <String>{};
    for (final s in current) {
      final dests = a.transitions['$s|$c'] ?? const <String>[];
      for (final d in dests) {
        next.addAll(algo.epsilonClosure(a, {d}));
      }
    }
    if (next.isEmpty) {
      final halt = 'HALT: transição não definida para ({${_namesOf(a, current)}}, $c)';
      msgs.add(halt);
      return RunDetail(accepted: false, visited: visited, messages: msgs, halt: halt);
    }
    msgs.add('({${_namesOf(a, current)}}, $c) → {${_namesOf(a, next)}}');
    current = next;
    visited.add(current);
  }

  final finals = current.where((id) => a.getState(id)?.isFinal == true).toSet();
  if (finals.isNotEmpty) {
    msgs.add('ACEITA (terminou em {${_namesOf(a, finals)}})');
    return RunDetail(accepted: true, visited: visited, messages: msgs);
  } else {
    msgs.add('REJEITADA (terminou em {${_namesOf(a, current)}})');
    return RunDetail(accepted: false, visited: visited, messages: msgs);
  }
}

/// Creates a step-by-step simulation session
StepByStepRun createStepByStepRun(Automaton a, String word) {
  final sigma = a.alphabet;
  final msgs = <String>[];
  
  if (a.initialId == null) {
    return StepByStepRun(
      automaton: a,
      word: word,
      currentStates: const <String>{},
      stepIndex: 0,
      messages: ['Defina um estado inicial.'],
      isComplete: true,
      halt: 'Sem estado inicial',
    );
  }
  
  if (sigma.isEmpty) {
    return StepByStepRun(
      automaton: a,
      word: word,
      currentStates: const <String>{},
      stepIndex: 0,
      messages: ['Defina Σ.'],
      isComplete: true,
      halt: 'Σ vazia',
    );
  }

  // Initialize with epsilon closure of initial state
  final initialStates = algo.epsilonClosure(a, {a.initialId!});
  msgs.add('Início em {${_namesOf(a, initialStates)}}');
  
  return StepByStepRun(
    automaton: a,
    word: word,
    currentStates: initialStates,
    stepIndex: 0,
    messages: msgs,
    isComplete: word.isEmpty,
  );
}

/// Executes one step of the simulation
StepByStepRun executeStep(StepByStepRun run) {
  if (run.isComplete || run.halt != null) {
    return run;
  }

  final wordChars = run.word.split('');
  if (run.stepIndex >= wordChars.length) {
    // Check final states
    final finals = run.currentStates.where((id) => run.automaton.getState(id)?.isFinal == true).toSet();
    final newMessages = List<String>.from(run.messages);
    
    if (finals.isNotEmpty) {
      newMessages.add('ACEITA (terminou em {${_namesOf(run.automaton, finals)}})');
      return run.copyWith(
        messages: newMessages,
        isComplete: true,
      );
    } else {
      newMessages.add('REJEITADA (terminou em {${_namesOf(run.automaton, run.currentStates)}})');
      return run.copyWith(
        messages: newMessages,
        isComplete: true,
      );
    }
  }

  final c = wordChars[run.stepIndex];
  final sigma = run.automaton.alphabet;
  final newMessages = List<String>.from(run.messages);

  // Check if symbol is in alphabet
  if (!sigma.contains(c)) {
    final alphaStr = run.automaton.alphabet.join(', ');
    final halt = 'HALT: símbolo "$c" não pertence a Σ = { $alphaStr }.';
    newMessages.add(halt);
    return run.copyWith(
      messages: newMessages,
      isComplete: true,
      halt: halt,
    );
  }

  // Compute next states
  final next = <String>{};
  for (final s in run.currentStates) {
    final dests = run.automaton.transitions['$s|$c'] ?? const <String>[];
    for (final d in dests) {
      next.addAll(algo.epsilonClosure(run.automaton, {d}));
    }
  }

  if (next.isEmpty) {
    final halt = 'HALT: transição não definida para ({${_namesOf(run.automaton, run.currentStates)}}, $c)';
    newMessages.add(halt);
    return run.copyWith(
      messages: newMessages,
      isComplete: true,
      halt: halt,
    );
  }

  newMessages.add('({${_namesOf(run.automaton, run.currentStates)}}, $c) → {${_namesOf(run.automaton, next)}}');
  
  return run.copyWith(
    currentStates: next,
    stepIndex: run.stepIndex + 1,
    messages: newMessages,
  );
}

/// Gets the current symbol being processed (null if complete)
String? getCurrentSymbol(StepByStepRun run) {
  if (run.isComplete || run.halt != null) return null;
  final wordChars = run.word.split('');
  if (run.stepIndex >= wordChars.length) return null;
  return wordChars[run.stepIndex];
}

/// Checks if the simulation is in a final state
bool isInFinalState(StepByStepRun run) {
  return run.currentStates.any((id) => run.automaton.getState(id)?.isFinal == true);
}

