import '../app_configuration_model.dart';

/// Configuration for the web build. Uses a relative path so the web server can
/// proxy API calls regardless of deployment origin.
AppConfiguration buildAppConfiguration() => const AppConfiguration(
      apiBaseUrl: '/api',
      platformLabel: 'web',
    );
