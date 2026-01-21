//
//  base_trace_viewer.dart
//  JFlutter
//
//  Provê widget base reutilizado pelos visualizadores de traços de FA, PDA e
//  TM, tratando colapso de listas extensas, seleção de passos e integração
//  opcional com o SimulationHighlightService para sincronizar destaques no
//  canvas.
//  Aceita um SimulationResult genérico e um builder de linhas especializado,
//  garantindo comportamento consistente e acessível para qualquer algoritmo que
//  produza sequências de passos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
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
  final double animationSpeed;
  final ValueChanged<int>? onStepChanged;

  const BaseTraceViewer({
    super.key,
    required this.result,
    required this.title,
    required this.buildStepLine,
    this.highlightService,
    this.animationSpeed = 1.0,
    this.onStepChanged,
  });

  @override
  State<BaseTraceViewer> createState() => _BaseTraceViewerState();
}

class _BaseTraceViewerState extends State<BaseTraceViewer> {
  static const int defaultFoldSize = 50;
  bool _folded = true;
  final int _foldSize = defaultFoldSize;
  int? _selectedIndex;
  bool _isPlaying = false;

  bool get _highlightEnabled =>
      widget.highlightService != null && widget.result.steps.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _highlightEnabled ? 0 : null;
  }

  @override
  void dispose() {
    _isPlaying = false;
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant BaseTraceViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != oldWidget.result ||
        widget.highlightService != oldWidget.highlightService) {
      setState(() {
        _selectedIndex = _highlightEnabled ? 0 : null;
        _isPlaying = false;
      });
    }
  }

  void _handleStepTap(int index) {
    if (!_highlightEnabled) return;
    _updateSelectedIndex(index);
  }

  void _previousStep() {
    if (!_highlightEnabled) return;
    final current = _selectedIndex ?? 0;
    if (current > 0) {
      _updateSelectedIndex(current - 1);
    }
  }

  void _nextStep() {
    if (!_highlightEnabled) return;
    final current = _selectedIndex ?? 0;
    if (current < widget.result.steps.length - 1) {
      _updateSelectedIndex(current + 1);
    }
  }

  void _playSteps() {
    if (!_highlightEnabled) return;
    setState(() {
      _isPlaying = true;
    });
    _playStepAnimation();
  }

  void _pauseSteps() {
    setState(() {
      _isPlaying = false;
    });
  }

  void _playStepAnimation() {
    if (!_isPlaying || !mounted) return;
    final current = _selectedIndex ?? 0;
    if (current < widget.result.steps.length - 1) {
      // Calculate delay based on animation speed: slower speed = longer delay
      final delayMs = (1000 / widget.animationSpeed).round();
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (_isPlaying && mounted) {
          _updateSelectedIndex(current + 1);
          _playStepAnimation();
        }
      });
    } else {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  void _resetSteps() {
    _updateSelectedIndex(0, emitHighlight: false);
    setState(() {
      _isPlaying = false;
    });
    widget.highlightService?.clear();
  }

  void _updateSelectedIndex(int index, {bool emitHighlight = true}) {
    setState(() {
      _selectedIndex = index;
    });
    if (emitHighlight) {
      widget.highlightService?.emitFromSteps(widget.result.steps, index);
    }
    widget.onStepChanged?.call(index);
  }

  Widget _buildNavigationControls(BuildContext context) {
    final current = _selectedIndex ?? 0;
    final maxIndex = widget.result.steps.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: current > 0 ? _previousStep : null,
            icon: const Icon(Icons.skip_previous),
            tooltip: 'Previous Step',
            iconSize: 20,
          ),
          IconButton(
            onPressed: _isPlaying ? _pauseSteps : _playSteps,
            icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            tooltip: _isPlaying ? 'Pause' : 'Play',
            iconSize: 20,
          ),
          IconButton(
            onPressed: current < maxIndex ? _nextStep : null,
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next Step',
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '${current + 1} / ${widget.result.steps.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          IconButton(
            onPressed: _resetSteps,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            iconSize: 20,
          ),
        ],
      ),
    );
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
        if (_highlightEnabled) _buildNavigationControls(context),
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
            height: 180,
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
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.08),
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
