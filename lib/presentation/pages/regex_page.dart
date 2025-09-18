import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/simulation_panel.dart';

/// Regular Expression page for testing and converting regular expressions
class RegexPage extends ConsumerStatefulWidget {
  const RegexPage({super.key});

  @override
  ConsumerState<RegexPage> createState() => _RegexPageState();
}

class _RegexPageState extends ConsumerState<RegexPage> {
  final TextEditingController _regexController = TextEditingController();
  final TextEditingController _testStringController = TextEditingController();
  String _currentRegex = '';
  String _testString = '';
  bool _isValid = false;
  bool _matches = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _regexController.dispose();
    _testStringController.dispose();
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

  void _testStringMatch() {
    setState(() {
      _testString = _testStringController.text;
      
      if (!_isValid || _currentRegex.isEmpty) {
        _matches = false;
        return;
      }
      
      try {
        // In a real implementation, you would use a proper regex engine
        // For now, we'll do basic pattern matching
        _matches = _basicPatternMatch(_currentRegex, _testString);
      } catch (e) {
        _matches = false;
        _errorMessage = 'Error testing string: $e';
      }
    });
  }

  bool _basicPatternMatch(String pattern, String text) {
    // Very basic pattern matching for demonstration
    // In a real implementation, you would use a proper regex engine
    if (pattern == text) return true;
    if (pattern == '.*') return true;
    if (pattern == '$text*') return true;
    if (pattern == '$text+') return true;
    
    // Simple wildcard matching
    if (pattern.contains('*')) {
      final parts = pattern.split('*');
      if (parts.length == 2) {
        return text.startsWith(parts[0]) && text.endsWith(parts[1]);
      }
    }
    
    return false;
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
    
    // TODO: Implement regex to NFA conversion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Regex to NFA conversion - Coming soon!'),
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
    
    // TODO: Implement regex to DFA conversion
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Regex to DFA conversion - Coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;
    
    if (isMobile) {
      return _buildMobileLayout();
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
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                    _isValid ? 'Valid regex' : (_errorMessage.isNotEmpty ? _errorMessage : 'Invalid regex'),
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
            
            // Help section
            Card(
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
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: SingleChildScrollView(
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
                    Row(
                      children: [
                        Icon(
                          _isValid ? Icons.check_circle : Icons.error,
                          color: _isValid ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isValid ? 'Valid regex' : (_errorMessage.isNotEmpty ? _errorMessage : 'Invalid regex'),
                          style: TextStyle(
                            color: _isValid ? Colors.green : Colors.red,
                            fontSize: 14,
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
                    
                    // Help section
                    Card(
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
                  ],
                ),
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
                      onNfaToDfa: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('NFA to DFA - Coming soon!')),
                        );
                      },
                      onMinimizeDfa: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('DFA Minimization - Coming soon!')),
                        );
                      },
                      onClear: () {
                        _regexController.clear();
                        _testStringController.clear();
                        setState(() {
                          _currentRegex = '';
                          _testString = '';
                          _isValid = false;
                          _matches = false;
                          _errorMessage = '';
                        });
                      },
                      onRegexToNfa: (regex) {
                        _regexController.text = regex;
                        _validateRegex();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Regex to NFA - Coming soon!')),
                        );
                      },
                      onFaToRegex: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('FA to Regex - Coming soon!')),
                        );
                      },
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
}
