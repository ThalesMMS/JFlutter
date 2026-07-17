import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_en.dart';

/// Resolves the app locale while keeping isolated widgets and previews usable.
///
/// Production mounts [AppLocalizations.delegate] at the app root. The English
/// fallback is only used by isolated widget harnesses that intentionally omit
/// localization delegates.
AppLocalizations appLocalizationsOf(BuildContext context) {
  return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      AppLocalizationsEn();
}
