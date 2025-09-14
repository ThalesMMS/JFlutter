import 'package:flutter/foundation.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/use_cases/algorithm_use_cases.dart';
import '../../core/repositories/automaton_repository.dart';

/// Provider for managing algorithm operations
class AlgorithmProvider extends ChangeNotifier {
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
  final CheckEquivalenceUseCase _checkEquivalenceUseCase;
  final SimulateWordUseCase _simulateWordUseCase;
  final CreateStepByStepSimulationUseCase _createStepByStepSimulationUseCase;

  bool _isLoading = false;
  String? _error;
  String? _lastRegexResult;
  bool? _lastEquivalenceResult;

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
    required CheckEquivalenceUseCase checkEquivalenceUseCase,
    required SimulateWordUseCase simulateWordUseCase,
    required CreateStepByStepSimulationUseCase createStepByStepSimulationUseCase,
  })  : _nfaToDfaUseCase = nfaToDfaUseCase,
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
        _checkEquivalenceUseCase = checkEquivalenceUseCase,
        _simulateWordUseCase = simulateWordUseCase,
        _createStepByStepSimulationUseCase = createStepByStepSimulationUseCase;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get lastRegexResult => _lastRegexResult;
  bool? get lastEquivalenceResult => _lastEquivalenceResult;

  /// Converts NFA to DFA
  Future<AutomatonEntity?> nfaToDfa(AutomatonEntity nfa) async {
    _setLoading(true);
    _clearError();

    final result = await _nfaToDfaUseCase.execute(nfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Removes lambda transitions from NFA
  Future<AutomatonEntity?> removeLambdaTransitions(AutomatonEntity nfa) async {
    _setLoading(true);
    _clearError();

    final result = await _removeLambdaTransitionsUseCase.execute(nfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Minimizes a DFA
  Future<AutomatonEntity?> minimizeDfa(AutomatonEntity dfa) async {
    _setLoading(true);
    _clearError();

    final result = await _minimizeDfaUseCase.execute(dfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Completes a DFA
  Future<AutomatonEntity?> completeDfa(AutomatonEntity dfa) async {
    _setLoading(true);
    _clearError();

    final result = await _completeDfaUseCase.execute(dfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates complement of a DFA
  Future<AutomatonEntity?> complementDfa(AutomatonEntity dfa) async {
    _setLoading(true);
    _clearError();

    final result = await _complementDfaUseCase.execute(dfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates union of two DFAs
  Future<AutomatonEntity?> unionDfa(AutomatonEntity a, AutomatonEntity b) async {
    _setLoading(true);
    _clearError();

    final result = await _unionDfaUseCase.execute(a, b);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates intersection of two DFAs
  Future<AutomatonEntity?> intersectionDfa(AutomatonEntity a, AutomatonEntity b) async {
    _setLoading(true);
    _clearError();

    final result = await _intersectionDfaUseCase.execute(a, b);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates difference of two DFAs
  Future<AutomatonEntity?> differenceDfa(AutomatonEntity a, AutomatonEntity b) async {
    _setLoading(true);
    _clearError();

    final result = await _differenceDfaUseCase.execute(a, b);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates prefix closure of a DFA
  Future<AutomatonEntity?> prefixClosureDfa(AutomatonEntity dfa) async {
    _setLoading(true);
    _clearError();

    final result = await _prefixClosureUseCase.execute(dfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates suffix closure of a DFA
  Future<AutomatonEntity?> suffixClosureDfa(AutomatonEntity dfa) async {
    _setLoading(true);
    _clearError();

    final result = await _suffixClosureUseCase.execute(dfa);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Converts regex to NFA
  Future<AutomatonEntity?> regexToNfa(String regex) async {
    _setLoading(true);
    _clearError();

    final result = await _regexToNfaUseCase.execute(regex);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Converts DFA to regex
  Future<String?> dfaToRegex(AutomatonEntity dfa, {bool allowLambda = false}) async {
    _setLoading(true);
    _clearError();

    final result = await _dfaToRegexUseCase.execute(dfa, allowLambda: allowLambda);

    _setLoading(false);

    if (result.isSuccess) {
      _lastRegexResult = result.data!;
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Checks if two DFAs are equivalent
  Future<bool?> checkEquivalence(AutomatonEntity a, AutomatonEntity b) async {
    _setLoading(true);
    _clearError();

    final result = await _checkEquivalenceUseCase.execute(a, b);

    _setLoading(false);

    if (result.isSuccess) {
      _lastEquivalenceResult = result.data!;
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Simulates a word on an automaton
  Future<SimulationResult?> simulateWord(AutomatonEntity automaton, String word) async {
    _setLoading(true);
    _clearError();

    final result = await _simulateWordUseCase.execute(automaton, word);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Creates step-by-step simulation
  Future<StepByStepSimulation?> createStepByStepSimulation(
    AutomatonEntity automaton, 
    String word
  ) async {
    _setLoading(true);
    _clearError();

    final result = await _createStepByStepSimulationUseCase.execute(automaton, word);

    _setLoading(false);

    if (result.isSuccess) {
      return result.data;
    } else {
      _setError(result.error!);
      return null;
    }
  }

  /// Clears any error state
  void clearError() {
    _clearError();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

