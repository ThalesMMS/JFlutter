import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/data/services/simulation_service.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SimulationService', () {
    late SimulationService service;
    late FSA simpleAutomaton;

    setUp(() {
      service = SimulationService();
      simpleAutomaton = _createSimpleDeterministicAutomaton();
    });

    test('returns failure when automaton is null', () {
      const request = SimulationRequest(
        inputString: 'a',
      );

      final result = service.simulate(request);

      expect(result.isFailure, isTrue);
      expect(result.error, 'Automaton is required');
    });

    test('returns failure when input string is null', () {
      final request = SimulationRequest(
        automaton: simpleAutomaton,
      );

      final result = service.simulate(request);

      expect(result.isFailure, isTrue);
      expect(result.error, 'Input string is required');
    });

    test('returns success with accepted result for valid input', () {
      final request = SimulationRequest(
        automaton: simpleAutomaton,
        inputString: 'a',
        stepByStep: true,
      );

      final result = service.simulate(request);

      expect(result.isSuccess, isTrue, reason: result.error);
      final SimulationResult simulation = result.data!;
      expect(simulation.isAccepted, isTrue);
      expect(simulation.inputString, 'a');
      expect(simulation.steps, isNotEmpty);
    });
  });
}

FSA _createSimpleDeterministicAutomaton() {
  final initialState = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  final acceptingState = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );

  final transition = FSATransition(
    id: 't0',
    fromState: initialState,
    toState: acceptingState,
    label: 'a',
    inputSymbols: const {'a'},
  );

  final now = DateTime.now();

  return FSA(
    id: 'simple_fsa',
    name: 'SimpleFSA',
    states: {initialState, acceptingState},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: initialState,
    acceptingStates: {acceptingState},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 200, 100),
  );
}
