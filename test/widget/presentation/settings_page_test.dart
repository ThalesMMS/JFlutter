import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/core/repositories/settings_repository.dart';
import 'package:jflutter/presentation/pages/settings_page.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository([SettingsModel? initialSettings])
      : _settings = initialSettings ?? const SettingsModel();

  SettingsModel _settings;
  final List<SettingsModel> savedSettings = [];

  @override
  Future<SettingsModel> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    _settings = settings;
    savedSettings.add(settings);
  }
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  required _FakeSettingsRepository repository,
  Size size = const Size(430, 932),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SettingsPage(repository: repository),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _ensureVisibleAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _updateSlider(WidgetTester tester, Key key, double value) {
  final slider = tester.widget<Slider>(find.byKey(key));
  expect(slider.onChanged, isNotNull);
  slider.onChanged!(value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsPage interactions', () {
    testWidgets('save settings button persists the current settings', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_theme_dark')),
      );
      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_show_tooltips_switch')),
      );
      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_save_button')),
      );

      expect(repository.savedSettings, hasLength(1));
      expect(
        repository.savedSettings.single,
        const SettingsModel(themeMode: 'dark', showTooltips: false),
      );
      expect(find.text('Settings saved.'), findsOneWidget);
    });

    testWidgets('reset to defaults reverts state and persists defaults', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository(
        const SettingsModel(
          emptyStringSymbol: 'ε',
          epsilonSymbol: 'λ',
          themeMode: 'dark',
          showGrid: false,
          showCoordinates: true,
          autoSave: false,
          showTooltips: false,
          gridSize: 35,
          nodeSize: 50,
          fontSize: 20,
        ),
      );

      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_reset_button')),
      );

      expect(repository.savedSettings, hasLength(1));
      expect(repository.savedSettings.single, const SettingsModel());

      expect(
        tester
            .widget<Switch>(
                find.byKey(const ValueKey('settings_show_grid_switch')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_coordinates_switch')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
                find.byKey(const ValueKey('settings_auto_save_switch')))
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_tooltips_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
                find.byKey(const ValueKey('settings_theme_system')))
            .selected,
        isTrue,
      );
    });

    testWidgets('toggle switches update their selected values', (tester) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      for (final key in const [
        ValueKey('settings_show_grid_switch'),
        ValueKey('settings_show_coordinates_switch'),
        ValueKey('settings_auto_save_switch'),
        ValueKey('settings_show_tooltips_switch'),
      ]) {
        await _ensureVisibleAndTap(tester, find.byKey(key));
      }

      expect(
        tester
            .widget<Switch>(
                find.byKey(const ValueKey('settings_show_grid_switch')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_coordinates_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
                find.byKey(const ValueKey('settings_auto_save_switch')))
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_tooltips_switch')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('sliders reflect updated values', (tester) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_grid_size_slider')),
      );
      await tester.pumpAndSettle();

      _updateSlider(tester, const ValueKey('settings_grid_size_slider'), 40);
      await tester.pumpAndSettle();
      _updateSlider(tester, const ValueKey('settings_node_size_slider'), 55);
      await tester.pumpAndSettle();
      _updateSlider(tester, const ValueKey('settings_font_size_slider'), 18);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Slider>(
                find.byKey(const ValueKey('settings_grid_size_slider')))
            .value,
        40,
      );
      expect(
        tester
            .widget<Slider>(
                find.byKey(const ValueKey('settings_node_size_slider')))
            .value,
        55,
      );
      expect(
        tester
            .widget<Slider>(
                find.byKey(const ValueKey('settings_font_size_slider')))
            .value,
        18,
      );
    });

    testWidgets('filter chip selections update the active options', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_empty_string_epsilon')),
      );
      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_epsilon_lambda')),
      );
      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_theme_dark')),
      );

      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_empty_string_epsilon')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_empty_string_lambda')),
            )
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_epsilon_lambda')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_epsilon_epsilon')),
            )
            .selected,
        isFalse,
      );
      expect(
        tester
            .widget<FilterChip>(
                find.byKey(const ValueKey('settings_theme_dark')))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
                find.byKey(const ValueKey('settings_theme_system')))
            .selected,
        isFalse,
      );
    });
  });
}
