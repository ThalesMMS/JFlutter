import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/automaton_simulator.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_analyzer.dart';
import '../../core/algorithms/regex_simplifier.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/regex_analysis.dart';

class RegexEditorOperationResult<T> {
  const RegexEditorOperationResult._({
    required this.isSuccess,
    this.data,
    this.error,
  });

  final bool isSuccess;
  final T? data;
  final String? error;

  bool get isFailure => !isSuccess;

  factory RegexEditorOperationResult.success([T? data]) {
    return RegexEditorOperationResult._(isSuccess: true, data: data);
  }

  factory RegexEditorOperationResult.failure([String? error]) {
    return RegexEditorOperationResult._(isSuccess: false, error: error);
  }
}

class RegexEditorState {
  const RegexEditorState({
    this.currentRegex = '',
    this.testString = '',
    this.isValid = false,
    this.matches = false,
    this.hasTested = false,
    this.errorMessage = '',
    this.equivalenceResult,
    this.equivalenceMessage = '',
    this.simplifyOutput = true,
    this.simplificationResult,
    this.showSimplificationSteps = false,
    this.selectedStepIndex = 0,
    this.regexAnalysis,
    this.showAnalysisDetails = false,
    this.sampleStrings,
    this.showSampleStringsDetails = false,
  });

  static const _unset = Object();

  final String currentRegex;
  final String testString;
  final bool isValid;
  final bool matches;
  final bool hasTested;
  final String errorMessage;
  final bool? equivalenceResult;
  final String equivalenceMessage;
  final bool simplifyOutput;
  final RegexSimplificationResult? simplificationResult;
  final bool showSimplificationSteps;
  final int selectedStepIndex;
  final RegexAnalysis? regexAnalysis;
  final bool showAnalysisDetails;
  final RegexSampleStrings? sampleStrings;
  final bool showSampleStringsDetails;

  bool get canRunRegexOperation => isValid && currentRegex.isNotEmpty;

  RegexEditorState copyWith({
    String? currentRegex,
    String? testString,
    bool? isValid,
    bool? matches,
    bool? hasTested,
    String? errorMessage,
    Object? equivalenceResult = _unset,
    String? equivalenceMessage,
    bool? simplifyOutput,
    Object? simplificationResult = _unset,
    bool? showSimplificationSteps,
    int? selectedStepIndex,
    Object? regexAnalysis = _unset,
    bool? showAnalysisDetails,
    Object? sampleStrings = _unset,
    bool? showSampleStringsDetails,
  }) {
    return RegexEditorState(
      currentRegex: currentRegex ?? this.currentRegex,
      testString: testString ?? this.testString,
      isValid: isValid ?? this.isValid,
      matches: matches ?? this.matches,
      hasTested: hasTested ?? this.hasTested,
      errorMessage: errorMessage ?? this.errorMessage,
      equivalenceResult: equivalenceResult == _unset
          ? this.equivalenceResult
          : equivalenceResult as bool?,
      equivalenceMessage: equivalenceMessage ?? this.equivalenceMessage,
      simplifyOutput: simplifyOutput ?? this.simplifyOutput,
      simplificationResult: simplificationResult == _unset
          ? this.simplificationResult
          : simplificationResult as RegexSimplificationResult?,
      showSimplificationSteps:
          showSimplificationSteps ?? this.showSimplificationSteps,
      selectedStepIndex: selectedStepIndex ?? this.selectedStepIndex,
      regexAnalysis: regexAnalysis == _unset
          ? this.regexAnalysis
          : regexAnalysis as RegexAnalysis?,
      showAnalysisDetails: showAnalysisDetails ?? this.showAnalysisDetails,
      sampleStrings: sampleStrings == _unset
          ? this.sampleStrings
          : sampleStrings as RegexSampleStrings?,
      showSampleStringsDetails:
          showSampleStringsDetails ?? this.showSampleStringsDetails,
    );
  }
}

class RegexEditorNotifier extends StateNotifier<RegexEditorState> {
  RegexEditorNotifier() : super(const RegexEditorState());

  void setSimplifyOutput(bool value) {
    state = state.copyWith(simplifyOutput: value);
  }

  void restorePersistedInput({
    required String currentRegex,
    required String testString,
    required bool simplifyOutput,
  }) {
    state = RegexEditorState(
      testString: testString,
      simplifyOutput: simplifyOutput,
    );

    if (currentRegex.isNotEmpty) {
      validateRegex(currentRegex);
      state = state.copyWith(testString: testString);
    }
  }

