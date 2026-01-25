//
//  diagnostic_service.dart
//  JFlutter
//
//  Implementa análise avançada de autômatos produzindo issues, avisos e sugestões em
//  múltiplas dimensões estruturais, semânticas, de desempenho e usabilidade.
//  Calcula severidade agregada, identifica padrões problemáticos e recomenda ações
//  corretivas detalhadas através de modelos de resultado especializados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/fsa.dart';
import '../models/state.dart' as automaton_state;
import '../models/fsa_transition.dart';

/// Enhanced diagnostic service for providing detailed error messages and diagnostics
class DiagnosticService {
  /// Generates detailed error messages for common automaton issues
  static DiagnosticResult analyzeAutomaton(FSA automaton) {
    final issues = <DiagnosticIssue>[];
    final warnings = <DiagnosticWarning>[];
    final suggestions = <DiagnosticSuggestion>[];

    // Check for basic structural issues
    _analyzeStructure(automaton, issues, warnings, suggestions);

    // Check for semantic issues
    _analyzeSemantics(automaton, issues, warnings, suggestions);

    // Check for performance issues
    _analyzePerformance(automaton, issues, warnings, suggestions);

    // Check for usability issues
    _analyzeUsability(automaton, issues, warnings, suggestions);

    return DiagnosticResult(
      issues: issues,
      warnings: warnings,
      suggestions: suggestions,
      severity: _calculateSeverity(issues, warnings),
    );
  }

  /// Analyzes structural issues
  static void _analyzeStructure(
    FSA automaton,
    List<DiagnosticIssue> issues,
    List<DiagnosticWarning> warnings,
    List<DiagnosticSuggestion> suggestions,
  ) {
    // Check for empty automaton
    if (automaton.states.isEmpty) {
      issues.add(
        const DiagnosticIssue(
          type: DiagnosticIssueType.structural,
          severity: DiagnosticSeverity.error,
          message: 'Automaton has no states',
          description: 'An automaton must have at least one state to be valid.',
          suggestion: 'Add at least one state to the automaton.',
          code: 'EMPTY_AUTOMATON',
        ),
      );
      return;
    }

    // Check for missing initial state
    final initialStates = automaton.states.where((s) => s.isInitial).toList();
    if (initialStates.isEmpty) {
      issues.add(
        const DiagnosticIssue(
          type: DiagnosticIssueType.structural,
          severity: DiagnosticSeverity.error,
          message: 'No initial state found',
          description: 'Every automaton must have exactly one initial state.',
          suggestion:
              'Mark one state as initial by setting its initial property to true.',
          code: 'NO_INITIAL_STATE',
        ),
      );
    } else if (initialStates.length > 1) {
      issues.add(
        const DiagnosticIssue(
          type: DiagnosticIssueType.structural,
          severity: DiagnosticSeverity.error,
          message: 'Multiple initial states found',
          description: 'An automaton can have only one initial state.',
          suggestion: 'Remove the initial property from all but one state.',
          code: 'MULTIPLE_INITIAL_STATES',
        ),
      );
    }

    // Check for states without transitions
    for (final state in automaton.states) {
      final outgoingTransitions = automaton.transitions
          .where((t) => t.fromState.id == state.id)
          .toList();

      if (outgoingTransitions.isEmpty && !state.isAccepting) {
        warnings.add(
          DiagnosticWarning(
            type: DiagnosticWarningType.structural,
            message: 'State "${state.name}" has no outgoing transitions',
            description:
                'This state is unreachable from any other state and is not accepting.',
            suggestion:
                'Add transitions from this state or remove it if not needed.',
            code: 'ISOLATED_STATE',
          ),
        );
      }
    }

    // Check for unreachable states
    final reachableStates = _findReachableStates(automaton);
    for (final state in automaton.states) {
      if (!reachableStates.contains(state.id)) {
        warnings.add(
          DiagnosticWarning(
            type: DiagnosticWarningType.structural,
            message: 'State "${state.name}" is unreachable',
            description: 'This state cannot be reached from the initial state.',
            suggestion: 'Add transitions to reach this state or remove it.',
            code: 'UNREACHABLE_STATE',
          ),
        );
      }
    }
  }

