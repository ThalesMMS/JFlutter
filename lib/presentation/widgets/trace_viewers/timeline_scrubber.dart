//
//  timeline_scrubber.dart
//  JFlutter
//
//  Widget de navegação temporal para simulações de autômatos. Provê controle
//  deslizante (slider) para percorrer passos de execução, permitindo salto
//  direto para qualquer ponto do traço. Exibe rótulos de passo atual/total
//  e responde a interações de arrastar e tocar, garantindo navegação precisa
//  em traços longos de FA, PDA e TM.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';

/// Timeline scrubber widget for navigating simulation steps.
///
/// This widget provides an interactive slider interface for jumping to any
/// step in a simulation trace. It displays the current step position and
/// total step count, and notifies listeners when the user drags or taps
/// to select a different step.
///
/// Features:
/// - Smooth slider control for precise step selection
/// - Clear visual indication of current position (step N of M)
/// - Support for drag and tap interactions
/// - Accessibility semantics for screen readers
/// - Material 3 theming integration
/// - Disabled state for single-step or empty traces
///
/// Example:
/// ```dart
/// TimelineScrubber(
///   currentStep: 5,
///   totalSteps: 20,
///   onStepChanged: (step) {
///     setState(() => selectedStep = step);
///     highlightService.emitFromSteps(steps, step);
///   },
/// )
/// ```
class TimelineScrubber extends StatelessWidget {
  const TimelineScrubber({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onStepChanged,
    this.enabled = true,
  }) : assert(currentStep >= 0, 'currentStep must be non-negative'),
       assert(totalSteps >= 0, 'totalSteps must be non-negative'),
       assert(
         currentStep < totalSteps || totalSteps == 0,
         'currentStep must be less than totalSteps',
       );

  /// Current step index (0-based).
  ///
  /// Represents the active step in the simulation trace.
  /// Expected to be in range [0, totalSteps).
  final int currentStep;

  /// Total number of steps in the simulation.
  ///
  /// If totalSteps is 0 or 1, the scrubber will be disabled
  /// since there are no meaningful navigation options.
  final int totalSteps;

  /// Callback invoked when the user selects a new step.
  ///
  /// The callback receives the newly selected step index (0-based).
  final ValueChanged<int> onStepChanged;

  /// Whether the scrubber is interactive.
  ///
  /// When false, the slider is disabled and grayed out.
  final bool enabled;

  /// Get semantic label for the current position.
  String _getPositionLabel() {
    if (totalSteps == 0) return 'No steps available';
    return 'Step ${currentStep + 1} of $totalSteps';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInteractive = enabled && totalSteps > 1;

    return Semantics(
      label: 'Timeline scrubber',
      value: _getPositionLabel(),
      hint: isInteractive ? 'Drag to navigate through simulation steps' : null,
      enabled: isInteractive,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Timeline',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                _getPositionLabel(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isInteractive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.12),
              disabledActiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.12),
              disabledInactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.12),
              disabledThumbColor: colorScheme.onSurface.withValues(alpha: 0.38),
              valueIndicatorColor: colorScheme.primaryContainer,
              valueIndicatorTextStyle: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: colorScheme.onPrimaryContainer),
            ),
            child: Slider(
              value: totalSteps > 0 ? currentStep.toDouble() : 0,
              min: 0,
              max: totalSteps > 1 ? (totalSteps - 1).toDouble() : 1,
              divisions: totalSteps > 1 ? totalSteps - 1 : 1,
              label: totalSteps > 0 ? 'Step ${currentStep + 1}' : 'No steps',
              onChanged: isInteractive
                  ? (value) => onStepChanged(value.round())
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
