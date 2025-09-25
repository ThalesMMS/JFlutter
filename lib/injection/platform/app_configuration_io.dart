import 'dart:io';

import '../app_configuration_model.dart';

/// Builds configuration for mobile and desktop platforms using dart:io.
AppConfiguration buildAppConfiguration() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const AppConfiguration(
      apiBaseUrl: 'https://api.jflutter.dev',
      platformLabel: 'mobile',
    );
  }

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    return const AppConfiguration(
      apiBaseUrl: 'http://localhost:8080/api',
      platformLabel: 'desktop',
    );
  }

  return const AppConfiguration(
    apiBaseUrl: 'https://api.jflutter.dev',
    platformLabel: 'io',
  );
}
