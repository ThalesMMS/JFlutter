import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/core/use_cases/automaton_use_cases.dart';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';

// Mock use cases for testing
class MockCreateAutomatonUseCase extends CreateAutomatonUseCase {
  MockCreateAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute({
    required String name,
    required AutomatonType type,
    Set<String> alphabet = const {},
  }) async {
    final automaton = AutomatonEntity(
      id: 'test-id',
      name: name,
      alphabet: alphabet,
      states: [],
      transitions: {},
      nextId: 0,
      type: type,
    );
    return Success(automaton);
  }
}

class MockLoadAutomatonUseCase extends LoadAutomatonUseCase {
  MockLoadAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute(String id) async {
    if (id == 'valid-id') {
      final automaton = AutomatonEntity(
        id: id,
        name: 'Test Automaton',
        alphabet: {'a', 'b'},
        states: [],
        transitions: {},
        nextId: 0,
        type: AutomatonType.dfa,
      );
      return Success(automaton);
    }
    return const Failure('Automaton not found');
  }
}

class MockSaveAutomatonUseCase extends SaveAutomatonUseCase {
  MockSaveAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute(AutomatonEntity automaton) async {
    return Success(automaton);
  }
}

class MockDeleteAutomatonUseCase extends DeleteAutomatonUseCase {
  MockDeleteAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<BoolResult> execute(String id) async {
    if (id == 'valid-id') {
      return const Success(true);
    }
    return const Failure('Automaton not found');
  }
}

class MockExportAutomatonUseCase extends ExportAutomatonUseCase {
  MockExportAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<StringResult> execute(AutomatonEntity automaton) async {
    return const Success('{"id":"test","name":"Test"}');
  }
}

class MockImportAutomatonUseCase extends ImportAutomatonUseCase {
  MockImportAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute(String jsonString) async {
    if (jsonString.contains('valid')) {
      final automaton = AutomatonEntity(
        id: 'imported-id',
        name: 'Imported Automaton',
        alphabet: {'a', 'b'},
        states: [],
        transitions: {},
        nextId: 0,
        type: AutomatonType.dfa,
      );
      return Success(automaton);
    }
    return const Failure('Invalid JSON');
  }
}

class MockValidateAutomatonUseCase extends ValidateAutomatonUseCase {
  MockValidateAutomatonUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<BoolResult> execute(AutomatonEntity automaton) async {
    if (automaton.states.isNotEmpty) {
      return const Success(true);
    }
    return const Failure('Automaton has no states');
  }
}

class MockAddStateUseCase extends AddStateUseCase {
  MockAddStateUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    bool isFinal = false,
    bool isInitial = false,
    required String name,
    required double x,
    required double y,
  }) async {
    final newState = StateEntity(
      id: 'new-state',
      name: name,
      x: 100.0,
      y: 100.0,
      isInitial: false,
      isFinal: false,
    );
    
    final updatedStates = [...automaton.states, newState];
    final updatedAutomaton = automaton.copyWith(
      states: updatedStates,
      nextId: automaton.nextId + 1,
    );
    
    return Success(updatedAutomaton);
  }
}

class MockRemoveStateUseCase extends RemoveStateUseCase {
  MockRemoveStateUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String stateId,
  }) async {
    final updatedStates = automaton.states.where((s) => s.id != stateId).toList();
    final updatedAutomaton = automaton.copyWith(states: updatedStates);
    
    return Success(updatedAutomaton);
  }
}

class MockAddTransitionUseCase extends AddTransitionUseCase {
  MockAddTransitionUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String fromStateId,
    required String symbol,
    required String toStateId,
  }) async {
    final key = '$fromStateId|$symbol';
    final updatedTransitions = Map<String, List<String>>.from(automaton.transitions);
    updatedTransitions[key] = [...(updatedTransitions[key] ?? []), toStateId];
    
    final updatedAutomaton = automaton.copyWith(transitions: updatedTransitions);
    
    return Success(updatedAutomaton);
  }
}

class MockRemoveTransitionUseCase extends RemoveTransitionUseCase {
  MockRemoveTransitionUseCase() : super(null as AutomatonRepository);
  
  @override
  Future<AutomatonResult> execute({
    required AutomatonEntity automaton,
    required String fromStateId,
    required String symbol,
    String? toStateId,
  }) async {
    final key = '$fromStateId|$symbol';
    final updatedTransitions = Map<String, List<String>>.from(automaton.transitions);
    final destinations = updatedTransitions[key] ?? [];
    destinations.remove(toStateId);
    
    if (destinations.isEmpty) {
      updatedTransitions.remove(key);
    } else {
      updatedTransitions[key] = destinations;
    }
    
    final updatedAutomaton = automaton.copyWith(transitions: updatedTransitions);
    
    return Success(updatedAutomaton);
  }
}

