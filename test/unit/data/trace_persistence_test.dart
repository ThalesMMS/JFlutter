import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/data/services/trace_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SimulationResult traceFixture({
    required String input,
    bool accepted = true,
  }) {
    return accepted
        ? SimulationResult.success(
            inputString: input,
            steps: <SimulationStep>[
              SimulationStep(
                currentState: 'q0',
                remainingInput: input,
                stepNumber: 0,
              ),
              const SimulationStep(
                currentState: 'q1',
                remainingInput: '',
                stepNumber: 1,
                isAccepted: true,
              ),
            ],
            executionTime: const Duration(milliseconds: 12),
          )
        : SimulationResult.failure(
            inputString: input,
            steps: <SimulationStep>[
              SimulationStep(
                currentState: 'q0',
                remainingInput: input,
                stepNumber: 0,
              ),
            ],
            errorMessage: 'rejected',
            executionTime: const Duration(milliseconds: 12),
          );
  }

  group('Trace persistence', () {
    late SharedPreferences prefs;
    late TracePersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      prefs = await SharedPreferences.getInstance();
      service = TracePersistenceService(prefs);
    });

    test('saveTraceToHistory and getTraceHistory round-trip', () async {
      final trace = traceFixture(input: 'abba');

      await service.saveTraceToHistory(
        trace,
        automatonType: 'dfa',
        automatonId: 'automaton-1',
      );

      final history = await service.getTraceHistory();

      expect(history, hasLength(1));
      expect(history.single['automatonType'], equals('dfa'));
      expect(history.single['automatonId'], equals('automaton-1'));
      expect(
        (history.single['trace'] as Map<String, dynamic>)['inputString'],
        equals('abba'),
      );
    });

    test('evicts the oldest trace when the 51st trace is saved', () async {
      for (var i = 0; i < 51; i++) {
        await service.saveTraceToHistory(
          traceFixture(input: 'input-$i'),
          automatonType: 'dfa',
        );
      }

      final history = await service.getTraceHistory();
      final inputs = history
          .map((entry) =>
              (entry['trace'] as Map<String, dynamic>)['inputString'])
          .toList();

      expect(history, hasLength(50));
      expect(inputs, isNot(contains('input-0')));
      expect(inputs.first, equals('input-50'));
      expect(inputs.last, equals('input-1'));
    });

    test('persists current_trace and step position across a simulated restart',
        () async {
      await service.saveCurrentTrace(traceFixture(input: 'restart'), 1);

      final restartedService = TracePersistenceService(prefs);
      final restored = await restartedService.getCurrentTrace();

      expect(restored, isNotNull);
      expect(restored!['currentStepIndex'], equals(1));
      expect(
        (restored['trace'] as Map<String, dynamic>)['inputString'],
        equals('restart'),
      );
    });

    test('stores and retrieves trace metadata', () async {
      await service.saveTraceMetadata(
        traceId: 'trace-1',
        automatonType: 'tm',
        automatonId: 'tm-1',
        inputString: '101',
        accepted: true,
        stepCount: 7,
        executionTime: const Duration(milliseconds: 25),
      );

      final metadata = await service.getTraceMetadata();

      expect(metadata.keys, contains('trace-1'));
      expect(metadata['trace-1']!['automatonType'], equals('tm'));
      expect(metadata['trace-1']!['automatonId'], equals('tm-1'));
      expect(metadata['trace-1']!['stepCount'], equals(7));
      expect(metadata['trace-1']!['executionTime'], equals(25));
    });

    test('returns an empty history for malformed trace_history JSON', () async {
      await prefs.setString('trace_history', '{"not":"a-list"}');

      final history = await service.getTraceHistory();

      expect(history, isEmpty);
    });

    test('skips history entries whose nested trace payload is not a map',
        () async {
      await prefs.setString(
        'trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'valid-trace',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': traceFixture(input: 'abba').toJson(),
          },
          <String, dynamic>{
            'id': 'invalid-trace',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'trace': 'not-a-map',
          },
        ]),
      );

      final history = await service.getTraceHistory();
      final statistics = await service.getTraceStatistics();

      expect(history, hasLength(1));
      expect(history.single['id'], equals('valid-trace'));
      expect(statistics['totalTraces'], equals(1));
    });

    test('normalizes malformed automaton types to unknown in statistics',
        () async {
      await prefs.setString(
        'trace_history',
        jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'trace-1',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 42,
            'trace': traceFixture(input: 'abba').toJson(),
          },
        ]),
      );

      final history = await service.getTraceHistory();
      final statistics = await service.getTraceStatistics();

      expect(history.single['automatonType'], equals('unknown'));
      expect(
        statistics['typeCounts'],
        equals(<String, int>{'unknown': 1}),
      );
    });

    test('returns null for corrupted current_trace data', () async {
      await prefs.setString('current_trace', '["broken"]');

      final currentTrace = await service.getCurrentTrace();

      expect(currentTrace, isNull);
    });

    test('returns null for object-shaped current_trace with invalid trace',
        () async {
      await prefs.setString(
        'current_trace',
        '{"trace":"broken","currentStepIndex":0}',
      );

      final currentTrace = await service.getCurrentTrace();

      expect(currentTrace, isNull);
    });

    test('tolerates metadata that references non-existent traces', () async {
      await prefs.setString(
        'trace_metadata',
        jsonEncode(<String, Object>{
          'orphan-trace': <String, Object>{
            'traceId': 'orphan-trace',
            'automatonType': 'pda',
          },
        }),
      );

      final metadata = await service.getTraceMetadata();
      final trace = await service.getTraceById('orphan-trace');

      expect(metadata.keys, contains('orphan-trace'));
      expect(metadata['orphan-trace']!['automatonType'], equals('pda'));
      expect(trace, isNull);
    });

    test('does not throw when malformed persistence payloads are read',
        () async {
      await prefs.setString('trace_history', 'not-json');
      await prefs.setString('current_trace', 'not-json');

      await expectLater(service.getTraceHistory(), completion(isEmpty));
      await expectLater(service.getCurrentTrace(), completion(isNull));
    });
  });
}
