// Contract tests for JFlutter Automaton API
// These tests must fail initially - they define the expected API contracts

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter_core/api/automaton_api.dart';
import 'package:jflutter_core/models/automaton.dart';

void main() {
  group('Automaton API Contract Tests', () {
    late AutomatonApi api;

    setUp(() {
      api = AutomatonApi();
    });

    group('GET /automata', () {
      test('should return list of automaton summaries', () async {
        // This test will fail until the endpoint is implemented
        final response = await api.listAutomata();
        
        expect(response.statusCode, 200);
        expect(response.data, isA<List<AutomatonSummary>>());
        expect(response.data.isNotEmpty, true);
      });

      test('should return empty list when no automata exist', () async {
        // Clear all automata first
        await api.clearAllAutomata();
        
        final response = await api.listAutomata();
        
        expect(response.statusCode, 200);
        expect(response.data, isEmpty);
      });
    });

    group('POST /automata', () {
      test('should create finite automaton successfully', () async {
        final request = CreateAutomatonRequest(
          name: 'Test FA',
          type: AutomatonType.DFA,
          description: 'Test finite automaton',
        );

        final response = await api.createAutomaton(request);
        
        expect(response.statusCode, 201);
        expect(response.data, isA<Automaton>());
        expect(response.data.name, 'Test FA');
        expect(response.data.type, AutomatonType.DFA);
        expect(response.data.id, isNotEmpty);
      });

      test('should create pushdown automaton successfully', () async {
        final request = CreateAutomatonRequest(
          name: 'Test PDA',
          type: AutomatonType.PDA,
          description: 'Test pushdown automaton',
        );

        final response = await api.createAutomaton(request);
        
        expect(response.statusCode, 201);
        expect(response.data, isA<Automaton>());
        expect(response.data.type, AutomatonType.PDA);
      });

      test('should create Turing machine successfully', () async {
        final request = CreateAutomatonRequest(
          name: 'Test TM',
          type: AutomatonType.TM,
          description: 'Test Turing machine',
        );

        final response = await api.createAutomaton(request);
        
        expect(response.statusCode, 201);
        expect(response.data, isA<Automaton>());
        expect(response.data.type, AutomatonType.TM);
      });

      test('should return 400 for invalid request', () async {
        final request = CreateAutomatonRequest(
          name: '', // Invalid empty name
          type: AutomatonType.DFA,
        );

        final response = await api.createAutomaton(request);
        
        expect(response.statusCode, 400);
        expect(response.error, isA<ErrorResponse>());
      });
    });

    group('GET /automata/{id}', () {
      late String automatonId;

      setUp(() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Test FA',
            type: AutomatonType.DFA,
          ),
        );
        automatonId = createResponse.data.id;
      });

      test('should return automaton by ID', () async {
        final response = await api.getAutomaton(automatonId);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<Automaton>());
        expect(response.data.id, automatonId);
      });

      test('should return 404 for non-existent automaton', () async {
        final response = await api.getAutomaton('non-existent-id');
        
        expect(response.statusCode, 404);
        expect(response.error, isA<ErrorResponse>());
      });
    });

    group('PUT /automata/{id}', () {
      late String automatonId;

      setUp(() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Test FA',
            type: AutomatonType.DFA,
          ),
        );
        automatonId = createResponse.data.id;
      });

      test('should update automaton successfully', () async {
        final updateRequest = UpdateAutomatonRequest(
          name: 'Updated FA',
          description: 'Updated description',
        );

        final response = await api.updateAutomaton(automatonId, updateRequest);
        
        expect(response.statusCode, 200);
        expect(response.data.name, 'Updated FA');
        expect(response.data.description, 'Updated description');
      });

      test('should return 404 for non-existent automaton', () async {
        final updateRequest = UpdateAutomatonRequest(name: 'Updated');
        
        final response = await api.updateAutomaton('non-existent-id', updateRequest);
        
        expect(response.statusCode, 404);
      });
    });

    group('DELETE /automata/{id}', () {
      late String automatonId;

      setUp() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Test FA',
            type: AutomatonType.DFA,
          ),
        );
        automatonId = createResponse.data.id;
      }

      test('should delete automaton successfully', () async {
        final response = await api.deleteAutomaton(automatonId);
        
        expect(response.statusCode, 204);
        
        // Verify automaton is deleted
        final getResponse = await api.getAutomaton(automatonId);
        expect(getResponse.statusCode, 404);
      });

      test('should return 404 for non-existent automaton', () async {
        final response = await api.deleteAutomaton('non-existent-id');
        
        expect(response.statusCode, 404);
      });
    });

    group('POST /automata/{id}/simulate', () {
      late String automatonId;

      setUp() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Test FA',
            type: AutomatonType.DFA,
          ),
        );
        automatonId = createResponse.data.id;
        
        // Add states and transitions for a simple FA
        await api.updateAutomaton(automatonId, UpdateAutomatonRequest(
          states: [
            State(id: 'q0', name: 'q0', position: Position(x: 0, y: 0), isInitial: true),
            State(id: 'q1', name: 'q1', position: Position(x: 100, y: 0), isAccepting: true),
          ],
          transitions: [
            Transition(
              id: 't1',
              fromState: 'q0',
              toState: 'q1',
              symbol: 'a',
            ),
          ],
        ));
      }

      test('should simulate automaton with accepting string', () async {
        final request = SimulationRequest(
          inputString: 'a',
          maxSteps: 100,
        );

        final response = await api.simulateAutomaton(automatonId, request);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<SimulationResult>());
        expect(response.data.isAccepting, true);
        expect(response.data.traceId, isNotEmpty);
      });

      test('should simulate automaton with rejecting string', () async {
        final request = SimulationRequest(
          inputString: 'b',
          maxSteps: 100,
        );

        final response = await api.simulateAutomaton(automatonId, request);
        
        expect(response.statusCode, 200);
        expect(response.data.isAccepting, false);
      });

      test('should return 400 for invalid simulation request', () async {
        final request = SimulationRequest(
          inputString: 'a',
          maxSteps: -1, // Invalid max steps
        );

        final response = await api.simulateAutomaton(automatonId, request);
        
        expect(response.statusCode, 400);
      });
    });

    group('POST /automata/{id}/algorithms', () {
      late String automatonId;

      setUp() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Test NFA',
            type: AutomatonType.NFA,
          ),
        );
        automatonId = createResponse.data.id;
      }

      test('should run NFA to DFA conversion', () async {
        final request = AlgorithmRequest(
          algorithmType: AlgorithmType.NFA_TO_DFA,
        );

        final response = await api.runAlgorithm(automatonId, request);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<AlgorithmResult>());
        expect(response.data.algorithmType, AlgorithmType.NFA_TO_DFA);
        expect(response.data.result, AlgorithmResultType.SUCCESS);
        expect(response.data.outputAutomaton, isNotEmpty);
      });

      test('should run DFA minimization', () async {
        final request = AlgorithmRequest(
          algorithmType: AlgorithmType.MINIMIZE_DFA,
        );

        final response = await api.runAlgorithm(automatonId, request);
        
        expect(response.statusCode, 200);
        expect(response.data.algorithmType, AlgorithmType.MINIMIZE_DFA);
        expect(response.data.result, AlgorithmResultType.SUCCESS);
      });

      test('should return 400 for invalid algorithm request', () async {
        final request = AlgorithmRequest(
          algorithmType: null, // Invalid algorithm type
        );

        final response = await api.runAlgorithm(automatonId, request);
        
        expect(response.statusCode, 400);
      });
    });

    group('POST /automata/operations', () {
      late String automatonId1;
      late String automatonId2;

      setUp() async {
        final createResponse1 = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'FA1',
            type: AutomatonType.DFA,
          ),
        );
        automatonId1 = createResponse1.data.id;

        final createResponse2 = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'FA2',
            type: AutomatonType.DFA,
          ),
        );
        automatonId2 = createResponse2.data.id;
      }

      test('should perform union operation', () async {
        final request = LanguageOperationRequest(
          operation: LanguageOperation.UNION,
          inputAutomata: [automatonId1, automatonId2],
        );

        final response = await api.performLanguageOperation(request);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<LanguageOperationResult>());
        expect(response.data.operation, LanguageOperation.UNION);
        expect(response.data.result, AlgorithmResultType.SUCCESS);
        expect(response.data.outputAutomaton, isNotEmpty);
      });

      test('should perform intersection operation', () async {
        final request = LanguageOperationRequest(
          operation: LanguageOperation.INTERSECTION,
          inputAutomata: [automatonId1, automatonId2],
        );

        final response = await api.performLanguageOperation(request);
        
        expect(response.statusCode, 200);
        expect(response.data.operation, LanguageOperation.INTERSECTION);
        expect(response.data.result, AlgorithmResultType.SUCCESS);
      });

      test('should return 400 for invalid operation request', () async {
        final request = LanguageOperationRequest(
          operation: LanguageOperation.UNION,
          inputAutomata: [], // Invalid empty list
        );

        final response = await api.performLanguageOperation(request);
        
        expect(response.statusCode, 400);
      });
    });

    group('POST /import/jff', () {
      test('should import JFLAP file successfully', () async {
        // This test will fail until file import is implemented
        final file = MockJFLAPFile('sample.jff', validJFLAPContent);
        
        final response = await api.importJFLAPFile(file);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<ImportResult>());
        expect(response.data.status, ImportStatus.SUCCESS);
        expect(response.data.automatonId, isNotEmpty);
      });

      test('should return 400 for invalid file format', () async {
        final file = MockJFLAPFile('invalid.jff', invalidContent);
        
        final response = await api.importJFLAPFile(file);
        
        expect(response.statusCode, 400);
        expect(response.error, isA<ErrorResponse>());
      });

      test('should return 422 for file validation failure', () async {
        final file = MockJFLAPFile('malformed.jff', malformedJFLAPContent);
        
        final response = await api.importJFLAPFile(file);
        
        expect(response.statusCode, 422);
        expect(response.data.status, ImportStatus.FAILURE);
        expect(response.data.errors, isNotEmpty);
      });
    });

    group('GET /export/{id}/jff', () {
      late String automatonId;

      setUp() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Export Test FA',
            type: AutomatonType.DFA,
          ),
        );
        automatonId = createResponse.data.id;
      }

      test('should export automaton to JFLAP format', () async {
        final response = await api.exportToJFLAP(automatonId);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<String>()); // JFLAP file content
        expect(response.data.isNotEmpty, true);
      });

      test('should return 404 for non-existent automaton', () async {
        final response = await api.exportToJFLAP('non-existent-id');
        
        expect(response.statusCode, 404);
      });
    });

    group('GET /export/{id}/json', () {
      late String automatonId;

      setUp() async {
        final createResponse = await api.createAutomaton(
          CreateAutomatonRequest(
            name: 'Export Test FA',
            type: AutomatonType.DFA,
          ),
        );
        automatonId = createResponse.data.id;
      }

      test('should export automaton to JSON format', () async {
        final response = await api.exportToJSON(automatonId);
        
        expect(response.statusCode, 200);
        expect(response.data, isA<Automaton>());
        expect(response.data.id, automatonId);
      });

      test('should return 404 for non-existent automaton', () async {
        final response = await api.exportToJSON('non-existent-id');
        
        expect(response.statusCode, 404);
      });
    });
  });
}

// Mock classes for testing
class MockJFLAPFile {
  final String filename;
  final String content;

  MockJFLAPFile(this.filename, this.content);
}

const String validJFLAPContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>0</x>
      <y>0</y>
      <initial/>
    </state>
    <state id="1" name="q1">
      <x>100</x>
      <y>0</y>
      <final/>
    </state>
    <transition>
      <from>0</from>
      <to>1</to>
      <read>a</read>
    </transition>
  </automaton>
</structure>
''';

const String invalidContent = 'This is not a valid JFLAP file';

const String malformedJFLAPContent = '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>fa</type>
  <automaton>
    <!-- Missing required elements -->
  </automaton>
</structure>
''';
