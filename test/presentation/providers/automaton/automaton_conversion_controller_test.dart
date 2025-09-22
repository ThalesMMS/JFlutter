import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/grammar_entity.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/use_cases/algorithm_use_cases.dart';
import 'package:jflutter/core/utils/automaton_entity_mapper.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_conversion_controller.dart';
import 'package:jflutter/presentation/providers/automaton/automaton_state.dart';
import 'package:test/test.dart';

import 'test_helpers.dart';

class _StubAlgorithmRepository extends FakeAlgorithmRepository {
  _StubAlgorithmRepository({
    this.nfaToDfaResult,
    this.minimizeDfaResult,
    this.completeDfaResult,
    this.regexToNfaResult,
    this.dfaToRegexResult,
    this.fsaToGrammarResult,
    this.equivalenceResult,
  });

  final AutomatonResult? nfaToDfaResult;
  final AutomatonResult? minimizeDfaResult;
  final AutomatonResult? completeDfaResult;
  final AutomatonResult? regexToNfaResult;
  final StringResult? dfaToRegexResult;
  final GrammarResult? fsaToGrammarResult;
  final BoolResult? equivalenceResult;

  @override
  Future<AutomatonResult> nfaToDfa(AutomatonEntity nfa) async {
    if (nfaToDfaResult != null) return nfaToDfaResult!;
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> minimizeDfa(AutomatonEntity dfa) async {
    if (minimizeDfaResult != null) return minimizeDfaResult!;
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> completeDfa(AutomatonEntity dfa) async {
    if (completeDfaResult != null) return completeDfaResult!;
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> regexToNfa(String regex) async {
    if (regexToNfaResult != null) return regexToNfaResult!;
    throw UnimplementedError();
  }

  @override
  Future<StringResult> dfaToRegex(AutomatonEntity dfa, {bool allowLambda = false}) async {
    if (dfaToRegexResult != null) return dfaToRegexResult!;
    throw UnimplementedError();
  }

  @override
  Future<GrammarResult> fsaToGrammar(AutomatonEntity fsa) async {
    if (fsaToGrammarResult != null) return fsaToGrammarResult!;
    throw UnimplementedError();
  }

  @override
  Future<BoolResult> areEquivalent(AutomatonEntity a, AutomatonEntity b) async {
    if (equivalenceResult != null) return equivalenceResult!;
    throw UnimplementedError();
  }
}

AutomatonConversionController _buildController(_StubAlgorithmRepository repository) {
  return AutomatonConversionController(
    nfaToDfaUseCase: NfaToDfaUseCase(repository),
    minimizeDfaUseCase: MinimizeDfaUseCase(repository),
    completeDfaUseCase: CompleteDfaUseCase(repository),
    regexToNfaUseCase: RegexToNfaUseCase(repository),
    dfaToRegexUseCase: DfaToRegexUseCase(repository),
    fsaToGrammarUseCase: FsaToGrammarUseCase(repository),
    checkEquivalenceUseCase: CheckEquivalenceUseCase(repository),
  );
}

void main() {
  group('AutomatonConversionController', () {
    test('convertNfaToDfa updates automaton on success', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final repository = _StubAlgorithmRepository(
        nfaToDfaResult: Success(buildAutomatonEntity(id: 'converted')),
      );
      final controller = _buildController(repository);

      final updated = await controller.convertNfaToDfa(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
      );

      expect(updated.isLoading, isFalse);
      expect(updated.error, isNull);
      expect(updated.currentAutomaton, isNotNull);
      expect(updated.currentAutomaton!.id, equals('converted'));
    });

    test('convertNfaToDfa stores error on failure', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final repository = _StubAlgorithmRepository(
        nfaToDfaResult: Failure('conversion failed'),
      );
      final controller = _buildController(repository);

      final updated = await controller.convertNfaToDfa(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
      );

      expect(updated.isLoading, isFalse);
      expect(updated.currentAutomaton?.id, equals(baseAutomaton.id));
      expect(updated.error, 'conversion failed');
    });

    test('convertRegexToNfa sets current automaton', () async {
      final repository = _StubAlgorithmRepository(
        regexToNfaResult: Success(buildAutomatonEntity(id: 'regex')),
      );
      final controller = _buildController(repository);

      final updated = await controller.convertRegexToNfa(
        const AutomatonState(isLoading: true),
        'a*',
      );

      expect(updated.isLoading, isFalse);
      expect(updated.currentAutomaton, isNotNull);
      expect(updated.currentAutomaton!.id, equals('regex'));
    });

    test('convertFsaToGrammar stores grammar result', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final grammar = buildGrammarEntity();
      final repository = _StubAlgorithmRepository(
        fsaToGrammarResult: Success(grammar),
      );
      final controller = _buildController(repository);

      final updated = await controller.convertFsaToGrammar(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
      );

      expect(updated.isLoading, isFalse);
      expect(updated.error, isNull);
      expect(updated.grammarResult, equals(grammar));
    });

    test('convertFaToRegex stores regex string', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final repository = _StubAlgorithmRepository(
        dfaToRegexResult: Success('a*'),
      );
      final controller = _buildController(repository);

      final updated = await controller.convertFaToRegex(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
      );

      expect(updated.isLoading, isFalse);
      expect(updated.regexResult, 'a*');
    });

    test('compareEquivalence stores success result', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final otherAutomaton = automatonEntityToFsa(buildAutomatonEntity(id: 'other'));
      final repository = _StubAlgorithmRepository(
        equivalenceResult: Success(true),
      );
      final controller = _buildController(repository);

      final updated = await controller.compareEquivalence(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
        otherAutomaton,
      );

      expect(updated.isLoading, isFalse);
      expect(updated.equivalenceResult, isTrue);
      expect(updated.equivalenceDetails,
          'The automata accept the same language.');
    });

    test('compareEquivalence stores failure result', () async {
      final baseAutomaton = automatonEntityToFsa(buildAutomatonEntity());
      final otherAutomaton = automatonEntityToFsa(buildAutomatonEntity(id: 'other'));
      final repository = _StubAlgorithmRepository(
        equivalenceResult: Failure('not equivalent'),
      );
      final controller = _buildController(repository);

      final updated = await controller.compareEquivalence(
        AutomatonState(currentAutomaton: baseAutomaton, isLoading: true),
        otherAutomaton,
      );

      expect(updated.isLoading, isFalse);
      expect(updated.equivalenceResult, isNull);
      expect(updated.equivalenceDetails, 'not equivalent');
      expect(updated.error, 'not equivalent');
    });
  });
}