  void clearInputs() {
    state = RegexEditorState(simplifyOutput: state.simplifyOutput);
  }

  void validateRegex(String regex) {
    final nextState = state.copyWith(
      currentRegex: regex,
      errorMessage: '',
      hasTested: false,
    );

    if (regex.isEmpty) {
      state = nextState.copyWith(isValid: false);
      return;
    }

    try {
      if (_isValidRegex(regex)) {
        state = nextState.copyWith(isValid: true);
      } else {
        state = nextState.copyWith(
          isValid: false,
          errorMessage: 'Invalid regular expression syntax',
        );
      }
    } catch (error) {
      state = nextState.copyWith(
        isValid: false,
        errorMessage: 'Invalid regular expression: $error',
      );
    }
  }

  Future<void> testStringMatch(String input) async {
    state = state.copyWith(
      testString: input,
      errorMessage: '',
      hasTested: true,
      matches: state.canRunRegexOperation ? state.matches : false,
    );

    if (!state.canRunRegexOperation) {
      return;
    }

    try {
      final conversionResult = RegexToNFAConverter.convert(state.currentRegex);
      if (!conversionResult.isSuccess || conversionResult.data == null) {
        state = state.copyWith(
          matches: false,
          errorMessage:
              conversionResult.error ?? 'Unable to convert regex to NFA',
        );
        return;
      }

      final simulationResult = await AutomatonSimulator.simulateNFA(
        conversionResult.data!,
        input,
      );

      if (simulationResult.isSuccess && simulationResult.data != null) {
        final result = simulationResult.data!;
        state = state.copyWith(
          matches: result.isAccepted,
          errorMessage: !result.isAccepted && result.errorMessage.isNotEmpty
              ? result.errorMessage
              : state.errorMessage,
        );
      } else {
        state = state.copyWith(
          matches: false,
          errorMessage:
              simulationResult.error ?? 'Failed to simulate automaton',
        );
      }
    } catch (error) {
      state = state.copyWith(
        matches: false,
        errorMessage: 'Error testing string: $error',
      );
    }
  }

