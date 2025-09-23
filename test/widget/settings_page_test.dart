import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/data/repositories/settings_repository_impl.dart';
import 'package:jflutter/data/storage/settings_storage.dart';
import 'package:jflutter/presentation/pages/settings_page.dart';
import 'package:jflutter/presentation/providers/settings_providers.dart';

void main() {
  testWidgets('loads settings from stored preferences', (WidgetTester tester) async {
    final storage = InMemorySettingsStorage({
      'settings_empty_string_symbol': 'ε',
      'settings_epsilon_symbol': 'λ',
      'settings_theme_mode': 'dark',
      'settings_show_grid': false,
      'settings_show_coordinates': true,
      'settings_auto_save': false,
      'settings_show_tooltips': false,
      'settings_grid_size': 42.0,
      'settings_node_size': 25.0,
      'settings_font_size': 16.0,
    });

    await _pumpSettingsPage(tester, storage);
    await tester.pumpAndSettle();

    final emptyStringChip = tester.widget<FilterChip>(
      find.byKey(const ValueKey('settings_empty_string_epsilon')),
    );
    expect(emptyStringChip.selected, isTrue);

    final themeChip = tester.widget<FilterChip>(
      find.byKey(const ValueKey('settings_theme_dark')),
    );
    expect(themeChip.selected, isTrue);

    final showGridSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('settings_show_grid_switch')),
    );
    expect(showGridSwitch.value, isFalse);

    final showCoordinatesSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('settings_show_coordinates_switch')),
    );
    expect(showCoordinatesSwitch.value, isTrue);

    final gridSizeSlider = tester.widget<Slider>(
      find.byKey(const ValueKey('settings_grid_size_slider')),
    );
    expect(gridSizeSlider.value, equals(42.0));
  });

  testWidgets('saves settings and restores them on next load', (WidgetTester tester) async {
    final storage = InMemorySettingsStorage();

    await _pumpSettingsPage(tester, storage);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_show_grid_switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_show_tooltips_switch')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_empty_string_epsilon')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_theme_dark')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings_save_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    await _pumpSettingsPage(tester, storage);
    await tester.pumpAndSettle();

    final reloadedGridSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('settings_show_grid_switch')),
    );
    expect(reloadedGridSwitch.value, isFalse);

    final reloadedTooltipSwitch = tester.widget<Switch>(
      find.byKey(const ValueKey('settings_show_tooltips_switch')),
    );
    expect(reloadedTooltipSwitch.value, isFalse);

    final reloadedEmptyChip = tester.widget<FilterChip>(
      find.byKey(const ValueKey('settings_empty_string_epsilon')),
    );
    expect(reloadedEmptyChip.selected, isTrue);

    final reloadedThemeChip = tester.widget<FilterChip>(
      find.byKey(const ValueKey('settings_theme_dark')),
    );
    expect(reloadedThemeChip.selected, isTrue);
  });
}

Future<void> _pumpSettingsPage(
  WidgetTester tester,
  SettingsStorage storage,
) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          SharedPreferencesSettingsRepository(storage: storage),
        ),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
}
