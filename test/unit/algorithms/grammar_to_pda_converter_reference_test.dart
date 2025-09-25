import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/grammar_to_pda_converter.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';

/// Reference-inspired test based on the palindrome NPDA defined in
/// `References/automata-main/tests/test_npda.py`.
void main() {
  group('GrammarToPDAConverter - reference palindrome grammar', () {
    test('converted PDA mirrors the reference NPDA acceptance behaviour', () {
      final grammar = _buildPalindromeGrammar();

      final conversionResult =
          GrammarToPDAConverter.convertGrammarToPDA(grammar);
      expect(conversionResult.isSuccess, isTrue,
          reason: 'Conversion should succeed for palindrome grammar.');

      final pda = conversionResult.data!;

      const acceptedInputs = ['', 'a', 'b', 'aba', 'abba', 'abaaba'];
      for (final input in acceptedInputs) {
        final simulation = PDASimulator.simulate(pda, input);
        expect(simulation.isSuccess, isTrue,
            reason: 'Simulation should succeed for "$input".');
        expect(simulation.data!.accepted, isTrue,
            reason:
                'Expected "$input" to be accepted by the converted palindrome PDA.');
      }

      const rejectedInputs = ['ab', 'ba', 'aaba', 'abb', 'aaa'];
      for (final input in rejectedInputs) {
        final simulation = PDASimulator.simulate(pda, input);
        expect(simulation.isSuccess, isTrue,
            reason: 'Simulation should succeed for "$input".');
        expect(simulation.data!.accepted, isFalse,
            reason:
                'Expected "$input" to be rejected by the converted palindrome PDA.');
      }
    });
  });
}

Grammar _buildPalindromeGrammar() {
  const timestamp = DateTime(2024, 1, 1);
  return Grammar(
    id: 'g_palindrome',
    name: 'palindrome',
    terminals: const {'a', 'b'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: const {
      Production(
        id: 'p1',
        leftSide: ['S'],
        rightSide: ['a', 'S', 'a'],
      ),
      Production(
        id: 'p2',
        leftSide: ['S'],
        rightSide: ['b', 'S', 'b'],
      ),
      Production(
        id: 'p3',
        leftSide: ['S'],
        rightSide: ['a'],
      ),
      Production(
        id: 'p4',
        leftSide: ['S'],
        rightSide: ['b'],
      ),
      Production(
        id: 'p5',
        leftSide: ['S'],
        rightSide: [],
        isLambda: true,
      ),
    },
    type: GrammarType.contextFree,
    created: timestamp,
    modified: timestamp,
  );
}
