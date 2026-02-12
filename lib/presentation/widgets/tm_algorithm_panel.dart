//
//  tm_algorithm_panel.dart
//  JFlutter
//
//  Disponibiliza o painel de análises para Máquinas de Turing, reunindo botões
//  para verificações de decidibilidade, alcançabilidade, linguagem, operações de
//  fita e métricas temporais e espaciais com resultados estruturados.
//  Conecta-se ao TMEditorProvider e aos AlgorithmOperations para executar
//  diagnósticos, mantendo estado local de foco e evitando recomputações
//  desnecessárias entre execuções.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/algorithm_operations.dart';
import '../../core/models/state.dart' as automaton_models;
import '../../core/models/tm.dart';
import '../../core/models/tm_analysis.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/tm_transition.dart' as tm_models show TapeDirection;
import '../../core/result.dart';
import '../../data/examples/tm_examples.dart';
import '../providers/tm_editor_provider.dart';

enum _TMAnalysisFocus {
  decidability,
  reachability,
  language,
  tape,
  time,
  space,
}

enum _TMAnalysisSection {
  state,
  transition,
  tape,
  reachability,
  timing,
  issues,
}

/// Panel for Turing Machine analysis algorithms
class TMAlgorithmPanel extends ConsumerStatefulWidget {
  const TMAlgorithmPanel({super.key, this.useExpanded = true});

  final bool useExpanded;

  @override
  ConsumerState<TMAlgorithmPanel> createState() => _TMAlgorithmPanelState();
}

