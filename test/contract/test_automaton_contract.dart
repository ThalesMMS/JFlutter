import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/automaton.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';

/// Contract tests for automaton CRUD operations
/// These tests MUST fail before implementation and MUST pass after implementation
void main() {
  group('Automaton Service Contract Tests', () {
    late AutomatonService automatonService;

    setUp(() {
      automatonService = AutomatonService();
    });

    group('Create Automaton', () {
      test('should create FSA automaton with valid data', () async {
        // Arrange
        final request = CreateAutomatonRequest(
          name: 'Test FSA',
          type: AutomatonType.fsa,
        );

        // Act
        final result = await automatonService.createAutomaton(request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.name, equals('Test FSA'));
        expect(result.data!.type, equals(AutomatonType.fsa));
        expect(result.data!.id, isNotEmpty);
        expect(result.data!.states, isEmpty);
        expect(result.data!.transitions, isEmpty);
        expect(result.data!.alphabet, isEmpty);
      });

      test('should create PDA automaton with valid data', () async {
        // Arrange
        final request = CreateAutomatonRequest(
          name: 'Test PDA',
          type: AutomatonType.pda,
        );

        // Act
        final result = await automatonService.createAutomaton(request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.pda));
      });

      test('should create TM automaton with valid data', () async {
        // Arrange
        final request = CreateAutomatonRequest(
          name: 'Test TM',
          type: AutomatonType.tm,
        );

        // Act
        final result = await automatonService.createAutomaton(request);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.type, equals(AutomatonType.tm));
      });

      test('should fail with empty name', () async {
        // Arrange
        final request = CreateAutomatonRequest(
          name: '',
          type: AutomatonType.fsa,
        );

        // Act
        final result = await automatonService.createAutomaton(request);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('name'));
      });
    });

    group('Get Automaton', () {
      test('should return automaton by ID', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'Test FSA',
          type: AutomatonType.fsa,
        );
        final createResult = await automatonService.createAutomaton(createRequest);
        final automatonId = createResult.data!.id;

        // Act
        final result = await automatonService.getAutomaton(automatonId);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.id, equals(automatonId));
        expect(result.data!.name, equals('Test FSA'));
      });

      test('should return error for non-existent automaton', () async {
        // Arrange
        const nonExistentId = 'non-existent-id';

        // Act
        final result = await automatonService.getAutomaton(nonExistentId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('not found'));
      });
    });

    group('Get All Automata', () {
      test('should return empty list when no automata exist', () async {
        // Act
        final result = await automatonService.getAllAutomata();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isEmpty);
      });

      test('should return all created automata', () async {
        // Arrange
        final request1 = CreateAutomatonRequest(
          name: 'FSA 1',
          type: AutomatonType.fsa,
        );
        final request2 = CreateAutomatonRequest(
          name: 'PDA 1',
          type: AutomatonType.pda,
        );

        await automatonService.createAutomaton(request1);
        await automatonService.createAutomaton(request2);

        // Act
        final result = await automatonService.getAllAutomata();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, hasLength(2));
        expect(result.data!.map((a) => a.name), containsAll(['FSA 1', 'PDA 1']));
      });
    });

    group('Update Automaton', () {
      test('should update automaton name', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'Original Name',
          type: AutomatonType.fsa,
        );
        final createResult = await automatonService.createAutomaton(createRequest);
        final automaton = createResult.data!;
        automaton.name = 'Updated Name';

        // Act
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.name, equals('Updated Name'));
      });

      test('should update automaton states', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'Test FSA',
          type: AutomatonType.fsa,
        );
        final createResult = await automatonService.createAutomaton(createRequest);
        final automaton = createResult.data!;
        
        final state = State(
          id: 'state1',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        automaton.states.add(state);

        // Act
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data!.states, hasLength(1));
        expect(result.data!.states.first.id, equals('state1'));
      });

      test('should fail to update non-existent automaton', () async {
        // Arrange
        final automaton = Automaton(
          id: 'non-existent',
          name: 'Test',
          type: AutomatonType.fsa,
          states: {},
          transitions: {},
          alphabet: {},
        );

        // Act
        final result = await automatonService.updateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('Delete Automaton', () {
      test('should delete existing automaton', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'To Delete',
          type: AutomatonType.fsa,
        );
        final createResult = await automatonService.createAutomaton(createRequest);
        final automatonId = createResult.data!.id;

        // Act
        final result = await automatonService.deleteAutomaton(automatonId);

        // Assert
        expect(result.isSuccess, isTrue);

        // Verify automaton is deleted
        final getResult = await automatonService.getAutomaton(automatonId);
        expect(getResult.isSuccess, isFalse);
      });

      test('should fail to delete non-existent automaton', () async {
        // Arrange
        const nonExistentId = 'non-existent-id';

        // Act
        final result = await automatonService.deleteAutomaton(nonExistentId);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
      });
    });

    group('Automaton Validation', () {
      test('should validate automaton with valid states and transitions', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'Valid FSA',
          type: AutomatonType.fsa,
        );
        final createResult = await automatonService.createAutomaton(createRequest);
        final automaton = createResult.data!;
        
        final state1 = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: true,
          isAccepting: false,
        );
        final state2 = State(
          id: 'q1',
          label: 'q1',
          position: Point(200, 100),
          isInitial: false,
          isAccepting: true,
        );
        
        automaton.states.addAll([state1, state2]);
        automaton.alphabet.add('a');
        automaton.initialState = state1;
        automaton.acceptingStates.add(state2);

        // Act
        final result = await automatonService.validateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isTrue);
      });

      test('should fail validation for automaton without initial state', () async {
        // Arrange
        final createRequest = CreateAutomatonRequest(
          name: 'Invalid FSA',
          type: AutomatonType.fsa,
        );
        final createResult = await automatonService.createAutomaton(createRequest);
        final automaton = createResult.data!;
        
        final state = State(
          id: 'q0',
          label: 'q0',
          position: Point(100, 100),
          isInitial: false,
          isAccepting: true,
        );
        
        automaton.states.add(state);
        automaton.acceptingStates.add(state);

        // Act
        final result = await automatonService.validateAutomaton(automaton);

        // Assert
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
        expect(result.error!.message, contains('initial state'));
      });
    });
  });
}
