import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/fsa.dart';
import '../../core/result.dart';
import '../providers/regex_page_view_model.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/regex/regex_conversion_actions.dart';
import '../widgets/regex/regex_equivalence_section.dart';
import '../widgets/regex/regex_help_card.dart';
import '../widgets/regex/regex_input_form.dart';
import '../widgets/regex/regex_test_section.dart';
import '../widgets/simulation_panel.dart';
import 'fsa_page.dart';

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
  ProviderSubscription<RegexPageState>? _subscription;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(regexPageViewModelProvider);
    _syncControllers(initialState);
    _subscription = ref.listen<RegexPageState>(
      regexPageViewModelProvider,
      (previous, next) => _syncControllers(next),
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _regexController.dispose();
    _testStringController.dispose();
    _comparisonRegexController.dispose();
    super.dispose();
  }

  void _syncControllers(RegexPageState state) {
    if (_regexController.text != state.regexInput) {
      _regexController.value = TextEditingValue(
        text: state.regexInput,
        selection: TextSelection.collapsed(offset: state.regexInput.length),
      );
    }
    if (_testStringController.text != state.testString) {
      _testStringController.value = TextEditingValue(
        text: state.testString,
        selection: TextSelection.collapsed(offset: state.testString.length),
      );
    }
    if (_comparisonRegexController.text != state.comparisonRegex) {
      _comparisonRegexController.value = TextEditingValue(
        text: state.comparisonRegex,
        selection:
            TextSelection.collapsed(offset: state.comparisonRegex.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(regexPageViewModelProvider);
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return isMobile ? _buildMobileLayout(state) : _buildDesktopLayout(state);
  }

  Widget _buildMobileLayout(RegexPageState state) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regular Expression',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildMainContent(state),
            const SizedBox(height: 24),
            const RegexHelpCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(RegexPageState state) {
    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regular Expression',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildMainContent(state),
                  const SizedBox(height: 24),
                  const RegexHelpCard(),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: AlgorithmPanel(
                      onNfaToDfa: _handleConvertToDfa,
                      onMinimizeDfa: null,
                      onClear: _clearInputs,
                      onRegexToNfa: (regex) {
                        _regexController.text = regex;
                        final notifier =
                            ref.read(regexPageViewModelProvider.notifier);
                        notifier.updateRegexInput(regex);
                        notifier.validateRegex();
                        final result = notifier.convertToNfa();
                        _showConversionMessage(
                          result,
                          successMessage:
                              'Converted regex to NFA. View it in the FSA workspace.',
                        );
                      },
                      onFaToRegex: null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SimulationPanel(
                      onSimulate: (input) {
                        final notifier =
                            ref.read(regexPageViewModelProvider.notifier);
                        notifier.updateTestString(input);
                        notifier.testStringMatch();
                      },
                      simulationResult: state.simulationResult,
                      regexResult: state.matchMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(RegexPageState state) {
    final notifier = ref.read(regexPageViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RegexInputForm(
          controller: _regexController,
          isValid: state.isValid,
          validationMessage: state.validationMessage,
          onChanged: notifier.updateRegexInput,
          onValidate: () {
            final result = notifier.validateRegex();
            if (!result.isSuccess && _regexController.text.isNotEmpty) {
              _showSnackBar(
                result.error ?? 'Invalid regular expression',
                isError: true,
              );
            }
          },
        ),
        const SizedBox(height: 24),
        RegexTestSection(
          controller: _testStringController,
          matchResult: state.matchResult,
          matchMessage: state.matchMessage,
          onChanged: (value) {
            notifier.updateTestString(value);
            if (value.isNotEmpty) {
              notifier.testStringMatch();
            }
          },
          onTest: () {
            notifier.updateTestString(_testStringController.text);
            final result = notifier.testStringMatch();
            if (!result.isSuccess && _testStringController.text.isNotEmpty) {
              _showSnackBar(
                result.error ?? 'Failed to test string',
                isError: true,
              );
            }
          },
        ),
        const SizedBox(height: 24),
        RegexConversionActions(
          enableConversion: state.regexInput.trim().isNotEmpty,
          onConvertToNfa: _handleConvertToNfa,
          onConvertToDfa: _handleConvertToDfa,
        ),
        const SizedBox(height: 24),
        RegexEquivalenceSection(
          controller: _comparisonRegexController,
          equivalenceResult: state.equivalenceResult,
          equivalenceMessage: state.equivalenceMessage,
          onChanged: notifier.updateComparisonRegex,
          onCompare: () {
            notifier.updateComparisonRegex(_comparisonRegexController.text);
            final result = notifier.compareEquivalence();
            if (!result.isSuccess) {
              _showSnackBar(result.error ?? 'Failed to compare', isError: true);
            }
          },
        ),
      ],
    );
  }

  void _handleConvertToNfa() {
    final notifier = ref.read(regexPageViewModelProvider.notifier);
    final result = notifier.convertToNfa();
    _showConversionMessage(
      result,
      successMessage:
          'Converted regex to NFA. View it in the FSA workspace.',
    );
  }

  void _handleConvertToDfa() {
    final notifier = ref.read(regexPageViewModelProvider.notifier);
    final result = notifier.convertToDfa();
    if (result.isSuccess) {
      _showSnackBar(
        'Converted regex to DFA. Opening the DFA in the FSA workspace.',
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const FSAPage()),
      );
    } else {
      _showSnackBar(
        result.error ?? 'Failed to convert regex to DFA',
        isError: true,
      );
    }
  }

  void _showConversionMessage(
    Result<FSA> result, {
    required String successMessage,
  }) {
    if (result.isSuccess) {
      _showSnackBar(successMessage);
    } else {
      _showSnackBar(
        result.error ?? 'Failed to convert regular expression',
        isError: true,
      );
    }
  }

  void _clearInputs() {
    ref.read(regexPageViewModelProvider.notifier).clearAll();
    _regexController.clear();
    _testStringController.clear();
    _comparisonRegexController.clear();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }
}
