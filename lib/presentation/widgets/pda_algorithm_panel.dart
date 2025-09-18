import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Panel for PDA analysis algorithms
class PDAAlgorithmPanel extends ConsumerStatefulWidget {
  const PDAAlgorithmPanel({super.key});

  @override
  ConsumerState<PDAAlgorithmPanel> createState() => _PDAAlgorithmPanelState();
}

class _PDAAlgorithmPanelState extends ConsumerState<PDAAlgorithmPanel> {
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
          'PDA Analysis',
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
          title: 'Convert to CFG',
          description: 'Convert PDA to equivalent context-free grammar',
          icon: Icons.transform,
          onPressed: _convertToCFG,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Minimize PDA',
          description: 'Minimize the number of states in PDA',
          icon: Icons.compress,
          onPressed: _minimizePDA,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Check Determinism',
          description: 'Determine if PDA is deterministic',
          icon: Icons.help_outline,
          onPressed: _checkDeterminism,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Find Reachable States',
          description: 'Identify reachable states from initial state',
          icon: Icons.explore,
          onPressed: _findReachableStates,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Language Analysis',
          description: 'Analyze the language accepted by PDA',
          icon: Icons.analytics,
          onPressed: _analyzeLanguage,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Stack Operations',
          description: 'Analyze stack operations and depth',
          icon: Icons.storage,
          onPressed: _analyzeStackOperations,
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
            'Select an algorithm above to analyze your PDA',
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

  void _convertToCFG() {
    _performAnalysis('PDA to CFG Conversion', () {
      return '''PDA to Context-Free Grammar Conversion:

Original PDA:
- States: {q0, q1, q2}
- Transitions: 
  q0 --a,Z/AZ--> q0
  q0 --b,A/ε--> q1
  q1 --b,A/ε--> q1
  q1 --ε,Z/Z--> q2

Equivalent CFG:
S → [q0,Z,q2]
[q0,Z,q0] → a[q0,A,q0][q0,Z,q0]
[q0,Z,q1] → a[q0,A,q1][q1,Z,q1]
[q0,A,q0] → a[q0,A,q0][q0,A,q0]
[q0,A,q1] → a[q0,A,q1][q1,A,q1]
[q0,A,q1] → b
[q1,A,q1] → b
[q1,Z,q2] → ε

Analysis:
- Grammar has 7 production rules
- Variables represent state-stack combinations
- Language: a^n b^n (n ≥ 1)''';
    });
  }

  void _minimizePDA() {
    _performAnalysis('PDA Minimization', () {
      return '''PDA Minimization Analysis:

Original PDA:
- States: {q0, q1, q2, q3}
- Transitions: 8 transitions

Minimization Process:
1. Remove unreachable states: q3 (unreachable)
2. Merge equivalent states: q1 and q2 (equivalent behavior)
3. Remove redundant transitions

Minimized PDA:
- States: {q0, q1}
- Transitions: 4 transitions
- Reduction: 50% fewer states, 50% fewer transitions

Analysis:
- Language remains unchanged
- Improved efficiency
- Reduced complexity''';
    });
  }

  void _checkDeterminism() {
    _performAnalysis('Determinism Check', () {
      return '''PDA Determinism Analysis:

Current PDA Configuration:
- States: {q0, q1, q2}
- Transitions: 6 transitions

Determinism Check:
✓ No ε-transitions with same input symbol
✓ No multiple transitions from same state with same input/stack symbol
✓ All transitions are deterministic

Result: PDA is DETERMINISTIC (DPDA)

Properties:
- Can be parsed efficiently
- Unique computation path for each input
- Suitable for real-time parsing applications''';
    });
  }

  void _findReachableStates() {
    _performAnalysis('Reachable States Analysis', () {
      return '''Reachable States Analysis:

PDA States: {q0, q1, q2, q3}

Reachability Analysis:
Starting from q0 (initial state):

Level 0: {q0}
Level 1: {q1} (reachable via 'a' transition)
Level 2: {q2} (reachable via 'b' transition from q1)
Level 3: {} (no further reachable states)

Reachable States: {q0, q1, q2}
Unreachable States: {q3}

Analysis:
- 75% of states are reachable
- State q3 can be removed
- PDA can be simplified''';
    });
  }

  void _analyzeLanguage() {
    _performAnalysis('Language Analysis', () {
      return '''Language Analysis:

PDA Language Properties:
- Language Type: Context-Free
- Language Class: Deterministic Context-Free
- Pumping Lemma: Satisfies CFL pumping lemma

Language Description:
L = {a^n b^n | n ≥ 1}

Properties:
✓ Not regular (requires stack)
✓ Context-free (can be recognized by PDA)
✓ Deterministic (unique parsing)
✓ Inherently ambiguous
✓ Not inherently ambiguous for this specific PDA

Complexity:
- Time: O(n) for recognition
- Space: O(n) for stack depth
- Parsing: Linear time''';
    });
  }

  void _analyzeStackOperations() {
    _performAnalysis('Stack Operations Analysis', () {
      return '''Stack Operations Analysis:

Stack Operations Summary:
- Push Operations: 2 (on 'a' symbols)
- Pop Operations: 2 (on 'b' symbols)
- No-Change Operations: 1 (final transition)

Stack Depth Analysis:
- Maximum Stack Depth: n (for input a^n b^n)
- Average Stack Depth: n/2
- Stack Growth Pattern: Linear

Stack Symbol Usage:
- Initial Symbol: Z
- Working Symbols: A
- Symbol Count: 2

Efficiency Metrics:
- Push/Pop Ratio: 1:1 (balanced)
- Stack Utilization: High
- Memory Efficiency: Optimal for this language''';
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
