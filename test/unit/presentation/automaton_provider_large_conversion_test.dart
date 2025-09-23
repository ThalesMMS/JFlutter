import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/use_cases/algorithm_use_cases.dart';
import 'package:jflutter/core/use_cases/automaton_use_cases.dart';
import 'package:jflutter/data/repositories/algorithm_repository_impl.dart';
import 'package:jflutter/data/repositories/automaton_repository_impl.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';

class _StubLayoutRepository implements LayoutRepository {
  _StubLayoutRepository(this._entityToReturn);

  final AutomatonEntity _entityToReturn;

  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) async {
    return Success(_entityToReturn);
  }

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) async {
    return Success(_entityToReturn);
  }

  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) async {
    return Success(_entityToReturn);
  }

  @override
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton) async {
    return Success(_entityToReturn);
  }

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) async {
    return Success(_entityToReturn);
  }

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) async {
    return Success(_entityToReturn);
  }
}

void main() {
  test('convert entity to FSA efficiently for large automata', () async {
    const stateCount = 500;
    final states = <State>{};
    final stateById = <String, State>{};
    for (var i = 0; i < stateCount; i++) {
      final id = 'q\$i';
      final state = State(
        id: id,
        label: id,
        position: Vector2.zero(),
        isInitial: i == 0,
        isAccepting: i == stateCount - 1,
      );
      states.add(state);
      stateById[id] = state;
    }

    final transitions = <FSATransition>{};
    for (var i = 0; i < stateCount - 1; i++) {
      final from = stateById['q\$i']!;
      final to = stateById['q\${i + 1}']!;
      transitions.add(FSATransition(
        id: 't\$i',
        fromState: from,
        toState: to,
        label: 'a',
        inputSymbols: const {'a'},
      ));
    }

    final initialState = stateById['q0'];
    final acceptingStates = {stateById['q${stateCount - 1}']!};

    final initialAutomaton = FSA(
      id: 'fsa-large',
      name: 'Large FSA',
      states: states,
      transitions: transitions,
      alphabet: const {'a'},
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: DateTime(2024),
      modified: DateTime(2024, 2),
      bounds: const math.Rectangle(0, 0, 1000, 1000),
    );

    final entityStates = [
      for (var i = 0; i < stateCount; i++)
        StateEntity(
          id: 'q\$i',
          name: 'q\$i',
          x: i.toDouble(),
          y: i.toDouble(),
          isInitial: i == 0,
          isFinal: i == stateCount - 1,
        ),
    ];

    final entityTransitions = <String, List<String>>{};
    for (var i = 0; i < stateCount - 1; i++) {
      entityTransitions['q\$i|a'] = ['q\${i + 1}'];
    }

    final layoutEntity = AutomatonEntity(
      id: 'entity-large',
      name: 'Large Automaton',
      alphabet: const {'a'},
      states: entityStates,
      transitions: entityTransitions,
      initialId: 'q0',
      nextId: stateCount,
      type: AutomatonType.dfa,
    );

    final automatonService = AutomatonService();
    final repository = AutomatonRepositoryImpl(automatonService);
    final algorithmRepository = AlgorithmRepositoryImpl();
    final provider = AutomatonProvider(
      createAutomatonUseCase: CreateAutomatonUseCase(repository),
      addStateUseCase: AddStateUseCase(repository),
      nfaToDfaUseCase: NfaToDfaUseCase(algorithmRepository),
      minimizeDfaUseCase: MinimizeDfaUseCase(algorithmRepository),
      completeDfaUseCase: CompleteDfaUseCase(algorithmRepository),
      regexToNfaUseCase: RegexToNfaUseCase(algorithmRepository),
      dfaToRegexUseCase: DfaToRegexUseCase(algorithmRepository),
      fsaToGrammarUseCase: FsaToGrammarUseCase(algorithmRepository),
      checkEquivalenceUseCase: CheckEquivalenceUseCase(algorithmRepository),
      simulateWordUseCase: SimulateWordUseCase(algorithmRepository),
      applyAutoLayoutUseCase: ApplyAutoLayoutUseCase(
        _StubLayoutRepository(layoutEntity),
      ),
    );

    provider.updateAutomaton(initialAutomaton);

    await provider.applyAutoLayout();

    final updatedAutomaton = provider.state.currentAutomaton;
    expect(updatedAutomaton, isNotNull);
    expect(updatedAutomaton!.states.length, stateCount);
    expect(updatedAutomaton.transitions.length, stateCount - 1);
    final firstTransition = updatedAutomaton.transitions.first as FSATransition;
    expect(firstTransition.fromState.id, 'q0');
    expect(firstTransition.toState.id, 'q1');
  });
}
