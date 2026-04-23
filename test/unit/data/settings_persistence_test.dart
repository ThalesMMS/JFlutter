import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/core/repositories/settings_repository.dart';
import 'package:jflutter/data/repositories/settings_repository_impl.dart';
import 'package:jflutter/data/storage/settings_storage.dart';
import 'package:jflutter/presentation/providers/settings_provider.dart';

class _RecordingSettingsStorage implements SettingsStorage {
  _RecordingSettingsStorage([Map<String, Object?>? initialValues])
      : values = Map<String, Object?>.from(initialValues ?? const {});

  final Map<String, Object?> values;

  @override
  Future<String?> readString(String key) async => values[key] as String?;

  @override
  Future<bool?> readBool(String key) async => values[key] as bool?;

  @override
  Future<double?> readDouble(String key) async =>
      (values[key] as num?)?.toDouble();

  @override
  Future<bool> writeString(String key, String value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> writeBool(String key, bool value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> writeDouble(String key, double value) async {
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    values.remove(key);
    return true;
  }
}

class _ThrowingSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsModel> loadSettings() async {
    throw Exception('load failed');
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

Future<void> _flushNotifierLoad() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

Map<String, Object?> _settingsValues(SettingsModel settings) {
  return <String, Object?>{
    'settings_empty_string_symbol': settings.emptyStringSymbol,
    'settings_epsilon_symbol': settings.epsilonSymbol,
    'settings_theme_mode': settings.themeMode,
    'settings_show_grid': settings.showGrid,
    'settings_show_coordinates': settings.showCoordinates,
    'settings_auto_save': settings.autoSave,
    'settings_show_tooltips': settings.showTooltips,
    'settings_grid_size': settings.gridSize,
    'settings_node_size': settings.nodeSize,
    'settings_font_size': settings.fontSize,
    'settings_animation_speed': settings.animationSpeed,
  };
}

SettingsModel _customSettings() {
  return const SettingsModel(
    emptyStringSymbol: '∅',
    epsilonSymbol: 'λ',
    themeMode: 'dark',
    showGrid: false,
    showCoordinates: true,
    autoSave: false,
    showTooltips: false,
    gridSize: 32,
    nodeSize: 44,
    fontSize: 18,
    animationSpeed: 1.5,
  );
}

void main() {
  group('Settings persistence', () {
    test('saveSettings writes all 11 keys correctly', () async {
      final storage = _RecordingSettingsStorage();
      final repository = SharedPreferencesSettingsRepository(storage: storage);
      final settings = _customSettings();

      await repository.saveSettings(settings);

      expect(storage.values, equals(_settingsValues(settings)));
      expect(storage.values.length, equals(11));
    });

    test('loadSettings restores all persisted settings accurately', () async {
      final settings = _customSettings();
      final storage = _RecordingSettingsStorage(_settingsValues(settings));
      final repository = SharedPreferencesSettingsRepository(storage: storage);

      final loaded = await repository.loadSettings();

      expect(loaded, equals(settings));
    });

    test('round-trips through save then load with a fresh repository',
        () async {
      final settings = _customSettings();
      final storage = _RecordingSettingsStorage();

      await SharedPreferencesSettingsRepository(storage: storage)
          .saveSettings(settings);

      final loaded = await SharedPreferencesSettingsRepository(storage: storage)
          .loadSettings();

      expect(loaded, equals(settings));
    });

    test('restores string, bool, and double settings by type', () async {
      final storage = _RecordingSettingsStorage(<String, Object?>{
        'settings_theme_mode': 'light',
        'settings_show_grid': false,
        'settings_grid_size': 28.0,
      });
      final repository = SharedPreferencesSettingsRepository(storage: storage);

      final loaded = await repository.loadSettings();

      expect(loaded.themeMode, equals('light'));
      expect(loaded.showGrid, isFalse);
      expect(loaded.gridSize, equals(28.0));
    });

    test('uses per-field defaults when individual keys are missing', () async {
      const defaults = SettingsModel();
      final persisted = _settingsValues(_customSettings());
      final assertions = <String, void Function(SettingsModel)>{
        'settings_empty_string_symbol': (settings) => expect(
              settings.emptyStringSymbol,
              equals(defaults.emptyStringSymbol),
            ),
        'settings_epsilon_symbol': (settings) => expect(
              settings.epsilonSymbol,
              equals(defaults.epsilonSymbol),
            ),
        'settings_theme_mode': (settings) => expect(
              settings.themeMode,
              equals(defaults.themeMode),
            ),
        'settings_show_grid': (settings) => expect(
              settings.showGrid,
              equals(defaults.showGrid),
            ),
        'settings_show_coordinates': (settings) => expect(
              settings.showCoordinates,
              equals(defaults.showCoordinates),
            ),
        'settings_auto_save': (settings) => expect(
              settings.autoSave,
              equals(defaults.autoSave),
            ),
        'settings_show_tooltips': (settings) => expect(
              settings.showTooltips,
              equals(defaults.showTooltips),
            ),
        'settings_grid_size': (settings) => expect(
              settings.gridSize,
              equals(defaults.gridSize),
            ),
        'settings_node_size': (settings) => expect(
              settings.nodeSize,
              equals(defaults.nodeSize),
            ),
        'settings_font_size': (settings) => expect(
              settings.fontSize,
              equals(defaults.fontSize),
            ),
        'settings_animation_speed': (settings) => expect(
              settings.animationSpeed,
              equals(defaults.animationSpeed),
            ),
      };

      for (final missingKey in persisted.keys) {
        final partial = Map<String, Object?>.from(persisted)
          ..remove(missingKey);
        final repository = SharedPreferencesSettingsRepository(
          storage: _RecordingSettingsStorage(partial),
        );

        final loaded = await repository.loadSettings();

        assertions[missingKey]!(loaded);
      }
    });

    test('returns full defaults when all persisted keys are absent', () async {
      final repository = SharedPreferencesSettingsRepository(
        storage: _RecordingSettingsStorage(),
      );

      final loaded = await repository.loadSettings();

      expect(loaded, equals(const SettingsModel()));
    });

    test('falls back to defaults for wrong persisted types', () async {
      final repository = SharedPreferencesSettingsRepository(
        storage: _RecordingSettingsStorage(<String, Object?>{
          'settings_theme_mode': 'dark',
          'settings_show_grid': 'false',
          'settings_grid_size': 'large',
          'settings_font_size': true,
        }),
      );

      final loaded = await repository.loadSettings();

      expect(loaded.themeMode, equals('dark'));
      expect(loaded.showGrid, equals(const SettingsModel().showGrid));
      expect(loaded.gridSize, equals(const SettingsModel().gridSize));
      expect(loaded.fontSize, equals(const SettingsModel().fontSize));
    });
  });

  group('SettingsNotifier loading', () {
    test('catches repository load failures and stays on defaults', () async {
      final notifier = SettingsNotifier(_ThrowingSettingsRepository());
      addTearDown(notifier.dispose);

      await _flushNotifierLoad();

      expect(notifier.state, equals(const SettingsModel()));
    });
  });
}
