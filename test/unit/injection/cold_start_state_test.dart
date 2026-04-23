import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/repositories/settings_repository.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/data/services/trace_persistence_service.dart';
import 'package:jflutter/injection/dependency_injection.dart';
import 'package:jflutter/presentation/providers/settings_provider.dart';
import 'package:jflutter/presentation/providers/unified_trace_provider.dart';

class _DelayedSettingsRepository implements SettingsRepository {
  _DelayedSettingsRepository(this._completer);

  final Completer<SettingsModel> _completer;

  @override
  Future<SettingsModel> loadSettings() => _completer.future;

  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

SimulationResult _trace(String input) {
  return SimulationResult.success(
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
    executionTime: const Duration(milliseconds: 10),
  );
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await getIt.reset();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('Cold start state', () {
    test('AutomatonService starts with an empty automata list', () {
      final service = AutomatonService();
      final result = service.listAutomata();

      expect(result.isSuccess, isTrue);
      expect(result.data, isEmpty);
    });

    test('SettingsNotifier exposes defaults before async load completes',
        () async {
      final completer = Completer<SettingsModel>();
      final notifier = SettingsNotifier(_DelayedSettingsRepository(completer));
      addTearDown(notifier.dispose);

      expect(notifier.state, equals(const SettingsModel()));

      completer.complete(
        const SettingsModel(themeMode: 'dark', showGrid: false),
      );
      await _flushAsyncWork();

      expect(notifier.state.themeMode, equals('dark'));
      expect(notifier.state.showGrid, isFalse);
    });

    test('UnifiedTraceNotifier loads persisted trace history on construction',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'trace_history': jsonEncode(<Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'trace-1',
            'timestamp': DateTime(2026, 4, 22).toIso8601String(),
            'automatonType': 'dfa',
            'automatonId': 'dfa-1',
            'trace': _trace('abba').toJson(),
          },
        ]),
      });
      final prefs = await SharedPreferences.getInstance();
      final notifier = UnifiedTraceNotifier(TracePersistenceService(prefs));
      addTearDown(notifier.dispose);

      await _flushAsyncWork();

      expect(notifier.state.traceHistory, hasLength(1));
      expect(notifier.state.traceHistory.single['id'], equals('trace-1'));
    });

    test('examples remain lazy and are not pre-loaded during startup',
        () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final assetRequests = <String>[];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', (ByteData? message) async {
        if (message != null) {
          assetRequests.add(utf8.decode(message.buffer.asUint8List()));
        }
        return ByteData.sublistView(Uint8List(0));
      });

      await setupDependencyInjection();

      expect(assetRequests, isEmpty);
    });
  });
}
