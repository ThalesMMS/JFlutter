import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/data/repositories/settings_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesStorePlatform originalStore;

  setUp(() async {
    originalStore = SharedPreferencesStorePlatform.instance;
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    await SharedPreferences.resetStatic();
  });

  tearDown(() async {
    SharedPreferencesStorePlatform.instance = originalStore;
    await SharedPreferences.resetStatic();
  });

  test('loadSettings returns defaults when storage is empty', () async {
    const repository = SharedPreferencesSettingsRepository();

    final settings = await repository.loadSettings();

    expect(settings, equals(const SettingsModel()));
  });

  test('saveSettings persists values that can be reloaded', () async {
    const savedSettings = SettingsModel(
      emptyStringSymbol: 'ε',
      epsilonSymbol: 'λ',
      themeMode: 'dark',
      showGrid: false,
      showCoordinates: true,
      autoSave: false,
      showTooltips: false,
      gridSize: 42.0,
      nodeSize: 25.0,
      fontSize: 16.0,
    );

    const repository = SharedPreferencesSettingsRepository();
    await repository.saveSettings(savedSettings);

    const reloadedRepository = SharedPreferencesSettingsRepository();
    final reloadedSettings = await reloadedRepository.loadSettings();

    expect(reloadedSettings, equals(savedSettings));
  });
}
