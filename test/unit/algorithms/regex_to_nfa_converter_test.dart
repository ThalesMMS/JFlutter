import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/regex_to_nfa_converter.dart';

void main() {
  group('RegexToNFAConverter Thompson compilation', () {
    test('a+ yields literal and epsilon transitions', () {
      final result = RegexToNFAConverter.convert('a+');

      expect(result.isSuccess, isTrue);
      final fsa = result.data!;

      final literalTransitions =
          fsa.deterministicTransitions.where((transition) => transition.inputSymbols.contains('a'));
      expect(literalTransitions.length, greaterThanOrEqualTo(1));

      final epsilonTransitions = fsa.epsilonTransitions;
      expect(epsilonTransitions, isNotEmpty);
      expect(
        epsilonTransitions.any((transition) => fsa.acceptingStates.contains(transition.toState)),
        isTrue,
      );
    });

    test('ba+ preserves prefix transitions and kleene wiring', () {
      final result = RegexToNFAConverter.convert('ba+');

      expect(result.isSuccess, isTrue);
      final fsa = result.data!;

      final initialTransitions =
          fsa.fsaTransitions.where((transition) => transition.fromState == fsa.initialState);
      expect(
        initialTransitions.any((transition) => transition.inputSymbols.contains('b')),
        isTrue,
      );

      final epsilonTransitions = fsa.epsilonTransitions;
      expect(epsilonTransitions, isNotEmpty);
      expect(
        epsilonTransitions.where((transition) => transition.toState.isAccepting).length,
        greaterThan(0),
      );
    });
  });

  group('RegexToNFAConverter long expressions', () {
    test('handles long concatenation chains efficiently', () {
      final regex = 'a' * 5000;

      final result = RegexToNFAConverter.convert(regex);

      expect(result.isSuccess, isTrue);
      expect(result.data!.states, isNotEmpty);
    });

    test('handles extensive unions without degradation', () {
      final regex = List.filled(2000, 'a').join('|');

      final result = RegexToNFAConverter.convert(regex);

      expect(result.isSuccess, isTrue);
    });

    test('handles repeated grouped expressions with unary operators', () {
      final buffer = StringBuffer();
      for (int i = 0; i < 1000; i++) {
        buffer.write('(ab)+');
      }

      final result = RegexToNFAConverter.convert(buffer.toString());

      expect(result.isSuccess, isTrue);
    });
  });
}
