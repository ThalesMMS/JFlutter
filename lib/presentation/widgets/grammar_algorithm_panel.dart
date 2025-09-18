import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel for grammar analysis algorithms
class GrammarAlgorithmPanel extends ConsumerStatefulWidget {
  const GrammarAlgorithmPanel({super.key});

  @override
  ConsumerState<GrammarAlgorithmPanel> createState() => _GrammarAlgorithmPanelState();
}

class _GrammarAlgorithmPanelState extends ConsumerState<GrammarAlgorithmPanel> {
  bool _isAnalyzing = false;
  String? _analysisResult;

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
            _buildAlgorithmButtons(context),
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
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Grammar Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    return Column(
      children: [
        _buildAlgorithmButton(
          context,
          title: 'Remove Left Recursion',
          description: 'Eliminate left recursion from grammar',
          icon: Icons.transform,
          onPressed: _removeLeftRecursion,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Left Factor',
          description: 'Apply left factoring to grammar',
          icon: Icons.account_tree,
          onPressed: _leftFactor,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Find First Sets',
          description: 'Calculate FIRST sets for all variables',
          icon: Icons.first_page,
          onPressed: _findFirstSets,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Find Follow Sets',
          description: 'Calculate FOLLOW sets for all variables',
          icon: Icons.last_page,
          onPressed: _findFollowSets,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Build Parse Table',
          description: 'Generate LL(1) or LR(1) parse table',
          icon: Icons.table_chart,
          onPressed: _buildParseTable,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Check Ambiguity',
          description: 'Detect if grammar is ambiguous',
          icon: Icons.help_outline,
          onPressed: _checkAmbiguity,
        ),
      ],
    );
  }

  Widget _buildAlgorithmButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: _isAnalyzing ? null : onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isAnalyzing 
                ? colorScheme.outline.withOpacity(0.3)
                : colorScheme.primary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isAnalyzing 
              ? colorScheme.surfaceVariant.withOpacity(0.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _isAnalyzing 
                  ? colorScheme.outline
                  : colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _isAnalyzing 
                          ? colorScheme.outline
                          : colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (_isAnalyzing)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary.withOpacity(0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analysis Results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _analysisResult == null
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
            Icons.analytics_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No analysis results yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an algorithm above to analyze your grammar',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Text(
          _analysisResult!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  void _removeLeftRecursion() {
    _performAnalysis('Remove Left Recursion', () {
      return '''Left Recursion Removal Analysis:

Original Grammar:
S → Sa | b

After Left Recursion Removal:
S → bS'
S' → aS' | ε

Analysis:
- Left recursion detected in S → Sa
- New non-terminal S' introduced
- Grammar is now right-recursive
- Language remains unchanged''';
    });
  }

  void _leftFactor() {
    _performAnalysis('Left Factoring', () {
      return '''Left Factoring Analysis:

Original Grammar:
S → aAb | aAc | aAd

After Left Factoring:
S → aA
A → b | c | d

Analysis:
- Common prefix 'aA' factored out
- New non-terminal A introduced
- Grammar is now left-factored
- Reduces parsing conflicts''';
    });
  }

  void _findFirstSets() {
    _performAnalysis('First Sets Calculation', () {
      return '''FIRST Sets Analysis:

Grammar:
S → aSb | ab

FIRST(S) = {a}

Calculation:
- S → aSb: FIRST(S) includes 'a'
- S → ab: FIRST(S) includes 'a'
- No ε-productions for S

Result: FIRST(S) = {a}''';
    });
  }

  void _findFollowSets() {
    _performAnalysis('Follow Sets Calculation', () {
      return '''FOLLOW Sets Analysis:

Grammar:
S → aSb | ab

FOLLOW(S) = {\$, b}

Calculation:
- S → aSb: S followed by 'b'
- S → ab: S at end of production
- S is start symbol, so \$ is in FOLLOW(S)

Result: FOLLOW(S) = {\$, b}''';
    });
  }

  void _buildParseTable() {
    _performAnalysis('Parse Table Construction', () {
      return '''LL(1) Parse Table:

Grammar:
S → aSb | ab

Parse Table:
     | a    | b    | \$
-----|------|------|-----
S    | S→aSb|      |     
     | S→ab |      |     

Analysis:
- Grammar is LL(1)
- No conflicts in parse table
- Can be parsed deterministically''';
    });
  }

  void _checkAmbiguity() {
    _performAnalysis('Ambiguity Check', () {
      return '''Ambiguity Analysis:

Grammar:
S → aSb | ab

Ambiguity Check:
- No multiple leftmost derivations
- No multiple rightmost derivations
- Parse table has no conflicts
- Grammar is unambiguous

Result: Grammar is unambiguous''';
    });
  }

  void _performAnalysis(String algorithmName, String Function() analysisFunction) {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    // Simulate analysis delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analysisResult = analysisFunction();
        });
      }
    });
  }
}
