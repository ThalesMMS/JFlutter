import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/automaton_simulator.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/simulation_result.dart';
import '../../core/result.dart';
import 'automaton_provider.dart';

@immutable
class RegexPageState {
  final String regexInput;
  final bool isValid;
  final String? validationMessage;
  final FSA? lastGeneratedNfa;
  final String testString;
  final bool? matchResult;
  final String? matchMessage;
  final SimulationResult? simulationResult;
  final String comparisonRegex;
  final bool? equivalenceResult;
  final String? equivalenceMessage;

  const RegexPageState({
    this.regexInput = '',
    this.isValid = false,
    this.validationMessage,
    this.lastGeneratedNfa,
    this.testString = '',
    this.matchResult,
    this.matchMessage,
    this.simulationResult,
    this.comparisonRegex = '',
    this.equivalenceResult,
    this.equivalenceMessage,
  });

  RegexPageState copyWith({
    String? regexInput,
    bool? isValid,
    String? validationMessage,
    FSA? lastGeneratedNfa,
    bool clearCachedNfa = false,
    String? testString,
    bool? matchResult,
    String? matchMessage,
    SimulationResult? simulationResult,
    bool clearSimulationResult = false,
    String? comparisonRegex,
    bool? equivalenceResult,
    String? equivalenceMessage,
  }) {
    return RegexPageState(
      regexInput: regexInput ?? this.regexInput,
      isValid: isValid ?? this.isValid,
      validationMessage: validationMessage,
      lastGeneratedNfa: clearCachedNfa
          ? null
          : (lastGeneratedNfa ?? this.lastGeneratedNfa),
      testString: testString ?? this.testString,
      matchResult: matchResult,
      matchMessage: matchMessage,
      simulationResult: clearSimulationResult
          ? null
          : (simulationResult ?? this.simulationResult),
      comparisonRegex: comparisonRegex ?? this.comparisonRegex,
      equivalenceResult: equivalenceResult,
      equivalenceMessage: equivalenceMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RegexPageState &&
        other.regexInput == regexInput &&
        other.isValid == isValid &&
        other.validationMessage == validationMessage &&
        other.lastGeneratedNfa == lastGeneratedNfa &&
        other.testString == testString &&
        other.matchResult == matchResult &&
        other.matchMessage == matchMessage &&
        other.simulationResult == simulationResult &&
        other.comparisonRegex == comparisonRegex &&
        other.equivalenceResult == equivalenceResult &&
        other.equivalenceMessage == equivalenceMessage;
  }

  @override
  int get hashCode => Object.hash(
        regexInput,
        isValid,
        validationMessage,
        lastGeneratedNfa,
        testString,
        matchResult,
        matchMessage,
        simulationResult,
        comparisonRegex,
        equivalenceResult,
        equivalenceMessage,
      );
}

class RegexPageViewModel extends StateNotifier<RegexPageState> {
  RegexPageViewModel(this._ref) : super(const RegexPageState());

  final Ref _ref;

  void updateRegexInput(String value) {
    state = state.copyWith(
      regexInput: value,
      isValid: false,
      validationMessage: null,
      matchResult: null,
      matchMessage: null,
      clearCachedNfa: true,
      clearSimulationResult: true,
      equivalenceResult: null,
      equivalenceMessage: null,
    );
  }

  void updateTestString(String value) {
    state = state.copyWith(
      testString: value,
      matchResult: null,
      matchMessage: null,
      clearSimulationResult: true,
    );
  }

  void updateComparisonRegex(String value) {
    state = state.copyWith(
      comparisonRegex: value,
      equivalenceResult: null,
      equivalenceMessage: null,
    );
  }

  void clearAll() {
    state = const RegexPageState();
  }

  Result<FSA> validateRegex() {
    final regex = state.regexInput.trim();
    if (regex.isEmpty) {
      state = state.copyWith(
        isValid: false,
        validationMessage: 'Regular expression cannot be empty',
        clearCachedNfa: true,
      );
      return ResultFactory.failure('Regular expression cannot be empty');
    }

    final result = RegexToNFAConverter.convert(regex);
    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        regexInput: regex,
        isValid: true,
        validationMessage: null,
        lastGeneratedNfa: result.data,
        clearSimulationResult: true,
      );
    } else {
      state = state.copyWith(
        isValid: false,
        validationMessage: result.error ?? 'Invalid regular expression',
        clearCachedNfa: true,
        clearSimulationResult: true,
      );
    }

