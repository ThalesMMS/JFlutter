part of 'dependency_injection.dart';

class _SharedPreferencesInitializationResult {
  const _SharedPreferencesInitializationResult({
    required this.prefs,
    required this.fallbackUsed,
    this.originalError,
  });

  final SharedPreferences prefs;
  final bool fallbackUsed;
  final Object? originalError;
}
