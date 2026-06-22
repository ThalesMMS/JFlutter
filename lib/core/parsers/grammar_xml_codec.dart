import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../models/grammar.dart';
import '../models/production.dart';
import '../result.dart';

/// Shared JFLAP XML codec for grammars.
class GrammarXmlCodec {
  const GrammarXmlCodec();

  /// Encodes a [Grammar] into the JFLAP grammar XML shape used by exports.
  String encodeGrammar(Grammar grammar) {
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'grammar');
        builder.element(
          'grammar',
          nest: () {
            builder.attribute('type', grammar.type.name);
            builder.element('start', nest: grammar.startSymbol);

            for (final production in grammar.productions) {
              builder.element(
                'production',
                nest: () {
                  builder.element('left', nest: production.leftSide.join(' '));
                  builder.element(
                    'right',
                    nest: production.rightSide.join(' '),
                  );
                },
              );
            }
          },
        );
      },
    );

    return builder.buildDocument().toXmlString(pretty: true);
  }

  /// Decodes JFLAP grammar XML into a [Grammar].
  Result<Grammar> decodeGrammarXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      return decodeGrammarDocument(document);
    } catch (e) {
      return Failure(e.toString());
    }
  }

  /// Decodes a parsed JFLAP grammar document into a [Grammar].
  Result<Grammar> decodeGrammarDocument(XmlDocument document) {
    try {
      final grammarElement = document.findAllElements('grammar').firstOrNull;
      if (grammarElement == null) {
        throw const FormatException(
          'JFLAP grammar import is missing the <grammar> element.',
        );
      }

      final startElement = grammarElement.findElements('start').firstOrNull;
      if (startElement == null) {
        throw const FormatException(
          'JFLAP grammar import is missing the <start> element.',
        );
      }
      final startSymbols = _splitGrammarSymbols(startElement.innerText);
      if (startSymbols.isEmpty) {
        throw const FormatException(
          'JFLAP grammar import has an empty <start> element.',
        );
      }
      if (startSymbols.length != 1) {
        throw const FormatException(
          'JFLAP grammar import must declare exactly one start symbol.',
        );
      }

      final productions = <Production>{};
      for (final productionElement in grammarElement.findAllElements(
        'production',
      )) {
        final leftElement = productionElement.findElements('left').firstOrNull;
        final rightElement =
            productionElement.findElements('right').firstOrNull;
        if (leftElement == null || rightElement == null) {
          throw const FormatException(
            'JFLAP grammar import has a <production> without <left> or <right>.',
          );
        }

        final leftSide = _splitGrammarSymbols(leftElement.innerText);
        final rightSide = _splitGrammarSymbols(rightElement.innerText);

        productions.add(
          Production(
            id: 'p${productions.length}',
            leftSide: leftSide,
            rightSide: rightSide,
            isLambda: rightSide.isEmpty,
            order: productions.length,
          ),
        );
      }

      final now = DateTime.now();
      return Success(
        Grammar(
          id: 'imported_grammar_${now.millisecondsSinceEpoch}',
          name: 'Imported Grammar',
          terminals: productions
              .expand((p) => p.rightSide)
              .where((s) => s.isNotEmpty)
              .toSet(),
          nonterminals: productions.expand((p) => p.leftSide).toSet(),
          startSymbol: startSymbols.single,
          productions: productions,
          type: GrammarType.contextFree,
          created: now,
          modified: now,
        ),
      );
    } catch (e) {
      return Failure(e.toString());
    }
  }

  List<String> _splitGrammarSymbols(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    return trimmed.split(RegExp(r'\s+'));
  }
}
