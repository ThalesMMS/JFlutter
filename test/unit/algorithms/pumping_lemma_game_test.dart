import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pumping_lemma_game.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/pumping_attempt.dart';
import 'package:jflutter/core/models/pumping_lemma_game.dart' as models;
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/result.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('PumpingLemmaGame caching behaviour', () {
    late FSA automaton;
    late models.PumpingLemmaGame game;

    setUp(() {
      final state = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: true,
      );

      automaton = FSA(
        id: 'fsa1',
        name: 'a*',
        states: {state},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: state,
            toState: state,
            label: 'a',
            inputSymbols: const {'a'},
          ),
        },
        alphabet: const {'a'},
        initialState: state,
        acceptingStates: {state},
        created: DateTime(2024, 1, 1),
        modified: DateTime(2024, 1, 1),
        bounds: math.Rectangle<double>(0, 0, 100, 100),
      );

      game = models.PumpingLemmaGame(
        automaton: automaton,
        pumpingLength: 2,
        challengeString: 'aaa',
        attempts: const [],
        isCompleted: false,
        score: 0,
        maxScore: 100,
      );
    });

    test('validateAttempt produces consistent success for valid decomposition', () {
      final attempt = PumpingAttempt(
        x: 'a',
        y: 'a',
        z: 'a',
        isCorrect: false,
        timestamp: DateTime(2024, 1, 1),
      );

      final Result<PumpingAttemptResult> first =
          PumpingLemmaGame.validateAttempt(game, attempt);
      final Result<PumpingAttemptResult> second =
          PumpingLemmaGame.validateAttempt(game, attempt);

      expect(first.isSuccess, isTrue);
      expect(first.data!.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(second.data!.isSuccess, isTrue);
    });

    test('generateHint remains deterministic for identical inputs', () {
      final first = PumpingLemmaGame.generateHint(game);
      final second = PumpingLemmaGame.generateHint(game);

      expect(first.isSuccess, isTrue);
      expect(second.isSuccess, isTrue);
      expect(first.data, 'Try x = "", y = "a", z = "aa"');
      expect(second.data, first.data);
    });
  });
}
