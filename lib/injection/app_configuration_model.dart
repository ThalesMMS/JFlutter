/// Platform-aware application configuration surface used during dependency
/// injection. Centralizes values that vary per target, such as backend API
/// endpoints, allowing services to resolve their runtime configuration without
/// scattering platform checks across the codebase.
class AppConfiguration {
  const AppConfiguration({
    required this.apiBaseUrl,
    required this.platformLabel,
  });

  /// Base URL used by HTTP services to reach the backend.
  final String apiBaseUrl;

  /// Human readable platform tag (web, mobile, desktop, etc).
  final String platformLabel;
}
