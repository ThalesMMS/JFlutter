import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/grammar.dart';
import '../../core/models/settings_model.dart';
import '../../data/services/active_session_persistence_service.dart';
import 'automaton_state_provider.dart';
import 'grammar_provider.dart';
import 'home_navigation_provider.dart';
import 'pda_editor_provider.dart';
import 'regex_editor_provider.dart';
import 'settings_provider.dart';
import 'tm_editor_provider.dart';
import 'unified_trace_provider.dart';

final activeSessionPersistenceServiceProvider =
    Provider<ActiveSessionPersistenceService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ActiveSessionPersistenceService(prefs);
});

final activeSessionPersistenceProvider =
    Provider<ActiveSessionPersistenceCoordinator>((ref) {
  final service = ref.watch(activeSessionPersistenceServiceProvider);
  final coordinator = ActiveSessionPersistenceCoordinator(ref, service);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

class ActiveSessionPersistenceCoordinator {
  ActiveSessionPersistenceCoordinator(this._ref, this._service) {
    _attachListeners();
    _restoreComplete = _restore();
  }

  final Ref _ref;
  final ActiveSessionPersistenceService _service;
  Timer? _saveDebounce;
  bool _isRestoring = false;
  bool _disposed = false;

  late final Future<void> _restoreComplete;

  Future<void> get restoreComplete => _restoreComplete;

  Future<void> flush() async {
    _saveDebounce?.cancel();
    _saveDebounce = null;
    await _saveNow();
  }

  void dispose() {
    _disposed = true;
    _saveDebounce?.cancel();
  }

  void _attachListeners() {
    _ref.listen<SettingsModel>(settingsProvider, _handleSettingsChanged);
    _ref.listen<int>(homeNavigationProvider, (_, __) => _scheduleSave());
    _ref.listen<AutomatonStateProviderState>(
      automatonStateProvider,
      (_, __) => _scheduleSave(),
    );
    _ref.listen<GrammarState>(
      grammarProvider,
      (_, __) => _scheduleSave(),
    );
    _ref.listen<PDAEditorState>(
      pdaEditorProvider,
      (_, __) => _scheduleSave(),
    );
    _ref.listen<TMEditorState>(
      tmEditorProvider,
      (_, __) => _scheduleSave(),
    );
    _ref.listen<RegexEditorState>(
      regexEditorProvider,
      (_, __) => _scheduleSave(),
    );
  }

  Future<void> _restore() async {
    if (!_service.autoSaveEnabled) {
      await _service.clearSession();
      return;
    }

    _isRestoring = true;
    try {
      final session = await _service.loadSession();
      if (_disposed || session == null) {
        return;
      }

      _applySession(session);
    } catch (error, stackTrace) {
      debugPrint('Failed to restore active editor session: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _isRestoring = false;
    }
  }

  void _applySession(ActiveSessionSnapshot session) {
    if (session.fsa != null) {
      _ref.read(automatonStateProvider.notifier).updateAutomaton(session.fsa!);
    }
    if (session.grammar != null) {
      _ref.read(grammarProvider.notifier).applyGrammar(session.grammar!);
    }
    if (session.pda != null) {
      _ref.read(pdaEditorProvider.notifier).setPda(session.pda!);
    }
    if (session.tm != null) {
      _ref.read(tmEditorProvider.notifier).setTm(session.tm!);
    }
    if (session.regex != null) {
      final regex = session.regex!;
      _ref.read(regexEditorProvider.notifier).restorePersistedInput(
            currentRegex: regex.currentRegex,
            testString: regex.testString,
            simplifyOutput: regex.simplifyOutput,
          );
    }

    _ref
        .read(homeNavigationProvider.notifier)
        .setIndex(session.activeWorkspaceIndex);
  }

  void _handleSettingsChanged(SettingsModel? previous, SettingsModel next) {
    if (_disposed) {
      return;
    }

    if (!next.autoSave) {
      _saveDebounce?.cancel();
      _saveDebounce = null;
      unawaited(_service.clearSession());
      return;
    }

    if (previous?.autoSave == false) {
      _scheduleSave();
    }
  }

  void _scheduleSave() {
    if (_disposed || _isRestoring) {
      return;
    }

    if (!_ref.read(settingsProvider).autoSave) {
      _saveDebounce?.cancel();
      _saveDebounce = null;
      unawaited(_service.clearSession());
      return;
    }

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_saveNow());
    });
  }

  Future<void> _saveNow() async {
    if (_disposed) {
      return;
    }

    if (!_ref.read(settingsProvider).autoSave) {
      await _service.clearSession();
      return;
    }

    try {
      await _service.saveSession(_buildSnapshot());
    } catch (error, stackTrace) {
      debugPrint('Failed to persist active editor session: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  ActiveSessionSnapshot _buildSnapshot() {
    final regexSnapshot = _buildRegexSnapshot(_ref.read(regexEditorProvider));

    return ActiveSessionSnapshot(
      activeWorkspaceIndex: _ref.read(homeNavigationProvider),
      savedAt: DateTime.now(),
      fsa: _ref.read(automatonStateProvider).currentAutomaton,
      grammar: _buildGrammarSnapshot(_ref.read(grammarProvider)),
      pda: _ref.read(pdaEditorProvider).pda,
      tm: _ref.read(tmEditorProvider).tm,
      regex: regexSnapshot?.hasContent == true ? regexSnapshot : null,
    );
  }

  Grammar? _buildGrammarSnapshot(GrammarState state) {
    final initial = GrammarState.initial();
    final hasGrammarContent = state.productions.isNotEmpty ||
        state.name != initial.name ||
        state.startSymbol != initial.startSymbol ||
        state.type != initial.type;

    if (!hasGrammarContent) {
      return null;
    }

    return _ref.read(grammarProvider.notifier).buildGrammar();
  }

  RegexSessionSnapshot? _buildRegexSnapshot(RegexEditorState state) {
    final snapshot = RegexSessionSnapshot(
      currentRegex: state.currentRegex,
      testString: state.testString,
      simplifyOutput: state.simplifyOutput,
    );

    return snapshot.hasContent ? snapshot : null;
  }
}
