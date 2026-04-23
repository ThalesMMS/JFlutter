//
//  settings_repository_impl.dart
//  JFlutter
//
//  Persiste preferências de interface e símbolos no SharedPreferences por meio de uma camada de repositório que aplica padrões e sincroniza o modelo de configurações.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../../core/models/settings_model.dart';
import '../../core/repositories/settings_repository.dart';
import '../storage/settings_storage.dart';

/// Settings repository backed by [SharedPreferences].
class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository({SettingsStorage? storage})
      : _storage = storage ?? const SharedPreferencesSettingsStorage();

  static const String _emptyStringSymbolKey = 'settings_empty_string_symbol';
  static const String _epsilonSymbolKey = 'settings_epsilon_symbol';
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _showGridKey = 'settings_show_grid';
  static const String _showCoordinatesKey = 'settings_show_coordinates';
  static const String _autoSaveKey = 'settings_auto_save';
  static const String _showTooltipsKey = 'settings_show_tooltips';
  static const String _gridSizeKey = 'settings_grid_size';
  static const String _nodeSizeKey = 'settings_node_size';
  static const String _fontSizeKey = 'settings_font_size';
  static const String _animationSpeedKey = 'settings_animation_speed';
  static const String _legacyUseDraw2dCanvasKey = 'settings_use_draw2d_canvas';
  static const Set<String> _supportedThemeModes = {'system', 'light', 'dark'};
  final SettingsStorage _storage;

  @override
  Future<SettingsModel> loadSettings() async {
    const defaults = SettingsModel();

    final settings = SettingsModel(
      emptyStringSymbol: await _readStringSetting(
        _emptyStringSymbolKey,
        defaults.emptyStringSymbol,
      ),
      epsilonSymbol: await _readStringSetting(
        _epsilonSymbolKey,
        defaults.epsilonSymbol,
      ),
      themeMode: await _readStringSetting(
        _themeModeKey,
        defaults.themeMode,
        isValid: _supportedThemeModes.contains,
      ),
      showGrid: await _readBoolSetting(_showGridKey, defaults.showGrid),
      showCoordinates: await _readBoolSetting(
        _showCoordinatesKey,
        defaults.showCoordinates,
      ),
      autoSave: await _readBoolSetting(_autoSaveKey, defaults.autoSave),
      showTooltips: await _readBoolSetting(
        _showTooltipsKey,
        defaults.showTooltips,
      ),
      gridSize: await _readDoubleSetting(_gridSizeKey, defaults.gridSize),
      nodeSize: await _readDoubleSetting(_nodeSizeKey, defaults.nodeSize),
      fontSize: await _readDoubleSetting(_fontSizeKey, defaults.fontSize),
      animationSpeed: await _readDoubleSetting(
        _animationSpeedKey,
        defaults.animationSpeed,
      ),
    );
    await _removeLegacyCanvasPreference();
    return settings;
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    final results = await Future.wait<bool>([
      _storage.writeString(_emptyStringSymbolKey, settings.emptyStringSymbol),
      _storage.writeString(_epsilonSymbolKey, settings.epsilonSymbol),
      _storage.writeString(_themeModeKey, settings.themeMode),
      _storage.writeBool(_showGridKey, settings.showGrid),
      _storage.writeBool(_showCoordinatesKey, settings.showCoordinates),
      _storage.writeBool(_autoSaveKey, settings.autoSave),
      _storage.writeBool(_showTooltipsKey, settings.showTooltips),
      _storage.writeDouble(_gridSizeKey, settings.gridSize),
      _storage.writeDouble(_nodeSizeKey, settings.nodeSize),
      _storage.writeDouble(_fontSizeKey, settings.fontSize),
      _storage.writeDouble(_animationSpeedKey, settings.animationSpeed),
    ]);

    if (results.any((success) => !success)) {
      throw Exception('Failed to save settings');
    }
    await _removeLegacyCanvasPreference();
  }

  Future<void> _removeLegacyCanvasPreference() async {
    try {
      await _storage.remove(_legacyUseDraw2dCanvasKey);
    } catch (_) {
      // Ignore cleanup failures – they should not block settings operations.
    }
  }

  Future<String> _readStringSetting(
    String key,
    String fallback, {
    bool Function(String value)? isValid,
  }) async {
    try {
      final value = await _storage.readString(key);
      if (value == null) {
        return fallback;
      }
      if (isValid != null && !isValid(value)) {
        return fallback;
      }
      return value;
    } catch (_) {
      return fallback;
    }
  }

  Future<bool> _readBoolSetting(String key, bool fallback) async {
    try {
      return await _storage.readBool(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<double> _readDoubleSetting(String key, double fallback) async {
    try {
      return await _storage.readDouble(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
