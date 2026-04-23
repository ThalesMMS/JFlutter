part of 'dependency_injection.dart';

enum DependencyInitializationStage {
  sharedPreferences,
  dataSources,
  services,
  repositories,
  useCases,
  providers,
}
