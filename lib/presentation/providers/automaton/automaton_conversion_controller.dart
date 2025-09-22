import '../../../core/models/fsa.dart';
import '../../../core/use_cases/algorithm_use_cases.dart';
import '../../../core/utils/automaton_entity_mapper.dart';

import 'automaton_state.dart';

class AutomatonConversionController {
  final NfaToDfaUseCase _nfaToDfaUseCase;
  final MinimizeDfaUseCase _minimizeDfaUseCase;
  final CompleteDfaUseCase _completeDfaUseCase;
  final RegexToNfaUseCase _regexToNfaUseCase;
  final DfaToRegexUseCase _dfaToRegexUseCase;
  final FsaToGrammarUseCase _fsaToGrammarUseCase;
  final CheckEquivalenceUseCase _checkEquivalenceUseCase;

  AutomatonConversionController({
    required NfaToDfaUseCase nfaToDfaUseCase,
    required MinimizeDfaUseCase minimizeDfaUseCase,
    required CompleteDfaUseCase completeDfaUseCase,
    required RegexToNfaUseCase regexToNfaUseCase,
    required DfaToRegexUseCase dfaToRegexUseCase,
    required FsaToGrammarUseCase fsaToGrammarUseCase,
    required CheckEquivalenceUseCase checkEquivalenceUseCase,
  })  : _nfaToDfaUseCase = nfaToDfaUseCase,
        _minimizeDfaUseCase = minimizeDfaUseCase,
        _completeDfaUseCase = completeDfaUseCase,
        _regexToNfaUseCase = regexToNfaUseCase,
        _dfaToRegexUseCase = dfaToRegexUseCase,
        _fsaToGrammarUseCase = fsaToGrammarUseCase,
        _checkEquivalenceUseCase = checkEquivalenceUseCase;

  Future<AutomatonState> convertNfaToDfa(AutomatonState state) async {
    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _nfaToDfaUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        return state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
          simulationResult: null,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error converting NFA to DFA: $e',
      );
    }
  }

  Future<AutomatonState> minimizeDfa(AutomatonState state) async {
    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _minimizeDfaUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        return state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
          simulationResult: null,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error minimizing DFA: $e',
      );
    }
  }

  Future<AutomatonState> completeDfa(AutomatonState state) async {
    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _completeDfaUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        return state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
          simulationResult: null,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error completing DFA: $e',
      );
    }
  }

  Future<AutomatonState> convertRegexToNfa(
    AutomatonState state,
    String regex,
  ) async {
    try {
      final result = await _regexToNfaUseCase.execute(regex);

      if (result.isSuccess) {
        return state.copyWith(
          currentAutomaton: automatonEntityToFsa(result.data!),
          simulationResult: null,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error converting regex to NFA: $e',
      );
    }
  }

  Future<AutomatonState> convertFsaToGrammar(AutomatonState state) async {
    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _fsaToGrammarUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        return state.copyWith(
          grammarResult: result.data,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error converting FSA to Grammar: $e',
      );
    }
  }

  Future<AutomatonState> convertFaToRegex(AutomatonState state) async {
    try {
      final automatonEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final result = await _dfaToRegexUseCase.execute(automatonEntity);

      if (result.isSuccess) {
        return state.copyWith(
          regexResult: result.data,
          isLoading: false,
        );
      } else {
        return state.copyWith(
          isLoading: false,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        error: 'Error converting FA to regex: $e',
      );
    }
  }

  Future<AutomatonState> compareEquivalence(
    AutomatonState state,
    FSA other,
  ) async {
    try {
      final currentEntity = fsaToAutomatonEntity(state.currentAutomaton!);
      final otherEntity = fsaToAutomatonEntity(other);
      final result = await _checkEquivalenceUseCase.execute(
        currentEntity,
        otherEntity,
      );

      if (result.isSuccess) {
        final areEquivalent = result.data!;
        return state.copyWith(
          isLoading: false,
          equivalenceResult: areEquivalent,
          equivalenceDetails: areEquivalent
              ? 'The automata accept the same language.'
              : 'A distinguishing string was found between the automata.',
        );
      } else {
        return state.copyWith(
          isLoading: false,
          equivalenceResult: null,
          equivalenceDetails: result.error,
          error: result.error,
        );
      }
    } catch (e) {
      return state.copyWith(
        isLoading: false,
        equivalenceResult: null,
        equivalenceDetails: 'Error comparing automata: $e',
        error: 'Error comparing automata: $e',
      );
    }
  }
}
