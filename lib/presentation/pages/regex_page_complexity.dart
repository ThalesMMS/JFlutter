part of 'regex_page.dart';

extension _RegexPageComplexitySections on _RegexPageState {
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
                    tooltip:
                        _showAnalysisDetails ? 'Hide details' : 'Show details',
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
        border: Border.all(color: levelColor.withValues(alpha: 0.3)),
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
                Icon(levelIcon, size: 16, color: Colors.white),
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
}
