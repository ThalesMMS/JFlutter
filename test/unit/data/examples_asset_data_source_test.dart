//
//  examples_asset_data_source_test.dart
//  JFlutter
//
//  Conjunto de testes que inspeciona as fixtures JSON de ExamplesAssetDataSource,
//  assegurando a presença de metadados obrigatórios, a estrutura esperada para
//  cada categoria e a coerência entre os arquivos de exemplo e suas descrições
//  utilizadas pelo aplicativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/data/data_sources/examples_asset_data_source.dart';

class _PdaTransition {
  const _PdaTransition({
    required this.toState,
    required this.inputSymbol,
    required this.requiredStackTop,
    required this.stackReplacement,
  });

  final String toState;
  final String inputSymbol;
  final String requiredStackTop;
  final String stackReplacement;
}

class _PdaConfiguration {
  const _PdaConfiguration({
    required this.state,
    required this.index,
    required this.stack,
  });

  final String state;
  final int index;
  final List<String> stack;
}

void main() {
  group('ExamplesAssetDataSource JSON validation', () {
    late ExamplesAssetDataSource dataSource;

    setUp(() {
      dataSource = ExamplesAssetDataSource();
    });

    ExampleMetadata metadataFor({
      required ExampleCategory category,
      required String fileName,
    }) {
      return ExampleMetadata(
        fileName: fileName,
        category: category,
        subcategory: 'Test',
        difficulty: DifficultyLevel.medium,
        description: 'Test metadata',
        tags: const ['test'],
        estimatedComplexity: ComplexityLevel.medium,
      );
    }

    Map<String, dynamic> loadExample(String fileName) {
      final file = File('jflutter_js/examples/$fileName');
      final jsonString = file.readAsStringSync();
      final decoded = jsonDecode(jsonString);
      expect(
        decoded,
        isA<Map<String, dynamic>>(),
        reason: 'Fixture $fileName must decode to a JSON object',
      );
      return decoded as Map<String, dynamic>;
    }

    test('Returns failure when DFA example is missing states', () {
      final json = loadExample('afd_ends_with_a.json');
      final metadata = metadataFor(
        category: ExampleCategory.dfa,
        fileName: 'afd_ends_with_a.json',
      );

      json.remove('states');

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'AFD - Termina com A',
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('states'));
    });

    test('Validates CFG example without producing an automaton model', () {
      final json = loadExample('glc_balanced_parentheses.json');
      final metadata = metadataFor(
        category: ExampleCategory.cfg,
        fileName: 'glc_balanced_parentheses.json',
      );

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'GLC - Parênteses balanceados',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('Validates PDA example structure', () {
      final json = loadExample('apda_palindrome.json');
      final metadata = metadataFor(
        category: ExampleCategory.pda,
        fileName: 'apda_palindrome.json',
      );

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'APD - Palíndromo',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    bool runPda(Map<String, dynamic> json, String input) {
      final transitionsRaw = json['transitions'];
      expect(transitionsRaw, isA<Map<String, dynamic>>());

      final transitions = <String, List<_PdaTransition>>{};
      (transitionsRaw as Map<String, dynamic>).forEach((key, value) {
        final parts = key.split('|');
        expect(
          parts.length,
          3,
          reason:
              'Transition key "$key" must follow the pattern estado|símbolo|topoDaPilha.',
        );

        final fromState = parts[0];
        final inputSymbol = parts[1];
        final requiredStackTop = parts[2];

        final targets = value is List ? value : [value];
        final parsedTargets = targets.map((dynamic target) {
          final targetString = target.toString();
          final targetParts = targetString.split('|');
          expect(
            targetParts.length,
            2,
            reason:
                'Transition target "$targetString" must follow the pattern estado|substituicaoPilha.',
          );

          final stackReplacement =
              targetParts.length > 1 ? targetParts[1] : '';

          return _PdaTransition(
            toState: targetParts[0],
            inputSymbol: inputSymbol,
            requiredStackTop: requiredStackTop,
            stackReplacement: stackReplacement,
          );
        }).toList();

        transitions.putIfAbsent(fromState, () => []).addAll(parsedTargets);
      });

      final initialState = json['initialId'] as String;
      final finalStates = Set<String>.from(
        (json['finalStates'] as List).map((e) => e.toString()),
      );
      final initialStack = (json['initialStack'] as List)
          .map((e) => e.toString())
          .toList();

      final queue = ListQueue<_PdaConfiguration>();
      queue.add(
        _PdaConfiguration(
          state: initialState,
          index: 0,
          stack: List<String>.from(initialStack),
        ),
      );

      final visited = <String>{};

      bool isEpsilon(String symbol) => symbol.isEmpty || symbol == 'λ';

      while (queue.isNotEmpty) {
        final config = queue.removeFirst();
        final signature =
            '${config.state}|${config.index}|${config.stack.join(',')}';
        if (!visited.add(signature)) {
          continue;
        }

        if (config.index == input.length &&
            finalStates.contains(config.state)) {
          return true;
        }

        final available = transitions[config.state];
        if (available == null) {
          continue;
        }

        for (final transition in available) {
          final nextStack = List<String>.from(config.stack);

          if (transition.requiredStackTop.isNotEmpty) {
            if (nextStack.isEmpty ||
                nextStack.last != transition.requiredStackTop) {
              continue;
            }
            nextStack.removeLast();
          }

          final consumesEpsilon = isEpsilon(transition.inputSymbol);

          if (!consumesEpsilon) {
            if (config.index >= input.length) {
              continue;
            }
            final currentSymbol = input[config.index];
            if (currentSymbol != transition.inputSymbol) {
              continue;
            }
          }

          final replacement = transition.stackReplacement;
          if (replacement.isNotEmpty) {
            for (var i = replacement.length - 1; i >= 0; i--) {
              nextStack.add(replacement[i]);
            }
          }

          final nextIndex = consumesEpsilon ? config.index : config.index + 1;

          queue.add(
            _PdaConfiguration(
              state: transition.toState,
              index: nextIndex,
              stack: nextStack,
            ),
          );
        }
      }

      return false;
    }

    test('APD palindrome example accepts palindromes and rejects non-palindromes', () {
      final json = loadExample('apda_palindrome.json');

      const accepted = ['','a','b','aa','bb','aba','bab','abba','baab','abbba'];
      const rejected = ['ab','ba','abb','aab','ababa','abbabb'];

      for (final word in accepted) {
        expect(
          runPda(json, word),
          isTrue,
          reason: 'Expected palindrome "$word" to be accepted.',
        );
      }

      for (final word in rejected) {
        expect(
          runPda(json, word),
          isFalse,
          reason: 'Expected non-palindrome "$word" to be rejected.',
        );
      }
    });

    test('Validates TM example structure', () {
      final json = loadExample('tm_binary_to_unary.json');
      final metadata = metadataFor(
        category: ExampleCategory.tm,
        fileName: 'tm_binary_to_unary.json',
      );

      final result = dataSource.convertJsonForTesting(
        json,
        metadata,
        'MT - Binário para unário',
      );

      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });
  });
}
