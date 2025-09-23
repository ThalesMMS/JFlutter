import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/grammar_to_pda_converter.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';

void main() {
  group('GrammarToPDAConverter - standard construction', () {
    test('produces PDA equivalent to grammar with epsilon and recursion', () {
      final grammar = _buildGrammar(
        name: 'anbn',
        terminals: {'a', 'b'},
        nonTerminals: {'S'},
        startSymbol: 'S',
        productions: [
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'S', 'b'],
          ),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
          ),
        ],
      );

      final conversionResult =
          GrammarToPDAConverter.convertGrammarToPDA(grammar);
      expect(conversionResult.isSuccess, isTrue);

      final pda = conversionResult.data!;
      final acceptedInputs = ['', 'ab', 'aabb', 'aaabbb'];
      for (final input in acceptedInputs) {
        final simulation = PDASimulator.simulate(pda, input);
        expect(simulation.isSuccess, isTrue, reason: 'Simulation should succeed for "$input"');
        expect(
          simulation.data!.accepted,
          isTrue,
          reason: 'Expected "$input" to be accepted by the converted PDA.',
        );
      }

      final rejectedInputs = ['a', 'abb', 'ba', 'bbaa'];
      for (final input in rejectedInputs) {
        final simulation = PDASimulator.simulate(pda, input);
        expect(simulation.isSuccess, isTrue, reason: 'Simulation should succeed for "$input"');
        expect(
          simulation.data!.accepted,
          isFalse,
          reason: 'Expected "$input" to be rejected by the converted PDA.',
        );
      }
    });

    test('accepts epsilon production grammar', () {
      final grammar = _buildGrammar(
        name: 'epsilon',
        terminals: {'a'},
        nonTerminals: {'S'},
        startSymbol: 'S',
        productions: [
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
          ),
        ],
      );

      final conversionResult =
          GrammarToPDAConverter.convertGrammarToPDAStandard(grammar);
      expect(conversionResult.isSuccess, isTrue);

      final pda = conversionResult.data!;
      final accepted = PDASimulator.simulate(pda, '');
      expect(accepted.isSuccess, isTrue);
      expect(accepted.data!.accepted, isTrue);

      final rejected = PDASimulator.simulate(pda, 'a');
      expect(rejected.isSuccess, isTrue);
      expect(rejected.data!.accepted, isFalse);
    });
  });

  group('GrammarToPDAConverter - Greibach construction', () {
    test('produces PDA equivalent to a GNF grammar', () {
      final grammar = _buildGrammar(
        name: 'a^n b',
        terminals: {'a', 'b'},
        nonTerminals: {'S'},
        startSymbol: 'S',
        productions: [
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: ['a', 'S'],
          ),
          const Production(
            id: 'p2',
            leftSide: ['S'],
            rightSide: ['b'],
          ),
        ],
      );

      final conversionResult =
          GrammarToPDAConverter.convertGrammarToPDAGreibach(grammar);
      expect(conversionResult.isSuccess, isTrue);

      final pda = conversionResult.data!;
      final acceptedInputs = ['b', 'ab', 'aab', 'aaab'];
      for (final input in acceptedInputs) {
        final simulation = PDASimulator.simulate(pda, input);
        expect(simulation.isSuccess, isTrue, reason: 'Simulation should succeed for "$input"');
        expect(
          simulation.data!.accepted,
          isTrue,
          reason: 'Expected "$input" to be accepted by the Greibach PDA.',
        );
      }

      final rejectedInputs = ['a', 'ba', 'abb', ''];
      for (final input in rejectedInputs) {
        final simulation = PDASimulator.simulate(pda, input);
        expect(simulation.isSuccess, isTrue, reason: 'Simulation should succeed for "$input"');
        expect(
          simulation.data!.accepted,
          isFalse,
          reason: 'Expected "$input" to be rejected by the Greibach PDA.',
        );
      }
    });
  });
}

Grammar _buildGrammar({
  required String name,
  required Set<String> terminals,
  required Set<String> nonTerminals,
  required String startSymbol,
  required List<Production> productions,
}) {
  final timestamp = DateTime(2024, 1, 1);
  return Grammar(
    id: 'g_$name',
    name: name,
    terminals: terminals,
    nonterminals: nonTerminals,
    startSymbol: startSymbol,
    productions: productions.toSet(),
    type: GrammarType.contextFree,
    created: timestamp,
    modified: timestamp,
  );
}