  RegexEditorOperationResult<FSA> convertToNfa() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<FSA>.failure();
    }

    final result = RegexToNFAConverter.convert(state.currentRegex);
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<FSA>.failure(result.error);
    }

    return RegexEditorOperationResult<FSA>.success(result.data!);
  }

  RegexEditorOperationResult<FSA> convertToDfa() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<FSA>.failure();
    }

    final regexToNfaResult = RegexToNFAConverter.convert(state.currentRegex);
    if (!regexToNfaResult.isSuccess || regexToNfaResult.data == null) {
      return RegexEditorOperationResult<FSA>.failure(regexToNfaResult.error);
    }

    final nfaToDfaResult = NFAToDFAConverter.convert(regexToNfaResult.data!);
    if (!nfaToDfaResult.isSuccess || nfaToDfaResult.data == null) {
      return RegexEditorOperationResult<FSA>.failure(nfaToDfaResult.error);
    }

    return RegexEditorOperationResult<FSA>.success(
      DFACompleter.complete(nfaToDfaResult.data!),
    );
  }

  void compareRegexEquivalence(String primaryInput, String secondaryInput) {
    final primary = primaryInput.trim();
    final secondary = secondaryInput.trim();

    state = state.copyWith(equivalenceResult: null, equivalenceMessage: '');

    if (primary.isEmpty || secondary.isEmpty) {
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: 'Enter both regular expressions to compare.',
      );
      return;
    }

    try {
      final firstConversion = RegexToNFAConverter.convert(primary);
      if (!firstConversion.isSuccess || firstConversion.data == null) {
        state = state.copyWith(
          equivalenceResult: false,
          equivalenceMessage:
              firstConversion.error ?? 'Unable to convert first regex to NFA',
        );
        return;
      }

      final secondConversion = RegexToNFAConverter.convert(secondary);
      if (!secondConversion.isSuccess || secondConversion.data == null) {
        state = state.copyWith(
          equivalenceResult: false,
          equivalenceMessage: secondConversion.error ??
              'Unable to convert second regex to NFA',
        );
        return;
      }

      final firstDfaResult = NFAToDFAConverter.convert(firstConversion.data!);
      if (!firstDfaResult.isSuccess || firstDfaResult.data == null) {
        state = state.copyWith(
          equivalenceResult: false,
          equivalenceMessage:
              firstDfaResult.error ?? 'Unable to convert first regex to DFA',
        );
        return;
      }

      final secondDfaResult = NFAToDFAConverter.convert(secondConversion.data!);
      if (!secondDfaResult.isSuccess || secondDfaResult.data == null) {
        state = state.copyWith(
          equivalenceResult: false,
          equivalenceMessage:
              secondDfaResult.error ?? 'Unable to convert second regex to DFA',
        );
        return;
      }

      final equivalent = EquivalenceChecker.areEquivalent(
        DFACompleter.complete(firstDfaResult.data!),
        DFACompleter.complete(secondDfaResult.data!),
      );

      state = state.copyWith(
        equivalenceResult: equivalent,
        equivalenceMessage: equivalent
            ? 'The regular expressions are equivalent.'
            : 'The regular expressions are not equivalent.',
      );
    } catch (error) {
      state = state.copyWith(
        equivalenceResult: false,
        equivalenceMessage: 'Error comparing regular expressions: $error',
      );
    }
  }

  RegexEditorOperationResult<void> runSimplificationWithSteps() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<void>.failure();
    }

    final result = RegexSimplifier.simplifyWithSteps(state.currentRegex);
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<void>.failure(result.error);
    }

    state = state.copyWith(
      simplificationResult: result.data,
      showSimplificationSteps: true,
      selectedStepIndex: 0,
    );
    return RegexEditorOperationResult<void>.success();
  }

  void clearSimplification() {
    state = state.copyWith(
      simplificationResult: null,
      showSimplificationSteps: false,
      selectedStepIndex: 0,
    );
  }

  void toggleSimplificationSteps() {
    state = state.copyWith(
      showSimplificationSteps: !state.showSimplificationSteps,
    );
  }

  void setSelectedStepIndex(int index) {
    final steps = state.simplificationResult?.steps ?? const [];
    if (index < 0 || index >= steps.length) {
      return;
    }
    state = state.copyWith(selectedStepIndex: index);
  }

  RegexEditorOperationResult<void> runComplexityAnalysis() {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<void>.failure();
    }

    final result = RegexAnalyzer.analyze(state.currentRegex);
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<void>.failure(result.error);
    }

    state = state.copyWith(
      regexAnalysis: result.data,
      showAnalysisDetails: true,
    );
    return RegexEditorOperationResult<void>.success();
  }

  void clearComplexityAnalysis() {
    state = state.copyWith(regexAnalysis: null, showAnalysisDetails: false);
  }

  void toggleAnalysisDetails() {
    state = state.copyWith(showAnalysisDetails: !state.showAnalysisDetails);
  }

  RegexEditorOperationResult<void> runSampleGeneration({
    int maxSamples = 10,
  }) {
    if (!state.canRunRegexOperation) {
      return RegexEditorOperationResult<void>.failure();
    }

    final result = RegexAnalyzer.generateSampleStrings(
      state.currentRegex,
      maxSamples: maxSamples,
      maxLength: 30,
    );
    if (!result.isSuccess || result.data == null) {
      return RegexEditorOperationResult<void>.failure(result.error);
    }

    state = state.copyWith(
      sampleStrings: result.data,
      showSampleStringsDetails: true,
    );
    return RegexEditorOperationResult<void>.success();
  }

  void clearSampleStrings() {
    state = state.copyWith(sampleStrings: null, showSampleStringsDetails: false);
  }

  void toggleSampleStringsDetails() {
    state = state.copyWith(
      showSampleStringsDetails: !state.showSampleStringsDetails,
    );
  }

  bool _isValidRegex(String regex) {
    int parenCount = 0;
    bool inBracket = false;
    bool escapeNext = false;

    for (var i = 0; i < regex.length; i++) {
      final char = regex[i];

      if (escapeNext) {
        escapeNext = false;
        continue;
      }

      if (char == '\\') {
        escapeNext = true;
        continue;
      }

      if (char == '[' && !escapeNext) {
        inBracket = true;
        continue;
      }

      if (char == ']' && !escapeNext) {
        inBracket = false;
        continue;
      }

      if (!inBracket) {
        if (char == '(') {
          parenCount++;
        } else if (char == ')') {
          parenCount--;
          if (parenCount < 0) return false;
        }
      }
    }

    return parenCount == 0 && !inBracket;
  }
}

final regexEditorProvider =
    StateNotifierProvider<RegexEditorNotifier, RegexEditorState>(
  (ref) => RegexEditorNotifier(),
);
