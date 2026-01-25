//
//  automaton_providers_integration_test.dart
//  JFlutter
//
//  Integration tests for the refactored automaton providers, verifying that
//  AutomatonStateProvider, AutomatonAlgorithmProvider, AutomatonSimulationProvider,
//  and AutomatonLayoutProvider can communicate and work together correctly.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/trace_persistence_service.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_algorithm_provider.dart';
import 'package:jflutter/presentation/providers/automaton_layout_provider.dart';
import 'package:jflutter/presentation/providers/automaton_simulation_provider.dart';
import 'package:jflutter/presentation/providers/automaton_state_provider.dart';

void main() {
  group('Automaton Providers Integration', () {
    late ProviderContainer container;
    late TracePersistenceService tracePersistenceService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tracePersistenceService = TracePersistenceService(prefs);

      // Create container with provider overrides to inject dependencies
      container = ProviderContainer(
        overrides: [
          automatonStateProvider.overrideWith((ref) {
            return AutomatonStateNotifier(automatonService: AutomatonService());
          }),
          automatonAlgorithmProvider.overrideWith((ref) {
            return AutomatonAlgorithmNotifier(ref);
          }),
          automatonSimulationProvider.overrideWith((ref) {
            return AutomatonSimulationNotifier(
              ref: ref,
              tracePersistenceService: tracePersistenceService,
            );
          }),
          automatonLayoutProvider.overrideWith((ref) {
            return AutomatonLayoutNotifier(ref, LayoutRepositoryImpl());
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'Algorithm provider can read current automaton from state provider',
      () async {
        // Create a simple NFA using state provider
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(100, 0),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'a'},
          label: 'a',
        );
        final nfa = FSA(
          id: 'nfa-test',
          name: 'Test NFA',
          states: {q0, q1},
          transitions: {transition},
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(nfa);

        // Verify state provider has the automaton
        final stateProviderState = container.read(automatonStateProvider);
        expect(stateProviderState.currentAutomaton, isNotNull);
        expect(stateProviderState.currentAutomaton!.id, 'nfa-test');

        // Convert NFA to DFA using algorithm provider
        final algorithmNotifier = container.read(
          automatonAlgorithmProvider.notifier,
        );
        await algorithmNotifier.convertNfaToDfa();

        // Verify algorithm provider can read the automaton and perform conversion
        final algorithmState = container.read(automatonAlgorithmProvider);
        expect(algorithmState.error, isNull);

        // Verify state provider now has the converted DFA
        final updatedState = container.read(automatonStateProvider);
        expect(updatedState.currentAutomaton, isNotNull);
        // The automaton should still work (conversion successful)
        expect(updatedState.error, isNull);
      },
    );

    test(
      'Simulation provider can access automaton from state provider',
      () async {
        // Create a simple DFA using state provider
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(100, 0),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'a'},
          label: 'a',
        );
        final dfa = FSA(
          id: 'dfa-test',
          name: 'Test DFA',
          states: {q0, q1},
          transitions: {transition},
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(dfa);

        // Verify state provider has the automaton
        final stateProviderState = container.read(automatonStateProvider);
        expect(stateProviderState.currentAutomaton, isNotNull);

        // Simulate input string using simulation provider
        final simulationNotifier = container.read(
          automatonSimulationProvider.notifier,
        );
        await simulationNotifier.simulateAutomaton('a');

        // Verify simulation provider can access the automaton and run simulation
        final simulationState = container.read(automatonSimulationProvider);
        expect(simulationState.error, isNull);
        expect(simulationState.simulationResult, isNotNull);
        expect(simulationState.simulationResult!.accepted, isTrue);
      },
    );

    test(
      'Layout provider can update automaton state in state provider',
      () async {
        // Create an automaton using state provider
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2.zero(), // Same position - needs layout
          isInitial: false,
          isAccepting: true,
        );
        final q2 = automaton_state.State(
          id: 'q2',
          label: 'q2',
          position: Vector2.zero(), // Same position - needs layout
          isInitial: false,
          isAccepting: false,
        );
        final automaton = FSA(
          id: 'layout-test',
          name: 'Test Layout',
          states: {q0, q1, q2},
          transitions: {},
          alphabet: {},
          initialState: q0,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(automaton);

        // Store original positions
        final originalState = container.read(automatonStateProvider);
        final originalAutomaton = originalState.currentAutomaton!;
        final originalPositions = originalAutomaton.states
            .map((s) => s.position)
            .toList();

        // Apply auto layout using layout provider
        final layoutNotifier = container.read(automatonLayoutProvider.notifier);
        await layoutNotifier.applyAutoLayout();

        // Verify layout provider can update the automaton in state provider
        final updatedState = container.read(automatonStateProvider);
        final updatedAutomaton = updatedState.currentAutomaton;

        expect(updatedAutomaton, isNotNull);
        expect(updatedState.error, isNull);

        // Layout should have changed positions (they were all at zero)
        final updatedPositions = updatedAutomaton!.states
            .map((s) => s.position)
            .toList();

        // At least some positions should be different after layout
        final positionsChanged = updatedPositions.any(
          (pos) => !originalPositions.any(
            (orig) => orig.x == pos.x && orig.y == pos.y,
          ),
        );
        expect(
          positionsChanged,
          isTrue,
          reason: 'Layout should update state positions',
        );
      },
    );

    test('Full integration: create → algorithm → simulate → layout', () async {
      // 1. Create automaton using state provider
      final stateNotifier = container.read(automatonStateProvider.notifier);
      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(50, 0),
        isInitial: false,
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a', 'b'},
        label: 'a,b',
      );
      final nfa = FSA(
        id: 'integration-test',
        name: 'Integration Test',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a', 'b'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      stateNotifier.updateAutomaton(nfa);
      expect(
        container.read(automatonStateProvider).currentAutomaton,
        isNotNull,
      );

      // 2. Run algorithm (NFA to DFA conversion)
      final algorithmNotifier = container.read(
        automatonAlgorithmProvider.notifier,
      );
      await algorithmNotifier.convertNfaToDfa();

      var stateAfterAlgorithm = container.read(automatonStateProvider);
      expect(stateAfterAlgorithm.currentAutomaton, isNotNull);
      expect(stateAfterAlgorithm.error, isNull);

      // 3. Simulate with input
      final simulationNotifier = container.read(
        automatonSimulationProvider.notifier,
      );
      await simulationNotifier.simulateAutomaton('ab');

      var simulationState = container.read(automatonSimulationProvider);
      expect(simulationState.simulationResult, isNotNull);
      expect(simulationState.error, isNull);

      // 4. Apply layout
      final layoutNotifier = container.read(automatonLayoutProvider.notifier);
      await layoutNotifier.applyAutoLayout();

      var finalState = container.read(automatonStateProvider);
      expect(finalState.currentAutomaton, isNotNull);
      expect(finalState.error, isNull);

      // Verify all providers worked correctly
      final finalAlgorithmState = container.read(automatonAlgorithmProvider);
      final finalSimulationState = container.read(automatonSimulationProvider);
      final finalLayoutState = container.read(automatonLayoutProvider);

      expect(finalAlgorithmState.error, isNull);
      expect(finalSimulationState.error, isNull);
      expect(finalLayoutState.error, isNull);
    });

    test('Providers clear their state when automaton changes', () async {
      // Create initial automaton
      final stateNotifier = container.read(automatonStateProvider.notifier);
      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: true,
      );
      final automaton1 = FSA(
        id: 'automaton-1',
        name: 'Automaton 1',
        states: {q0},
        transitions: {},
        alphabet: {},
        initialState: q0,
        acceptingStates: {q0},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      stateNotifier.updateAutomaton(automaton1);

      // Run algorithm to generate results
      final algorithmNotifier = container.read(
        automatonAlgorithmProvider.notifier,
      );
      await algorithmNotifier.convertFsaToGrammar();

      // Verify algorithm has results
      var algorithmState = container.read(automatonAlgorithmProvider);
      expect(algorithmState.grammarResult, isNotNull);

      // Create a different automaton
      final automaton2 = FSA(
        id: 'automaton-2', // Different ID
        name: 'Automaton 2',
        states: {q0},
        transitions: {},
        alphabet: {},
        initialState: q0,
        acceptingStates: {q0},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      stateNotifier.updateAutomaton(automaton2);

      // Verify algorithm results were cleared when automaton changed
      algorithmState = container.read(automatonAlgorithmProvider);
      expect(
        algorithmState.grammarResult,
        isNull,
        reason: 'Algorithm results should clear when automaton changes',
      );
    });
  });
}
