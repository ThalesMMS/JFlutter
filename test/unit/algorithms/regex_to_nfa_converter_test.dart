import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/regex_to_nfa_converter.dart';

void main() {
  group('RegexToNFAConverter plus operator', () {
    test('a+ produces concatenation with kleene star wiring', () {
      final result = RegexToNFAConverter.convert('a+');

      expect(result.isSuccess, isTrue);
      final fsa = result.data!;

      expect(fsa.alphabet.contains('a'), isTrue);
      expect(fsa.initialState, isNotNull);
      expect(fsa.acceptingStates.length, 1);

      final statesByLabel = {for (final state in fsa.states) state.label: state};
      expect(statesByLabel.containsKey('q_initial'), isTrue);
      expect(statesByLabel.containsKey('q_final'), isTrue);

      final kleeneInitial = statesByLabel['q_initial']!;
      final kleeneFinal = statesByLabel['q_final']!;
      expect(fsa.acceptingStates.contains(kleeneFinal), isTrue);

      final deterministicTransitions =
          fsa.deterministicTransitions.where((t) => t.inputSymbols.contains('a'));
      expect(deterministicTransitions.length, 1);
      final aTransition = deterministicTransitions.first;
      expect(aTransition.fromState.label, 'q0');
      expect(aTransition.toState.label, 'q1');

      final epsilonTransitions = fsa.epsilonTransitions;
      expect(
        epsilonTransitions.any(
          (transition) =>
              transition.fromState.label == 'q1' && transition.toState == kleeneInitial,
        ),
        isTrue,
      );
      expect(
        epsilonTransitions.any(
          (transition) =>
              transition.fromState == kleeneInitial && transition.toState == kleeneFinal,
        ),
        isTrue,
      );
    });

    test('ba+ keeps transitions into and out of the plus component', () {
      final result = RegexToNFAConverter.convert('ba+');

      expect(result.isSuccess, isTrue);
      final fsa = result.data!;

      final initialTransitions =
          fsa.fsaTransitions.where((transition) => transition.fromState == fsa.initialState);
      expect(
        initialTransitions.any((transition) => transition.inputSymbols.contains('b')),
        isTrue,
      );

      final kleeneInitial = fsa.states.firstWhere((state) => state.label == 'q_initial');
      final epsilonTransitions = fsa.epsilonTransitions;
      expect(
        epsilonTransitions.any(
          (transition) =>
              transition.toState == kleeneInitial && transition.fromState.label == 'q1',
        ),
        isTrue,
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
