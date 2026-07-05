import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/grammar.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/data/services/active_session_persistence_service.dart';
import 'package:jflutter/presentation/providers/active_session_provider.dart';
import 'package:jflutter/presentation/providers/automaton_state_provider.dart';
import 'package:jflutter/presentation/providers/grammar_provider.dart';
import 'package:jflutter/presentation/providers/home_navigation_provider.dart';
import 'package:jflutter/presentation/providers/regex_editor_provider.dart';
import 'package:jflutter/presentation/providers/settings_provider.dart';
import 'package:jflutter/presentation/providers/unified_trace_provider.dart';

void main() {
  group('activeSessionPersistenceProvider', () {
    test('restores persisted workspace state when autosave is enabled',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: HomeNavigationNotifier.regexIndex,
          savedAt: DateTime.utc(2026),
          fsa: _fsa(),
          grammar: _grammar(),
          regex: const RegexSessionSnapshot(
            currentRegex: 'ab*',
            testString: 'abb',
            simplifyOutput: false,
          ),
        ),
      );

      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final coordinator = container.read(activeSessionPersistenceProvider);
      await coordinator.restoreComplete;

      expect(
        container.read(automatonStateProvider).currentAutomaton?.id,
        'fsa-1',
      );
      expect(container.read(grammarProvider).productions.single.id, 'p1');
      expect(container.read(regexEditorProvider).currentRegex, 'ab*');
      expect(container.read(regexEditorProvider).testString, 'abb');
      expect(container.read(regexEditorProvider).simplifyOutput, isFalse);
      expect(
        container.read(homeNavigationProvider),
        HomeNavigationNotifier.regexIndex,
      );
    });

    test('does not restore persisted workspace state when autosave is disabled',
        () async {
      SharedPreferences.setMockInitialValues({
        ActiveSessionPersistenceService.autoSaveKey: false,
      });
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: HomeNavigationNotifier.regexIndex,
          savedAt: DateTime.utc(2026),
          fsa: _fsa(),
        ),
      );

      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final coordinator = container.read(activeSessionPersistenceProvider);
      await coordinator.restoreComplete;

      expect(container.read(automatonStateProvider).currentAutomaton, isNull);
      expect(
        container.read(homeNavigationProvider),
        HomeNavigationNotifier.fsaIndex,
      );
      expect(await service.loadSession(), isNull);
    });

    test('flush persists the current editor state when autosave is enabled',
        () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final coordinator = container.read(activeSessionPersistenceProvider);
      await coordinator.restoreComplete;

      container.read(automatonStateProvider.notifier).updateAutomaton(_fsa());
      container.read(homeNavigationProvider.notifier).setIndex(
            HomeNavigationNotifier.fsaIndex,
          );

      await coordinator.flush();

      final restored = await service.loadSession();
      expect(restored?.fsa?.id, 'fsa-1');
      expect(
        restored?.activeWorkspaceIndex,
        HomeNavigationNotifier.fsaIndex,
      );
    });

    test('flush clears persisted state when autosave is disabled', () async {
      SharedPreferences.setMockInitialValues(const {});
      final prefs = await SharedPreferences.getInstance();
      final service = ActiveSessionPersistenceService(prefs);
      await service.saveSession(
        ActiveSessionSnapshot(
          activeWorkspaceIndex: HomeNavigationNotifier.fsaIndex,
          savedAt: DateTime.utc(2026),
          fsa: _fsa(),
        ),
      );
      final container = _containerWithPrefs(prefs);
      addTearDown(container.dispose);

      final coordinator = container.read(activeSessionPersistenceProvider);
      await coordinator.restoreComplete;
      await container.read(settingsProvider.notifier).refreshFromModel(
            const SettingsModel(autoSave: false),
          );

      await coordinator.flush();

      expect(await service.loadSession(), isNull);
    });
  });
}

ProviderContainer _containerWithPrefs(SharedPreferences prefs) {
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
}

FSA _fsa() {
  final state = _state('q0', isInitial: true, isAccepting: true);
  return FSA(
    id: 'fsa-1',
    name: 'Saved FSA',
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

Grammar _grammar() {
  return Grammar(
    id: 'grammar-1',
    name: 'Saved Grammar',
    terminals: const {'a'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: const {
      Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.regular,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
  );
}

automaton_state.State _state(
  String id, {
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2.zero(),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}
