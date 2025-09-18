import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton_data.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/models/grammar_data.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/regular_expression_data.dart';
import 'package:jflutter/core/models/pumping_lemma_data.dart';
import 'package:jflutter/core/models/test_case.dart';
import 'package:jflutter/core/models/view_settings.dart';
import 'package:jflutter/core/models/app_state.dart';
import 'package:jflutter/core/services/workspace_service.dart';

void main() {
  group('Workspace API Contract Tests', () {
    late WorkspaceService workspaceService;

    setUp(() {
      workspaceService = WorkspaceService();
    });

    group('GET /workspaces', () {
      test('should return all workspaces with correct schema', () async {
        // Arrange
        // No setup needed - testing empty state

        // Act
        final result = await workspaceService.getAllWorkspaces();

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('workspaces'), isTrue);
        expect(result.containsKey('viewSettings'), isTrue);
        expect(result.containsKey('appState'), isTrue);

        final workspaces = result['workspaces'] as Map<String, dynamic>;
        expect(workspaces.containsKey('finite_automaton'), isTrue);
        expect(workspaces.containsKey('pushdown_automaton'), isTrue);
        expect(workspaces.containsKey('turing_machine'), isTrue);
        expect(workspaces.containsKey('grammar'), isTrue);
        expect(workspaces.containsKey('regular_expression'), isTrue);
        expect(workspaces.containsKey('pumping_lemma'), isTrue);
      });
    });

    group('GET /workspaces/{workspaceId}', () {
      test('should return finite automaton workspace', () async {
        // Act
        final result = await workspaceService.getWorkspace('finite_automaton');

        // Assert
        expect(result, isA<AutomatonData>());
        expect(result.states, isA<List<State>>());
        expect(result.transitions, isA<List<Transition>>());
        expect(result.alphabet, isA<Set<String>>());
        expect(result.finalStates, isA<Set<String>>());
      });

      test('should return grammar workspace', () async {
        // Act
        final result = await workspaceService.getWorkspace('grammar');

        // Assert
        expect(result, isA<GrammarData>());
        expect(result.variables, isA<Set<String>>());
        expect(result.terminals, isA<Set<String>>());
        expect(result.productions, isA<List<Production>>());
        expect(result.startVariable, isA<String>());
      });

      test('should return 404 for invalid workspace ID', () async {
        // Act & Assert
        expect(
          () => workspaceService.getWorkspace('invalid_workspace'),
          throwsA(isA<WorkspaceNotFoundException>()),
        );
      });
    });

    group('PUT /workspaces/{workspaceId}', () {
      test('should update finite automaton workspace', () async {
        // Arrange
        final automatonData = AutomatonData(
          states: [
            State(
              id: 'q0',
              label: 'q0',
              position: Point(100, 100),
              isInitial: true,
              isFinal: false,
            ),
          ],
          transitions: [],
          alphabet: {'a', 'b'},
          initialState: 'q0',
          finalStates: {},
        );

        // Act
        await workspaceService.updateWorkspace('finite_automaton', automatonData);

        // Assert
        final updated = await workspaceService.getWorkspace('finite_automaton');
        expect(updated.states.length, equals(1));
        expect(updated.states.first.id, equals('q0'));
        expect(updated.alphabet, equals({'a', 'b'}));
      });

      test('should return 400 for invalid automaton data', () async {
        // Arrange
        final invalidData = AutomatonData(
          states: [],
          transitions: [],
          alphabet: {},
          initialState: null,
          finalStates: {},
        );

        // Act & Assert
        expect(
          () => workspaceService.updateWorkspace('finite_automaton', invalidData),
          throwsA(isA<InvalidWorkspaceDataException>()),
        );
      });
    });

    group('POST /workspaces/{workspaceId}/states', () {
      test('should add state to finite automaton', () async {
        // Arrange
        final newState = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isFinal: true,
        );

        // Act
        await workspaceService.addState('finite_automaton', newState);

        // Assert
        final workspace = await workspaceService.getWorkspace('finite_automaton');
        expect(workspace.states.length, equals(1));
        expect(workspace.states.first.id, equals('q1'));
        expect(workspace.states.first.isFinal, isTrue);
      });

      test('should return 400 for invalid state data', () async {
        // Arrange
        final invalidState = State(
          id: '',
          label: '',
          position: Point(0, 0),
          isInitial: false,
          isFinal: false,
        );

        // Act & Assert
        expect(
          () => workspaceService.addState('finite_automaton', invalidState),
          throwsA(isA<InvalidStateDataException>()),
        );
      });
    });

    group('DELETE /workspaces/{workspaceId}/states', () {
      test('should delete state from finite automaton', () async {
        // Arrange
        final state = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isFinal: true,
        );
        await workspaceService.addState('finite_automaton', state);

        // Act
        await workspaceService.deleteState('finite_automaton', 'q1');

        // Assert
        final workspace = await workspaceService.getWorkspace('finite_automaton');
        expect(workspace.states.length, equals(0));
      });

      test('should return 404 for non-existent state', () async {
        // Act & Assert
        expect(
          () => workspaceService.deleteState('finite_automaton', 'non_existent'),
          throwsA(isA<StateNotFoundException>()),
        );
      });
    });

    group('POST /workspaces/{workspaceId}/transitions', () {
      test('should add transition to finite automaton', () async {
        // Arrange
        final state1 = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isFinal: false,
        );
        final state2 = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isFinal: true,
        );
        await workspaceService.addState('finite_automaton', state1);
        await workspaceService.addState('finite_automaton', state2);

        final transition = Transition(
          id: 't1',
          fromState: 'q0',
          toState: 'q1',
          label: 'a',
          controlPoints: [],
        );

        // Act
        await workspaceService.addTransition('finite_automaton', transition);

        // Assert
        final workspace = await workspaceService.getWorkspace('finite_automaton');
        expect(workspace.transitions.length, equals(1));
        expect(workspace.transitions.first.label, equals('a'));
      });

      test('should return 400 for invalid transition data', () async {
        // Arrange
        final invalidTransition = Transition(
          id: '',
          fromState: 'non_existent',
          toState: 'non_existent',
          label: '',
          controlPoints: [],
        );

        // Act & Assert
        expect(
          () => workspaceService.addTransition('finite_automaton', invalidTransition),
          throwsA(isA<InvalidTransitionDataException>()),
        );
      });
    });

    group('POST /workspaces/{workspaceId}/simulate', () {
      test('should simulate finite automaton with valid input', () async {
        // Arrange
        final state1 = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isFinal: false,
        );
        final state2 = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 200),
          isInitial: false,
          isFinal: true,
        );
        await workspaceService.addState('finite_automaton', state1);
        await workspaceService.addState('finite_automaton', state2);

        final transition = Transition(
          id: 't1',
          fromState: 'q0',
          toState: 'q1',
          label: 'a',
          controlPoints: [],
        );
        await workspaceService.addTransition('finite_automaton', transition);

        // Act
        final result = await workspaceService.simulate('finite_automaton', 'a');

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('accepted'), isTrue);
        expect(result.containsKey('steps'), isTrue);
        expect(result['accepted'], isA<bool>());
        expect(result['steps'], isA<List>());
      });

      test('should return 400 for invalid input string', () async {
        // Act & Assert
        expect(
          () => workspaceService.simulate('finite_automaton', ''),
          throwsA(isA<InvalidInputStringException>()),
        );
      });
    });

    group('POST /workspaces/grammar/productions', () {
      test('should add production to grammar', () async {
        // Arrange
        final production = Production(
          id: 'p1',
          leftSide: 'S',
          rightSide: 'aSb',
        );

        // Act
        await workspaceService.addProduction(production);

        // Assert
        final workspace = await workspaceService.getWorkspace('grammar');
        expect(workspace.productions.length, equals(1));
        expect(workspace.productions.first.leftSide, equals('S'));
        expect(workspace.productions.first.rightSide, equals('aSb'));
      });

      test('should return 400 for invalid production data', () async {
        // Arrange
        final invalidProduction = Production(
          id: '',
          leftSide: '',
          rightSide: '',
        );

        // Act & Assert
        expect(
          () => workspaceService.addProduction(invalidProduction),
          throwsA(isA<InvalidProductionDataException>()),
        );
      });
    });

    group('POST /workspaces/regular_expression/test', () {
      test('should test regular expression against string', () async {
        // Act
        final result = await workspaceService.testRegularExpression('a*b', 'aaab');

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result.containsKey('matches'), isTrue);
        expect(result.containsKey('groups'), isTrue);
        expect(result['matches'], isA<bool>());
        expect(result['groups'], isA<List>());
      });

      test('should return 400 for invalid expression', () async {
        // Act & Assert
        expect(
          () => workspaceService.testRegularExpression('[invalid', 'test'),
          throwsA(isA<InvalidRegularExpressionException>()),
        );
      });
    });
  });
}

// Custom exception classes for contract testing
class WorkspaceNotFoundException implements Exception {
  final String message;
  WorkspaceNotFoundException(this.message);
}

class InvalidWorkspaceDataException implements Exception {
  final String message;
  InvalidWorkspaceDataException(this.message);
}

class InvalidStateDataException implements Exception {
  final String message;
  InvalidStateDataException(this.message);
}

class StateNotFoundException implements Exception {
  final String message;
  StateNotFoundException(this.message);
}

class InvalidTransitionDataException implements Exception {
  final String message;
  InvalidTransitionDataException(this.message);
}

class InvalidInputStringException implements Exception {
  final String message;
  InvalidInputStringException(this.message);
}

class InvalidProductionDataException implements Exception {
  final String message;
  InvalidProductionDataException(this.message);
}

class InvalidRegularExpressionException implements Exception {
  final String message;
  InvalidRegularExpressionException(this.message);
}
