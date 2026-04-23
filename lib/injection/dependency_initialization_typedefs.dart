part of 'dependency_injection.dart';

typedef SharedPreferencesProvider = Future<SharedPreferences> Function();
typedef DependencyInitializationObserver = void Function(
  DependencyInitializationStage stage,
);
typedef DependencyInitializationLogger = void Function(String message);
