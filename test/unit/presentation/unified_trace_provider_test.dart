import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/data/services/trace_persistence_service.dart';
import 'package:jflutter/presentation/providers/unified_trace_provider.dart';

SimulationResult _trace({String input = 'abba'}) {
  return SimulationResult.success(
    inputString: input,
    steps: const <SimulationStep>[
      SimulationStep(currentState: 'q0', remainingInput: 'abba', stepNumber: 0),
      SimulationStep(currentState: 'q1', remainingInput: 'bba', stepNumber: 1),
      SimulationStep(
        currentState: 'q2',
        remainingInput: '',
        stepNumber: 2,
        isAccepted: true,
      ),
    ],
    executionTime: const Duration(milliseconds: 8),
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnifiedTraceNotifier restoration', () {
    late SharedPreferences prefs;
    late TracePersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const {});
      prefs = await SharedPreferences.getInstance();
      service = TracePersistenceService(prefs);
    });

    test('restores persisted current trace and step index on startup',
        () async {
      final trace = _trace();
      await service.saveCurrentTrace(trace, 2);

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await _flushAsyncWork();

      expect(notifier.state.currentTrace, isNotNull);
      expect(
          notifier.state.currentTrace!.inputString, equals(trace.inputString));
      expect(notifier.state.currentTrace!.stepCount, equals(trace.stepCount));
      expect(notifier.state.currentStepIndex, equals(2));
      expect(notifier.state.traceStatistics['totalTraces'], equals(0));
    });

    test('setTrace persists current trace immediately for relaunch recovery',
        () async {
      final trace = _trace(input: 'aa');
      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await notifier.setTrace(trace);
      await _flushAsyncWork();

      final restored = await service.getCurrentTrace();
      expect(restored, isNotNull);
      expect(restored!['currentStepIndex'], equals(0));
      expect(
        (restored['trace'] as Map<String, dynamic>)['inputString'],
        equals('aa'),
      );
      expect(notifier.state.traceHistory, hasLength(1));
    });

    test('snapshot getters return immutable copies', () async {
      final trace = _trace(input: 'immutability');
      await service.saveTraceToHistory(
        trace,
        automatonType: 'dfa',
        automatonId: 'dfa-1',
      );

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      notifier.setAutomatonContext(automatonType: 'dfa', automatonId: 'dfa-1');
      await _flushAsyncWork();

      final statistics = notifier.traceStatisticsSnapshot;
      final automatonTraces = notifier.currentAutomatonTracesSnapshot;
      final typeTraces = notifier.currentTypeTracesSnapshot;

      expect(() => statistics['totalTraces'] = 99, throwsUnsupportedError);
      expect(
        () => (statistics['typeCounts'] as Map<String, dynamic>)['dfa'] = 99,
        throwsUnsupportedError,
      );
      expect(
        () => automatonTraces.add(<String, dynamic>{}),
        throwsUnsupportedError,
      );
      expect(
        () => (automatonTraces.single['trace']
            as Map<String, dynamic>)['inputString'] = 'mutated',
        throwsUnsupportedError,
      );
      expect(() => typeTraces.clear(), throwsUnsupportedError);
    });

    test('clears malformed persisted current traces instead of crashing',
        () async {
      await prefs.setString('current_trace', '{"trace":"broken"}');

      final notifier = UnifiedTraceNotifier(service);
      addTearDown(notifier.dispose);

      await _flushAsyncWork();

      expect(notifier.state.currentTrace, isNull);
      expect(await service.getCurrentTrace(), isNull);
    });
  });
}
