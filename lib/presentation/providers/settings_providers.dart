import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/settings_model.dart';
import '../../core/repositories/settings_repository.dart';
import 'settings_view_model.dart';

/// Provider for injecting the [SettingsRepository].
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('settingsRepositoryProvider must be overridden');
});

/// Provider exposing the [SettingsViewModel].
final settingsViewModelProvider =
    StateNotifierProvider<SettingsViewModel, AsyncValue<SettingsModel>>(
  (ref) => SettingsViewModel(ref.watch(settingsRepositoryProvider)),
);
