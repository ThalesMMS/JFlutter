import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/use_cases/algorithm_use_cases.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/models/grammar.dart';
import '../../core/result.dart';

/// Provider for algorithm operations
class AlgorithmProvider extends StateNotifier<AlgorithmState> {
  final NfaToDfaUseCase _nfaToDfaUseCase;
  final RemoveLambdaTransitionsUseCase _removeLambdaTransitionsUseCase;
  final MinimizeDfaUseCase _minimizeDfaUseCase;
  final CompleteDfaUseCase _completeDfaUseCase;
  final ComplementDfaUseCase _complementDfaUseCase;
  final UnionDfaUseCase _unionDfaUseCase;
  final IntersectionDfaUseCase _intersectionDfaUseCase;
  final DifferenceDfaUseCase _differenceDfaUseCase;
  final PrefixClosureUseCase _prefixClosureUseCase;
  final SuffixClosureUseCase _suffixClosureUseCase;
  final RegexToNfaUseCase _regexToNfaUseCase;
  final DfaToRegexUseCase _dfaToRegexUseCase;
  final FsaToGrammarUseCase _fsaToGrammarUseCase;
  final CheckEquivalenceUseCase _checkEquivalenceUseCase;
  final SimulateWordUseCase _simulateWordUseCase;
  final CreateStepByStepSimulationUseCase _createStepByStepSimulationUseCase;

  AlgorithmProvider({
    required NfaToDfaUseCase nfaToDfaUseCase,
    required RemoveLambdaTransitionsUseCase removeLambdaTransitionsUseCase,
    required MinimizeDfaUseCase minimizeDfaUseCase,
    required CompleteDfaUseCase completeDfaUseCase,
    required ComplementDfaUseCase complementDfaUseCase,
    required UnionDfaUseCase unionDfaUseCase,
    required IntersectionDfaUseCase intersectionDfaUseCase,
    required DifferenceDfaUseCase differenceDfaUseCase,
    required PrefixClosureUseCase prefixClosureUseCase,
    required SuffixClosureUseCase suffixClosureUseCase,
    required RegexToNfaUseCase regexToNfaUseCase,
    required DfaToRegexUseCase dfaToRegexUseCase,
    required FsaToGrammarUseCase fsaToGrammarUseCase,
    required CheckEquivalenceUseCase checkEquivalenceUseCase,
    required SimulateWordUseCase simulateWordUseCase,
    required CreateStepByStepSimulationUseCase createStepByStepSimulationUseCase,
  }) : _nfaToDfaUseCase = nfaToDfaUseCase,
       _removeLambdaTransitionsUseCase = removeLambdaTransitionsUseCase,
       _minimizeDfaUseCase = minimizeDfaUseCase,
       _completeDfaUseCase = completeDfaUseCase,
       _complementDfaUseCase = complementDfaUseCase,
       _unionDfaUseCase = unionDfaUseCase,
       _intersectionDfaUseCase = intersectionDfaUseCase,
       _differenceDfaUseCase = differenceDfaUseCase,
       _prefixClosureUseCase = prefixClosureUseCase,
       _suffixClosureUseCase = suffixClosureUseCase,
       _regexToNfaUseCase = regexToNfaUseCase,
       _dfaToRegexUseCase = dfaToRegexUseCase,
       _fsaToGrammarUseCase = fsaToGrammarUseCase,
       _checkEquivalenceUseCase = checkEquivalenceUseCase,
       _simulateWordUseCase = simulateWordUseCase,
       _createStepByStepSimulationUseCase = createStepByStepSimulationUseCase,
       super(AlgorithmState.initial());

  /// Converts NFA to DFA
  Future<void> convertNfaToDfa(AutomatonEntity nfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _nfaToDfaUseCase.execute(nfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Removes lambda transitions from NFA
  Future<void> removeLambdaTransitions(AutomatonEntity nfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _removeLambdaTransitionsUseCase.execute(nfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Minimizes DFA
  Future<void> minimizeDfa(AutomatonEntity dfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _minimizeDfaUseCase.execute(dfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Completes DFA
  Future<void> completeDfa(AutomatonEntity dfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _completeDfaUseCase.execute(dfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Complements DFA
  Future<void> complementDfa(AutomatonEntity dfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _complementDfaUseCase.execute(dfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Unions two DFAs
  Future<void> unionDfa(AutomatonEntity dfa1, AutomatonEntity dfa2) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _unionDfaUseCase.execute(dfa1, dfa2);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Intersects two DFAs
  Future<void> intersectionDfa(AutomatonEntity dfa1, AutomatonEntity dfa2) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _intersectionDfaUseCase.execute(dfa1, dfa2);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Differences two DFAs
  Future<void> differenceDfa(AutomatonEntity dfa1, AutomatonEntity dfa2) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _differenceDfaUseCase.execute(dfa1, dfa2);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Prefix closure of DFA
  Future<void> prefixClosureDfa(AutomatonEntity dfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _prefixClosureUseCase.execute(dfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Suffix closure of DFA
  Future<void> suffixClosureDfa(AutomatonEntity dfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _suffixClosureUseCase.execute(dfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Converts regex to NFA
  Future<void> convertRegexToNfa(String regex) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _regexToNfaUseCase.execute(regex);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Converts DFA to regex
  Future<void> convertDfaToRegex(AutomatonEntity dfa) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _dfaToRegexUseCase.execute(dfa);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Converts FSA to grammar
  Future<void> convertFsaToGrammar(AutomatonEntity fsa) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _fsaToGrammarUseCase.execute(fsa);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Checks equivalence of two automata
  Future<void> checkEquivalence(AutomatonEntity automaton1, AutomatonEntity automaton2) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _checkEquivalenceUseCase.execute(automaton1, automaton2);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Simulates word on automaton
  Future<void> simulateWord(AutomatonEntity automaton, String word) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _simulateWordUseCase.execute(automaton, word);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Creates step-by-step simulation
  Future<void> createStepByStepSimulation(AutomatonEntity automaton, String word) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _createStepByStepSimulationUseCase.execute(automaton, word);
    
    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        result: result.data,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: result.error,
      );
    }
  }

  /// Clears the current result
  void clearResult() {
    state = state.copyWith(result: null, error: null);
  }
}

/// State for algorithm operations
class AlgorithmState {
  final bool isLoading;
  final String? error;
  final dynamic result;

  const AlgorithmState({
    required this.isLoading,
    this.error,
    this.result,
  });

  factory AlgorithmState.initial() {
    return const AlgorithmState(
      isLoading: false,
      error: null,
      result: null,
    );
  }

  AlgorithmState copyWith({
    bool? isLoading,
    String? error,
    dynamic result,
  }) {
    return AlgorithmState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }
}
