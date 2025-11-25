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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/automaton_simulator.dart';
import '../../core/algorithms/dfa_completer.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/nfa_to_dfa_converter.dart';
import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/models/fsa.dart';
import '../providers/automaton_provider.dart';
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
    ref.read(automatonProvider.notifier).updateAutomaton(automaton);
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    final isTablet = screenSize.width >= 768 && screenSize.width < 1400;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
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

  Widget _buildDesktopLayout() {
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
                child: _buildInputArea(),
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

  Widget _buildTabletLayout() {
    return Scaffold(
      body: TabletLayoutContainer(
        canvas: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: _buildInputArea(),
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

  Widget _buildInputArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regular Expression',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
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
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withOpacity(0.8),
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
    });
  }
}
