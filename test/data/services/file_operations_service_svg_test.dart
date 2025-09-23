import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/data/services/file_operations_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FileOperationsService SVG export', () {
    late Directory tempDir;
    late FileOperationsService service;
    late FSA automatonWithSpecialChars;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('svg_escape_test');
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
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('escapes special characters in SVG text nodes', () async {
      final filePath = '${tempDir.path}/special_chars.svg';
      final result = await service.exportAutomatonToSVG(
        automatonWithSpecialChars,
        filePath,
      );

      expect(result.isSuccess, isTrue, reason: result.error);

      final svgContent = await File(filePath).readAsString();

      expect(svgContent, contains('S &amp;&lt;&gt;&quot;&apos;'));
      expect(svgContent, contains('a&amp;&lt;&gt;&quot;&apos;'));
      expect(svgContent, contains('&apos;'));
      expect(svgContent, isNot(contains('S &<')));
      expect(svgContent, isNot(contains('a&<')));
    });
  });
}
