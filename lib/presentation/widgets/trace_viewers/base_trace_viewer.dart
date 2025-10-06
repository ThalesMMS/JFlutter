import 'package:flutter/material.dart';

import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../../../core/services/simulation_highlight_service.dart';

/// Base trace viewer with folding support used by FA/PDA/TM viewers.
class BaseTraceViewer extends StatefulWidget {
  final SimulationResult result;
  final String title;
  final Widget Function(SimulationStep step, int index) buildStepLine;
  final SimulationHighlightService? highlightService;

  const BaseTraceViewer({
    super.key,
    required this.result,
    required this.title,
    required this.buildStepLine,
    this.highlightService,
  });

  @override
  State<BaseTraceViewer> createState() => _BaseTraceViewerState();
}

class _BaseTraceViewerState extends State<BaseTraceViewer> {
  static const int defaultFoldSize = 50;
  bool _folded = true;
  final int _foldSize = defaultFoldSize;
  int? _selectedIndex;

  bool get _highlightEnabled =>
      widget.highlightService != null && widget.result.steps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _highlightEnabled ? 0 : null;
  }

  @override
  void didUpdateWidget(covariant BaseTraceViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != oldWidget.result ||
        widget.highlightService != oldWidget.highlightService) {
      setState(() {
        _selectedIndex = _highlightEnabled ? 0 : null;
      });
    }
  }

  void _handleStepTap(int index) {
    if (!_highlightEnabled) return;
    setState(() {
      _selectedIndex = index;
    });
    widget.highlightService?.emitFromSteps(widget.result.steps, index);
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.result.steps;
    final isAccepted = widget.result.accepted;
    final color = isAccepted ? Colors.green : Colors.red;
    final visibleCount = _folded
        ? steps.length.clamp(0, _foldSize)
        : steps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isAccepted ? Icons.check_circle : Icons.cancel,
              color: color,
              size: 18,
            ),
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                final isSelected = _highlightEnabled && _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: InkWell(
                    onTap: _highlightEnabled
                        ? () => _handleStepTap(index)
                        : null,
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: isSelected
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.2,
                              ),
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.08),
                            )
                          : const BoxDecoration(),
                      child: widget.buildStepLine(step, index),
                    ),
                  ),
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
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
      ],
    );
  }
}
