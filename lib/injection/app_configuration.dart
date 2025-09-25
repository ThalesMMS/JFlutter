import 'app_configuration_model.dart';
import 'platform/app_configuration_stub.dart'
    if (dart.library.io) 'platform/app_configuration_io.dart'
    if (dart.library.html) 'platform/app_configuration_web.dart';

/// Resolves the platform specific configuration by delegating to the
/// appropriate implementation based on the active runtime (web, mobile, etc).
AppConfiguration resolveAppConfiguration() => buildAppConfiguration();
