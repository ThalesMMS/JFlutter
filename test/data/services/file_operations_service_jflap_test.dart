import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/data/services/file_operations_service.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileOperationsService JFLAP export/import', () {
    late Directory tempDir;
    late FileOperationsService service;
    late FSA automatonWithSpecialChars;
    late Grammar grammarWithSpecialChars;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('jflap_escape_test');
      service = FileOperationsService();

      const stateLabel = "S &<>\"'";
      const transitionSymbol = "a&<>\"'";

      final initialState = automaton_state.State(
        id: 's0',
        label: stateLabel,
        position: Vector2(100, 100),
        isInitial: true,
      );

      final acceptingState = automaton_state.State(
        id: 's1',
        label: 'accept',
        position: Vector2(200, 100),
        isAccepting: true,
      );

      final transition = FSATransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: transitionSymbol,
        inputSymbols: {transitionSymbol},
      );

      automatonWithSpecialChars = FSA(
        id: 'special_chars_automaton',
        name: 'SpecialChars',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: {transitionSymbol},
        initialState: initialState,
        acceptingStates: {acceptingState},
        bounds: const math.Rectangle(0, 0, 400, 300),
        created: DateTime.now(),
        modified: DateTime.now(),
      );

      const startSymbol = "S&<>\"'";
      const terminalSymbol = "a&<>\"'";

      final production = Production(
        id: 'p0',
        leftSide: const [startSymbol],
        rightSide: const [terminalSymbol],
        order: 0,
      );

      grammarWithSpecialChars = Grammar(
        id: 'grammar_special_chars',
        name: 'GrammarSpecialChars',
        terminals: const {terminalSymbol},
        nonterminals: const {startSymbol},
        startSymbol: startSymbol,
        productions: {production},
        type: GrammarType.contextFree,
        created: DateTime.now(),
        modified: DateTime.now(),
      );
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('persists automaton labels with reserved XML characters', () async {
      final filePath = '${tempDir.path}/automaton.jff';
      final saveResult = await service.saveAutomatonToJFLAP(
        automatonWithSpecialChars,
        filePath,
      );

      expect(saveResult.isSuccess, isTrue, reason: saveResult.error);

      final xmlContent = await File(filePath).readAsString();

      expect(xmlContent, contains('name="S &amp;&lt;&gt;&quot;&apos;"'));
      expect(xmlContent, contains('<read>a&amp;&lt;&gt;&quot;&apos;</read>'));
      expect(xmlContent, isNot(contains('S &<>')));
      expect(xmlContent, isNot(contains('<read>a&<')));

      final loadResult = await service.loadAutomatonFromJFLAP(filePath);
      expect(loadResult.isSuccess, isTrue, reason: loadResult.error);

      final imported = loadResult.data!;
      final importedState =
          imported.states.firstWhere((state) => state.id == 's0');
      final importedTransition = imported.transitions
          .whereType<FSATransition>()
          .firstWhere((t) => t.id == 't0');

      expect(importedState.label, equals("S &<>\"'"));
      expect(importedTransition.symbol, equals("a&<>\"'"));
    });

    test('persists grammar symbols with reserved XML characters', () async {
      final filePath = '${tempDir.path}/grammar.cfg';
      final saveResult = await service.saveGrammarToJFLAP(
        grammarWithSpecialChars,
        filePath,
      );

      expect(saveResult.isSuccess, isTrue, reason: saveResult.error);

      final xmlContent = await File(filePath).readAsString();

      expect(xmlContent, contains('<start>S&amp;&lt;&gt;&quot;&apos;</start>'));
      expect(xmlContent, contains('<left>S&amp;&lt;&gt;&quot;&apos;</left>'));
      expect(xmlContent, contains('<right>a&amp;&lt;&gt;&quot;&apos;</right>'));
      expect(xmlContent, isNot(contains('<start>S&<')));
      expect(xmlContent, isNot(contains('<left>S&<')));
      expect(xmlContent, isNot(contains('<right>a&<')));

      final loadResult = await service.loadGrammarFromJFLAP(filePath);
      expect(loadResult.isSuccess, isTrue, reason: loadResult.error);

      final imported = loadResult.data!;
      expect(imported.startSymbol, equals("S&<>\"'"));

      final importedProduction = imported.productions.firstWhere(
        (production) => production.id == 'p0',
      );

      expect(importedProduction.leftSide, equals(const ["S&<>\"'"]));
      expect(importedProduction.rightSide, equals(const ["a&<>\"'"]));
    });
  });
}
