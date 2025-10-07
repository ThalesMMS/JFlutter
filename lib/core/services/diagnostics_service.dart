//
//  diagnostics_service.dart
//  JFlutter
//
//  Serviço estático que avalia autômatos finitos e produz diagnósticos detalhados,
//  cobrindo estados iniciais, alcançabilidade, transições, componentes e padrões de
//  epsilon ou não determinismo.
//  Também interpreta falhas de simulação para gerar mensagens específicas e sugestões
//  acionáveis, promovendo orientações para correção dentro da interface.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/state.dart' as automaton_state;

/// Service for providing detailed diagnostics and error messages
class DiagnosticsService {
  /// Provides detailed error messages for automaton validation
  static List<DiagnosticMessage> validateAutomaton(FSA automaton) {
    final diagnostics = <DiagnosticMessage>[];

    // Check for empty automaton
    if (automaton.states.isEmpty) {
      diagnostics.add(
        DiagnosticMessage.error(
          'Empty Automaton',
          'The automaton has no states. Add at least one state to create a valid automaton.',
          'Add a state using the "Add State" button.',
        ),
      );
      return diagnostics;
    }

    // Check for initial state
    final initialStates = automaton.states.where((s) => s.isInitial).toList();
    if (initialStates.isEmpty) {
      diagnostics.add(
        DiagnosticMessage.error(
          'No Initial State',
          'The automaton has no initial state. Every automaton must have exactly one initial state.',
          'Select a state and mark it as initial using the state properties.',
        ),
      );
    } else if (initialStates.length > 1) {
      diagnostics.add(
        DiagnosticMessage.error(
          'Multiple Initial States',
          'The automaton has ${initialStates.length} initial states. Every automaton must have exactly one initial state.',
          'Select all but one initial state and unmark them as initial.',
        ),
      );
    }

    // Check for accepting states
    final acceptingStates = automaton.states
        .where((s) => s.isAccepting)
        .toList();
    if (acceptingStates.isEmpty) {
      diagnostics.add(
        DiagnosticMessage.warning(
          'No Accepting States',
          'The automaton has no accepting states. This means it will reject all input strings.',
          'Consider adding at least one accepting state if you want the automaton to accept some strings.',
        ),
      );
    }

    // Check for unreachable states
    final reachableStates = _findReachableStates(automaton);
    final unreachableStates = automaton.states
        .where((s) => !reachableStates.contains(s))
        .toList();
    if (unreachableStates.isNotEmpty) {
      diagnostics.add(
        DiagnosticMessage.warning(
          'Unreachable States',
          'The automaton has ${unreachableStates.length} unreachable states: ${unreachableStates.map((s) => s.label).join(', ')}.',
          'These states can be removed without changing the automaton\'s behavior.',
        ),
      );
    }

    // Check for dead states
    final deadStates = _findDeadStates(automaton);
    if (deadStates.isNotEmpty) {
      diagnostics.add(
        DiagnosticMessage.warning(
          'Dead States',
          'The automaton has ${deadStates.length} dead states: ${deadStates.map((s) => s.label).join(', ')}.',
          'These states cannot reach any accepting state and can be removed.',
        ),
      );
    }

    // Check for nondeterministic transitions
    final nondeterministicIssues = _findNondeterministicIssues(automaton);
    if (nondeterministicIssues.isNotEmpty) {
      diagnostics.add(
        DiagnosticMessage.info(
          'Nondeterministic Transitions',
          'The automaton has ${nondeterministicIssues.length} nondeterministic transitions.',
          'This is normal for NFAs but may indicate issues for DFAs.',
        ),
      );
    }

    // Check for epsilon transitions
    final epsilonTransitions = automaton.transitions
        .where((t) => t is FSATransition && t.isEpsilonTransition)
        .toList();
    if (epsilonTransitions.isNotEmpty) {
      diagnostics.add(
        DiagnosticMessage.info(
          'Epsilon Transitions',
          'The automaton has ${epsilonTransitions.length} epsilon transitions.',
          'Epsilon transitions are allowed in NFAs but not in DFAs.',
        ),
      );
    }

    // Check for disconnected components
    final components = _findConnectedComponents(automaton);
    if (components.length > 1) {
      diagnostics.add(
        DiagnosticMessage.warning(
          'Disconnected Components',
          'The automaton has ${components.length} disconnected components.',
          'Consider connecting all components or removing unused ones.',
        ),
      );
    }

    return diagnostics;
  }

