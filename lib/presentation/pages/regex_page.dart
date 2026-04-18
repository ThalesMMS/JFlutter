//
//  regex_page.dart
//  JFlutter
//
//  Centraliza as ferramentas de expressões regulares permitindo validar,
//  simular e converter padrões em autômatos, reutilizando algoritmos do núcleo
//  para checar equivalência, aceitação de cadeias e sincronizar resultados com
//  o provedor de autômatos ativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/automaton_simulator.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_analyzer.dart';
import '../../core/algorithms/regex_simplifier.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../../core/models/regex_analysis.dart';
import '../../core/models/regex_simplification_step.dart';
import '../../l10n/app_localizations.dart';
import '../providers/automaton_algorithm_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/help_provider.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/context_aware_help_panel.dart';
import '../widgets/simulation_panel.dart';
import '../widgets/tablet_layout_container.dart';
import 'fsa_page.dart';

part 'regex_page_layout.dart';
part 'regex_page_simplification.dart';
part 'regex_page_complexity.dart';
part 'regex_page_samples.dart';

/// Regular Expression page for testing and converting regular expressions
class RegexPage extends ConsumerStatefulWidget {
  const RegexPage({super.key});

  @override
  ConsumerState<RegexPage> createState() => _RegexPageState();
}

class _RegexPageState extends ConsumerState<RegexPage> {
  final TextEditingController _regexController = TextEditingController();
  final TextEditingController _testStringController = TextEditingController();
  final TextEditingController _comparisonRegexController =
      TextEditingController();
  String _currentRegex = '';
  String _testString = '';
  bool _isValid = false;
  bool _matches = false;
  bool _hasTested = false;
  String _errorMessage = '';
  bool? _equivalenceResult;
  String _equivalenceMessage = '';
  bool _simplifyOutput = true;
  RegexSimplificationResult? _simplificationResult;
  bool _showSimplificationSteps = false;
  int _selectedStepIndex = 0;
  RegexAnalysis? _regexAnalysis;
  bool _showAnalysisDetails = false;
  RegexSampleStrings? _sampleStrings;
  bool _showSampleStringsDetails = false;

  @override
  void dispose() {
    _regexController.dispose();
    _testStringController.dispose();
    _comparisonRegexController.dispose();
    super.dispose();
  }

  void _validateRegex() {
    setState(() {
      _currentRegex = _regexController.text;
      _errorMessage = '';
      _hasTested = false;

      if (_currentRegex.isEmpty) {
        _isValid = false;
        return;
      }

      try {
        // Basic regex validation - check for balanced parentheses and valid characters
        if (_isValidRegex(_currentRegex)) {
          _isValid = true;
        } else {
          _isValid = false;
          _errorMessage = 'Invalid regular expression syntax';
        }
      } catch (e) {
        _isValid = false;
        _errorMessage = 'Invalid regular expression: $e';
      }
    });
  }

  bool _isValidRegex(String regex) {
    // Basic validation for common regex patterns
    // This is a simplified validation - in a real implementation,
    // you would use a proper regex parser
    int parenCount = 0;
    bool inBracket = false;
    bool escapeNext = false;

    for (int i = 0; i < regex.length; i++) {
      final char = regex[i];

      if (escapeNext) {
        escapeNext = false;
        continue;
      }

      if (char == '\\') {
        escapeNext = true;
        continue;
      }

      if (char == '[' && !escapeNext) {
        inBracket = true;
        continue;
      }

      if (char == ']' && !escapeNext) {
        inBracket = false;
        continue;
      }

      if (!inBracket) {
        if (char == '(') {
          parenCount++;
        } else if (char == ')') {
          parenCount--;
          if (parenCount < 0) return false;
        }
      }
    }

    return parenCount == 0 && !inBracket;
  }

  Future<void> _testStringMatch() async {
    setState(() {
      _testString = _testStringController.text;
      _errorMessage = '';
      _hasTested = true;

      if (!_isValid || _currentRegex.isEmpty) {
        _matches = false;
        return;
      }
    });

    if (!_isValid || _currentRegex.isEmpty) {
      return;
    }

    try {
      final conversionResult = RegexToNFAConverter.convert(_currentRegex);
      if (!conversionResult.isSuccess || conversionResult.data == null) {
        setState(() {
          _matches = false;
          _errorMessage =
              conversionResult.error ?? 'Unable to convert regex to NFA';
        });
        return;
      }

      final simulationResult = await AutomatonSimulator.simulateNFA(
        conversionResult.data!,
        _testString,
      );

      setState(() {
        if (simulationResult.isSuccess && simulationResult.data != null) {
          _matches = simulationResult.data!.isAccepted;
          if (!_matches && simulationResult.data!.errorMessage.isNotEmpty) {
            _errorMessage = simulationResult.data!.errorMessage;
          }
        } else {
          _matches = false;
          _errorMessage =
              simulationResult.error ?? 'Failed to simulate automaton';
        }
      });
    } catch (e) {
      setState(() {
        _matches = false;
        _errorMessage = 'Error testing string: $e';
      });
    }
  }