void main() {
  group('AutomatonProvider Tests', () {
    late AutomatonProvider provider;

    setUp(() {
      provider = AutomatonProvider(
        createAutomatonUseCase: MockCreateAutomatonUseCase(),
        loadAutomatonUseCase: MockLoadAutomatonUseCase(),
        saveAutomatonUseCase: MockSaveAutomatonUseCase(),
        deleteAutomatonUseCase: MockDeleteAutomatonUseCase(),
        exportAutomatonUseCase: MockExportAutomatonUseCase(),
        importAutomatonUseCase: MockImportAutomatonUseCase(),
        validateAutomatonUseCase: MockValidateAutomatonUseCase(),
        addStateUseCase: MockAddStateUseCase(),
        removeStateUseCase: MockRemoveStateUseCase(),
        addTransitionUseCase: MockAddTransitionUseCase(),
        removeTransitionUseCase: MockRemoveTransitionUseCase(),
      );
    });

    test('initial state should be correct', () {
      expect(provider.currentAutomaton, null);
      expect(provider.isLoading, false);
      expect(provider.error, null);
      expect(provider.validationErrors, isEmpty);
    });

    test('createAutomaton should create new automaton', () async {
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
        alphabet: {'a', 'b'},
      );

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.name, 'Test DFA');
      expect(provider.currentAutomaton!.type, AutomatonType.dfa);
      expect(provider.currentAutomaton!.alphabet, {'a', 'b'});
      expect(provider.error, null);
    });

    test('loadAutomaton should load existing automaton', () async {
      await provider.loadAutomaton('valid-id');

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.id, 'valid-id');
      expect(provider.currentAutomaton!.name, 'Test Automaton');
      expect(provider.error, null);
    });

    test('loadAutomaton should handle non-existent automaton', () async {
      await provider.loadAutomaton('invalid-id');

      expect(provider.currentAutomaton, null);
      expect(provider.error, 'Automaton not found');
    });

    test('saveAutomaton should save current automaton', () async {
      // First create an automaton
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );

      // Then save it
      await provider.saveAutomaton();

      expect(provider.error, null);
    });

    test('deleteAutomaton should delete automaton', () async {
      await provider.deleteAutomaton('valid-id');

      expect(provider.error, null);
    });

    test('deleteAutomaton should handle non-existent automaton', () async {
      await provider.deleteAutomaton('invalid-id');

      expect(provider.error, 'Automaton not found');
    });

    test('exportAutomaton should export current automaton', () async {
      // First create an automaton
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );

      // Then export it
      await provider.exportAutomaton();

      expect(provider.error, null);
    });

    test('importAutomaton should import valid JSON', () async {
      await provider.importAutomaton('{"valid": "json"}');

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.name, 'Imported Automaton');
      expect(provider.error, null);
    });

    test('importAutomaton should handle invalid JSON', () async {
      await provider.importAutomaton('invalid json');

      expect(provider.currentAutomaton, null);
      expect(provider.error, 'Invalid JSON');
    });

    test('validateAutomaton should validate current automaton', () async {
      // Create automaton with states
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );

      // Add a state first
      await provider.addState(
        name: 'Test State',
        x: 100.0,
        y: 100.0,
      );

      // Then validate
      await provider.validateAutomaton();

      expect(provider.validationErrors, isEmpty);
    });

    test('addState should add state to current automaton', () async {
      // First create an automaton
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );

      // Then add a state
      await provider.addState(
        name: 'New State',
        x: 100.0,
        y: 100.0,
      );

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.states.length, 1);
      expect(provider.currentAutomaton!.states.first.name, 'New State');
      expect(provider.error, null);
    });

    test('removeState should remove state from current automaton', () async {
      // First create an automaton and add a state
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );
      await provider.addState(
        name: 'State to Remove',
        x: 100.0,
        y: 100.0,
      );

      final stateId = provider.currentAutomaton!.states.first.id;

      // Then remove the state
      await provider.removeState(stateId);

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.states, isEmpty);
      expect(provider.error, null);
    });

    test('addTransition should add transition to current automaton', () async {
      // First create an automaton and add states
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );
      await provider.addState(
        name: 'State 1',
        x: 100.0,
        y: 100.0,
      );
      await provider.addState(
        name: 'State 2',
        x: 200.0,
        y: 100.0,
      );

      final states = provider.currentAutomaton!.states;
      final fromStateId = states[0].id;
      final toStateId = states[1].id;

      // Then add a transition
      await provider.addTransition(
        fromStateId: fromStateId,
        symbol: 'a',
        toStateId: toStateId,
      );

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.transitions.containsKey('$fromStateId|a'), true);
      expect(provider.currentAutomaton!.transitions['$fromStateId|a'], contains(toStateId));
      expect(provider.error, null);
    });

    test('removeTransition should remove transition from current automaton', () async {
      // First create an automaton, add states and transition
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );
      await provider.addState(
        name: 'State 1',
        x: 100.0,
        y: 100.0,
      );
      await provider.addState(
        name: 'State 2',
        x: 200.0,
        y: 100.0,
      );

      final states = provider.currentAutomaton!.states;
      final fromStateId = states[0].id;
      final toStateId = states[1].id;

      await provider.addTransition(
        fromStateId: fromStateId,
        symbol: 'a',
        toStateId: toStateId,
      );

      // Then remove the transition
      await provider.removeTransition(fromStateId, 'a', toStateId);

      expect(provider.currentAutomaton, isNotNull);
      expect(provider.currentAutomaton!.transitions.containsKey('$fromStateId|a'), false);
      expect(provider.error, null);
    });

    test('clearError should clear error state', () async {
      // First create an error
      await provider.loadAutomaton('invalid-id');
      expect(provider.error, isNotNull);

      // Then clear it
      provider.clearError();
      expect(provider.error, null);
    });

    test('clearValidationErrors should clear validation errors', () async {
      // First create validation errors
      await provider.createAutomaton(
        name: 'Test DFA',
        type: AutomatonType.dfa,
      );
      await provider.validateAutomaton();

      // Then clear them
      provider.clearValidationErrors();
      expect(provider.validationErrors, isEmpty);
    });
  });
}
