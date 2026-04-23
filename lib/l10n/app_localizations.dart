import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.localizationsDelegates` in
/// their app's `localizationsDelegates` list, and the locales they support in
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// Title for the transition selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Select transition'**
  String get selectTransition;

  /// Action label for creating a new transition from the selection dialog.
  ///
  /// In en, this message translates to:
  /// **'Create new transition'**
  String get createNewTransition;

  /// Tooltip for opening contextual help for the current regex workflow.
  ///
  /// In en, this message translates to:
  /// **'Context-Aware Help'**
  String get contextAwareHelp;

  /// Label for the algorithms section.
  ///
  /// In en, this message translates to:
  /// **'Algorithms'**
  String get algorithms;

  /// Title for the regular expression page.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression'**
  String get regularExpressionTitle;

  /// Form label for the primary regular expression input.
  ///
  /// In en, this message translates to:
  /// **'Regular Expression:'**
  String get regularExpressionLabel;

  /// Hint text shown in the regular expression input.
  ///
  /// In en, this message translates to:
  /// **'Enter regular expression (e.g., a*b+)'**
  String get regularExpressionHint;

  /// Button label for validating the entered regular expression.
  ///
  /// In en, this message translates to:
  /// **'Validate Regex'**
  String get validateRegex;

  /// Validation message shown when no regular expression was entered.
  ///
  /// In en, this message translates to:
  /// **'Enter a regular expression to validate.'**
  String get enterRegexToValidate;

  /// Status message shown when the regular expression is valid.
  ///
  /// In en, this message translates to:
  /// **'Valid regex'**
  String get validRegex;

  /// Status message shown when the regular expression is invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid regex'**
  String get invalidRegex;

  /// Form label for the test string input.
  ///
  /// In en, this message translates to:
  /// **'Test String:'**
  String get testStringLabel;

  /// Hint text shown in the test string input.
  ///
  /// In en, this message translates to:
  /// **'Enter string to test'**
  String get testStringHint;

  /// Tooltip for the test string action.
  ///
  /// In en, this message translates to:
  /// **'Test String'**
  String get testStringTooltip;

  /// Result label shown when the test string matches the regular expression.
  ///
  /// In en, this message translates to:
  /// **'Matches!'**
  String get matches;

  /// Result label shown when the test string does not match the regular expression.
  ///
  /// In en, this message translates to:
  /// **'Does not match'**
  String get doesNotMatch;

  /// Section label for regular-expression-to-automaton conversion actions.
  ///
  /// In en, this message translates to:
  /// **'Convert to Automaton:'**
  String get convertToAutomaton;

  /// Button label for converting the regular expression to an NFA.
  ///
  /// In en, this message translates to:
  /// **'Convert to NFA'**
  String get convertToNfa;

  /// Button label for converting the regular expression to a DFA.
  ///
  /// In en, this message translates to:
  /// **'Convert to DFA'**
  String get convertToDfa;

  /// Switch label for simplifying converted regex output.
  ///
  /// In en, this message translates to:
  /// **'Simplify Output'**
  String get simplifyOutput;

  /// Subtitle explaining the simplify output switch.
  ///
  /// In en, this message translates to:
  /// **'Apply algebraic simplifications to converted automata'**
  String get simplifyOutputSubtitle;

  /// Section label for comparing two regular expressions.
  ///
  /// In en, this message translates to:
  /// **'Compare Regular Expressions:'**
  String get compareRegularExpressions;

  /// Hint text for the comparison regular expression input.
  ///
  /// In en, this message translates to:
  /// **'Enter second regular expression'**
  String get comparisonRegexHint;

  /// Button label for checking whether two regular expressions are equivalent.
  ///
  /// In en, this message translates to:
  /// **'Compare Equivalence'**
  String get compareEquivalence;

  /// Title for the regular expression help dialog.
  ///
  /// In en, this message translates to:
  /// **'Regex Help'**
  String get regexHelp;

  /// Help text listing common regular expression patterns and meanings.
  ///
  /// In en, this message translates to:
  /// **'Common patterns:\n• a* - zero or more a\'s\n• a+ - one or more a\'s\n• a? - zero or one a\n• a|b - a or b\n• (ab)* - zero or more ab\'s\n• [abc] - any of a, b, or c'**
  String get regexHelpPatterns;

  /// Header for a converted regular expression after simplification.
  ///
  /// In en, this message translates to:
  /// **'Converted Regex (Simplified)'**
  String get convertedRegexSimplified;

  /// Header for a converted regular expression before simplification.
  ///
  /// In en, this message translates to:
  /// **'Converted Regex (Raw)'**
  String get convertedRegexRaw;

  /// Snackbar message shown after copying a regular expression.
  ///
  /// In en, this message translates to:
  /// **'Regex copied to clipboard'**
  String get regexCopiedToClipboard;

  /// Tooltip or button label for copying text to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// Tooltip shown when the simplify output toggle is on.
  ///
  /// In en, this message translates to:
  /// **'Toggle off to see raw output'**
  String get toggleOffRawOutput;

  /// Tooltip shown when the simplify output toggle is off.
  ///
  /// In en, this message translates to:
  /// **'Toggle on to see simplified output'**
  String get toggleOnSimplifiedOutput;

  /// Snackbar message shown before conversion when the regex input is invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid regular expression first'**
  String get enterValidRegexFirst;

  /// Error message shown when regex-to-NFA conversion fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert regex to NFA'**
  String get failedConvertRegexToNfa;

  /// Success message shown after converting a regex to an NFA.
  ///
  /// In en, this message translates to:
  /// **'Converted regex to NFA. View it in the FSA workspace.'**
  String get convertedRegexToNfa;

  /// Error message shown when NFA-to-DFA conversion fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to convert NFA to DFA'**
  String get failedConvertNfaToDfa;

  /// Success message shown after converting a regex through NFA to DFA.
  ///
  /// In en, this message translates to:
  /// **'Converted regex to DFA. Opening the DFA in the FSA workspace.'**
  String get convertedRegexToDfa;

  /// Error message shown when regex simplification fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to simplify regex'**
  String get failedSimplifyRegex;

  /// Error message shown when regex complexity analysis fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to analyze regex'**
  String get failedAnalyzeRegex;

  /// Error message shown when sample string generation fails.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate sample strings'**
  String get failedGenerateSampleStrings;

  /// Title for the regex simplification steps panel.
  ///
  /// In en, this message translates to:
  /// **'Simplification Steps'**
  String get simplificationSteps;

  /// Tooltip or button label for hiding simplification steps.
  ///
  /// In en, this message translates to:
  /// **'Hide steps'**
  String get hideSteps;

  /// Tooltip or button label for showing simplification steps.
  ///
  /// In en, this message translates to:
  /// **'Show steps'**
  String get showSteps;

  /// Button label for running regex simplification with step details.
  ///
  /// In en, this message translates to:
  /// **'Simplify with Steps'**
  String get simplifyWithSteps;

  /// Button label for clearing regex simplification results.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Button label for rerunning regex simplification.
  ///
  /// In en, this message translates to:
  /// **'Re-simplify'**
  String get resimplify;

  /// Label for the original regex value.
  ///
  /// In en, this message translates to:
  /// **'Original:'**
  String get originalLabel;

  /// Label suffix for the number of simplification rules applied.
  ///
  /// In en, this message translates to:
  /// **'rule(s) applied'**
  String get rulesAppliedLabel;

  /// Label for the simplified regex value.
  ///
  /// In en, this message translates to:
  /// **'Simplified:'**
  String get simplifiedLabel;

  /// Snackbar message shown after copying a simplified regex.
  ///
  /// In en, this message translates to:
  /// **'Simplified regex copied to clipboard'**
  String get simplifiedRegexCopiedToClipboard;

  /// Tooltip or button label for copying the simplified regex.
  ///
  /// In en, this message translates to:
  /// **'Copy simplified regex'**
  String get copySimplifiedRegex;

  /// Short status label indicating saved work.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Abbreviation for a character count.
  ///
  /// In en, this message translates to:
  /// **'chars'**
  String get charactersAbbreviation;

  /// Label for the percentage reduction metric.
  ///
  /// In en, this message translates to:
  /// **'Reduction'**
  String get reduction;

  /// Label for elapsed processing time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Label for a simplification step number.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get stepLabel;

  /// Separator label between current and total step counts.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofLabel;

  /// Tooltip or button label for moving to the previous simplification step.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get previousStep;

  /// Tooltip or button label for moving to the next simplification step.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get nextStep;

  /// Header for the list of all simplification steps.
  ///
  /// In en, this message translates to:
  /// **'All Steps:'**
  String get allSteps;

  /// Label for the before-and-after transformation section.
  ///
  /// In en, this message translates to:
  /// **'Transformation'**
  String get transformation;

  /// Label for the expression before a simplification step.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// Label for the expression after a simplification step.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// Label for the simplification rule used by a step.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get rule;

  /// Metric label for regular expression star height.
  ///
  /// In en, this message translates to:
  /// **'Star Height'**
  String get starHeight;

  /// Metric label for regular expression nesting depth.
  ///
  /// In en, this message translates to:
  /// **'Nesting Depth'**
  String get nestingDepth;

  /// Metric label for the number of regex operators.
  ///
  /// In en, this message translates to:
  /// **'Operators'**
  String get operators;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales
      .map((Locale supportedLocale) => supportedLocale.languageCode)
      .contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
