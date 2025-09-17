import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/simulation_service.dart';

/// Contract tests for simulation operations
/// These tests MUST fail before implementation and MUST pass after implementation
void main() {
  group('Simulation Service Contract Tests', () {
    late AutomatonService automatonService;
    late SimulationService simulationService;

    setUp(() {
      automatonService = AutomatonService();
      simulationService = SimulationService();
    });

    group('FSA Simulation', () {
      test('should accept valid input string', () async {
        // Arrange
        final automaton = await createSimpleFSA();
        final request = SimulationRequest(
          inputString: 'ab',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        expect(result.data!.inputString, equals('ab'));
        expect(result.data!.steps, isNotEmpty);
        expect(result.data!.errorMessage, isEmpty);
      });

      test('should reject invalid input string', () async {
        // Arrange
        final automaton = await createSimpleFSA();
        final request = SimulationRequest(
          inputString: 'c',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isFalse);
        expect(result.data!.inputString, equals('c'));
        expect(result.data!.steps, isNotEmpty);
      });

      test('should handle empty string', () async {
        // Arrange
        final automaton = await createSimpleFSA();
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

      test('should provide step-by-step simulation', () async {
        // Arrange
        final automaton = await createSimpleFSA();
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
        
        // Verify each step has required fields
        for (final step in result.data!.steps) {
          expect(step.currentState, isNotNull);
          expect(step.remainingInput, isNotNull);
          expect(step.stepNumber, greaterThan(0));
        }
      });
    });

    group('NFA Simulation', () {
      test('should handle non-deterministic transitions', () async {
        // Arrange
        final automaton = await createNFA();
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
      });

      test('should handle lambda transitions', () async {
        // Arrange
        final automaton = await createNFAWithLambda();
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
      });
    });

    group('PDA Simulation', () {
      test('should simulate PDA with stack operations', () async {
        // Arrange
        final automaton = await createPDA();
        final request = SimulationRequest(
          inputString: 'aabb',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        
        // Verify stack operations are tracked
        final stepsWithStack = result.data!.steps
            .where((step) => step.stackContents.isNotEmpty);
        expect(stepsWithStack, isNotEmpty);
      });

      test('should handle stack underflow', () async {
        // Arrange
        final automaton = await createPDA();
        final request = SimulationRequest(
          inputString: 'ab',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isFalse);
      });
    });

    group('Turing Machine Simulation', () {
      test('should simulate TM with tape operations', () async {
        // Arrange
        final automaton = await createTM();
        final request = SimulationRequest(
          inputString: '101',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isTrue);
        
        // Verify tape operations are tracked
        final stepsWithTape = result.data!.steps
            .where((step) => step.tapeContents.isNotEmpty);
        expect(stepsWithTape, isNotEmpty);
      });

      test('should handle infinite loop detection', () async {
        // Arrange
        final automaton = await createInfiniteLoopTM();
        final request = SimulationRequest(
          inputString: '1',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.accepted, isFalse);
        expect(result.data!.errorMessage, contains('infinite loop'));
      });
    });

    group('Error Handling', () {
      test('should return error for non-existent automaton', () async {
        // Arrange
        const nonExistentId = 'non-existent-id';
        final request = SimulationRequest(
          inputString: 'test',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(nonExistentId, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('not found'));
      });

      test('should return error for invalid automaton', () async {
        // Arrange
        final automaton = await createInvalidAutomaton();
        final request = SimulationRequest(
          inputString: 'test',
          stepByStep: false,
        );

        // Act
        final result = await simulationService.simulate(automaton.id, request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('invalid'));
      });
    });

    group('Performance', () {
      test('should complete simulation within time limit', () async {
        // Arrange
        final automaton = await createLargeAutomaton();
        final request = SimulationRequest(
          inputString: 'a' * 100,
          stepByStep: false,
        );

        // Act
        final stopwatch = Stopwatch()..start();
        final result = await simulationService.simulate(automaton.id, request);
        stopwatch.stop();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 second limit
      });
    });
  });

  // Helper methods to create test automata
  Future<Automaton> createSimpleFSA() async {
    final request = CreateAutomatonRequest(
      name: 'Simple FSA',
      type: AutomatonType.fsa,
    );
    final result = await AutomatonService().createAutomaton(request);
    
    final automaton = result.data!;
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

  Future<Automaton> createNFA() async {
    // Implementation for NFA creation
    throw UnimplementedError('NFA creation not implemented yet');
  }

  Future<Automaton> createNFAWithLambda() async {
    // Implementation for NFA with lambda transitions
    throw UnimplementedError('NFA with lambda creation not implemented yet');
  }

  Future<Automaton> createPDA() async {
    // Implementation for PDA creation
    throw UnimplementedError('PDA creation not implemented yet');
  }

  Future<Automaton> createTM() async {
    // Implementation for TM creation
    throw UnimplementedError('TM creation not implemented yet');
  }

  Future<Automaton> createInfiniteLoopTM() async {
    // Implementation for infinite loop TM
    throw UnimplementedError('Infinite loop TM creation not implemented yet');
  }

  Future<Automaton> createInvalidAutomaton() async {
    // Implementation for invalid automaton
    throw UnimplementedError('Invalid automaton creation not implemented yet');
  }

  Future<Automaton> createLargeAutomaton() async {
    // Implementation for large automaton
    throw UnimplementedError('Large automaton creation not implemented yet');
  }
}
