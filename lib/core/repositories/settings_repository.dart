import '../models/settings_model.dart';

/// Repository contract for persisting and retrieving user settings.
abstract class SettingsRepository {
  /// Loads previously saved settings or returns defaults when unavailable.
  Future<SettingsModel> loadSettings();

  /// Persists the provided [settings].
  Future<void> saveSettings(SettingsModel settings);
}
