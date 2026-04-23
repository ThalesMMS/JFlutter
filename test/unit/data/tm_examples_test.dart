import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/tm_simulator.dart';
import 'package:jflutter/data/examples/tm_examples.dart';

void main() {
  group('TMExamples', () {
    test('exposes the Apple v1 TM example set', () {
      final factories = TMExamples.getExampleFactories();

      expect(factories, hasLength(4));
      expect(
        factories.keys,
        containsAll(<String>[
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
          'MT - Verificador de palíndromo',
        ]),
      );
      expect(factories.keys, isNot(contains('a^n b^n')));
    });

    test('builds four TM examples for the picker', () {
      final examples = TMExamples.getAllExamples();

      expect(examples, hasLength(4));
      expect(
        examples.map((example) => example.name),
        containsAll(<String>[
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
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
  });
}
