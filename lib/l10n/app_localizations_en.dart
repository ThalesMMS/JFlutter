// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get selectTransition => 'Select transition';

  @override
  String get createNewTransition => 'Create new transition';

  @override
  String get contextAwareHelp => 'Context-Aware Help';

  @override
  String get algorithms => 'Algorithms';

  @override
  String get homeHelpTooltip => 'Help';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeNavigationFsaLabel => 'FSA';

  @override
  String get homeNavigationFsaDescription => 'Finite State Automata';

  @override
  String get homeNavigationGrammarLabel => 'Grammar';

  @override
  String get homeNavigationGrammarDescription => 'Context-Free Grammars';

  @override
  String get homeNavigationPdaLabel => 'PDA';

  @override
  String get homeNavigationPdaDescription => 'Pushdown Automata';

  @override
  String get homeNavigationTmLabel => 'TM';

  @override
  String get homeNavigationTmDescription => 'Turing Machines';

  @override
  String get homeNavigationRegexLabel => 'Regex';

  @override
  String get homeNavigationRegexDescription => 'Regular Expressions';

  @override
  String get homeNavigationPumpingLabel => 'Pumping';

  @override
  String get homeNavigationPumpingDescription => 'Pumping Lemma';

  @override
  String get helpPageTitle => 'Help & Documentation';

  @override
  String get helpSearchTooltip => 'Search Help';

  @override
  String get helpQuickStartTitle => 'Quick Start Guide';

  @override
  String get helpQuickStartBody =>
      'Welcome to JFlutter. Here is a quick way to get started:\n\n'
      '1. Choose a workspace such as FSA, Grammar, PDA, TM, or Regex.\n'
      '2. Start with a blank workspace or open a supported example or file.\n'
      '3. Use the editor to build your machine or grammar. Double-tap a state for quick actions.\n'
      '4. Run simulations to test your work.\n'
      '5. Use algorithms to transform structures.\n\n'
      'Tips:\n'
      '• Use navigation tabs or section chips to switch workspaces quickly.\n'
      '• Double-tap a state to open its quick action menu.\n'
      '• Pinch to zoom on the canvas.\n'
      '• Tap the Quick Start icon whenever you need a refresher.';

  @override
  String get helpGotIt => 'Got it!';

  @override
  String get helpSearchFieldLabel => 'Search help...';

  @override
  String get helpSearchClear => 'Clear search';

  @override
  String get helpSearchClose => 'Close search';

  @override
  String get helpSearchTitle => 'Search Help';

  @override
  String get helpSearchSubtitle =>
      'Find tutorials, shortcuts, and theory explanations';

  @override
  String get helpSearchNoResults => 'No results found';

  @override
  String get helpSearchNoResultsDescription =>
      'Try different keywords or check your spelling';

  @override
  String get helpSectionGettingStarted => 'Getting Started';

  @override
  String get helpSectionFsa => 'FSA';

  @override
  String get helpSectionGrammar => 'Grammar';

  @override
  String get helpSectionPda => 'PDA';

  @override
  String get helpSectionTm => 'Turing Machine';

  @override
  String get helpSectionRegex => 'Regular Expression';

  @override
  String get helpSectionPumping => 'Pumping Lemma';

  @override
  String get helpSectionFileOperations => 'File Operations';

  @override
  String get helpSectionTroubleshooting => 'Troubleshooting';

  @override
  String get helpSectionLicenses => 'Licenses';

  @override
  String get regularExpressionTitle => 'Regular Expression';

  @override
  String get regularExpressionLabel => 'Regular Expression:';

  @override
  String get regularExpressionHint => 'Enter regular expression (e.g., a*b+)';

  @override
  String get validateRegex => 'Validate Regex';

  @override
  String get enterRegexToValidate => 'Enter a regular expression to validate.';

  @override
  String get validRegex => 'Valid regex';

  @override
  String get invalidRegex => 'Invalid regex';

  @override
  String get testStringLabel => 'Test String:';

  @override
  String get testStringHint => 'Enter string to test';

  @override
  String get testStringTooltip => 'Test String';

  @override
  String get matches => 'Matches!';

  @override
  String get doesNotMatch => 'Does not match';

  @override
  String get convertToAutomaton => 'Convert to Automaton:';

  @override
  String get convertToNfa => 'Convert to NFA';

  @override
  String get convertToDfa => 'Convert to DFA';

  @override
  String get simplifyOutput => 'Simplify Output';

  @override
  String get simplifyOutputSubtitle =>
      'Apply algebraic simplifications to converted automata';

  @override
  String get compareRegularExpressions => 'Compare Regular Expressions:';

  @override
  String get comparisonRegexHint => 'Enter second regular expression';

  @override
  String get compareEquivalence => 'Compare Equivalence';

  @override
  String get regexHelp => 'Regex Help';

  @override
  String get regexHelpPatterns =>
      'Common patterns:\n• a* - zero or more a\'s\n• a+ - one or more a\'s\n• a? - zero or one a\n• a|b - a or b\n• (ab)* - zero or more ab\'s\n• [abc] - any of a, b, or c';

  @override
  String get convertedRegexSimplified => 'Converted Regex (Simplified)';

  @override
  String get convertedRegexRaw => 'Converted Regex (Raw)';

  @override
  String get regexCopiedToClipboard => 'Regex copied to clipboard';

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get toggleOffRawOutput => 'Toggle off to see raw output';

  @override
  String get toggleOnSimplifiedOutput => 'Toggle on to see simplified output';

  @override
  String get enterValidRegexFirst =>
      'Please enter a valid regular expression first';

  @override
  String get failedConvertRegexToNfa => 'Failed to convert regex to NFA';

  @override
  String get convertedRegexToNfa =>
      'Converted regex to NFA. View it in the FSA workspace.';

  @override
  String get failedConvertNfaToDfa => 'Failed to convert NFA to DFA';

  @override
  String get convertedRegexToDfa =>
      'Converted regex to DFA. Opening the DFA in the FSA workspace.';

  @override
  String get failedSimplifyRegex => 'Failed to simplify regex';

  @override
  String get failedAnalyzeRegex => 'Failed to analyze regex';

  @override
  String get failedGenerateSampleStrings => 'Failed to generate sample strings';

  @override
  String get simplificationSteps => 'Simplification Steps';

  @override
  String get hideSteps => 'Hide steps';

  @override
  String get showSteps => 'Show steps';

  @override
  String get simplifyWithSteps => 'Simplify with Steps';

  @override
  String get clear => 'Clear';

  @override
  String get resimplify => 'Re-simplify';

  @override
  String get originalLabel => 'Original:';

  @override
  String get rulesAppliedLabel => 'rule(s) applied';

  @override
  String get simplifiedLabel => 'Simplified:';

  @override
  String get simplifiedRegexCopiedToClipboard =>
      'Simplified regex copied to clipboard';

  @override
  String get copySimplifiedRegex => 'Copy simplified regex';

  @override
  String get saved => 'Saved';

  @override
  String get charactersAbbreviation => 'chars';

  @override
  String get reduction => 'Reduction';

  @override
  String get time => 'Time';

  @override
  String get stepLabel => 'Step';

  @override
  String get ofLabel => 'of';

  @override
  String get previousStep => 'Previous step';

  @override
  String get nextStep => 'Next step';

  @override
  String get allSteps => 'All Steps:';

  @override
  String get transformation => 'Transformation';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get rule => 'Rule';

  @override
  String get starHeight => 'Star Height';

  @override
  String get nestingDepth => 'Nesting Depth';

  @override
  String get operators => 'Operators';
}
