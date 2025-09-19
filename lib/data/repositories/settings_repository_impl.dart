import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/settings_model.dart';
import '../../core/repositories/settings_repository.dart';

/// Settings repository backed by [SharedPreferences].
class SharedPreferencesSettingsRepository implements SettingsRepository {
  const SharedPreferencesSettingsRepository({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider = preferencesProvider;

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

  final Future<SharedPreferences> Function()? _preferencesProvider;

  Future<SharedPreferences> _getPreferences() {
    final provider = _preferencesProvider;
    if (provider != null) {
      return provider();
    }
    return SharedPreferences.getInstance();
  }

  @override
  Future<SettingsModel> loadSettings() async {
    final prefs = await _getPreferences();
    const defaults = SettingsModel();

    return SettingsModel(
      emptyStringSymbol: prefs.getString(_emptyStringSymbolKey) ?? defaults.emptyStringSymbol,
      epsilonSymbol: prefs.getString(_epsilonSymbolKey) ?? defaults.epsilonSymbol,
      themeMode: prefs.getString(_themeModeKey) ?? defaults.themeMode,
      showGrid: prefs.getBool(_showGridKey) ?? defaults.showGrid,
      showCoordinates: prefs.getBool(_showCoordinatesKey) ?? defaults.showCoordinates,
      autoSave: prefs.getBool(_autoSaveKey) ?? defaults.autoSave,
      showTooltips: prefs.getBool(_showTooltipsKey) ?? defaults.showTooltips,
      gridSize: prefs.getDouble(_gridSizeKey) ?? defaults.gridSize,
      nodeSize: prefs.getDouble(_nodeSizeKey) ?? defaults.nodeSize,
      fontSize: prefs.getDouble(_fontSizeKey) ?? defaults.fontSize,
    );
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await _getPreferences();

    final results = await Future.wait<bool>([
      prefs.setString(_emptyStringSymbolKey, settings.emptyStringSymbol),
      prefs.setString(_epsilonSymbolKey, settings.epsilonSymbol),
      prefs.setString(_themeModeKey, settings.themeMode),
      prefs.setBool(_showGridKey, settings.showGrid),
      prefs.setBool(_showCoordinatesKey, settings.showCoordinates),
      prefs.setBool(_autoSaveKey, settings.autoSave),
      prefs.setBool(_showTooltipsKey, settings.showTooltips),
      prefs.setDouble(_gridSizeKey, settings.gridSize),
      prefs.setDouble(_nodeSizeKey, settings.nodeSize),
      prefs.setDouble(_fontSizeKey, settings.fontSize),
    ]);

    if (results.any((success) => !success)) {
      throw Exception('Failed to save settings');
    }
  }
}