  /// Analyzes semantic issues
  static void _analyzeSemantics(
    FSA automaton,
    List<DiagnosticIssue> issues,
    List<DiagnosticWarning> warnings,
    List<DiagnosticSuggestion> suggestions,
  ) {
    // Check for epsilon transitions in DFA
    final epsilonTransitions = automaton.transitions
        .where((t) => t is FSATransition && t.isEpsilonTransition)
        .toList();

    if (epsilonTransitions.isNotEmpty) {
      warnings.add(
        const DiagnosticWarning(
          type: DiagnosticWarningType.semantic,
          message: 'Epsilon transitions found',
          description:
              'This automaton contains epsilon transitions, making it an NFA rather than a DFA.',
          suggestion:
              'Remove epsilon transitions or convert to NFA explicitly.',
          code: 'EPSILON_TRANSITIONS',
        ),
      );
    }

    // Check for non-deterministic transitions
    final nondeterministicStates = _findNondeterministicStates(automaton);
    for (final stateId in nondeterministicStates) {
      final state = automaton.states.firstWhere((s) => s.id == stateId);
      warnings.add(
        DiagnosticWarning(
          type: DiagnosticWarningType.semantic,
          message: 'Non-deterministic state "${state.name}"',
          description:
              'This state has multiple transitions with the same input symbol.',
          suggestion: 'Convert to DFA or explicitly mark as NFA.',
          code: 'NONDETERMINISTIC_STATE',
        ),
      );
    }

    // Check for dead states
    final deadStates = _findDeadStates(automaton);
    for (final stateId in deadStates) {
      final state = automaton.states.firstWhere((s) => s.id == stateId);
      if (!state.isAccepting) {
        warnings.add(
          DiagnosticWarning(
            type: DiagnosticWarningType.semantic,
            message: 'Dead state "${state.name}"',
            description: 'This state cannot reach any accepting state.',
            suggestion:
                'Remove this state or add transitions to accepting states.',
            code: 'DEAD_STATE',
          ),
        );
      }
    }
  }

  /// Analyzes performance issues
  static void _analyzePerformance(
    FSA automaton,
    List<DiagnosticIssue> issues,
    List<DiagnosticWarning> warnings,
    List<DiagnosticSuggestion> suggestions,
  ) {
    // Check for large automaton
    if (automaton.states.length > 50) {
      warnings.add(
        DiagnosticWarning(
          type: DiagnosticWarningType.performance,
          message: 'Large automaton detected',
          description:
              'This automaton has ${automaton.states.length} states, which may impact performance.',
          suggestion:
              'Consider minimizing the automaton or breaking it into smaller parts.',
          code: 'LARGE_AUTOMATON',
        ),
      );
    }

    // Check for many transitions
    if (automaton.transitions.length > 200) {
      warnings.add(
        DiagnosticWarning(
          type: DiagnosticWarningType.performance,
          message: 'Many transitions detected',
          description:
              'This automaton has ${automaton.transitions.length} transitions, which may impact performance.',
          suggestion: 'Consider optimizing the automaton structure.',
          code: 'MANY_TRANSITIONS',
        ),
      );
    }

    // Check for complex alphabet
    if (automaton.alphabet.length > 20) {
      warnings.add(
        DiagnosticWarning(
          type: DiagnosticWarningType.performance,
          message: 'Large alphabet detected',
          description:
              'This automaton has ${automaton.alphabet.length} symbols in its alphabet.',
          suggestion: 'Consider using a more compact alphabet representation.',
          code: 'LARGE_ALPHABET',
        ),
      );
    }
  }

  /// Analyzes usability issues
  static void _analyzeUsability(
    FSA automaton,
    List<DiagnosticIssue> issues,
    List<DiagnosticWarning> warnings,
    List<DiagnosticSuggestion> suggestions,
  ) {
    // Check for overlapping states
    final overlappingStates = _findOverlappingStates(automaton);
    for (final pair in overlappingStates) {
      warnings.add(
        DiagnosticWarning(
          type: DiagnosticWarningType.usability,
          message: 'Overlapping states detected',
          description:
              'States "${pair.$1.name}" and "${pair.$2.name}" are positioned too close together.',
          suggestion: 'Move one of the states to improve visibility.',
          code: 'OVERLAPPING_STATES',
        ),
      );
    }

    // Check for long transition labels
    for (final transition in automaton.transitions) {
      if (transition.label.length > 10) {
        warnings.add(
          DiagnosticWarning(
            type: DiagnosticWarningType.usability,
            message: 'Long transition label',
            description:
                'Transition label "${transition.label}" is very long and may be hard to read.',
            suggestion: 'Consider shortening the label or using abbreviations.',
            code: 'LONG_TRANSITION_LABEL',
          ),
        );
      }
    }

    // Check for missing state labels
    for (final state in automaton.states) {
      if (state.name.isEmpty || state.name == state.id) {
        suggestions.add(
          DiagnosticSuggestion(
            type: DiagnosticSuggestionType.usability,
            message: 'Add descriptive state label',
            description:
                'State "${state.id}" could benefit from a more descriptive name.',
            suggestion:
                'Consider renaming the state to something more meaningful.',
            code: 'DESCRIPTIVE_STATE_NAME',
          ),
        );
      }
    }
  }

