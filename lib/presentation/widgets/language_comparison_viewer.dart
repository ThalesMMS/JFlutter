//
//  language_comparison_viewer.dart
//  JFlutter
//
//  Widget para visualização de resultados de comparação de equivalência de
//  linguagens entre dois autômatos finitos. Exibe o resultado da comparação,
//  string distinguidora (contraexemplo), autômatos lado a lado, autômato produto
//  (opcional) e passos do algoritmo, permitindo análise educacional completa da
//  comparação de linguagens via construção do autômato produto e BFS.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import '../../core/models/equivalence_comparison_result.dart';
import '../../core/models/fsa.dart';
import 'automaton_graphview_canvas.dart';

/// Widget for visualizing language equivalence comparison results
///
/// Displays comparison outcome, distinguishing string (if not equivalent),
/// side-by-side automata comparison, optional product automaton visualization,
/// and algorithm steps for educational analysis of language comparison.
class LanguageComparisonViewer extends StatefulWidget {
  /// The comparison result to display
  final EquivalenceComparisonResult comparisonResult;

  /// Optional title for the first automaton (defaults to "Automaton A")
  final String? automatonATitle;

  /// Optional title for the second automaton (defaults to "Automaton B")
  final String? automatonBTitle;

  /// Whether to show the product automaton visualization
  final bool showProductAutomaton;

  /// Whether to show algorithm steps
  final bool showSteps;

  const LanguageComparisonViewer({
    super.key,
    required this.comparisonResult,
    this.automatonATitle,
    this.automatonBTitle,
    this.showProductAutomaton = false,
    this.showSteps = false,
  });

  @override
  State<LanguageComparisonViewer> createState() =>
      _LanguageComparisonViewerState();
}

class _LanguageComparisonViewerState extends State<LanguageComparisonViewer> {
  final GlobalKey _automatonACanvasKey = GlobalKey();
  final GlobalKey _automatonBCanvasKey = GlobalKey();
  final GlobalKey _productCanvasKey = GlobalKey();
  bool _showProductAutomatonSection = false;
  bool _showStepsSection = false;

  @override
  void initState() {
    super.initState();
    _showProductAutomatonSection = widget.showProductAutomaton;
    _showStepsSection = widget.showSteps;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with equivalence result badge
            _buildHeader(colorScheme, textTheme),
            const SizedBox(height: 16),

            // Counterexample section (if not equivalent)
            if (!widget.comparisonResult.isEquivalent) ...[
              _buildCounterexampleSection(colorScheme, textTheme),
              const SizedBox(height: 16),
            ],

            // Statistics comparison
            _buildStatistics(colorScheme, textTheme),
            const SizedBox(height: 16),

            // Side-by-side automaton comparison
            Expanded(
              child: Column(
                children: [
                  // Main comparison section
                  Expanded(
                    child: Row(
                      children: [
                        // Automaton A
                        Expanded(
                          child: _buildAutomatonSection(
                            context: context,
                            automaton:
                                widget.comparisonResult.originalAutomaton,
                            title: widget.automatonATitle ?? 'Automaton A',
                            canvasKey: _automatonACanvasKey,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Automaton B
                        Expanded(
                          child: _buildAutomatonSection(
                            context: context,
                            automaton:
                                widget.comparisonResult.comparedAutomaton,
                            title: widget.automatonBTitle ?? 'Automaton B',
                            canvasKey: _automatonBCanvasKey,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product automaton section (collapsible)
                  if (widget.comparisonResult.productAutomaton != null) ...[
                    const SizedBox(height: 16),
                    _buildProductAutomatonSection(colorScheme, textTheme),
                  ],

                  // Algorithm steps section (collapsible)
                  if (widget.comparisonResult.steps.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStepsSection(colorScheme, textTheme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    final isEquivalent = widget.comparisonResult.isEquivalent;
    final badgeColor = isEquivalent ? colorScheme.primary : colorScheme.error;
    final badgeIcon = isEquivalent ? Icons.check_circle : Icons.cancel;
    final badgeText = isEquivalent ? 'EQUIVALENT' : 'NOT EQUIVALENT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 24),
          const SizedBox(width: 8),
          Text(
            badgeText,
            style: textTheme.titleLarge?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(Icons.access_time, color: colorScheme.onSurface, size: 16),
          const SizedBox(width: 4),
          Text(
            '${widget.comparisonResult.executionTimeMs}ms',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterexampleSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final distinguishingString = widget.comparisonResult.distinguishingString;
    if (distinguishingString == null) return const SizedBox.shrink();

    final displayString = distinguishingString.isEmpty
        ? 'ε (empty string)'
        : '"$distinguishingString"';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Distinguishing String Found',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  displayString,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This string is accepted by one automaton but rejected by the other, '
            'proving that the two automata recognize different languages.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ColorScheme colorScheme, TextTheme textTheme) {
    final automatonA = widget.comparisonResult.originalAutomaton;
    final automatonB = widget.comparisonResult.comparedAutomaton;
    final statesA = automatonA.states.length;
    final statesB = automatonB.states.length;
    final transitionsA = automatonA.transitions.length;
    final transitionsB = automatonB.transitions.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'States (A)',
            value: statesA,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'States (B)',
            value: statesB,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'Transitions (A)',
            value: transitionsA,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'Transitions (B)',
            value: transitionsB,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAutomatonSection({
    required BuildContext context,
    required FSA automaton,
    required String title,
    required GlobalKey canvasKey,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_tree, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              child: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: canvasKey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductAutomatonSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showProductAutomatonSection = !_showProductAutomatonSection;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showProductAutomatonSection
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(Icons.grid_on, color: colorScheme.tertiary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Product Automaton',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showProductAutomatonSection) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AutomatonGraphViewCanvas(
                  automaton: widget.comparisonResult.productAutomaton!,
                  canvasKey: _productCanvasKey,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showStepsSection = !_showStepsSection;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showStepsSection ? Icons.expand_more : Icons.chevron_right,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(Icons.list_alt, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Algorithm Steps',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.comparisonResult.steps.length} steps',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showStepsSection) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: widget.comparisonResult.steps.length,
              itemBuilder: (context, index) {
                final stepData = widget.comparisonResult.steps[index];
                // Note: The actual step rendering would need to convert
                // Map<String, dynamic> to proper step objects based on the
                // algorithm. For now, we show a placeholder.
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(color: colorScheme.onPrimary),
                      ),
                    ),
                    title: Text(
                      stepData['type']?.toString() ?? 'Step ${index + 1}',
                      style: textTheme.titleSmall,
                    ),
                    subtitle: Text(
                      stepData['description']?.toString() ?? '',
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
