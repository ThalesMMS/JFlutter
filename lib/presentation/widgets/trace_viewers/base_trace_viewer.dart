import 'package:flutter/material.dart';

import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';

/// Base trace viewer with folding support used by FA/PDA/TM viewers.
class BaseTraceViewer extends StatefulWidget {
  final SimulationResult result;
  final String title;
  final Widget Function(SimulationStep step, int index) buildStepLine;

  const BaseTraceViewer({
    super.key,
    required this.result,
    required this.title,
    required this.buildStepLine,
  });

  @override
  State<BaseTraceViewer> createState() => _BaseTraceViewerState();
}

class _BaseTraceViewerState extends State<BaseTraceViewer> {
  static const int defaultFoldSize = 50;
  bool _folded = true;
  int _foldSize = defaultFoldSize;

  @override
  Widget build(BuildContext context) {
    final steps = widget.result.steps;
    final isAccepted = widget.result.accepted;
    final color = isAccepted ? Colors.green : Colors.red;
    final visibleCount =
        _folded ? steps.length.clamp(0, _foldSize) : steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isAccepted ? Icons.check_circle : Icons.cancel,
                color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
            ),
            const Spacer(),
            if (steps.length > defaultFoldSize)
              TextButton.icon(
                onPressed: () => setState(() => _folded = !_folded),
                icon: Icon(_folded ? Icons.unfold_more : Icons.unfold_less),
                label: Text(_folded ? 'Expand' : 'Collapse'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (steps.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No steps recorded',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: visibleCount,
              itemBuilder: (context, index) {
                final step = steps[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: widget.buildStepLine(step, index),
                );
              },
            ),
          ),
        if (_folded && steps.length > visibleCount)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${steps.length - visibleCount} more steps hidden',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
          ),
      ],
    );
  }
}