  /// Provides detailed error messages for simulation failures
  static List<DiagnosticMessage> analyzeSimulationFailure(
    FSA automaton,
    String inputString,
    String failureReason,
  ) {
    final diagnostics = <DiagnosticMessage>[];

    // Analyze why simulation failed
    if (failureReason.contains('No transition found')) {
      diagnostics.add(
        DiagnosticMessage.error(
          'No Valid Transition',
          'The automaton cannot process the input string "$inputString" because there is no valid transition for one of the symbols.',
          'Check that all symbols in the input are in the automaton\'s alphabet.',
        ),
      );
    } else if (failureReason.contains('Rejected')) {
      diagnostics.add(
        DiagnosticMessage.info(
          'Input Rejected',
          'The input string "$inputString" was processed but ended in a non-accepting state.',
          'This is the expected behavior for this input string with this automaton.',
        ),
      );
    } else if (failureReason.contains('Timeout')) {
      diagnostics.add(
        DiagnosticMessage.error(
          'Simulation Timeout',
          'The simulation took too long to complete, possibly due to an infinite loop.',
          'Check for cycles in the automaton that might cause infinite loops.',
        ),
      );
    }

    // Provide suggestions based on the input
    final alphabet = automaton.alphabet;
    final invalidSymbols = inputString
        .split('')
        .where((s) => !alphabet.contains(s))
        .toSet();
    if (invalidSymbols.isNotEmpty) {
      diagnostics.add(
        DiagnosticMessage.error(
          'Invalid Symbols',
          'The input contains symbols not in the automaton\'s alphabet: ${invalidSymbols.join(', ')}.',
          'Either add these symbols to the automaton\'s alphabet or use only valid symbols.',
        ),
      );
    }

    return diagnostics;
  }

  /// Normalizes transition order for consistent comparison
  static List<FSATransition> normalizeTransitionOrder(
    Set<FSATransition> transitions,
  ) {
    final transitionList = transitions.toList();

    // Sort by from state, then to state, then by label
    transitionList.sort((a, b) {
      final fromComparison = a.fromState.label.compareTo(b.fromState.label);
      if (fromComparison != 0) return fromComparison;

      final toComparison = a.toState.label.compareTo(b.toState.label);
      if (toComparison != 0) return toComparison;

      return a.label.compareTo(b.label);
    });

    return transitionList;
  }

  /// Normalizes state order for consistent comparison
  static List<automaton_state.State> normalizeStateOrder(
    Set<automaton_state.State> states,
  ) {
    final stateList = states.toList();

    // Sort by label
    stateList.sort((a, b) => a.label.compareTo(b.label));

    return stateList;
  }

  /// Finds reachable states from the initial state
  static Set<automaton_state.State> _findReachableStates(FSA automaton) {
    final reachable = <automaton_state.State>{};
    final initialState = automaton.states.where((s) => s.isInitial).firstOrNull;

    if (initialState == null) return reachable;

    final toVisit = <automaton_state.State>[initialState];

    while (toVisit.isNotEmpty) {
      final current = toVisit.removeAt(0);
      if (reachable.contains(current)) continue;

      reachable.add(current);

      // Find all states reachable from current state
      for (final transition in automaton.transitions) {
        if (transition.fromState == current) {
          toVisit.add(transition.toState);
        }
      }
    }

    return reachable;
  }

  /// Finds dead states (states that cannot reach any accepting state)
  static List<automaton_state.State> _findDeadStates(FSA automaton) {
    final deadStates = <automaton_state.State>[];

    for (final state in automaton.states) {
      if (_canReachAcceptingState(automaton, state)) {
        continue;
      }
      deadStates.add(state);
    }

    return deadStates;
  }

  /// Checks if a state can reach any accepting state
  static bool _canReachAcceptingState(
    FSA automaton,
    automaton_state.State startState,
  ) {
    if (startState.isAccepting) return true;

    final visited = <automaton_state.State>{};
    final toVisit = <automaton_state.State>[startState];

    while (toVisit.isNotEmpty) {
      final current = toVisit.removeAt(0);
      if (visited.contains(current)) continue;

      visited.add(current);

      if (current.isAccepting) return true;

      // Find all states reachable from current state
      for (final transition in automaton.transitions) {
        if (transition.fromState == current &&
            !visited.contains(transition.toState)) {
          toVisit.add(transition.toState);
        }
      }
    }

    return false;
  }

