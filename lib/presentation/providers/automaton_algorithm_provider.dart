//
//  automaton_algorithm_provider.dart
//  JFlutter
//
//  Gerencia a execução de algoritmos formais (conversões, minimização,
//  equivalência) sobre autômatos, expondo operações reativas que invocam
//  algoritmos do núcleo e atualizam estados de resultado, mantendo separação
//  de responsabilidades com AutomatonStateProvider para operações CRUD.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/dfa_minimizer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/fa_to_regex_converter.dart';
import '../../core/algorithms/fsa_to_grammar_converter.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import 'automaton_state_provider.dart';

/// State for algorithm operations
class AlgorithmOperationState {
  final String? regexResult;
  final Grammar? grammarResult;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final bool isLoading;
  final String? error;

  const AlgorithmOperationState({
    this.regexResult,
    this.grammarResult,
    this.equivalenceResult,
    this.equivalenceDetails,
    this.isLoading = false,
    this.error,
  });

  static const _unset = Object();

  AlgorithmOperationState copyWith({
    Object? regexResult = _unset,
    Object? grammarResult = _unset,
    Object? equivalenceResult = _unset,
    Object? equivalenceDetails = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return AlgorithmOperationState(
      regexResult: regexResult == _unset
          ? this.regexResult
          : regexResult as String?,
      grammarResult: grammarResult == _unset
          ? this.grammarResult
          : grammarResult as Grammar?,
      equivalenceResult: equivalenceResult == _unset
          ? this.equivalenceResult
          : equivalenceResult as bool?,
      equivalenceDetails: equivalenceDetails == _unset
          ? this.equivalenceDetails
          : equivalenceDetails as String?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  /// Clear all algorithm results
  AlgorithmOperationState clear() {
    return const AlgorithmOperationState();
  }

  /// Clear only error state
  AlgorithmOperationState clearError() {
    return copyWith(error: null);
  }
}

/// Provider for automaton algorithm operations
class AutomatonAlgorithmNotifier
    extends StateNotifier<AlgorithmOperationState> {
  final Ref ref;

  AutomatonAlgorithmNotifier(this.ref)
    : super(const AlgorithmOperationState()) {
    // Listen to automaton state changes and clear results when automaton changes
    ref.listen<AutomatonStateProviderState>(automatonStateProvider, (
      previous,
      next,
    ) {
      // Clear algorithm results when the automaton changes
      final previousAutomaton = previous?.currentAutomaton;
      final nextAutomaton = next.currentAutomaton;
      if (!identical(previousAutomaton, nextAutomaton)) {
        state = state.clear();
      }
    });
  }

  /// Converts NFA to DFA
  Future<void> convertNfaToDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = NFAToDFAConverter.convert(currentAutomaton);

      if (result.isSuccess) {
        // Update the automaton in the state provider
        ref.read(automatonStateProvider.notifier).updateAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting NFA to DFA: $e',
      );
    }
  }

  /// Minimizes DFA
  Future<void> minimizeDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = DFAMinimizer.minimize(currentAutomaton);

      if (result.isSuccess) {
        // Update the automaton in the state provider
        ref.read(automatonStateProvider.notifier).updateAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error minimizing DFA: $e',
      );
    }
  }

  /// Completes DFA
  Future<void> completeDfa() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final result = DFACompleter.complete(currentAutomaton);
      // Update the automaton in the state provider
      ref.read(automatonStateProvider.notifier).updateAutomaton(result);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error completing DFA: $e',
      );
    }
  }

  /// Converts FSA to Grammar
  Future<Grammar?> convertFsaToGrammar() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = FSAToGrammarConverter.convert(currentAutomaton);
      state = state.copyWith(isLoading: false, grammarResult: result);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FSA to Grammar: $e',
      );
      return null;
    }
  }

  /// Converts regex to NFA
  Future<void> convertRegexToNfa(String regex) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      // Use the core algorithm directly
      final result = RegexToNFAConverter.convert(regex);

      if (result.isSuccess) {
        // Update the automaton in the state provider
        ref.read(automatonStateProvider.notifier).updateAutomaton(result.data!);
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting regex to NFA: $e',
      );
    }
  }

  /// Converts FA to regex
  Future<String?> convertFaToRegex() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use the core algorithm directly
      final result = FAToRegexConverter.convert(currentAutomaton);

      if (result.isSuccess) {
        // Store the regex result in state
        state = state.copyWith(regexResult: result.data, isLoading: false);
        return result.data;
      } else {
        state = state.copyWith(isLoading: false, error: result.error);
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error converting FA to regex: $e',
      );
      return null;
    }
  }

  /// Compares the current automaton with another automaton for equivalence
  Future<bool?> compareEquivalence(FSA other) async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return null;

    state = state.copyWith(
      isLoading: true,
      error: null,
      equivalenceResult: null,
      equivalenceDetails: null,
    );

    try {
      final areEquivalent = EquivalenceChecker.areEquivalent(
        currentAutomaton,
        other,
      );
      state = state.copyWith(
        isLoading: false,
        equivalenceResult: areEquivalent,
        equivalenceDetails: areEquivalent
            ? 'The automata accept the same language.'
            : 'A distinguishing string was found between the automata.',
      );
      return areEquivalent;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        equivalenceResult: null,
        equivalenceDetails: 'Error comparing automata: $e',
        error: 'Error comparing automata: $e',
      );
      return null;
    }
  }

  /// Clear algorithm results
  void clearAlgorithmResults() {
    state = state.clear();
  }

  /// Clears any error messages
  void clearError() {
    state = state.clearError();
  }
}

/// Provider registration for automaton algorithm operations
final automatonAlgorithmProvider =
    StateNotifierProvider<AutomatonAlgorithmNotifier, AlgorithmOperationState>(
      (ref) => AutomatonAlgorithmNotifier(ref),
    );
