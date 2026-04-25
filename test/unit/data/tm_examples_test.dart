import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/tm_simulator.dart';
import 'package:jflutter/data/examples/tm_examples.dart';

void main() {
  group('TMExamples', () {
    test('exposes the Apple v1 TM example set', () {
      final factories = TMExamples.getExampleFactories();

      expect(factories, hasLength(5));
      expect(
        factories.keys,
        containsAll(<String>[
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
          'a^n b^n',
          'MT - Verificador de palíndromo',
        ]),
      );
    });

    test('builds five TM examples for the picker', () {
      final examples = TMExamples.getAllExamples();

      expect(examples, hasLength(5));
      expect(
        examples.map((example) => example.name),
        containsAll(<String>[
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
          'a^n b^n',
          'MT - Verificador de palíndromo',
        ]),
      );
    });

    test('binaryToUnary rewrites the tape instead of echoing the input', () {
      final result = TMSimulator.simulate(
        TMExamples.binaryToUnary(),
        '101',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.steps.last.tapeContents.replaceAll('B', ''), '111');
    });

    test('palindrome example rewinds before resuming the outer loop', () {
      final tm = TMExamples.palindrome();
      final rewindState =
          tm.states.firstWhere((state) => state.id == 'qBackLeft');
      final t7 =
          tm.tmTransitions.firstWhere((transition) => transition.id == 't7');
      final t11 =
          tm.tmTransitions.firstWhere((transition) => transition.id == 't11');
      final rewindToStart = tm.tmTransitions.firstWhere(
        (transition) => transition.id == 't15',
      );

      expect(t7.toState.id, rewindState.id);
      expect(t11.toState.id, rewindState.id);
      expect(rewindToStart.fromState.id, rewindState.id);
      expect(rewindToStart.toState.id, 'q0');
    });

    test('palindrome example accepts single-character inputs', () {
      final zeroResult = TMSimulator.simulate(
        TMExamples.palindrome(),
        '0',
        stepByStep: true,
      );
      final oneResult = TMSimulator.simulate(
        TMExamples.palindrome(),
        '1',
        stepByStep: true,
      );

      expect(zeroResult.isSuccess, isTrue);
      expect(zeroResult.data!.accepted, isTrue);
      expect(oneResult.isSuccess, isTrue);
      expect(oneResult.data!.accepted, isTrue);
    });

    test('palindrome example rejects non-palindromes', () {
      final result = TMSimulator.simulate(
        TMExamples.palindrome(),
        '011',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
    });

    test('copyString inserts a separator and accepts simple input', () {
      final result = TMSimulator.simulate(
        TMExamples.copyString(),
        '10',
        stepByStep: true,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNotNull);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.steps.last.tapeContents, contains('#'));
    });

    // ---------------------------------------------------------------------------
    // binaryIncrement
    // ---------------------------------------------------------------------------

    group('binaryIncrement', () {
      test('has correct default id and name', () {
        final tm = TMExamples.binaryIncrement();

        expect(tm.id, equals('tm_binary_increment'));
        expect(tm.name, equals('MT - Incremento binário'));
      });

      test('has a single initial state q0', () {
        final tm = TMExamples.binaryIncrement();

        expect(tm.initialState, isNotNull);
        expect(tm.initialState!.id, equals('q0'));
        expect(tm.states.where((s) => s.isInitial), hasLength(1));
      });

      test('has a single accepting state q2', () {
        final tm = TMExamples.binaryIncrement();

        expect(tm.acceptingStates, hasLength(1));
        expect(tm.acceptingStates.first.id, equals('q2'));
      });

      test('has correct input and tape alphabets', () {
        final tm = TMExamples.binaryIncrement();

        expect(tm.alphabet, containsAll(<String>['0', '1']));
        expect(tm.tapeAlphabet, containsAll(<String>['0', '1', 'B']));
        expect(tm.blankSymbol, equals('B'));
      });

      test('increments binary 101 to 110', () {
        final result = TMSimulator.simulate(
          TMExamples.binaryIncrement(),
          '101',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
        expect(
          result.data!.steps.last.tapeContents.replaceAll('B', ''),
          equals('110'),
        );
      });

      test('increments binary 0 to 1', () {
        final result = TMSimulator.simulate(
          TMExamples.binaryIncrement(),
          '0',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
        expect(
          result.data!.steps.last.tapeContents.replaceAll('B', ''),
          equals('1'),
        );
      });

      test('handles overflow: all-ones input gains a leading 1', () {
        final result = TMSimulator.simulate(
          TMExamples.binaryIncrement(),
          '111',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
        final tape = result.data!.steps.last.tapeContents.replaceAll('B', '');
        expect(tape, equals('1000'));
      });

      test('accepts custom id, name, and bounds', () {
        const customBounds = math.Rectangle(10, 20, 400, 300);
        final tm = TMExamples.binaryIncrement(
          id: 'my_increment',
          name: 'My Increment TM',
          bounds: customBounds,
        );

        expect(tm.id, equals('my_increment'));
        expect(tm.name, equals('My Increment TM'));
        expect(tm.bounds, equals(customBounds));
      });
    });

    // ---------------------------------------------------------------------------
    // aNbN
    // ---------------------------------------------------------------------------

    group('aNbN', () {
      test('has correct default id and name', () {
        final tm = TMExamples.aNbN();

        expect(tm.id, equals('tm_anbn'));
        expect(tm.name, equals('a^n b^n'));
      });

      test('has exactly five states and eleven transitions', () {
        final tm = TMExamples.aNbN();

        expect(tm.states, hasLength(5));
        expect(tm.tmTransitions, hasLength(11));
      });

      test('has a single initial state q0', () {
        final tm = TMExamples.aNbN();

        expect(tm.initialState, isNotNull);
        expect(tm.initialState!.id, equals('q0'));
        expect(tm.states.where((s) => s.isInitial), hasLength(1));
      });

      test('has exactly one accepting state q4', () {
        final tm = TMExamples.aNbN();

        expect(tm.acceptingStates, hasLength(1));
        expect(tm.acceptingStates.first.id, equals('q4'));
      });

      test('has correct input and tape alphabets', () {
        final tm = TMExamples.aNbN();

        expect(tm.alphabet, containsAll(<String>['a', 'b']));
        expect(tm.tapeAlphabet, containsAll(<String>['a', 'b', 'X', 'Y', 'B']));
        expect(tm.blankSymbol, equals('B'));
      });

      test('accepts empty input for n equals zero', () {
        final result = TMSimulator.simulate(
          TMExamples.aNbN(),
          '',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
      });

      test('accepts "ab" (n=1)', () {
        final result = TMSimulator.simulate(
          TMExamples.aNbN(),
          'ab',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
      });

      test('accepts "aabb" (n=2)', () {
        final result = TMSimulator.simulate(
          TMExamples.aNbN(),
          'aabb',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
      });

      test('accepts "aaabbb" (n=3)', () {
        final result = TMSimulator.simulate(
          TMExamples.aNbN(),
          'aaabbb',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isTrue);
      });

      test('rejects "aab" (more a than b)', () {
        final result = TMSimulator.simulate(
          TMExamples.aNbN(),
          'aab',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isFalse);
      });

      test('rejects "abb" (more b than a)', () {
        final result = TMSimulator.simulate(
          TMExamples.aNbN(),
          'abb',
          stepByStep: true,
        );

        expect(result.isSuccess, isTrue);
        expect(result.data!.accepted, isFalse);
      });

      test('aNbN is included in getAllExamples', () {
        final examples = TMExamples.getAllExamples();
        final ids = examples.map((e) => e.id).toList();

        expect(ids, contains('tm_anbn'));
      });

      test('accepts custom id, name, and bounds', () {
        const customBounds = math.Rectangle(5, 5, 500, 400);
        final tm = TMExamples.aNbN(
          id: 'custom_anbn',
          name: 'Custom aNbN',
          bounds: customBounds,
        );

        expect(tm.id, equals('custom_anbn'));
        expect(tm.name, equals('Custom aNbN'));
        expect(tm.bounds, equals(customBounds));
      });
    });

    // ---------------------------------------------------------------------------
    // getExampleByName
    // ---------------------------------------------------------------------------

    group('getExampleByName', () {
      test('returns a TM for each known factory name', () {
        final knownNames = <String>[
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
          'a^n b^n',
          'MT - Verificador de palíndromo',
        ];

        for (final name in knownNames) {
          final tm = TMExamples.getExampleByName(name);
          expect(tm, isNotNull, reason: 'Expected TM for "$name"');
          expect(tm!.name, equals(name));
        }
      });

      test('returns null for an unrecognised name', () {
        expect(TMExamples.getExampleByName('does not exist'), isNull);
        expect(TMExamples.getExampleByName(''), isNull);
      });

      test('each call returns a fresh TM instance', () {
        final first = TMExamples.getExampleByName('MT - Incremento binário');
        final second = TMExamples.getExampleByName('MT - Incremento binário');

        expect(first, isNotNull);
        expect(second, isNotNull);
        expect(identical(first, second), isFalse,
            reason: 'Factory should return a new object each time');
      });
    });

    // ---------------------------------------------------------------------------
    // All examples — structural invariants
    // ---------------------------------------------------------------------------

    group('all examples structural invariants', () {
      test('every example has exactly one initial state', () {
        for (final tm in TMExamples.getAllExamples()) {
          final initialCount = tm.states.where((s) => s.isInitial).length;
          expect(
            initialCount,
            equals(1),
            reason: '${tm.name} should have exactly one initial state',
          );
        }
      });

      test('every example has at least one accepting state', () {
        for (final tm in TMExamples.getAllExamples()) {
          expect(
            tm.acceptingStates,
            isNotEmpty,
            reason: '${tm.name} should have at least one accepting state',
          );
        }
      });

      test('every example has a non-empty input alphabet and tape alphabet',
          () {
        for (final tm in TMExamples.getAllExamples()) {
          expect(
            tm.alphabet,
            isNotEmpty,
            reason: '${tm.name} should have a non-empty alphabet',
          );
          expect(
            tm.tapeAlphabet,
            isNotEmpty,
            reason: '${tm.name} should have a non-empty tape alphabet',
          );
        }
      });

      test('tape alphabet is a superset of the input alphabet for all examples',
          () {
        for (final tm in TMExamples.getAllExamples()) {
          for (final symbol in tm.alphabet) {
            expect(
              tm.tapeAlphabet,
              contains(symbol),
              reason:
                  '${tm.name}: tape alphabet must include input symbol "$symbol"',
            );
          }
        }
      });

      test('blank symbol is always present in the tape alphabet', () {
        final allExamples = TMExamples.getAllExamples();
        for (final tm in allExamples) {
          expect(
            tm.tapeAlphabet,
            contains(tm.blankSymbol),
            reason: '${tm.name}: tape alphabet must include the blank symbol',
          );
        }
      });

      test('each example creates a distinct TM object on every call', () {
        final first = TMExamples.binaryIncrement();
        final second = TMExamples.binaryIncrement();

        expect(identical(first, second), isFalse);
      });
    });
  });
}
