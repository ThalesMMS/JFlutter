import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/simulation_service.dart';

/// Integration tests for FSA creation and simulation
/// These tests verify end-to-end functionality
void main() {
  group('FSA Creation and Simulation Integration Tests', () {
    late AutomatonService automatonService;
    late SimulationService simulationService;

    setUp(() {
      automatonService = AutomatonService();
      simulationService = SimulationService();
    });

    group('FSA Creation Workflow', () {
      test('should create FSA with states and transitions', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'Test FSA',
          type: AutomatonType.fsa,
        );

        // Act - Create automaton
        final createResult = await automatonService.createAutomaton(createRequest);
        expect(createResult.isSuccess, isTrue);
        
        final automaton = createResult.data!;
        
        // Add states
        final q0 = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        final q1 = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 100),
          isInitial: false,
          isAccepting: true,
        );
        
        automaton.states.addAll([q0, q1]);
        automaton.alphabet.addAll(['a', 'b']);
        automaton.initialState = q0;
        automaton.acceptingStates.add(q1);
        
        // Add transition
        final transition = FSATransition(
          id: 't1',
          fromState: q0,
          toState: q1,
          label: 'a',
          inputSymbols: {'a'},
        );
        automaton.transitions.add(transition);
        
        // Update automaton
        final updateResult = await automatonService.updateAutomaton(automaton);
        expect(updateResult.isSuccess, isTrue);
        
        // Assert
        final updatedAutomaton = updateResult.data!;
        expect(updatedAutomaton.states, hasLength(2));
        expect(updatedAutomaton.transitions, hasLength(1));
        expect(updatedAutomaton.alphabet, containsAll(['a', 'b']));
        expect(updatedAutomaton.initialState, equals(q0));
        expect(updatedAutomaton.acceptingStates, contains(q1));
      });

      test('should validate FSA before simulation', () async {
        // Arrange
        final automaton = await createValidFSA();

        // Act
        final validationResult = await automatonService.validateAutomaton(automaton);

        // Assert
        expect(validationResult.isSuccess, isTrue);
        expect(validationResult.data, isTrue);
      });

      test('should reject invalid FSA', () async {
        // Arrange
        final automaton = await createInvalidFSA();

        // Act
        final validationResult = await automatonService.validateAutomaton(automaton);

        // Assert
        expect(validationResult.isSuccess, isFalse);
        expect(validationResult.error, isNotNull);
      });
    });

    group('FSA Simulation Workflow', () {
      test('should simulate FSA with valid input', () async {
        // Arrange
        final automaton = await createValidFSA();
        final request = SimulationRequest(
          inputString: 'a',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        expect(result.data!.inputString, equals('a'));
        expect(result.data!.steps, isNotEmpty);
        expect(result.data!.errorMessage, isEmpty);
      });

      test('should simulate FSA with invalid input', () async {
        // Arrange
        final automaton = await createValidFSA();
        final request = SimulationRequest(
          inputString: 'b',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isFalse);
        expect(result.data!.inputString, equals('b'));
      });

      test('should provide step-by-step simulation', () async {
        // Arrange
        final automaton = await createComplexFSA();
        final request = SimulationRequest(
          inputString: 'ab',
          stepByStep: true,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.steps, hasLength(greaterThan(1)));
        
        // Verify step progression
        for (int i = 0; i < result.data!.steps.length; i++) {
          final step = result.data!.steps[i];
          expect(step.stepNumber, equals(i + 1));
          expect(step.currentState, isNotNull);
          expect(step.remainingInput, isNotNull);
        }
      });

      test('should handle empty string simulation', () async {
        // Arrange
        final automaton = await createValidFSA();
        final request = SimulationRequest(
          inputString: '',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.inputString, equals(''));
        expect(result.data!.steps, isNotEmpty);
      });
    });

    group('FSA State Management', () {
      test('should add state to existing FSA', () async {
        // Arrange
        final automaton = await createValidFSA();
        final newState = State(
          id: 'q2',
          label: 'q2',
          position: Point(300, 100),
          isInitial: false,
          isAccepting: false,
        );

        // Act
        automaton.states.add(newState);
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.states, hasLength(3));
        expect(result.data!.states.any((s) => s.id == 'q2'), isTrue);
      });

      test('should remove state from FSA', () async {
        // Arrange
        final automaton = await createValidFSA();
        final stateToRemove = automaton.states.first;

        // Act
        automaton.states.remove(stateToRemove);
        // Also remove transitions involving this state
        automaton.transitions.removeWhere((t) => 
          t.fromState.id == stateToRemove.id || t.toState.id == stateToRemove.id);
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.states, hasLength(1));
        expect(result.data!.transitions, isEmpty);
      });

      test('should update state properties', () async {
        // Arrange
        final automaton = await createValidFSA();
        final state = automaton.states.first;
        state.label = 'updated_label';
        state.isAccepting = true;

        // Act
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        final updatedState = result.data!.states.firstWhere((s) => s.id == state.id);
        expect(updatedState.label, equals('updated_label'));
        expect(updatedState.isAccepting, isTrue);
      });
    });

    group('FSA Transition Management', () {
      test('should add transition to FSA', () async {
        // Arrange
        final automaton = await createValidFSA();
        final fromState = automaton.states.first;
        final toState = automaton.states.last;
        final newTransition = FSATransition(
          id: 't2',
          fromState: fromState,
          toState: toState,
          label: 'b',
          inputSymbols: {'b'},
        );

        // Act
        automaton.transitions.add(newTransition);
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.transitions, hasLength(2));
        expect(result.data!.transitions.any((t) => t.id == 't2'), isTrue);
      });

      test('should remove transition from FSA', () async {
        // Arrange
        final automaton = await createValidFSA();
        final transitionToRemove = automaton.transitions.first;

        // Act
        automaton.transitions.remove(transitionToRemove);
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.transitions, isEmpty);
      });

      test('should update transition properties', () async {
        // Arrange
        final automaton = await createValidFSA();
        final transition = automaton.transitions.first as FSATransition;
        transition.label = 'c';
        transition.inputSymbols = {'c'};

        // Act
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        final updatedTransition = result.data!.transitions.first as FSATransition;
        expect(updatedTransition.label, equals('c'));
        expect(updatedTransition.inputSymbols, contains('c'));
      });
    });

    group('FSA Persistence', () {
      test('should save and load FSA', () async {
        // Arrange
        final automaton = await createValidFSA();
        final automatonId = automaton.id;

        // Act - Save
        final saveResult = await automatonService.saveAutomaton(automaton);
        expect(saveResult.isSuccess, isTrue);

        // Act - Load
        final loadResult = await automatonService.getAutomaton(automatonId);

        // Assert
        expect(loadResult.isSuccess, isTrue);
        expect(loadResult.data!.id, equals(automatonId));
        expect(loadResult.data!.states, hasLength(automaton.states.length));
        expect(loadResult.data!.transitions, hasLength(automaton.transitions.length));
      });

      test('should export FSA to file', () async {
        // Arrange
        final automaton = await createValidFSA();

        // Act
        final result = await automatonService.exportAutomaton(automaton.id, 'test_export.jff');

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data, isA<String>());
      });

      test('should import FSA from file', () async {
        // Arrange
        final filePath = 'test_import.jff';
        final fileContent = createJFLAPFileContent();

        // Act
        final result = await automatonService.importAutomaton(filePath, fileContent);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.fsa));
      });
    });
  });

  // Helper methods
  Future<Automaton> createValidFSA() async {
    final createRequest = CreateAutomatonRequest(
      name: 'Valid FSA',
      type: AutomatonType.fsa,
    );
    final createResult = await AutomatonService().createAutomaton(createRequest);
    
    final automaton = createResult.data!;
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Point(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Point(200, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    automaton.states.addAll([q0, q1]);
    automaton.alphabet.addAll(['a', 'b']);
    automaton.initialState = q0;
    automaton.acceptingStates.add(q1);
    
    final transition = FSATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      label: 'a',
      inputSymbols: {'a'},
    );
    automaton.transitions.add(transition);
    
    await AutomatonService().updateAutomaton(automaton);
    return automaton;
  }

  Future<Automaton> createInvalidFSA() async {
    final createRequest = CreateAutomatonRequest(
      name: 'Invalid FSA',
      type: AutomatonType.fsa,
    );
    final createResult = await AutomatonService().createAutomaton(createRequest);
    
    final automaton = createResult.data!;
    // Create FSA without initial state (invalid)
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Point(100, 100),
      isInitial: false, // No initial state
      isAccepting: true,
    );
    
    automaton.states.add(q0);
    automaton.acceptingStates.add(q0);
    
    await AutomatonService().updateAutomaton(automaton);
    return automaton;
  }

  Future<Automaton> createComplexFSA() async {
    final createRequest = CreateAutomatonRequest(
      name: 'Complex FSA',
      type: AutomatonType.fsa,
    );
    final createResult = await AutomatonService().createAutomaton(createRequest);
    
    final automaton = createResult.data!;
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Point(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Point(200, 100),
      isInitial: false,
      isAccepting: false,
    );
    final q2 = State(
      id: 'q2',
      label: 'q2',
      position: Point(300, 100),
      isInitial: false,
      isAccepting: true,
    );
    
    automaton.states.addAll([q0, q1, q2]);
    automaton.alphabet.addAll(['a', 'b']);
    automaton.initialState = q0;
    automaton.acceptingStates.add(q2);
    
    final transition1 = FSATransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      label: 'a',
      inputSymbols: {'a'},
    );
    final transition2 = FSATransition(
      id: 't2',
      fromState: q1,
      toState: q2,
      label: 'b',
      inputSymbols: {'b'},
    );
    automaton.transitions.addAll([transition1, transition2]);
    
    await AutomatonService().updateAutomaton(automaton);
    return automaton;
  }

  String createJFLAPFileContent() {
    return '''<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>100.0</x>
      <y>100.0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>200.0</x>
      <y>100.0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>''';
  }
}
