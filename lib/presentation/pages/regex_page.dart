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
import '../providers/automaton_algorithm_provider.dart';
import '../providers/automaton_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/simulation_panel.dart';
import '../widgets/tablet_layout_container.dart';
import 'fsa_page.dart';

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
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid regular expression first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexToNFAConverter.convert(_currentRegex);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to convert regex to NFA'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _pushAutomatonToProvider(result.data!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Converted regex to NFA. View it in the FSA workspace.'),
      ),
    );
  }

  void _convertToDFA() {
    if (!_isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid regular expression first'),
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
            regexToNfaResult.error ?? 'Failed to convert regex to NFA',
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
          content: Text(nfaToDfaResult.error ?? 'Failed to convert NFA to DFA'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final completedDfa = DFACompleter.complete(nfaToDfaResult.data!);
    _pushAutomatonToProvider(completedDfa);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Converted regex to DFA. Opening the DFA in the FSA workspace.',
        ),
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

  void _runSimplificationWithSteps() {
    if (!_isValid || _currentRegex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid regular expression first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexSimplifier.simplifyWithSteps(_currentRegex);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to simplify regex'),
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
    if (!_isValid || _currentRegex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid regular expression first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = RegexAnalyzer.analyze(_currentRegex);
    if (!result.isSuccess || result.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to analyze regex'),
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
    if (!_isValid || _currentRegex.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid regular expression first'),
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
          content: Text(result.error ?? 'Failed to generate sample strings'),
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

  Widget _buildMobileLayout(AlgorithmOperationState algorithmState) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Regular Expression',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Regex input
            Text(
              'Regular Expression:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _regexController,
              decoration: InputDecoration(
                hintText: 'Enter regular expression (e.g., a*b+)',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _validateRegex,
                  icon: const Icon(Icons.check),
                  tooltip: 'Validate Regex',
                ),
              ),
              onChanged: (value) => _validateRegex(),
            ),

            // Validation status
            const SizedBox(height: 8),
            if (_currentRegex.isEmpty)
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enter a regular expression to validate.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Icon(
                    _isValid ? Icons.check_circle : Icons.error,
                    color: _isValid ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isValid
                          ? 'Valid regex'
                          : (_errorMessage.isNotEmpty
                                ? _errorMessage
                                : 'Invalid regex'),
                      style: TextStyle(
                        color: _isValid ? Colors.green : Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Test string input
            Text(
              'Test String:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testStringController,
              decoration: InputDecoration(
                hintText: 'Enter string to test',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: _testStringMatch,
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Test String',
                ),
              ),
              onChanged: (value) => _testStringMatch(),
            ),

            // Match result
            const SizedBox(height: 8),
            if (_testString.isNotEmpty)
              Row(
                children: [
                  Icon(
                    _matches ? Icons.check_circle : Icons.cancel,
                    color: _matches ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _matches ? 'Matches!' : 'Does not match',
                    style: TextStyle(
                      color: _matches ? Colors.green : Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Conversion buttons
            Text(
              'Convert to Automaton:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _convertToNFA,
                    icon: const Icon(Icons.account_tree),
                    label: const Text('Convert to NFA'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _convertToDFA,
                    icon: const Icon(Icons.account_tree_outlined),
                    label: const Text('Convert to DFA'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // FA→Regex conversion result display
            if (_buildFaToRegexResult(algorithmState) != null) ...[
              _buildFaToRegexResult(algorithmState)!,
              const SizedBox(height: 16),
            ],

            // Simplification toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildSwitchSetting(
                  'Simplify Output',
                  'Apply algebraic simplifications to converted automata',
                  _simplifyOutput,
                  (value) {
                    setState(() {
                      _simplifyOutput = value;
                    });
                  },
                  switchKey: const ValueKey('regex_simplify_output_switch'),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Simplification steps section
            _buildSimplificationStepsSection(),

            const SizedBox(height: 16),

            // Complexity analysis section
            _buildComplexityAnalysisSection(),

            const SizedBox(height: 16),

            // Sample strings section
            _buildSampleStringsSection(),

            const SizedBox(height: 24),

            // Compare regular expressions
            Text(
              'Compare Regular Expressions:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comparisonRegexController,
              decoration: const InputDecoration(
                hintText: 'Enter second regular expression',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _compareRegexEquivalence,
                icon: const Icon(Icons.compare_arrows),
                label: const Text('Compare Equivalence'),
              ),
            ),
            if (_equivalenceMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    _equivalenceResult == true
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: _equivalenceResult == true
                        ? Colors.green
                        : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _equivalenceMessage,
                      style: TextStyle(
                        color: _equivalenceResult == true
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 14,
                        fontWeight: _equivalenceResult == true
                            ? FontWeight.bold
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Help section
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regex Help',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Common patterns:\n'
                        '• a* - zero or more a\'s\n'
                        '• a+ - one or more a\'s\n'
                        '• a? - zero or one a\n'
                        '• a|b - a or b\n'
                        '• (ab)* - zero or more ab\'s\n'
                        '• [abc] - any of a, b, or c',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(AlgorithmOperationState algorithmState) {
    return Scaffold(
      body: Row(
        children: [
          // Left panel - Regex input and testing
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: SingleChildScrollView(
                child: _buildInputArea(algorithmState),
              ),
            ),
          ),

          // Right panel - Algorithm operations
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Algorithms',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Algorithm panel
                  Expanded(
                    child: AlgorithmPanel(
                      onNfaToDfa: _convertToDFA,
                      onMinimizeDfa: null,
                      onClear: _clearInputs,
                      onRegexToNfa: (regex) {
                        _regexController.text = regex;
                        _validateRegex();
                        _convertToNFA();
                      },
                      onFaToRegex: null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Simulation panel
                  Expanded(
                    child: SimulationPanel(
                      onSimulate: (input) {
                        _testStringController.text = input;
                        _testStringMatch();
                      },
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

  Widget _buildTabletLayout(AlgorithmOperationState algorithmState) {
    return Scaffold(
      body: TabletLayoutContainer(
        canvas: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildInputArea(algorithmState),
        ),
        algorithmPanel: AlgorithmPanel(
          onNfaToDfa: _convertToDFA,
          onMinimizeDfa: null,
          onClear: _clearInputs,
          onRegexToNfa: (regex) {
            _regexController.text = regex;
            _validateRegex();
            _convertToNFA();
          },
          onFaToRegex: null,
        ),
        simulationPanel: SimulationPanel(
          onSimulate: (input) {
            _testStringController.text = input;
            _testStringMatch();
          },
        ),
      ),
    );
  }

  Widget _buildInputArea(AlgorithmOperationState algorithmState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regular Expression',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Regex input
        Text(
          'Regular Expression:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _regexController,
          decoration: InputDecoration(
            hintText: 'Enter regular expression (e.g., a*b+)',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _validateRegex,
              icon: const Icon(Icons.check),
              tooltip: 'Validate Regex',
            ),
          ),
          onChanged: (value) => _validateRegex(),
        ),

        // Validation status
        const SizedBox(height: 8),
        if (_currentRegex.isEmpty)
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Enter a regular expression to validate.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Icon(
                _isValid ? Icons.check_circle : Icons.error,
                color: _isValid ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isValid
                      ? 'Valid regex'
                      : (_errorMessage.isNotEmpty
                            ? _errorMessage
                            : 'Invalid regex'),
                  style: TextStyle(
                    color: _isValid ? Colors.green : Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Test string input
        Text('Test String:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: _testStringController,
          decoration: InputDecoration(
            hintText: 'Enter string to test',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              onPressed: _testStringMatch,
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Test String',
              // tooltip: 'Test String', // Duplicate removed
            ),
          ),
          onChanged: (value) => _testStringMatch(),
        ),

        // Match result
        const SizedBox(height: 8),
        if (_testString.isNotEmpty)
          Row(
            children: [
              Icon(
                _matches ? Icons.check_circle : Icons.cancel,
                color: _matches ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _matches ? 'Matches!' : 'Does not match',
                style: TextStyle(
                  color: _matches ? Colors.green : Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

        const SizedBox(height: 24),

        // Conversion buttons
        Text(
          'Convert to Automaton:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _convertToNFA,
                icon: const Icon(Icons.account_tree),
                label: const Text('Convert to NFA'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _convertToDFA,
                icon: const Icon(Icons.account_tree_outlined),
                label: const Text('Convert to DFA'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // FA→Regex conversion result display
        if (_buildFaToRegexResult(algorithmState) != null) ...[
          _buildFaToRegexResult(algorithmState)!,
          const SizedBox(height: 16),
        ],

        // Simplification toggle
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildSwitchSetting(
              'Simplify Output',
              'Apply algebraic simplifications to converted automata',
              _simplifyOutput,
              (value) {
                setState(() {
                  _simplifyOutput = value;
                });
              },
              switchKey: const ValueKey('regex_simplify_output_switch'),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Simplification steps section
        _buildSimplificationStepsSection(),

        const SizedBox(height: 16),

        // Complexity analysis section
        _buildComplexityAnalysisSection(),

        const SizedBox(height: 16),

        // Sample strings section
        _buildSampleStringsSection(),

        const SizedBox(height: 24),

        // Compare regular expressions
        Text(
          'Compare Regular Expressions:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _comparisonRegexController,
          decoration: const InputDecoration(
            hintText: 'Enter second regular expression',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: ElevatedButton.icon(
            onPressed: _compareRegexEquivalence,
            icon: const Icon(Icons.compare_arrows),
            label: const Text('Compare Equivalence'),
          ),
        ),
        if (_equivalenceMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                _equivalenceResult == true
                    ? Icons.check_circle
                    : Icons.error_outline,
                color: _equivalenceResult == true
                    ? Colors.green
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _equivalenceMessage,
                  style: TextStyle(
                    color: _equivalenceResult == true
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 14,
                    fontWeight: _equivalenceResult == true
                        ? FontWeight.bold
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 24),

        // Help section
        SizedBox(
          width: double.infinity,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regex Help',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Common patterns:\n'
                    '• a* - zero or more a\'s\n'
                    '• a+ - one or more a\'s\n'
                    '• a? - zero or one a\n'
                    '• a|b - a or b\n'
                    '• (ab)* - zero or more ab\'s\n'
                    '• [abc] - any of a, b, or c',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _clearInputs() {
    _regexController.clear();
    _testStringController.clear();
    _comparisonRegexController.clear();
    setState(() {
      _currentRegex = '';
      _testString = '';
      _isValid = false;
      _matches = false;
      _errorMessage = '';
      _equivalenceResult = null;
      _equivalenceMessage = '';
      _simplificationResult = null;
      _showSimplificationSteps = false;
      _selectedStepIndex = 0;
      _regexAnalysis = null;
      _showAnalysisDetails = false;
      _sampleStrings = null;
      _showSampleStringsDetails = false;
    });
  }

  Widget? _buildFaToRegexResult(AlgorithmOperationState algorithmState) {
    // Only show if we have conversion results
    if (algorithmState.rawRegexResult == null &&
        algorithmState.simplifiedRegexResult == null) {
      return null;
    }

    final displayedRegex = _simplifyOutput
        ? algorithmState.simplifiedRegexResult
        : algorithmState.rawRegexResult;

    if (displayedRegex == null) return null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Converted Regex ${_simplifyOutput ? '(Simplified)' : '(Raw)'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: displayedRegex));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Regex copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: SelectableText(
                displayedRegex,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (algorithmState.rawRegexResult != null &&
                algorithmState.simplifiedRegexResult != null &&
                algorithmState.rawRegexResult !=
                    algorithmState.simplifiedRegexResult)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _simplifyOutput
                      ? 'Toggle off to see raw output'
                      : 'Toggle on to see simplified output',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged, {
    Key? switchKey,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        Switch(key: switchKey, value: value, onChanged: onChanged),
      ],
    );
  }

  /// Builds the simplification steps display section
  Widget _buildSimplificationStepsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and action buttons
            Row(
              children: [
                Icon(
                  Icons.auto_fix_high,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Simplification Steps',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_simplificationResult != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSimplificationSteps = !_showSimplificationSteps;
                      });
                    },
                    icon: Icon(
                      _showSimplificationSteps
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: _showSimplificationSteps
                        ? 'Hide steps'
                        : 'Show steps',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Simplify button
            if (_simplificationResult == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runSimplificationWithSteps,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Simplify with Steps'),
                ),
              )
            else ...[
              // Summary section
              _buildSimplificationSummary(),
              const SizedBox(height: 12),

              // Expandable steps list
              if (_showSimplificationSteps) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildStepsList(),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _simplificationResult = null;
                        _showSimplificationSteps = false;
                        _selectedStepIndex = 0;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _runSimplificationWithSteps,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('Re-simplify'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the simplification summary showing original vs simplified
  Widget _buildSimplificationSummary() {
    final result = _simplificationResult;
    if (result == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original regex
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Original:',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  result.originalRegex,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Arrow indicating transformation
          Row(
            children: [
              const SizedBox(width: 80),
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                '${result.totalRulesApplied} rule(s) applied',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Simplified regex
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  'Simplified:',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  result.simplifiedRegex,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: result.madeProgress
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: result.madeProgress
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (result.madeProgress)
                IconButton(
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: result.simplifiedRegex),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simplified regex copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: 'Copy simplified regex',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Stats
          if (result.madeProgress) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  'Saved',
                  '${result.charactersSaved} chars',
                  Icons.compress,
                  colorScheme.tertiary,
                ),
                _buildStatChip(
                  'Reduction',
                  '${result.reductionPercentage.toStringAsFixed(1)}%',
                  Icons.trending_down,
                  colorScheme.secondary,
                ),
                _buildStatChip(
                  'Time',
                  '${result.executionTimeMs}ms',
                  Icons.timer_outlined,
                  colorScheme.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a small stat chip widget
  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of simplification steps
  Widget _buildStepsList() {
    final result = _simplificationResult;
    if (result == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step navigation
        if (result.steps.length > 1) ...[
          Row(
            children: [
              Text(
                'Step ${_selectedStepIndex + 1} of ${result.steps.length}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _selectedStepIndex > 0
                    ? () => setState(() => _selectedStepIndex--)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous step',
              ),
              IconButton(
                onPressed: _selectedStepIndex < result.steps.length - 1
                    ? () => setState(() => _selectedStepIndex++)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next step',
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Current step detail
        if (result.steps.isNotEmpty)
          _buildStepCard(result.steps[_selectedStepIndex]),

        const SizedBox(height: 12),

        // Step timeline
        Text(
          'All Steps:',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        ...result.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isSelected = index == _selectedStepIndex;
          return _buildStepTimelineItem(step, index, isSelected);
        }),
      ],
    );
  }

  /// Builds a detailed card for a single step
  Widget _buildStepCard(RegexSimplificationStep step) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Step ${step.stepNumber}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Step type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  step.stepType.displayName,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Explanation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.explanation,
                    style: textTheme.bodySmall?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Rule application details
          if (step.appliesRule && step.ruleApplied != null) ...[
            const SizedBox(height: 12),
            _buildRuleApplicationDetails(step),
          ],

          // Complexity metrics
          if (step.starHeight != null || step.nestingDepth != null) ...[
            const SizedBox(height: 12),
            _buildComplexityMetrics(step),
          ],
        ],
      ),
    );
  }

  /// Builds the rule application details section
  Widget _buildRuleApplicationDetails(RegexSimplificationStep step) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: colorScheme.tertiary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                size: 16,
                color: colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Text(
                'Transformation',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Before -> After display
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Before',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        step.matchedSubexpression ?? step.originalRegex ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'After',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        step.replacementSubexpression ??
                            step.simplifiedRegex ??
                            '',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Rule formal notation
          if (step.ruleApplied != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'Rule: ${step.ruleApplied!.formalNotation}',
                style: textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the complexity metrics section
  Widget _buildComplexityMetrics(RegexSimplificationStep step) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (step.starHeight != null)
          _buildMetricBadge(
            'Star Height',
            step.starHeight.toString(),
            Icons.star_outline,
            colorScheme,
            textTheme,
          ),
        if (step.nestingDepth != null)
          _buildMetricBadge(
            'Nesting Depth',
            step.nestingDepth.toString(),
            Icons.layers_outlined,
            colorScheme,
            textTheme,
          ),
        if (step.operatorCount != null)
          _buildMetricBadge(
            'Operators',
            step.operatorCount.toString(),
            Icons.functions,
            colorScheme,
            textTheme,
          ),
      ],
    );
  }

  /// Builds a metric badge widget
  Widget _buildMetricBadge(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a timeline item for a step
  Widget _buildStepTimelineItem(
    RegexSimplificationStep step,
    int index,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => setState(() => _selectedStepIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            // Step number circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  '${step.stepNumber}',
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Step title
            Expanded(
              child: Text(
                step.title,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Rule indicator for applyRule steps
            if (step.appliesRule)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  step.ruleApplied?.formalNotation ?? '',
                  style: textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the complexity analysis display section
  Widget _buildComplexityAnalysisSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and action buttons
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Complexity Analysis',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_regexAnalysis != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showAnalysisDetails = !_showAnalysisDetails;
                      });
                    },
                    icon: Icon(
                      _showAnalysisDetails
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: _showAnalysisDetails
                        ? 'Hide details'
                        : 'Show details',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Analyze button
            if (_regexAnalysis == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runComplexityAnalysis,
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Analyze Complexity'),
                ),
              )
            else ...[
              // Analysis summary with complexity level
              _buildComplexityLevelIndicator(),
              const SizedBox(height: 12),

              // Expandable details
              if (_showAnalysisDetails) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildComplexityDetails(),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _regexAnalysis = null;
                        _showAnalysisDetails = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _runComplexityAnalysis,
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: const Text('Re-analyze'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the complexity level indicator with color coding
  Widget _buildComplexityLevelIndicator() {
    final analysis = _regexAnalysis;
    if (analysis == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get color based on complexity level
    final levelColor = _getComplexityColor(analysis.complexityLevel);
    final levelIcon = _getComplexityIcon(analysis.complexityLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: levelColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: levelColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Complexity level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: levelColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  levelIcon,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  analysis.complexityLevel.displayName,
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Key metrics summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  analysis.complexityLevel.description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildMiniMetric(
                      'Star Height',
                      analysis.starHeight.toString(),
                      Icons.star_outline,
                    ),
                    _buildMiniMetric(
                      'Nesting',
                      analysis.nestingDepth.toString(),
                      Icons.layers_outlined,
                    ),
                    _buildMiniMetric(
                      'Alphabet',
                      analysis.alphabetSize.toString(),
                      Icons.abc,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a mini metric display
  Widget _buildMiniMetric(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Builds the detailed complexity analysis view
  Widget _buildComplexityDetails() {
    final analysis = _regexAnalysis;
    if (analysis == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Complexity metrics section
        Text(
          'Complexity Metrics',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Star Height',
          analysis.starHeight.toString(),
          'Maximum nesting of Kleene star operators (*)',
          Icons.star_outline,
          colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Nesting Depth',
          analysis.nestingDepth.toString(),
          'Maximum depth of parentheses nesting',
          Icons.layers_outlined,
          colorScheme.secondary,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          'Complexity Score',
          analysis.complexityScore.toString(),
          'Weighted sum of all complexity factors',
          Icons.speed,
          colorScheme.tertiary,
        ),

        const SizedBox(height: 16),

        // Operator breakdown section
        Text(
          'Operator Breakdown',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildOperatorBreakdown(analysis),

        const SizedBox(height: 16),

        // Alphabet section
        Text(
          'Alphabet',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildAlphabetDisplay(analysis),
      ],
    );
  }

  /// Builds a metric row with label, value, description, and icon
  Widget _buildMetricRow(
    String label,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the operator breakdown display
  Widget _buildOperatorBreakdown(RegexAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final structure = analysis.structureAnalysis;

    final operators = [
      ('Union (|)', structure.unionCount, Icons.call_split),
      ('Concatenation', structure.concatenationCount, Icons.link),
      ('Kleene Star (*)', structure.starCount, Icons.star),
      ('Plus (+)', structure.plusCount, Icons.add),
      ('Optional (?)', structure.questionCount, Icons.help_outline),
    ];

    // Filter to only show operators that are used
    final usedOperators = operators.where((op) => op.$2 > 0).toList();

    if (usedOperators.isEmpty) {
      return Text(
        'No operators used (literal expression)',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: usedOperators.map((op) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(op.$3, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                op.$1,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${op.$2}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds the alphabet display
  Widget _buildAlphabetDisplay(RegexAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alphabet = analysis.structureAnalysis.alphabet;

    if (alphabet.isEmpty) {
      return Text(
        'Empty alphabet (epsilon-only expression)',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Sort alphabet for consistent display
    final sortedAlphabet = alphabet.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Size: ${alphabet.length} symbol(s)',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sortedAlphabet.map((symbol) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  symbol,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Gets the color for a complexity level
  Color _getComplexityColor(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.simple:
        return Colors.green;
      case ComplexityLevel.moderate:
        return Colors.orange;
      case ComplexityLevel.complex:
        return Colors.red;
    }
  }

  /// Gets the icon for a complexity level
  IconData _getComplexityIcon(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.simple:
        return Icons.check_circle;
      case ComplexityLevel.moderate:
        return Icons.warning;
      case ComplexityLevel.complex:
        return Icons.error;
    }
  }

  /// Builds the sample strings display section
  Widget _buildSampleStringsSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and action buttons
            Row(
              children: [
                Icon(
                  Icons.text_snippet_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sample Strings',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_sampleStrings != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _showSampleStringsDetails = !_showSampleStringsDetails;
                      });
                    },
                    icon: Icon(
                      _showSampleStringsDetails
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: _showSampleStringsDetails
                        ? 'Hide samples'
                        : 'Show samples',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Generate button
            if (_sampleStrings == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runSampleGeneration,
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: const Text('Generate Sample Strings'),
                ),
              )
            else ...[
              // Sample strings summary
              _buildSampleStringsSummary(),
              const SizedBox(height: 12),

              // Expandable samples list
              if (_showSampleStringsDetails) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildSampleStringsList(),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _sampleStrings = null;
                        _showSampleStringsDetails = false;
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Clear'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _runSampleGeneration(maxSamples: 15),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Generate More'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the sample strings summary showing key info
  Widget _buildSampleStringsSummary() {
    final samples = _sampleStrings;
    if (samples == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary row
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${samples.count} sample string(s) generated',
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (samples.acceptsEmptyString)
                _buildInfoChip(
                  'Accepts ε',
                  Icons.check,
                  colorScheme.tertiary,
                ),
              if (samples.shortestString != null)
                _buildInfoChip(
                  'Shortest: "${_displayString(samples.shortestString!)}"',
                  Icons.short_text,
                  colorScheme.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an info chip widget
  Widget _buildInfoChip(String label, IconData icon, Color color) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of sample strings
  Widget _buildSampleStringsList() {
    final samples = _sampleStrings;
    if (samples == null || samples.samples.isEmpty) {
      return Center(
        child: Text(
          'No sample strings generated',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generated Samples:',
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: samples.samples.map((sample) {
              return _buildSampleChip(sample);
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Copy all button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              final allSamples = samples.samples.join('\n');
              Clipboard.setData(ClipboardData(text: allSamples));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All samples copied to clipboard'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.copy_all, size: 16),
            label: const Text('Copy All'),
          ),
        ),
      ],
    );
  }

  /// Builds a single sample string chip
  Widget _buildSampleChip(String sample) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayText = _displayString(sample);

    return InkWell(
      onTap: () {
        // Copy this sample to clipboard
        Clipboard.setData(ClipboardData(text: sample));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: "$displayText"'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$displayText"',
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.content_copy,
              size: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a string for display, showing special representations for empty/epsilon
  String _displayString(String s) {
    if (s.isEmpty) return 'ε';
    if (s.length > 20) return '${s.substring(0, 17)}...';
    return s;
  }
}
