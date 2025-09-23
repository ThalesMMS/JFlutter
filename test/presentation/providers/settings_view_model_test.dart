import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/settings_model.dart';
import 'package:jflutter/core/repositories/settings_repository.dart';
import 'package:jflutter/presentation/providers/settings_providers.dart';
import 'package:jflutter/presentation/providers/settings_view_model.dart';

void main() {
  late FakeSettingsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeSettingsRepository();
    container = ProviderContainer(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('load populates state with repository values', () async {
    repository.settingsToLoad = const SettingsModel(themeMode: 'dark');

    await container.read(settingsViewModelProvider.notifier).load();
    final state = container.read(settingsViewModelProvider);

    expect(state.asData?.value, equals(repository.settingsToLoad));
  });

  test('save persists current settings', () async {
    await container.read(settingsViewModelProvider.notifier).load();
    final viewModel = container.read(settingsViewModelProvider.notifier);

    viewModel.updateThemeMode('dark');
    final message = await viewModel.save();

    expect(message, isNull);
    expect(repository.savedSettings?.themeMode, equals('dark'));
  });

  test('save returns error message when repository throws', () async {
    await container.read(settingsViewModelProvider.notifier).load();
    repository.throwOnSave = true;

    final message = await container.read(settingsViewModelProvider.notifier).save();

    expect(message, SettingsViewModel.saveErrorMessage);
  });

  test('reset restores defaults and persists them', () async {
    repository.settingsToLoad = const SettingsModel(themeMode: 'light', showGrid: false);
    await container.read(settingsViewModelProvider.notifier).load();
    repository.throwOnSave = false;

    final message = await container.read(settingsViewModelProvider.notifier).reset();
    final state = container.read(settingsViewModelProvider);

    expect(message, isNull);
    expect(state.asData?.value, const SettingsModel());
    expect(repository.savedSettings, const SettingsModel());
  });

  test('reset returns error message and restores previous state when save fails', () async {
    repository.settingsToLoad = const SettingsModel(themeMode: 'light', showGrid: false);
    await container.read(settingsViewModelProvider.notifier).load();
    final viewModel = container.read(settingsViewModelProvider.notifier);
    viewModel.updateThemeMode('dark');
    repository.throwOnSave = true;

    final message = await viewModel.reset();
    final state = container.read(settingsViewModelProvider);

    expect(message, SettingsViewModel.resetErrorMessage);
    expect(state.asData?.value.themeMode, equals('dark'));
  });

  test('load returns error message when repository throws', () async {
    repository.throwOnLoad = true;

    final message = await container.read(settingsViewModelProvider.notifier).load();
    final state = container.read(settingsViewModelProvider);

    expect(message, SettingsViewModel.loadErrorMessage);
    expect(state.hasError, isTrue);
  });

  test('field updates modify the current settings state', () async {
    await container.read(settingsViewModelProvider.notifier).load();
    final viewModel = container.read(settingsViewModelProvider.notifier);

    viewModel
      ..updateEmptyStringSymbol('ε')
      ..updateEpsilonSymbol('λ')
      ..updateThemeMode('dark')
      ..updateShowGrid(false)
      ..updateShowCoordinates(true)
      ..updateGridSize(30)
      ..updateNodeSize(45)
      ..updateFontSize(18)
      ..updateAutoSave(false)
      ..updateShowTooltips(false);

    final settings = container.read(settingsViewModelProvider).asData?.value;

    expect(settings, isNotNull);
    expect(settings?.emptyStringSymbol, equals('ε'));
    expect(settings?.epsilonSymbol, equals('λ'));
    expect(settings?.themeMode, equals('dark'));
    expect(settings?.showGrid, isFalse);
    expect(settings?.showCoordinates, isTrue);
    expect(settings?.gridSize, equals(30));
    expect(settings?.nodeSize, equals(45));
    expect(settings?.fontSize, equals(18));
    expect(settings?.autoSave, isFalse);
    expect(settings?.showTooltips, isFalse);
  });
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({SettingsModel? initial})
      : settingsToLoad = initial ?? const SettingsModel();

  SettingsModel settingsToLoad;
  SettingsModel? savedSettings;
  bool throwOnLoad = false;
  bool throwOnSave = false;

  @override
  Future<SettingsModel> loadSettings() async {
    if (throwOnLoad) {
      throw Exception('Failed to load');
    }
    return settingsToLoad;
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    if (throwOnSave) {
      throw Exception('Failed to save');
    }
    savedSettings = settings;
  }
}