  /// Finds reachable states from the initial state
  static Set<String> _findReachableStates(FSA automaton) {
    final initialState = automaton.states.where((s) => s.isInitial).firstOrNull;
    if (initialState == null) return {};

    final reachable = <String>{};
    final toVisit = <String>[initialState.id];

    while (toVisit.isNotEmpty) {
      final currentId = toVisit.removeAt(0);
      if (reachable.contains(currentId)) continue;

      reachable.add(currentId);

      final outgoingTransitions = automaton.transitions.where(
        (t) => t.fromState.id == currentId,
      );

      for (final transition in outgoingTransitions) {
        toVisit.add(transition.toState.id);
      }
    }

    return reachable;
  }

  /// Finds non-deterministic states
  static Set<String> _findNondeterministicStates(FSA automaton) {
    final nondeterministic = <String>{};

    for (final state in automaton.states) {
      final transitions = automaton.transitions
          .where((t) => t.fromState.id == state.id)
          .toList();

      final symbolTransitions = <String, List<FSATransition>>{};

      for (final transition in transitions) {
        if (transition is FSATransition) {
          for (final symbol in transition.inputSymbols) {
            symbolTransitions.putIfAbsent(symbol, () => []);
            symbolTransitions[symbol]!.add(transition);
          }
        }
      }

      for (final symbol in symbolTransitions.keys) {
        if (symbolTransitions[symbol]!.length > 1) {
          nondeterministic.add(state.id);
          break;
        }
      }
    }

    return nondeterministic;
  }

  /// Finds dead states (states that cannot reach accepting states)
  static Set<String> _findDeadStates(FSA automaton) {
    final acceptingStates = automaton.states
        .where((s) => s.isAccepting)
        .map((s) => s.id)
        .toSet();

    final deadStates = <String>{};

    for (final state in automaton.states) {
      if (acceptingStates.contains(state.id)) continue;

      final reachable = <String>{};
      final toVisit = <String>[state.id];

      while (toVisit.isNotEmpty) {
        final currentId = toVisit.removeAt(0);
        if (reachable.contains(currentId)) continue;

        reachable.add(currentId);

        if (acceptingStates.contains(currentId)) {
          // This state can reach an accepting state
          break;
        }

        final outgoingTransitions = automaton.transitions.where(
          (t) => t.fromState.id == currentId,
        );

        for (final transition in outgoingTransitions) {
          toVisit.add(transition.toState.id);
        }
      }

      if (!reachable.any((id) => acceptingStates.contains(id))) {
        deadStates.add(state.id);
      }
    }

    return deadStates;
  }

  /// Finds overlapping states
  static List<(automaton_state.State, automaton_state.State)>
  _findOverlappingStates(FSA automaton) {
    final overlapping = <(automaton_state.State, automaton_state.State)>[];
    const minDistance = 60.0; // Minimum distance between states

    final states = automaton.states.toList();
    for (int i = 0; i < states.length; i++) {
      for (int j = i + 1; j < states.length; j++) {
        final state1 = states[i];
        final state2 = states[j];

        final distance = (state1.position - state2.position).length;
        if (distance < minDistance) {
          overlapping.add((state1, state2));
        }
      }
    }

    return overlapping;
  }

  /// Calculates overall severity
  static DiagnosticSeverity _calculateSeverity(
    List<DiagnosticIssue> issues,
    List<DiagnosticWarning> warnings,
  ) {
    if (issues.any((i) => i.severity == DiagnosticSeverity.error)) {
      return DiagnosticSeverity.error;
    }
    if (issues.any((i) => i.severity == DiagnosticSeverity.warning)) {
      return DiagnosticSeverity.warning;
    }
    if (warnings.isNotEmpty) {
      return DiagnosticSeverity.warning;
    }
    return DiagnosticSeverity.info;
  }

