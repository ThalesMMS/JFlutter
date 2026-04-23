/// Static feature flags for the Apple v1.0 release surface.
class V1FeatureFlags {
  const V1FeatureFlags._();

  static const bool showFsaModule = true;
  static const bool showGrammarModule = true;
  static const bool showPdaModule = true;
  static const bool showTmModule = true;
  static const bool showRegexModule = true;
  static const bool showPumpingLemma = false;

  static const bool fsaSupportsJflapImport = true;
  static const bool fsaSupportsJflapExport = true;
  static const bool fsaSupportsJsonImport = true;
  static const bool fsaSupportsJsonExport = true;
  static const bool fsaSupportsSvgExport = true;
  static const bool fsaSupportsPngExport = true;

  static const bool grammarSupportsJflapImport = true;
  static const bool grammarSupportsJflapExport = true;
  static const bool grammarSupportsSvgExport = true;

  static const bool pdaSupportsJflapImport = false;
  static const bool pdaSupportsJflapExport = false;
  static const bool pdaSupportsJsonImport = false;
  static const bool pdaSupportsJsonExport = false;
  static const bool pdaSupportsSvgExport = true;

  static const bool tmSupportsJflapImport = false;
  static const bool tmSupportsJflapExport = false;
  static const bool tmSupportsJsonImport = false;
  static const bool tmSupportsJsonExport = false;
  static const bool tmSupportsSvgExport = true;

  static const bool regexSupportsFileImport = false;
  static const bool regexSupportsFileExport = false;
}
