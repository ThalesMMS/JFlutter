//
//  dependency_injection.dart
//  JFlutter
//
//  Configura o contêiner GetIt mínimo que ainda resta no aplicativo,
//  inicializando SharedPreferences para providers Riverpod que dependem de
//  estado assíncrono de plataforma durante o startup.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

part 'dependency_initialization_typedefs.dart';
part 'dependency_initialization_stage.dart';
part 'shared_preferences_initialization_result.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;
SharedPreferencesStorePlatform? _originalSharedPreferencesStorePlatform;
bool _sharedPreferencesFallbackApplied = false;

/// Sets up dependency injection for the application
Future<void> setupDependencyInjection({
  SharedPreferencesProvider? sharedPreferencesProvider,
  DependencyInitializationObserver? onStage,
  DependencyInitializationLogger? logger,
}) async {
  final log = logger ?? debugPrint;

  // Initialize SharedPreferences for trace persistence
  onStage?.call(DependencyInitializationStage.sharedPreferences);
  final prefsResult = await _initializeSharedPreferences(
    provider: sharedPreferencesProvider,
    logger: log,
  );
  final prefs = prefsResult.prefs;

  // Async platform preferences must be ready before ProviderScope builds.
  getIt.registerSingleton<SharedPreferences>(prefs);
}

/// Resets all dependencies (useful for testing)
Future<void> resetDependencies() async {
  await getIt.reset();
  if (_originalSharedPreferencesStorePlatform != null) {
    SharedPreferencesStorePlatform.instance =
        _originalSharedPreferencesStorePlatform!;
  }
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.resetStatic();
  _originalSharedPreferencesStorePlatform = null;
  _sharedPreferencesFallbackApplied = false;
}

Future<_SharedPreferencesInitializationResult> _initializeSharedPreferences({
  SharedPreferencesProvider? provider,
  required DependencyInitializationLogger logger,
}) async {
  final resolver = provider ?? SharedPreferences.getInstance;

  try {
    final prefs = await resolver();
    return _SharedPreferencesInitializationResult(
      prefs: prefs,
    );
  } catch (error, stackTrace) {
    logger(
      '[DI] SharedPreferences initialization failed. Falling back to in-memory preferences. Error: $error',
    );
    debugPrintStack(stackTrace: stackTrace);

    try {
      if (!_sharedPreferencesFallbackApplied) {
        _originalSharedPreferencesStorePlatform =
            SharedPreferencesStorePlatform.instance;
        _sharedPreferencesFallbackApplied = true;
      }
      SharedPreferencesStorePlatform.instance =
          InMemorySharedPreferencesStore.empty();
      final fallbackPrefs = await SharedPreferences.getInstance();
      return _SharedPreferencesInitializationResult(
        prefs: fallbackPrefs,
      );
    } catch (fallbackError, fallbackStackTrace) {
      if (_originalSharedPreferencesStorePlatform != null) {
        SharedPreferencesStorePlatform.instance =
            _originalSharedPreferencesStorePlatform!;
      }
      _originalSharedPreferencesStorePlatform = null;
      _sharedPreferencesFallbackApplied = false;
      logger(
        '[DI] SharedPreferences fallback initialization failed: $fallbackError',
      );
      debugPrintStack(stackTrace: fallbackStackTrace);
      rethrow;
    }
  }
}