class _TMAlgorithmPanelState extends ConsumerState<TMAlgorithmPanel> {
  bool _isAnalyzing = false;
  TMAnalysis? _analysis;
  String? _analysisError;
  TM? _analyzedTm;
  _TMAnalysisFocus? _currentFocus;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
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
        Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          'TM Analysis',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    return Column(
      children: [
        _buildExamplesSection(context),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildAlgorithmButton(
          context,
          title: 'Check Decidability',
          description: 'Verify halting states and potential infinite loops',
          icon: Icons.help_outline,
          focus: _TMAnalysisFocus.decidability,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Find Reachable States',
          description: 'Identify which states can be reached from the start',
          icon: Icons.explore,
          focus: _TMAnalysisFocus.reachability,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Language Analysis',
          description: 'Inspect accepting structure and transition coverage',
          icon: Icons.analytics,
          focus: _TMAnalysisFocus.language,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Tape Operations',
          description: 'Review read/write symbols and head movements',
          icon: Icons.storage,
          focus: _TMAnalysisFocus.tape,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Time Characteristics',
          description: 'Understand analysis runtime and processed elements',
          icon: Icons.timer,
          focus: _TMAnalysisFocus.time,
        ),
        const SizedBox(height: 12),
        _buildAlgorithmButton(
          context,
          title: 'Space Characteristics',
          description: 'Assess tape alphabet and movement coverage',
          icon: Icons.memory,
          focus: _TMAnalysisFocus.space,
        ),
      ],
    );
  }

  Widget _buildAlgorithmButton(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required _TMAnalysisFocus focus,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _currentFocus == focus;

    return InkWell(
      onTap: _isAnalyzing ? null : () => _performAnalysis(focus),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _isAnalyzing
                ? colorScheme.outline.withValues(alpha: 0.3)
                : isSelected
                ? colorScheme.primary
                : colorScheme.primary.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
          color: _isAnalyzing
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.35)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _isAnalyzing ? colorScheme.outline : colorScheme.primary,
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
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
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
                color: colorScheme.primary.withValues(alpha: 0.5),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final hasData = _analysis != null || _analysisError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analysis Results',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        hasData ? _buildResults(context) : _buildEmptyResults(context),
      ],
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
            'Select an algorithm above to analyze your TM.',
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
    final colorScheme = Theme.of(context).colorScheme;

    if (_analysisError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
          color: colorScheme.errorContainer.withValues(alpha: 0.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _analysisError!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final analysis = _analysis;
    final tm = _analyzedTm;
    if (analysis == null || tm == null) {
      return _buildEmptyResults(context);
    }

    final reachability = analysis.reachabilityAnalysis;
    final unreachableStates = reachability.unreachableStates;
    final haltingStates = tm.acceptingStates;
    final reachableHaltingStates = haltingStates
        .where((state) => reachability.reachableStates.contains(state))
        .toSet();
    final unreachableHaltingStates = haltingStates
        .where((state) => !reachability.reachableStates.contains(state))
        .toSet();
    final potentialInfinite = _findPotentialInfiniteLoops(tm);

    final children = <Widget>[
      if (_currentFocus != null) ...[
        _buildFocusBanner(context, _currentFocus!),
        const SizedBox(height: 12),
      ],
      _buildSectionCard(
        context,
        title: 'State Analysis',
        section: _TMAnalysisSection.state,
        children: [
          _buildMetricRow(
            context,
            'Total states',
            analysis.stateAnalysis.totalStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Accepting states',
            analysis.stateAnalysis.acceptingStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Non-accepting states',
            analysis.stateAnalysis.nonAcceptingStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Reachable halting states',
            '${reachableHaltingStates.length} of ${haltingStates.length}',
            highlight: unreachableHaltingStates.isEmpty,
            isWarning: unreachableHaltingStates.isNotEmpty,
          ),
          if (unreachableHaltingStates.isNotEmpty)
            _buildChipList(
              context,
              label: 'Halting states not reached',
              values: _formatStates(unreachableHaltingStates),
              isWarning: true,
            ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Transition Analysis',
        section: _TMAnalysisSection.transition,
        children: [
          _buildMetricRow(
            context,
            'Total transitions',
            analysis.transitionAnalysis.totalTransitions.toString(),
          ),
          _buildMetricRow(
            context,
            'TM transitions',
            analysis.transitionAnalysis.tmTransitions.toString(),
          ),
          _buildMetricRow(
            context,
            'Non-TM transitions',
            analysis.transitionAnalysis.fsaTransitions.toString(),
            isError: analysis.transitionAnalysis.fsaTransitions > 0,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Tape Operations',
        section: _TMAnalysisSection.tape,
        children: [
          _buildChipList(
            context,
            label: 'Read symbols',
            values: _sorted(analysis.tapeAnalysis.readOperations),
          ),
          _buildChipList(
            context,
            label: 'Write symbols',
            values: _sorted(analysis.tapeAnalysis.writeOperations),
          ),
          _buildChipList(
            context,
            label: 'Move directions',
            values: _sorted(analysis.tapeAnalysis.moveDirections),
          ),
          _buildChipList(
            context,
            label: 'Tape alphabet',
            values: _sorted(analysis.tapeAnalysis.tapeSymbols),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Reachability',
        section: _TMAnalysisSection.reachability,
        children: [
          _buildMetricRow(
            context,
            'Reachable states',
            reachability.reachableStates.length.toString(),
          ),
          _buildChipList(
            context,
            label: 'Reachable',
            values: _formatStates(reachability.reachableStates),
          ),
          _buildMetricRow(
            context,
            'Unreachable states',
            unreachableStates.length.toString(),
            isWarning: unreachableStates.isNotEmpty,
          ),
          if (unreachableStates.isNotEmpty)
            _buildChipList(
              context,
              label: 'Unreachable',
              values: _formatStates(unreachableStates),
              isWarning: true,
            ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Execution Timing',
        section: _TMAnalysisSection.timing,
        children: [
          _buildMetricRow(
            context,
            'Analysis time',
            _formatDuration(analysis.executionTime),
          ),
          _buildMetricRow(
            context,
            'States processed',
            analysis.stateAnalysis.totalStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Transitions inspected',
            analysis.transitionAnalysis.totalTransitions.toString(),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Potential Issues',
        section: _TMAnalysisSection.issues,
        children: [
          if (unreachableStates.isEmpty && potentialInfinite.isEmpty)
            _buildStatusMessage(
              context,
              message: 'No structural issues detected.',
              isPositive: true,
            ),
          if (unreachableStates.isNotEmpty)
            _buildStatusMessage(
              context,
              message:
                  '${unreachableStates.length} state(s) cannot be reached from the initial state.',
              isWarning: true,
            ),
          if (potentialInfinite.isNotEmpty)
            _buildStatusMessage(
              context,
              message:
                  'Detected ${potentialInfinite.length} self-loop transition(s) that do not move the head.',
              isWarning: true,
            ),
          if (potentialInfinite.isNotEmpty)
            _buildChipList(
              context,
              label: 'Potentially non-halting transitions',
              values: potentialInfinite
                  .map(
                    (t) =>
                        '${t.fromState.label.isNotEmpty ? t.fromState.label : t.fromState.id} • ${t.readSymbol}→${t.writeSymbol} (${t.direction.name})',
                  )
                  .toList(),
              isWarning: true,
            ),
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    final theme = Theme.of(context);
    final examples = TMExamples.getExampleFactories();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Load Examples',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...examples.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildExampleButton(
              context,
              title: entry.key,
              onPressed: () => _loadExample(entry.value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleButton(
    BuildContext context, {
    required String title,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.file_open, size: 18),
        label: Text(title),
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          side: BorderSide(color: colorScheme.secondary.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  void _loadExample(TM Function() exampleFactory) {
    try {
      final tm = exampleFactory();
      ref.read(tmEditorProvider.notifier).setTm(tm);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Example loaded: ${tm.name}')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load example: $error')),
      );
    }
  }

  Future<void> _performAnalysis(_TMAnalysisFocus focus) async {
    setState(() {
      _isAnalyzing = true;
      _analysis = null;
      _analysisError = null;
      _currentFocus = focus;
    });

    final tm = ref.read(tmEditorProvider).tm;
    if (tm == null) {
      setState(() {
        _isAnalyzing = false;
        _analysisError =
            'No Turing machine available. Draw states and transitions on the canvas to analyze.';
      });
      return;
    }

    final Result<TMAnalysis> result;
    try {
      result = AlgorithmOperations.analyzeTm(tm);
    } catch (error) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = 'Failed to analyze the Turing machine: $error';
      });
      return;
    }

    if (!mounted) return;

    setState(() {
      _isAnalyzing = false;
      if (result.isSuccess) {
        _analysis = result.data;
        _analyzedTm = tm;
      } else {
        _analysisError =
            result.error ??
            'Analysis failed due to an unknown error. Please verify the machine configuration.';
      }
    });
  }

  Widget _buildFocusBanner(BuildContext context, _TMAnalysisFocus focus) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analysis focus: ${_focusLabel(focus)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _focusLabel(_TMAnalysisFocus focus) {
    switch (focus) {
      case _TMAnalysisFocus.decidability:
        return 'Decidability';
      case _TMAnalysisFocus.reachability:
        return 'Reachability';
      case _TMAnalysisFocus.language:
        return 'Language structure';
      case _TMAnalysisFocus.tape:
        return 'Tape operations';
      case _TMAnalysisFocus.time:
        return 'Time characteristics';
      case _TMAnalysisFocus.space:
        return 'Space characteristics';
    }
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required _TMAnalysisSection section,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = _shouldHighlight(section);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.4),
        ),
        color: highlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  bool _shouldHighlight(_TMAnalysisSection section) {
    final focus = _currentFocus;
    if (focus == null) return false;

    switch (focus) {
      case _TMAnalysisFocus.decidability:
        return {
          _TMAnalysisSection.state,
          _TMAnalysisSection.reachability,
          _TMAnalysisSection.issues,
        }.contains(section);
      case _TMAnalysisFocus.reachability:
        return section == _TMAnalysisSection.reachability;
      case _TMAnalysisFocus.language:
        return {
          _TMAnalysisSection.state,
          _TMAnalysisSection.transition,
        }.contains(section);
      case _TMAnalysisFocus.tape:
        return section == _TMAnalysisSection.tape;
      case _TMAnalysisFocus.time:
        return section == _TMAnalysisSection.timing;
      case _TMAnalysisFocus.space:
        return section == _TMAnalysisSection.tape;
    }
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
    bool isWarning = false,
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color? valueColor;
    if (isError) {
      valueColor = colorScheme.error;
    } else if (isWarning) {
      valueColor = colorScheme.tertiary;
    } else if (highlight) {
      valueColor = colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: highlight ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(
    BuildContext context, {
    required String label,
    required List<String> values,
    bool isWarning = false,
  }) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (value) => Chip(
                    label: Text(value),
                    backgroundColor: isWarning
                        ? colorScheme.errorContainer.withValues(alpha: 0.5)
                        : colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    side: BorderSide(
                      color: isWarning
                          ? colorScheme.error
                          : colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(
    BuildContext context, {
    required String message,
    bool isWarning = false,
    bool isPositive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color? textColor;
    IconData icon;
    if (isPositive) {
      textColor = colorScheme.primary;
      icon = Icons.check_circle_outline;
    } else if (isWarning) {
      textColor = colorScheme.error;
      icon = Icons.warning_amber_outlined;
    } else {
      textColor = colorScheme.onSurfaceVariant;
      icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _formatStates(Set<automaton_models.State> states) {
    final List<String> labels = states
        .map((state) => state.label.isNotEmpty ? state.label : state.id)
        .toList();
    labels.sort();
    return labels;
  }

  List<String> _sorted(Set<String> values) {
    final list = values.toList();
    list.sort();
    return list;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds >= 1) {
      return '${duration.inMilliseconds} ms';
    }
    if (duration.inMicroseconds >= 1) {
      return '${duration.inMicroseconds} μs';
    }
    final nanoseconds = duration.inMicroseconds * 1000;
    return '$nanoseconds ns';
  }

  List<TMTransition> _findPotentialInfiniteLoops(TM tm) {
    final transitions = tm.transitions.whereType<TMTransition>();
    return transitions
        .where(
          (transition) =>
              transition.fromState == transition.toState &&
              transition.readSymbol == transition.writeSymbol &&
              transition.direction == tm_models.TapeDirection.stay,
        )
        .toList();
  }
}