  void _convertToNFA() {
    final l10n = AppLocalizations.of(context);

    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidRegexFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexToNFAConverter.convert(_currentRegex);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? l10n.failedConvertRegexToNfa),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _pushAutomatonToProvider(result.data!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.convertedRegexToNfa),
      ),
    );
  }

  void _convertToDFA() {
    final l10n = AppLocalizations.of(context);

    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidRegexFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final regexToNfaResult = RegexToNFAConverter.convert(_currentRegex);
    if (!regexToNfaResult.isSuccess || regexToNfaResult.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            regexToNfaResult.error ?? l10n.failedConvertRegexToNfa,
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final nfa = regexToNfaResult.data!;
    final nfaToDfaResult = NFAToDFAConverter.convert(nfa);
    if (!nfaToDfaResult.isSuccess || nfaToDfaResult.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nfaToDfaResult.error ?? l10n.failedConvertNfaToDfa),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final completedDfa = DFACompleter.complete(nfaToDfaResult.data!);
    _pushAutomatonToProvider(completedDfa);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.convertedRegexToDfa),
      ),
    );

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FSAPage()));
  }

  void _pushAutomatonToProvider(FSA automaton) {
    ref.read(automatonStateProvider.notifier).updateAutomaton(automaton);
  }

  void _compareRegexEquivalence() {
    final primary = _regexController.text.trim();
    final secondary = _comparisonRegexController.text.trim();

    setState(() {
      _equivalenceResult = null;
      _equivalenceMessage = '';
    });

    if (primary.isEmpty || secondary.isEmpty) {
      setState(() {
        _equivalenceResult = false;
        _equivalenceMessage = 'Enter both regular expressions to compare.';
      });
      return;
    }

    try {
      final firstConversion = RegexToNFAConverter.convert(primary);
      if (!firstConversion.isSuccess || firstConversion.data == null) {
        setState(() {
          _equivalenceResult = false;
          _equivalenceMessage =
              firstConversion.error ?? 'Unable to convert first regex to NFA';
        });
        return;
      }

      final secondConversion = RegexToNFAConverter.convert(secondary);
      if (!secondConversion.isSuccess || secondConversion.data == null) {
        setState(() {
          _equivalenceResult = false;
          _equivalenceMessage =
              secondConversion.error ?? 'Unable to convert second regex to NFA';
        });
        return;
      }

      final firstDfaResult = NFAToDFAConverter.convert(firstConversion.data!);
      if (!firstDfaResult.isSuccess || firstDfaResult.data == null) {
        setState(() {
          _equivalenceResult = false;
          _equivalenceMessage =
              firstDfaResult.error ?? 'Unable to convert first regex to DFA';
        });
        return;
      }

      final secondDfaResult = NFAToDFAConverter.convert(secondConversion.data!);
      if (!secondDfaResult.isSuccess || secondDfaResult.data == null) {
        setState(() {
          _equivalenceResult = false;
          _equivalenceMessage =
              secondDfaResult.error ?? 'Unable to convert second regex to DFA';
        });
        return;
      }

      final completedFirst = DFACompleter.complete(firstDfaResult.data!);
      final completedSecond = DFACompleter.complete(secondDfaResult.data!);

      final equivalent = EquivalenceChecker.areEquivalent(
        completedFirst,
        completedSecond,
      );

      setState(() {
        _equivalenceResult = equivalent;
        _equivalenceMessage = equivalent
            ? 'The regular expressions are equivalent.'
            : 'The regular expressions are not equivalent.';
      });
    } catch (e) {
      setState(() {
        _equivalenceResult = false;
        _equivalenceMessage = 'Error comparing regular expressions: $e';
      });
    }
  }

  void _showContextualHelp() {
    final helpNotifier = ref.read(helpProvider.notifier);

    // Determine the most relevant help content based on current regex state
    String helpContextId;
    if (_currentRegex.isNotEmpty && _isValid) {
      // Show conversion help if user has a valid regex
      helpContextId = 'algo_regex_to_nfa';
    } else {
      // Default: show general regex concepts
      helpContextId = 'concept_regex';
    }

    final helpContent = helpNotifier.getHelpByContext(helpContextId);
    if (helpContent != null) {
      ContextAwareHelpPanel.show(context, helpContent: helpContent);
    }
  }

  void _runSimplificationWithSteps() {
    final l10n = AppLocalizations.of(context);

    if (!_isValid || _currentRegex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidRegexFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexSimplifier.simplifyWithSteps(_currentRegex);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? l10n.failedSimplifyRegex),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _simplificationResult = result.data;
      _showSimplificationSteps = true;
      _selectedStepIndex = 0;
    });
  }

  void _runComplexityAnalysis() {
    final l10n = AppLocalizations.of(context);

    if (!_isValid || _currentRegex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidRegexFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexAnalyzer.analyze(_currentRegex);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? l10n.failedAnalyzeRegex),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _regexAnalysis = result.data;
      _showAnalysisDetails = true;
    });
  }

  void _runSampleGeneration({int maxSamples = 10}) {
    final l10n = AppLocalizations.of(context);

    if (!_isValid || _currentRegex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidRegexFirst),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexAnalyzer.generateSampleStrings(
      _currentRegex,
      maxSamples: maxSamples,
      maxLength: 30,
    );
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? l10n.failedGenerateSampleStrings),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _sampleStrings = result.data;
      _showSampleStringsDetails = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch algorithm provider to get FA→Regex conversion results
    final algorithmState = ref.watch(automatonAlgorithmProvider);

    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1400;

    if (isMobile) {
      return _buildMobileLayout(algorithmState);
    } else if (isTablet) {
      return _buildTabletLayout(algorithmState);
    } else {
      return _buildDesktopLayout(algorithmState);
    }
  }
}
