part of 'dependency_injection.dart';

class DependencyInitializationStatus {
  const DependencyInitializationStatus({
    required this.sharedPreferencesFallbackUsed,
    this.sharedPreferencesError,
  });

  final bool sharedPreferencesFallbackUsed;
  final Object? sharedPreferencesError;
}
