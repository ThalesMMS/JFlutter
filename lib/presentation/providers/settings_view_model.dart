import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/settings_model.dart';
import '../../core/repositories/settings_repository.dart';

/// State notifier responsible for managing settings persistence and updates.
class SettingsViewModel extends StateNotifier<AsyncValue<SettingsModel>> {
  SettingsViewModel(this._repository)
      : super(const AsyncValue.loading()) {
    unawaited(load());
  }

  /// Error message displayed when loading settings fails.
  static const String loadErrorMessage =
      'Failed to load settings. Please try again.';

  /// Error message displayed when saving settings fails.
  static const String saveErrorMessage =
      'Failed to save settings. Please try again.';

  /// Error message displayed when resetting settings fails.
  static const String resetErrorMessage =
      'Failed to reset settings. Please try again.';

  final SettingsRepository _repository;

  /// Loads persisted settings and updates the notifier state.
  Future<String?> load() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.loadSettings();
      state = AsyncValue.data(settings);
      return null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return loadErrorMessage;
    }
  }

  /// Persists the current settings.
  Future<String?> save() async {
    final settings = state.valueOrNull;
    if (settings == null) {
      return saveErrorMessage;
    }

    try {
      await _repository.saveSettings(settings);
      return null;
    } catch (_) {
      return saveErrorMessage;
    }
  }

  /// Restores settings to their default values and persists them.
  Future<String?> reset() async {
    const defaults = SettingsModel();
    final previousState = state.valueOrNull;
    state = const AsyncValue.data(defaults);

    try {
      await _repository.saveSettings(defaults);
      return null;
    } catch (_) {
      if (previousState != null) {
        state = AsyncValue.data(previousState);
      }
      return resetErrorMessage;
    }
  }

  /// Updates the empty string symbol.
  void updateEmptyStringSymbol(String value) {
    state = state.whenData(
      (settings) => settings.copyWith(emptyStringSymbol: value),
    );
  }

  /// Updates the epsilon transition symbol.
  void updateEpsilonSymbol(String value) {
    state = state.whenData(
      (settings) => settings.copyWith(epsilonSymbol: value),
    );
  }

  /// Updates the selected theme mode.
  void updateThemeMode(String value) {
    state = state.whenData(
      (settings) => settings.copyWith(themeMode: value),
    );
  }

  /// Toggles the grid visibility.
  void updateShowGrid(bool value) {
    state = state.whenData(
      (settings) => settings.copyWith(showGrid: value),
    );
  }

  /// Toggles the coordinates visibility.
  void updateShowCoordinates(bool value) {
    state = state.whenData(
      (settings) => settings.copyWith(showCoordinates: value),
    );
  }

  /// Updates the grid size.
  void updateGridSize(double value) {
    state = state.whenData(
      (settings) => settings.copyWith(gridSize: value),
    );
  }

  /// Updates the node size.
  void updateNodeSize(double value) {
    state = state.whenData(
      (settings) => settings.copyWith(nodeSize: value),
    );
  }

  /// Updates the font size.
  void updateFontSize(double value) {
    state = state.whenData(
      (settings) => settings.copyWith(fontSize: value),
    );
  }

  /// Toggles autosave behaviour.
  void updateAutoSave(bool value) {
    state = state.whenData(
      (settings) => settings.copyWith(autoSave: value),
    );
  }

  /// Toggles tooltip visibility.
  void updateShowTooltips(bool value) {
    state = state.whenData(
      (settings) => settings.copyWith(showTooltips: value),
    );
  }
}
