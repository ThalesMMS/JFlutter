// Integration test for finite automata language operations
// This test MUST fail initially - it defines the expected integration behavior

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('Finite Automata Language Operations Integration Tests', () {
    late AutomatonApi api;
    late String automatonA;
    late String automatonB;

    setUp(() async {
      api = AutomatonApi();
      
      // Create automaton A: accepts strings ending with 'a'
      final createResponseA = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Automaton A',
          type: AutomatonType.DFA,
          description: 'Accepts strings ending with a',
        ),
      );
      automatonA = createResponseA.data.id;
      
      await api.updateAutomaton(automatonA, UpdateAutomatonRequest(
        states: [
          State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0), isAccepting: true),
        ],
        transitions: [
          Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
          Transition(id: 't2', fromState: 'q1', toState: 'q1', symbol: 'b'),
        ],
      ));

      // Create automaton B: accepts strings ending with 'b'
      final createResponseB = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Automaton B',
          type: AutomatonType.DFA,
          description: 'Accepts strings ending with b',
        ),
      );
      automatonB = createResponseB.data.id;
      
      await api.updateAutomaton(automatonB, UpdateAutomatonRequest(
        states: [
          State(id: 'p0', name: 'p0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'p1', name: 'p1', position: Position(x: 100, y: 0), isAccepting: true),
        ],
        transitions: [
          Transition(id: 't3', fromState: 'p0', toState: 'p1', symbol: 'b'),
          Transition(id: 't4', fromState: 'p1', toState: 'p1', symbol: 'a'),
        ],
      ));
    });

    test('should perform union operation correctly', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.UNION,
        inputAutomata: [automatonA, automatonB],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Test the resulting automaton
      final resultAutomaton = await api.getAutomaton(response.data.outputAutomaton);
      expect(resultAutomaton.statusCode, 200);
      
      // Verify it accepts strings from both languages
      final simulateA = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'a'),
      );
      expect(simulateA.data.isAccepting, true);
      
      final simulateB = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'b'),
      );
      expect(simulateB.data.isAccepting, true);
    });

    test('should perform intersection operation correctly', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.INTERSECTION,
        inputAutomata: [automatonA, automatonB],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Test the resulting automaton (should accept empty language)
      final resultAutomaton = await api.getAutomaton(response.data.outputAutomaton);
      expect(resultAutomaton.statusCode, 200);
      
      // Verify it doesn't accept strings from either language
      final simulateA = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'a'),
      );
      expect(simulateA.data.isAccepting, false);
      
      final simulateB = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'b'),
      );
      expect(simulateB.data.isAccepting, false);
    });

    test('should perform complement operation correctly', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.COMPLEMENT,
        inputAutomata: [automatonA],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Test the resulting automaton
      final resultAutomaton = await api.getAutomaton(response.data.outputAutomaton);
      expect(resultAutomaton.statusCode, 200);
      
      // Verify it accepts strings not in the original language
      final simulateA = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'a'),
      );
      expect(simulateA.data.isAccepting, false); // 'a' was in original language
      
      final simulateB = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'b'),
      );
      expect(simulateB.data.isAccepting, true); // 'b' was not in original language
    });

    test('should perform concatenation operation correctly', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.CONCATENATION,
        inputAutomata: [automatonA, automatonB],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Test the resulting automaton
      final resultAutomaton = await api.getAutomaton(response.data.outputAutomaton);
      expect(resultAutomaton.statusCode, 200);
      
      // Verify it accepts concatenated strings
      final simulate = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'ab'), // 'a' from A, 'b' from B
      );
      expect(simulate.data.isAccepting, true);
    });

    test('should perform Kleene star operation correctly', () async {
      final request = LanguageOperationRequest(
        operation: LanguageOperation.KLEENE_STAR,
        inputAutomata: [automatonA],
      );

      final response = await api.performLanguageOperation(request);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Test the resulting automaton
      final resultAutomaton = await api.getAutomaton(response.data.outputAutomaton);
      expect(resultAutomaton.statusCode, 200);
      
      // Verify it accepts zero or more repetitions
      final simulateEmpty = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: ''),
      );
      expect(simulateEmpty.data.isAccepting, true);
      
      final simulateSingle = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'a'),
      );
      expect(simulateSingle.data.isAccepting, true);
      
      final simulateMultiple = await api.simulateAutomaton(
        response.data.outputAutomaton,
        SimulationRequest(inputString: 'aa'),
      );
      expect(simulateMultiple.data.isAccepting, true);
    });
  });
}
