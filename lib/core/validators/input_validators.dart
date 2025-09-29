import '../models/fsa.dart';
import '../models/pda.dart';
import '../models/grammar.dart';
import '../models/tm.dart';

class ValidationIssue {
  final String code;
  final String message;
  final String? location;
  const ValidationIssue(this.code, this.message, {this.location});
}

class InputValidators {
  static List<ValidationIssue> validateFSA(FSA fsa) {
    final issues = <ValidationIssue>[];
    if (fsa.states.isEmpty) {
      issues.add(ValidationIssue('FSA_EMPTY', 'Automaton has no states'));
    }
    if (fsa.initialState == null) {
      issues.add(
          ValidationIssue('FSA_NO_INITIAL', 'Automaton has no initial state'));
    }
    for (final t in fsa.transitions) {
      if (!fsa.states.contains(t.fromState)) {
        issues.add(ValidationIssue(
            'FSA_BAD_FROM', 'Transition from unknown state ${t.fromState.id}'));
      }
      if (!fsa.states.contains(t.toState)) {
        issues.add(ValidationIssue(
            'FSA_BAD_TO', 'Transition to unknown state ${t.toState.id}'));
      }
    }
    return issues;
  }

  static List<ValidationIssue> validatePDA(PDA pda) {
    final issues = <ValidationIssue>[];
    if (pda.states.isEmpty) {
      issues.add(ValidationIssue('PDA_EMPTY', 'PDA has no states'));
    }
    if (pda.initialState == null) {
      issues.add(ValidationIssue('PDA_NO_INITIAL', 'PDA has no initial state'));
    }
    if (pda.acceptingStates.isEmpty) {
      issues.add(
          ValidationIssue('PDA_NO_ACCEPTING', 'PDA has no accepting states'));
    }
    return issues;
  }

  static List<ValidationIssue> validateGrammar(Grammar grammar) {
    final issues = <ValidationIssue>[];
    if (grammar.productions.isEmpty) {
      issues.add(ValidationIssue('CFG_EMPTY', 'Grammar has no productions'));
    }
    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      issues.add(ValidationIssue(
          'CFG_BAD_START', 'Start symbol must be a non-terminal'));
    }
    return issues;
  }

  static List<ValidationIssue> validateTM(TM tm) {
    final issues = <ValidationIssue>[];
    if (tm.states.isEmpty) {
      issues.add(ValidationIssue('TM_EMPTY', 'TM has no states'));
    }
    if (tm.initialState == null) {
      issues.add(ValidationIssue('TM_NO_INITIAL', 'TM has no initial state'));
    }
    if (!tm.tapeAlphabet.contains(tm.blankSymbol)) {
      issues.add(
          ValidationIssue('TM_BLANK', 'Blank symbol is not in tape alphabet'));
    }
    return issues;
  }
}
