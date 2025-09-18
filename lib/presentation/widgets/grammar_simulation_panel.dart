import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';

/// Panel for grammar parsing and string testing
class GrammarSimulationPanel extends ConsumerStatefulWidget {
  const GrammarSimulationPanel({super.key});

  @override
  ConsumerState<GrammarSimulationPanel> createState() => _GrammarSimulationPanelState();
}

class _GrammarSimulationPanelState extends ConsumerState<GrammarSimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final List<Production> _sampleProductions = [
    Production(id: 'p1', leftSide: ['S'], rightSide: ['a', 'S', 'b']),
    Production(id: 'p2', leftSide: ['S'], rightSide: ['a', 'b']),
  ];
  
  bool _isParsing = false;
  String? _parseResult;
  List<String> _parseSteps = [];
  String _selectedAlgorithm = 'CYK';

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildAlgorithmSelector(context),
            const SizedBox(height: 16),
            _buildInputSection(context),
            const SizedBox(height: 16),
            _buildParseButton(context),
            const SizedBox(height: 16),
            _buildResultsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.play_arrow,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Grammar Parser',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parsing Algorithm',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedAlgorithm,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: 'CYK', child: Text('CYK (Cocke-Younger-Kasami)')),
              DropdownMenuItem(value: 'LL', child: Text('LL Parser')),
              DropdownMenuItem(value: 'LR', child: Text('LR Parser')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedAlgorithm = value!;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test String',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              labelText: 'Input String',
              hintText: 'e.g., aabb, abab, ε',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _parseString(),
          ),
          const SizedBox(height: 8),
          Text(
            'Examples: aabb, abab, aabbb (for S → aSb | ab)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isParsing ? null : _parseString,
        icon: _isParsing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_isParsing ? 'Parsing...' : 'Parse String'),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parse Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _parseResult == null
                ? _buildEmptyResults(context)
                : _buildResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.psychology,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No parse results yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter a string and click Parse to see results',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final isAccepted = _parseResult == 'Accepted';
    final color = isAccepted ? Colors.green : Colors.red;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                _parseResult!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          if (_parseSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Parse Steps:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _parseSteps.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${index + 1}. ${_parseSteps[index]}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _parseString() {
    final inputString = _inputController.text.trim();
    
    if (inputString.isEmpty) {
      _showError('Please enter a string to parse');
      return;
    }
    
    setState(() {
      _isParsing = true;
      _parseResult = null;
      _parseSteps.clear();
    });
    
    // Simulate parsing (in real implementation, this would call the actual parser)
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _simulateParse(inputString);
      }
    });
  }

  void _simulateParse(String inputString) {
    // Simple simulation for demonstration
    // In real implementation, this would use the actual grammar parser
    final isAccepted = _simulateCYKParse(inputString);
    
    setState(() {
      _isParsing = false;
      _parseResult = isAccepted ? 'Accepted' : 'Rejected';
      _parseSteps = _generateParseSteps(inputString, isAccepted);
    });
  }

  bool _simulateCYKParse(String inputString) {
    // Simple simulation for the grammar S → aSb | ab
    // This is just for demonstration - real implementation would be more complex
    if (inputString == 'ab') return true;
    if (inputString == 'aabb') return true;
    if (inputString == 'aaabbb') return true;
    if (inputString == '') return false;
    
    // Check if string matches pattern a^n b^n
    final aCount = inputString.split('a').length - 1;
    final bCount = inputString.split('b').length - 1;
    final hasOnlyAB = inputString.replaceAll('a', '').replaceAll('b', '').isEmpty;
    
    return hasOnlyAB && aCount == bCount && aCount > 0;
  }

  List<String> _generateParseSteps(String inputString, bool isAccepted) {
    if (!isAccepted) {
      return [
        'Input: $inputString',
        'No valid derivation found',
        'String rejected by grammar'
      ];
    }
    
    final steps = <String>['Input: $inputString'];
    
    if (inputString == 'ab') {
      steps.addAll([
        'Apply rule: S → ab',
        'Derivation: S ⇒ ab',
        'String accepted!'
      ]);
    } else if (inputString == 'aabb') {
      steps.addAll([
        'Apply rule: S → aSb',
        'Derivation: S ⇒ aSb',
        'Apply rule: S → ab',
        'Derivation: S ⇒ aSb ⇒ aabb',
        'String accepted!'
      ]);
    } else {
      steps.addAll([
        'Apply rule: S → aSb (multiple times)',
        'Apply rule: S → ab (final step)',
        'String accepted!'
      ]);
    }
    
    return steps;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