    return result;
  }

  Result<bool> testStringMatch() {
    final testString = state.testString;
    if (testString.isEmpty) {
      state = state.copyWith(
        matchResult: null,
        matchMessage: null,
        clearSimulationResult: true,
      );
      return ResultFactory.failure('Test string cannot be empty');
    }

    final nfa = state.lastGeneratedNfa ?? _ensureNfa();
    if (nfa == null) {
      final message = state.validationMessage ??
          'Please validate the regular expression before testing.';
      state = state.copyWith(
        matchResult: null,
        matchMessage: message,
        clearSimulationResult: true,
      );
      return ResultFactory.failure(message);
    }

    final simulation = AutomatonSimulator.simulateNFA(nfa, testString);
    if (simulation.isSuccess && simulation.data != null) {
      final result = simulation.data!;
      state = state.copyWith(
        matchResult: result.isAccepted,
        matchMessage: result.errorMessage.isNotEmpty ? result.errorMessage : null,
        simulationResult: result,
      );
      return ResultFactory.success(result.isAccepted);
    } else {
      final message =
          simulation.error ?? 'Failed to simulate automaton for the test string';
      state = state.copyWith(
        matchResult: false,
        matchMessage: message,
        clearSimulationResult: true,
      );
      return ResultFactory.failure(message);
    }
  }

  Result<FSA> convertToNfa() {
    final regex = state.regexInput.trim();
    if (regex.isEmpty) {
      return ResultFactory.failure('Please enter a regular expression first');
    }

    final conversion = RegexToNFAConverter.convert(regex);
    if (conversion.isSuccess && conversion.data != null) {
      final nfa = conversion.data!;
      state = state.copyWith(
        regexInput: regex,
        isValid: true,
        validationMessage: null,
        lastGeneratedNfa: nfa,
      );
      _pushAutomaton(nfa);
    } else {
      state = state.copyWith(
        isValid: false,
        validationMessage:
            conversion.error ?? 'Failed to convert regex to automaton',
        clearCachedNfa: true,
      );
    }
    return conversion;
  }

  Result<FSA> convertToDfa() {
    final nfaResult = convertToNfa();
    if (!nfaResult.isSuccess || nfaResult.data == null) {
      return ResultFactory.failure(
          nfaResult.error ?? 'Failed to convert regex to NFA');
    }

    final nfa = nfaResult.data!;
    final dfaResult = NFAToDFAConverter.convert(nfa);
    if (!dfaResult.isSuccess || dfaResult.data == null) {
      final message = dfaResult.error ?? 'Failed to convert NFA to DFA';
      return ResultFactory.failure(message);
    }

    final completedDfa = DFACompleter.complete(dfaResult.data!);
    _pushAutomaton(completedDfa);
    return ResultFactory.success(completedDfa);
  }

  Result<bool> compareEquivalence() {
    final primary = state.regexInput.trim();
    final secondary = state.comparisonRegex.trim();

    if (primary.isEmpty || secondary.isEmpty) {
      const message = 'Enter both regular expressions to compare.';
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: message,
      );
      return ResultFactory.failure(message);
    }

    final firstConversion = RegexToNFAConverter.convert(primary);
    if (!firstConversion.isSuccess || firstConversion.data == null) {
      final message =
          firstConversion.error ?? 'Unable to convert first regex to NFA';
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: message,
      );
      return ResultFactory.failure(message);
    }

    final secondConversion = RegexToNFAConverter.convert(secondary);
    if (!secondConversion.isSuccess || secondConversion.data == null) {
      final message =
          secondConversion.error ?? 'Unable to convert second regex to NFA';
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: message,
      );
      return ResultFactory.failure(message);
    }

    final firstDfaResult = NFAToDFAConverter.convert(firstConversion.data!);
    if (!firstDfaResult.isSuccess || firstDfaResult.data == null) {
      final message =
          firstDfaResult.error ?? 'Unable to convert first regex to DFA';
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: message,
      );
      return ResultFactory.failure(message);
    }

    final secondDfaResult = NFAToDFAConverter.convert(secondConversion.data!);
    if (!secondDfaResult.isSuccess || secondDfaResult.data == null) {
      final message =
          secondDfaResult.error ?? 'Unable to convert second regex to DFA';
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: message,
      );
      return ResultFactory.failure(message);
    }

    final completedFirst = DFACompleter.complete(firstDfaResult.data!);
    final completedSecond = DFACompleter.complete(secondDfaResult.data!);

    final equivalent =
        EquivalenceChecker.areEquivalent(completedFirst, completedSecond);
    state = state.copyWith(
      equivalenceResult: equivalent,
      equivalenceMessage: equivalent
          ? 'The regular expressions are equivalent.'
          : 'The regular expressions are not equivalent.',
    );

    return ResultFactory.success(equivalent);
  }

  FSA? _ensureNfa() {
    final regex = state.regexInput.trim();
    if (regex.isEmpty) {
      return null;
    }

    final conversion = RegexToNFAConverter.convert(regex);
    if (conversion.isSuccess && conversion.data != null) {
      state = state.copyWith(
        regexInput: regex,
        isValid: true,
        validationMessage: null,
        lastGeneratedNfa: conversion.data,
      );
      return conversion.data;
    }

    state = state.copyWith(
      isValid: false,
      validationMessage:
          conversion.error ?? 'Unable to convert regex to automaton',
      clearCachedNfa: true,
    );
    return null;
  }

  void _pushAutomaton(FSA automaton) {
    try {
      final notifier = _ref.read(automatonProvider.notifier);
      notifier.updateAutomaton(automaton);
    } catch (_) {
      // In testing scenarios the provider may not be available.
    }
  }
}

final regexPageViewModelProvider =
    StateNotifierProvider<RegexPageViewModel, RegexPageState>((ref) {
  return RegexPageViewModel(ref);
});
