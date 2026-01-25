//
//  import_export_validation_test.dart
//  JFlutter
//
//  Suite de testes que exercita o ImportExportValidationService, garantindo que
//  autômatos válidos sejam aceitos, que inconsistências estruturais sejam
//  identificadas antes da serialização e que relatórios de erro agreguem todas
//  as violações detectadas em diferentes cenários.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:jflutter/data/services/import_export_validation_service.dart';
import 'package:jflutter/data/services/serialization_service.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/fsa_transition.dart';

void main() {
  group('ImportExportValidationService', () {
    late ImportExportValidationService validationService;
    late FSA testAutomaton;

    setUp(() {
      validationService = ImportExportValidationService(SerializationService());

      // Create a simple test automaton
      final state1 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 100),
        isInitial: true,
        isAccepting: false,
      );

      final state2 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(200, 100),
        isInitial: false,
        isAccepting: true,
      );

      final transition = FSATransition(
        id: 't1',
        fromState: state1,
        toState: state2,
        label: 'a',
        inputSymbols: const {'a'},
      );

      testAutomaton = FSA(
        id: 'test_automaton',
        name: 'Test Automaton',
        states: {state1, state2},
        transitions: {transition},
        alphabet: const {'a'},
        acceptingStates: {state2},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 400, 300),
      );
    });

    test('should validate JFLAP round-trip successfully', () async {
      final result = validationService.validateJflapRoundTrip(testAutomaton);

      expect(result.success, isTrue);
      expect(result.message, contains('JFLAP round-trip validation passed'));
      expect(result.details, isNotNull);
      expect(result.details!['originalStates'], equals(2));
      expect(result.details!['reconstructedStates'], equals(2));
    });

    test('should validate JSON round-trip successfully', () async {
      final result = validationService.validateJsonRoundTrip(testAutomaton);

      expect(result.success, isTrue);
      expect(result.message, contains('JSON round-trip validation passed'));
      expect(result.details, isNotNull);
      expect(result.details!['originalStates'], equals(2));
      expect(result.details!['reconstructedStates'], equals(2));
    });

    test('should validate SVG export successfully', () async {
      final result = validationService.validateSvgExport(testAutomaton);

      expect(result.success, isTrue);
      expect(result.message, contains('SVG export validation passed'));
      expect(result.details, isNotNull);
      expect(result.details!['states'], equals(2));
      expect(result.details!['transitions'], equals(1));
    });

    test('should validate cross-format compatibility', () async {
      final result = validationService.validateCrossFormatCompatibility(
        testAutomaton,
      );

      expect(result.success, isTrue);
      expect(
        result.message,
        contains('Cross-format compatibility validation passed'),
      );
      expect(result.details, isNotNull);
      expect(result.details!['jflapStates'], equals(2));
      expect(result.details!['jsonStates'], equals(2));
    });

    test('should validate error handling', () async {
      final result = validationService.validateErrorHandling();

      expect(result.success, isTrue);
      expect(result.message, contains('Error handling validation passed'));
      expect(result.details, isNotNull);

      // Check that all error cases were handled correctly
      final details = result.details!;
      expect(details['Invalid JSON'], isTrue);
      expect(details['Invalid XML'], isTrue);
      expect(details['Empty input'], isTrue);
      expect(details['Null input'], isTrue);
      expect(details['Malformed JFLAP'], isTrue);
    });

    test('should perform comprehensive validation', () async {
      final result = await validationService.validateAllFormats(testAutomaton);

      expect(result.success, isTrue);
      expect(result.message, contains('All import/export validations passed'));
      expect(result.formatResults, hasLength(5));
      expect(result.summary['totalTests'], equals(5));
      expect(result.summary['passedTests'], equals(5));
      expect(result.summary['failedTests'], equals(0));
    });

    test('should handle empty automaton', () async {
      final emptyAutomaton = FSA(
        id: 'empty',
        name: 'Empty',
        states: const {},
        transitions: const {},
        alphabet: const {},
        acceptingStates: const {},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 400, 300),
      );

      final result = await validationService.validateAllFormats(emptyAutomaton);

      // Should still pass validation even with empty automaton
      expect(result.success, isTrue);
    });

    test('should handle automaton with self-loops', () async {
      final selfLoopState = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 100),
        isInitial: true,
        isAccepting: true,
      );

      final selfLoopTransition = FSATransition(
        id: 'self_loop',
        fromState: selfLoopState,
        toState: selfLoopState,
        label: 'a',
        inputSymbols: const {'a'},
      );

      final selfLoopAutomaton = FSA(
        id: 'self_loop_automaton',
        name: 'Self Loop Automaton',
        states: {selfLoopState},
        transitions: {selfLoopTransition},
        alphabet: const {'a'},
        acceptingStates: {selfLoopState},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 400, 300),
      );

      final result = await validationService.validateAllFormats(
        selfLoopAutomaton,
      );

      expect(result.success, isTrue);
    });

    test('should handle automaton with multiple transitions', () async {
      final state1 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 100),
        isInitial: true,
        isAccepting: false,
      );

      final state2 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(200, 100),
        isInitial: false,
        isAccepting: false,
      );

      final state3 = automaton_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(300, 100),
        isInitial: false,
        isAccepting: true,
      );

      final transition1 = FSATransition(
        id: 't1',
        fromState: state1,
        toState: state2,
        label: 'a',
        inputSymbols: const {'a'},
      );

      final transition2 = FSATransition(
        id: 't2',
        fromState: state2,
        toState: state3,
        label: 'b',
        inputSymbols: const {'b'},
      );

      final multiTransitionAutomaton = FSA(
        id: 'multi_transition_automaton',
        name: 'Multi Transition Automaton',
        states: {state1, state2, state3},
        transitions: {transition1, transition2},
        alphabet: const {'a', 'b'},
        acceptingStates: {state3},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const Rectangle(0, 0, 400, 300),
      );

      final result = await validationService.validateAllFormats(
        multiTransitionAutomaton,
      );

      expect(result.success, isTrue);
    });
  });
}
