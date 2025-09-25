import '../app_configuration_model.dart';

/// Fallback configuration used when neither the IO nor web libraries are
/// available (e.g. during analysis). Defaults to the production API endpoint.
AppConfiguration buildAppConfiguration() => const AppConfiguration(
      apiBaseUrl: 'https://api.jflutter.dev',
      platformLabel: 'unknown',
    );
