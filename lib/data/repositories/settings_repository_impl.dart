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
  final SettingsStorage _storage;

  @override
  Future<SettingsModel> loadSettings() async {
    const defaults = SettingsModel();

    return SettingsModel(
      emptyStringSymbol:
          await _storage.readString(_emptyStringSymbolKey) ??
          defaults.emptyStringSymbol,
      epsilonSymbol:
          await _storage.readString(_epsilonSymbolKey) ??
          defaults.epsilonSymbol,
      themeMode: await _storage.readString(_themeModeKey) ?? defaults.themeMode,
      showGrid: await _storage.readBool(_showGridKey) ?? defaults.showGrid,
      showCoordinates:
          await _storage.readBool(_showCoordinatesKey) ??
          defaults.showCoordinates,
      autoSave: await _storage.readBool(_autoSaveKey) ?? defaults.autoSave,
      showTooltips:
          await _storage.readBool(_showTooltipsKey) ?? defaults.showTooltips,
      gridSize: await _storage.readDouble(_gridSizeKey) ?? defaults.gridSize,
      nodeSize: await _storage.readDouble(_nodeSizeKey) ?? defaults.nodeSize,
      fontSize: await _storage.readDouble(_fontSizeKey) ?? defaults.fontSize,
    );
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
    ]);

    if (results.any((success) => !success)) {
      throw Exception('Failed to save settings');
    }
  }
}