  /// Finds nondeterministic issues in the automaton
  static List<String> _findNondeterministicIssues(FSA automaton) {
    final issues = <String>[];
    final outgoingByState = <String, Map<String, List<FSATransition>>>{};

    // Group transitions by state and symbol
    for (final transition in automaton.transitions) {
      if (transition is! FSATransition) continue;
      final fromId = transition.fromState.id;
      final symbol = transition.isEpsilonTransition
          ? (transition.lambdaSymbol ?? 'ε')
          : transition.inputSymbols.isEmpty
          ? transition.label
          : transition.inputSymbols.first;

      outgoingByState.putIfAbsent(
        fromId,
        () => <String, List<FSATransition>>{},
      );
      outgoingByState[fromId]!.putIfAbsent(symbol, () => <FSATransition>[]);
      outgoingByState[fromId]![symbol]!.add(transition);
    }

    // Check for nondeterministic transitions
    for (final stateId in outgoingByState.keys) {
      for (final symbol in outgoingByState[stateId]!.keys) {
        final transitions = outgoingByState[stateId]![symbol]!;
        if (transitions.length > 1) {
          final state = automaton.states.firstWhere((s) => s.id == stateId);
          issues.add(
            'State ${state.label} has ${transitions.length} transitions on symbol "$symbol"',
          );
        }
      }
    }

    return issues;
  }

  /// Finds connected components in the automaton
  static List<Set<automaton_state.State>> _findConnectedComponents(
    FSA automaton,
  ) {
    final components = <Set<automaton_state.State>>[];
    final visited = <automaton_state.State>{};

    for (final state in automaton.states) {
      if (visited.contains(state)) continue;

      final component = <automaton_state.State>{};
      final toVisit = <automaton_state.State>[state];

      while (toVisit.isNotEmpty) {
        final current = toVisit.removeAt(0);
        if (visited.contains(current)) continue;

        visited.add(current);
        component.add(current);

        // Find all connected states
        for (final transition in automaton.transitions) {
          if (transition.fromState == current &&
              !visited.contains(transition.toState)) {
            toVisit.add(transition.toState);
          }
          if (transition.toState == current &&
              !visited.contains(transition.fromState)) {
            toVisit.add(transition.fromState);
          }
        }
      }

      if (component.isNotEmpty) {
        components.add(component);
      }
    }

    return components;
  }
}

/// Represents a diagnostic message with severity and suggestions
class DiagnosticMessage {
  final DiagnosticSeverity severity;
  final String title;
  final String message;
  final String? suggestion;

  const DiagnosticMessage({
    required this.severity,
    required this.title,
    required this.message,
    this.suggestion,
  });

  factory DiagnosticMessage.error(
    String title,
    String message, [
    String? suggestion,
  ]) {
    return DiagnosticMessage(
      severity: DiagnosticSeverity.error,
      title: title,
      message: message,
      suggestion: suggestion,
    );
  }

  factory DiagnosticMessage.warning(
    String title,
    String message, [
    String? suggestion,
  ]) {
    return DiagnosticMessage(
      severity: DiagnosticSeverity.warning,
      title: title,
      message: message,
      suggestion: suggestion,
    );
  }

  factory DiagnosticMessage.info(
    String title,
    String message, [
    String? suggestion,
  ]) {
    return DiagnosticMessage(
      severity: DiagnosticSeverity.info,
      title: title,
      message: message,
      suggestion: suggestion,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[$severity] $title');
    buffer.writeln('  $message');
    if (suggestion != null) {
      buffer.writeln('  Suggestion: $suggestion');
    }
    return buffer.toString();
  }
}

/// Severity levels for diagnostic messages
enum DiagnosticSeverity { error, warning, info }

/// Extension to provide string representation of severity
extension DiagnosticSeverityExtension on DiagnosticSeverity {
  String get displayName {
    switch (this) {
      case DiagnosticSeverity.error:
        return 'Error';
      case DiagnosticSeverity.warning:
        return 'Warning';
      case DiagnosticSeverity.info:
        return 'Info';
    }
  }
}
