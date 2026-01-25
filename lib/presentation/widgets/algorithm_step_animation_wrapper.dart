//
//  algorithm_step_animation_wrapper.dart
//  JFlutter
//
//  Componente wrapper que adiciona animações de transição suaves entre passos
//  de algoritmos educacionais. Utiliza AnimatedSwitcher com FadeTransition e
//  SlideTransition para feedback visual fluido durante navegação step-by-step.
//  Consome configurações de duração e curva do algorithm_animation_provider.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/algorithm_step.dart';
import '../providers/algorithm_animation_provider.dart';
import 'algorithm_step_viewer.dart';

/// Wrapper widget that adds smooth transition animations between algorithm steps
///
/// Uses AnimatedSwitcher to animate between different AlgorithmStep instances.
/// Animation duration and curve are controlled by the algorithm_animation_provider.
/// The key is set to step.id so that AnimatedSwitcher detects step changes.
class AlgorithmStepAnimationWrapper extends ConsumerWidget {
  /// The algorithm step to display
  final AlgorithmStep step;

  /// Optional callback when user wants to see more details
  final VoidCallback? onShowDetails;

  /// Whether to show expanded details by default
  final bool showExpandedDetails;

  /// Animation type to use for transitions
  final AnimationType animationType;

  const AlgorithmStepAnimationWrapper({
    super.key,
    required this.step,
    this.onShowDetails,
    this.showExpandedDetails = false,
    this.animationType = AnimationType.fadeSlide,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationState = ref.watch(algorithmAnimationProvider);

    return AnimatedSwitcher(
      duration: animationState.animationDuration,
      switchInCurve: animationState.animationCurve,
      switchOutCurve: animationState.animationCurve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return _buildTransition(child, animation);
      },
      child: AlgorithmStepViewer(
        key: ValueKey(step.id),
        step: step,
        onShowDetails: onShowDetails,
        showExpandedDetails: showExpandedDetails,
      ),
    );
  }

  /// Builds the appropriate transition based on animation type
  Widget _buildTransition(Widget child, Animation<double> animation) {
    switch (animationType) {
      case AnimationType.fade:
        return FadeTransition(
          opacity: animation,
          child: child,
        );

      case AnimationType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );

      case AnimationType.fadeSlide:
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );

      case AnimationType.scale:
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.95,
            end: 1.0,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
    }
  }
}

/// Animation types available for step transitions
enum AnimationType {
  /// Simple fade in/out
  fade,

  /// Horizontal slide
  slide,

  /// Combined fade and slide (default)
  fadeSlide,

  /// Scale with fade
  scale,
}
