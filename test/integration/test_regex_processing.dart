// Integration test for regex processing pipeline
// This test MUST fail initially - it defines the expected integration behavior

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('Regex Processing Pipeline Integration Tests', () {
    late AutomatonApi api;
    late String regexId;

    setUp(() async {
      api = AutomatonApi();
      
      // Create regex: (a|b)*abb
      final createResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Test Regex',
          type: AutomatonType.REGEX,
          description: 'Regex pattern (a|b)*abb',
        ),
      );
      regexId = createResponse.data.id;
      
      await api.updateAutomaton(regexId, UpdateAutomatonRequest(
        // Regex-specific fields would be set here
        // This depends on the actual regex model structure
      ));
    });

    test('should parse regex pattern correctly', () async {
      // Test regex pattern parsing
      final algorithmRequest = AlgorithmRequest(
        algorithmType: AlgorithmType.REGEX_TO_NFA,
        parameters: {'pattern': '(a|b)*abb'},
      );

      final response = await api.runAlgorithm(regexId, algorithmRequest);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      expect(response.data.outputAutomaton, isNotEmpty);
    });

    test('should convert regex to NFA using Thompson construction', () async {
      final algorithmRequest = AlgorithmRequest(
        algorithmType: AlgorithmType.REGEX_TO_NFA,
        parameters: {'pattern': 'a*b+'},
      );

      final response = await api.runAlgorithm(regexId, algorithmRequest);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Verify the resulting NFA
      final nfaResponse = await api.getAutomaton(response.data.outputAutomaton);
      expect(nfaResponse.statusCode, 200);
      expect(nfaResponse.data.type, AutomatonType.NFA);
      
      // Test simulation with matching strings
      final matchingStrings = ['abb', 'aabb', 'babb', 'aaabb'];
      
      for (final testString in matchingStrings) {
        final simulateResponse = await api.simulateAutomaton(
          response.data.outputAutomaton,
          SimulationRequest(inputString: testString),
        );
        
        expect(simulateResponse.statusCode, 200);
        expect(simulateResponse.data.isAccepting, true, 
               reason: 'String "$testString" should match pattern "a*b+"');
      }
    });

    test('should convert FA to regex correctly', () async {
      // First create a simple FA
      final faResponse = await api.createAutomaton(
        CreateAutomatonRequest(
          name: 'Simple FA',
          type: AutomatonType.DFA,
        ),
      );
      
      await api.updateAutomaton(faResponse.data.id, UpdateAutomatonRequest(
        states: [
          State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
          State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0), isAccepting: true),
        ],
        transitions: [
          Transition(id: 't1', fromState: 'q0', toState: 'q1', symbol: 'a'),
          Transition(id: 't2', fromState: 'q1', toState: 'q1', symbol: 'b'),
        ],
      ));

      // Convert FA to regex
      final algorithmRequest = AlgorithmRequest(
        algorithmType: AlgorithmType.FA_TO_REGEX,
      );

      final response = await api.runAlgorithm(faResponse.data.id, algorithmRequest);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      expect(response.data.outputAutomaton, isNotEmpty);
      
      // Verify the resulting regex
      final regexResponse = await api.getAutomaton(response.data.outputAutomaton);
      expect(regexResponse.statusCode, 200);
      expect(regexResponse.data.type, AutomatonType.REGEX);
    });

    test('should handle complex regex patterns', () async {
      final complexPatterns = [
        'a*',
        'a+b*',
        '(a|b)*',
        'a(b|c)*d',
        '(a|b)(c|d)*',
      ];
      
      for (final pattern in complexPatterns) {
        final algorithmRequest = AlgorithmRequest(
          algorithmType: AlgorithmType.REGEX_TO_NFA,
          parameters: {'pattern': pattern},
        );

        final response = await api.runAlgorithm(regexId, algorithmRequest);
        
        expect(response.statusCode, 200);
        expect(response.data.result, AlgorithmResultType.SUCCESS, 
               reason: 'Pattern "$pattern" should be valid');
      }
    });

    test('should reject invalid regex patterns', () async {
      final invalidPatterns = [
        'a**', // Double Kleene star
        '(a', // Unmatched parenthesis
        'a|', // Incomplete union
        '*a', // Invalid Kleene star position
      ];
      
      for (final pattern in invalidPatterns) {
        final algorithmRequest = AlgorithmRequest(
          algorithmType: AlgorithmType.REGEX_TO_NFA,
          parameters: {'pattern': pattern},
        );

        final response = await api.runAlgorithm(regexId, algorithmRequest);
        
        expect(response.statusCode, 200);
        expect(response.data.result, AlgorithmResultType.FAILURE, 
               reason: 'Pattern "$pattern" should be invalid');
      }
    });

    test('should provide regex AST representation', () async {
      final algorithmRequest = AlgorithmRequest(
        algorithmType: AlgorithmType.REGEX_TO_NFA,
        parameters: {'pattern': '(a|b)*abb', 'includeAST': true},
      );

      final response = await api.runAlgorithm(regexId, algorithmRequest);
      
      expect(response.statusCode, 200);
      expect(response.data.result, AlgorithmResultType.SUCCESS);
      
      // Verify AST is included in the result
      expect(response.data.metadata, isNotEmpty);
      // AST details would be in metadata
    });

    test('should handle regex with different operators', () async {
      final operatorTests = [
        {'pattern': 'a|b', 'testStrings': ['a', 'b'], 'nonMatching': ['c', 'ab']},
        {'pattern': 'ab', 'testStrings': ['ab'], 'nonMatching': ['a', 'b', 'ba']},
        {'pattern': 'a*', 'testStrings': ['', 'a', 'aa', 'aaa'], 'nonMatching': ['b', 'ab']},
        {'pattern': 'a+b', 'testStrings': ['ab', 'aab', 'aaab'], 'nonMatching': ['b', 'a', 'ba']},
      ];
      
      for (final test in operatorTests) {
        final pattern = test['pattern'] as String;
        final matchingStrings = test['testStrings'] as List<String>;
        final nonMatchingStrings = test['nonMatching'] as List<String>;
        
        final algorithmRequest = AlgorithmRequest(
          algorithmType: AlgorithmType.REGEX_TO_NFA,
          parameters: {'pattern': pattern},
        );

        final response = await api.runAlgorithm(regexId, algorithmRequest);
        
        expect(response.statusCode, 200);
        expect(response.data.result, AlgorithmResultType.SUCCESS);
        
        // Test matching strings
        for (final testString in matchingStrings) {
          final simulateResponse = await api.simulateAutomaton(
            response.data.outputAutomaton,
            SimulationRequest(inputString: testString),
          );
          
          expect(simulateResponse.data.isAccepting, true, 
                 reason: 'String "$testString" should match pattern "$pattern"');
        }
        
        // Test non-matching strings
        for (final testString in nonMatchingStrings) {
          final simulateResponse = await api.simulateAutomaton(
            response.data.outputAutomaton,
            SimulationRequest(inputString: testString),
          );
          
          expect(simulateResponse.data.isAccepting, false, 
                 reason: 'String "$testString" should not match pattern "$pattern"');
        }
      }
    });
  });
}