  /// Generates a user-friendly error message
  static String generateErrorMessage(DiagnosticResult result) {
    if (result.issues.isEmpty && result.warnings.isEmpty) {
      return 'Automaton is valid with no issues detected.';
    }

    final buffer = StringBuffer();

    if (result.issues.isNotEmpty) {
      buffer.writeln('Issues found:');
      for (final issue in result.issues) {
        buffer.writeln('• ${issue.message}');
        if (issue.suggestion.isNotEmpty) {
          buffer.writeln('  Suggestion: ${issue.suggestion}');
        }
      }
    }

    if (result.warnings.isNotEmpty) {
      if (result.issues.isNotEmpty) buffer.writeln();
      buffer.writeln('Warnings:');
      for (final warning in result.warnings) {
        buffer.writeln('• ${warning.message}');
        if (warning.suggestion.isNotEmpty) {
          buffer.writeln('  Suggestion: ${warning.suggestion}');
        }
      }
    }

    return buffer.toString().trim();
  }

  /// Generates a detailed diagnostic report
  static String generateDiagnosticReport(DiagnosticResult result) {
    final buffer = StringBuffer();

    buffer.writeln('=== AUTOMATON DIAGNOSTIC REPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Overall Severity: ${result.severity.name.toUpperCase()}');
    buffer.writeln();

    if (result.issues.isNotEmpty) {
      buffer.writeln('ISSUES (${result.issues.length}):');
      for (int i = 0; i < result.issues.length; i++) {
        final issue = result.issues[i];
        buffer.writeln(
          '${i + 1}. [${issue.severity.name.toUpperCase()}] ${issue.message}',
        );
        buffer.writeln('   Code: ${issue.code}');
        buffer.writeln('   Description: ${issue.description}');
        if (issue.suggestion.isNotEmpty) {
          buffer.writeln('   Suggestion: ${issue.suggestion}');
        }
        buffer.writeln();
      }
    }

    if (result.warnings.isNotEmpty) {
      buffer.writeln('WARNINGS (${result.warnings.length}):');
      for (int i = 0; i < result.warnings.length; i++) {
        final warning = result.warnings[i];
        buffer.writeln(
          '${i + 1}. [${warning.type.name.toUpperCase()}] ${warning.message}',
        );
        buffer.writeln('   Code: ${warning.code}');
        buffer.writeln('   Description: ${warning.description}');
        if (warning.suggestion.isNotEmpty) {
          buffer.writeln('   Suggestion: ${warning.suggestion}');
        }
        buffer.writeln();
      }
    }

    if (result.suggestions.isNotEmpty) {
      buffer.writeln('SUGGESTIONS (${result.suggestions.length}):');
      for (int i = 0; i < result.suggestions.length; i++) {
        final suggestion = result.suggestions[i];
        buffer.writeln(
          '${i + 1}. [${suggestion.type.name.toUpperCase()}] ${suggestion.message}',
        );
        buffer.writeln('   Description: ${suggestion.description}');
        buffer.writeln('   Suggestion: ${suggestion.suggestion}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }
}

/// Result of diagnostic analysis
class DiagnosticResult {
  final List<DiagnosticIssue> issues;
  final List<DiagnosticWarning> warnings;
  final List<DiagnosticSuggestion> suggestions;
  final DiagnosticSeverity severity;

  const DiagnosticResult({
    required this.issues,
    required this.warnings,
    required this.suggestions,
    required this.severity,
  });

  bool get hasIssues => issues.isNotEmpty;
  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasSuggestions => suggestions.isNotEmpty;
  bool get isHealthy => !hasIssues && !hasWarnings;
}

/// Diagnostic issue
class DiagnosticIssue {
  final DiagnosticIssueType type;
  final DiagnosticSeverity severity;
  final String message;
  final String description;
  final String suggestion;
  final String code;

  const DiagnosticIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.description,
    required this.suggestion,
    required this.code,
  });
}

/// Diagnostic warning
class DiagnosticWarning {
  final DiagnosticWarningType type;
  final String message;
  final String description;
  final String suggestion;
  final String code;

  const DiagnosticWarning({
    required this.type,
    required this.message,
    required this.description,
    required this.suggestion,
    required this.code,
  });
}

/// Diagnostic suggestion
class DiagnosticSuggestion {
  final DiagnosticSuggestionType type;
  final String message;
  final String description;
  final String suggestion;
  final String code;

  const DiagnosticSuggestion({
    required this.type,
    required this.message,
    required this.description,
    required this.suggestion,
    required this.code,
  });
}

/// Diagnostic issue types
enum DiagnosticIssueType { structural, semantic, performance, usability }

/// Diagnostic warning types
enum DiagnosticWarningType { structural, semantic, performance, usability }

/// Diagnostic suggestion types
enum DiagnosticSuggestionType { structural, semantic, performance, usability }

/// Diagnostic severity levels
enum DiagnosticSeverity { info, warning, error }
