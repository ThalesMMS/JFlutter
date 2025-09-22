import 'package:flutter/material.dart';

import '../../core/models/state.dart' as automaton_models;
import '../../core/models/tm.dart';
import '../../core/models/tm_analysis.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/tm_transition.dart' as tm_models show TapeDirection;
import '../../providers/tm_algorithm_view_model.dart';

class AnalysisResults extends StatelessWidget {
  const AnalysisResults({super.key, required this.state});

  final TMAlgorithmState state;

  @override
  Widget build(BuildContext context) {
    final hasData = state.analysis != null || state.errorMessage != null;

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
            child: hasData ? _buildResults(context) : _buildEmptyResults(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No analysis results yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select an algorithm above to analyze your TM.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.outline,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withOpacity(0.2)),
          color: colorScheme.errorContainer.withOpacity(0.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final analysis = state.analysis;
    final tm = state.analyzedTm;
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
      if (state.focus != null) ...[
        _buildFocusBanner(context, state.focus!),
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
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildFocusBanner(BuildContext context, TMAnalysisFocus focus) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Analysis focus: ${_focusLabel(focus)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  String _focusLabel(TMAnalysisFocus focus) {
    switch (focus) {
      case TMAnalysisFocus.decidability:
        return 'Decidability';
      case TMAnalysisFocus.reachability:
        return 'Reachability';
      case TMAnalysisFocus.language:
        return 'Language structure';
      case TMAnalysisFocus.tape:
        return 'Tape operations';
      case TMAnalysisFocus.time:
        return 'Time characteristics';
      case TMAnalysisFocus.space:
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
          color:
              highlight ? colorScheme.primary : colorScheme.outline.withOpacity(0.4),
        ),
        color: highlight
            ? colorScheme.primaryContainer.withOpacity(0.35)
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  bool _shouldHighlight(_TMAnalysisSection section) {
    final focus = state.focus;
    if (focus == null) return false;

    switch (focus) {
      case TMAnalysisFocus.decidability:
        return {
          _TMAnalysisSection.state,
          _TMAnalysisSection.reachability,
          _TMAnalysisSection.issues,
        }.contains(section);
      case TMAnalysisFocus.reachability:
        return section == _TMAnalysisSection.reachability;
      case TMAnalysisFocus.language:
        return {
          _TMAnalysisSection.state,
          _TMAnalysisSection.transition,
        }.contains(section);
      case TMAnalysisFocus.tape:
        return section == _TMAnalysisSection.tape;
      case TMAnalysisFocus.time:
        return section == _TMAnalysisSection.timing;
      case TMAnalysisFocus.space:
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
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
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
                        ? colorScheme.errorContainer.withOpacity(0.5)
                        : colorScheme.secondaryContainer.withOpacity(0.4),
                    side: BorderSide(
                      color: isWarning
                          ? colorScheme.error
                          : colorScheme.secondary.withOpacity(0.5),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: textColor,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _formatStates(Set<automaton_models.State> states) {
    final labels = states
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

enum _TMAnalysisSection {
  state,
  transition,
  tape,
  reachability,
  timing,
  issues,
}
