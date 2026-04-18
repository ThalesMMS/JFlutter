//
//  transition_label_updates_test.dart
//  JFlutter
//
//  Testes voltados aos providers de edição de transições, assegurando que
//  autômatos finitos, PDAs e máquinas de Turing recebam atualizações consistentes
//  de rótulos, símbolos e parâmetros específicos de cada modelo durante as
//  operações de edição em tempo real.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';

void main() {
  group('Transition updates', () {
    test(
      'AutomatonProvider.updateTransitionLabel updates labels and symbols',
      () {
        final provider = AutomatonProvider(
          automatonService: AutomatonService(),
          layoutRepository: LayoutRepositoryImpl(),
        );

        final stateA = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final stateB = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(100, 0),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't0',
          fromState: stateA,
          toState: stateB,
          inputSymbols: const {'a'},
          label: 'a',
        );
        final automaton = FSA(
          id: 'fa',
          name: 'test',
          states: {stateA, stateB},
          transitions: {transition},
          alphabet: {'a'},
          initialState: stateA,
          acceptingStates: {stateB},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        provider.updateAutomaton(automaton);
        provider.updateTransitionLabel(id: 't0', label: 'b,c');

        final updated = provider.state.currentAutomaton!;
        final updatedTransition = updated.transitions
            .whereType<FSATransition>()
            .firstWhere((element) => element.id == 't0');

        expect(updatedTransition.label, 'b,c');
        expect(updatedTransition.inputSymbols, {'b', 'c'});
        expect(updated.alphabet.containsAll({'a', 'b', 'c'}), isTrue);
      },
    );

    test('AutomatonProvider conversion preserves epsilon transitions', () {
      final provider = AutomatonProvider(
        automatonService: AutomatonService(),
        layoutRepository: LayoutRepositoryImpl(),
      );

      final stateA = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final stateB = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final transition = FSATransition.epsilon(
        id: 't0',
        fromState: stateA,
        toState: stateB,
      );
      final automaton = FSA(
        id: 'fa',
        name: 'test',
        states: {stateA, stateB},
        transitions: {transition},
        alphabet: const {},
        initialState: stateA,
        acceptingStates: {stateB},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      final entity = provider.convertFsaToEntity(automaton);
      final roundTrip = provider.convertEntityToFsa(entity);
      final roundTripTransition =
          roundTrip.transitions.whereType<FSATransition>().single;

      expect(entity.transitions['q0|ε'], ['q1']);
      expect(entity.type, AutomatonType.nfaLambda);
      expect(roundTripTransition.label, 'ε');
      expect(roundTripTransition.inputSymbols, isEmpty);
      expect(roundTripTransition.lambdaSymbol, 'ε');
    });

    test('AutomatonProvider conversion infers nondeterministic FSA type', () {
      final provider = AutomatonProvider(
        automatonService: AutomatonService(),
        layoutRepository: LayoutRepositoryImpl(),
      );

      final stateA = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final stateB = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
      );
      final stateC = automaton_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(200, 0),
        isAccepting: true,
      );
      final automaton = FSA(
        id: 'fa',
        name: 'test',
        states: {stateA, stateB, stateC},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: stateA,
            toState: stateB,
            inputSymbols: const {'a'},
            label: 'a',
          ),
          FSATransition(
            id: 't1',
            fromState: stateA,
            toState: stateC,
            inputSymbols: const {'a'},
            label: 'a',
          ),
        },
        alphabet: const {'a'},
        initialState: stateA,
        acceptingStates: {stateC},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      final entity = provider.convertFsaToEntity(automaton);

      expect(entity.type, AutomatonType.nfa);
    });

    test('AutomatonProvider conversion skips missing transition endpoints', () {
      final provider = AutomatonProvider(
        automatonService: AutomatonService(),
        layoutRepository: LayoutRepositoryImpl(),
      );

      const entity = AutomatonEntity(
        id: 'fa',
        name: 'test',
        alphabet: {'a'},
        states: [
          StateEntity(
            id: 'q0',
            name: 'q0',
            x: 0,
            y: 0,
            isInitial: true,
            isFinal: false,
          ),
          StateEntity(
            id: 'q1',
            name: 'q1',
            x: 100,
            y: 0,
            isInitial: false,
            isFinal: true,
          ),
        ],
        transitions: {
          'missing|a': ['q1'],
          'q0|a': ['missing'],
        },
        initialId: 'q0',
        nextId: 2,
        type: AutomatonType.nfa,
      );

      final automaton = provider.convertEntityToFsa(entity);

      expect(automaton.transitions, isEmpty);
    });

    test('TMEditorNotifier.updateTransitionOperations rewrites operations', () {
      final notifier = TMEditorNotifier();

      notifier.upsertState(id: 'q0', label: 'q0', x: 0, y: 0);
      notifier.upsertState(id: 'q1', label: 'q1', x: 100, y: 0);
      notifier.addOrUpdateTransition(
        id: 't0',
        fromStateId: 'q0',
        toStateId: 'q1',
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );

      notifier.updateTransitionOperations(
        id: 't0',
        readSymbol: 'x',
        writeSymbol: 'y',
        direction: TapeDirection.left,
      );

      final tm = notifier.state.tm!;
      final transition = tm.transitions.whereType<TMTransition>().firstWhere(
            (element) => element.id == 't0',
          );

      expect(transition.readSymbol, 'x');
      expect(transition.writeSymbol, 'y');
      expect(transition.direction, TapeDirection.left);
      expect(transition.label, 'x/y,L');
    });

    test('PDAEditorNotifier.upsertTransition updates stack operations', () {
      final notifier = PDAEditorNotifier();

      notifier.addOrUpdateState(id: 'q0', label: 'q0', x: 0, y: 0);
      notifier.addOrUpdateState(id: 'q1', label: 'q1', x: 100, y: 0);
      notifier.upsertTransition(
        id: 't0',
        fromStateId: 'q0',
        toStateId: 'q1',
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      notifier.upsertTransition(
        id: 't0',
        readSymbol: '',
        popSymbol: '',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPop: true,
        isLambdaPush: true,
      );

      final pda = notifier.state.pda!;
      final transition = pda.pdaTransitions.firstWhere(
        (element) => element.id == 't0',
      );

      expect(transition.isLambdaInput, isTrue);
      expect(transition.isLambdaPop, isTrue);
      expect(transition.isLambdaPush, isTrue);
      expect(transition.label, 'λ, λ/λ');
    });
  });
}
