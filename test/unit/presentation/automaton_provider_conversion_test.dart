import 'dart:math' as math;

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/use_cases/algorithm_use_cases.dart';
import 'package:jflutter/core/use_cases/automaton_use_cases.dart';
import 'package:jflutter/data/repositories/algorithm_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';

class _RecordingLayoutRepository implements LayoutRepository {
  AutomatonEntity? lastEntity;

  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) async {
    lastEntity = automaton;
    return Success(automaton);
  }

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton) =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) =>
      throw UnimplementedError();
}

class _FakeAutomatonRepository implements AutomatonRepository {
  @override
  Future<AutomatonResult> exportAutomaton(AutomatonEntity automaton) =>
      throw UnimplementedError();

  @override
  Future<ListResult<AutomatonEntity>> loadAllAutomatons() =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> loadAutomaton(String id) =>
      throw UnimplementedError();

  @override
  Future<BoolResult> deleteAutomaton(String id) =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> importAutomaton(String jsonString) =>
      throw UnimplementedError();

  @override
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton) =>
      Future.value(Success(automaton));

  @override
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton) =>
      throw UnimplementedError();
}

void main() {
  group('AutomatonProvider conversions', () {
    test('preserves epsilon transitions and automaton type during round-trip', () async {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final epsilonTransition = FSATransition.epsilon(
        id: 't0',
        fromState: q0,
        toState: q1,
      );
      final symbolTransition = FSATransition(
        id: 't1',
        fromState: q1,
        toState: q1,
        label: 'a',
        inputSymbols: {'a'},
      );

      final fsa = FSA(
        id: 'fsa-1',
        name: 'lambda-nfa',
        states: {q0, q1},
        transitions: {epsilonTransition, symbolTransition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle(0, 0, 200, 200),
      );

      final layoutRepository = _RecordingLayoutRepository();
      final algorithmRepository = AlgorithmRepositoryImpl();
      final automatonRepository = _FakeAutomatonRepository();
      final provider = AutomatonProvider(
        createAutomatonUseCase: CreateAutomatonUseCase(automatonRepository),
        addStateUseCase: AddStateUseCase(automatonRepository),
        nfaToDfaUseCase: NfaToDfaUseCase(algorithmRepository),
        minimizeDfaUseCase: MinimizeDfaUseCase(algorithmRepository),
        completeDfaUseCase: CompleteDfaUseCase(algorithmRepository),
        regexToNfaUseCase: RegexToNfaUseCase(algorithmRepository),
        dfaToRegexUseCase: DfaToRegexUseCase(algorithmRepository),
        fsaToGrammarUseCase: FsaToGrammarUseCase(algorithmRepository),
        checkEquivalenceUseCase: CheckEquivalenceUseCase(algorithmRepository),
        simulateWordUseCase: SimulateWordUseCase(algorithmRepository),
        applyAutoLayoutUseCase: ApplyAutoLayoutUseCase(layoutRepository),
      );

      provider.updateAutomaton(fsa);

      await provider.applyAutoLayout();

      final recordedEntity = layoutRepository.lastEntity;
      expect(recordedEntity, isNotNull);
      expect(recordedEntity!.type, AutomatonType.nfaLambda);
      expect(recordedEntity.transitions['q0|ε'], equals(['q1']));

      final updatedFsa = provider.state.currentAutomaton;
      expect(updatedFsa, isNotNull);
      expect(updatedFsa!.hasEpsilonTransitions, isTrue);
      expect(updatedFsa.isDeterministic, isFalse);
      final updatedTransitions =
          updatedFsa.transitions.whereType<FSATransition>().toList();
      final roundTrippedEpsilon = updatedTransitions
          .firstWhere((transition) => transition.lambdaSymbol != null);
      expect(roundTrippedEpsilon.lambdaSymbol, equals('ε'));
      expect(roundTrippedEpsilon.inputSymbols, isEmpty);
    });
  });
}
