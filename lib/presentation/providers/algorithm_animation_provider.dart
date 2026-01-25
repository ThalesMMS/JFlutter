//
//  algorithm_animation_provider.dart
//  JFlutter
//
//  Gerencia o estado de animação durante transições entre passos de
//  algoritmos educacionais, controlando duração, curvas e estado de
//  execução para proporcionar feedback visual suave ao usuário.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for algorithm step transition animations
class AlgorithmAnimationState {
  final bool isAnimating;
  final Duration animationDuration;
  final Curve animationCurve;

  const AlgorithmAnimationState({
    this.isAnimating = false,
    this.animationDuration = const Duration(milliseconds: 400),
    this.animationCurve = Curves.easeInOut,
  });

  AlgorithmAnimationState copyWith({
    bool? isAnimating,
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return AlgorithmAnimationState(
      isAnimating: isAnimating ?? this.isAnimating,
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }

  /// Reset to default animation state
  AlgorithmAnimationState reset() {
    return const AlgorithmAnimationState();
  }

  /// Check if animations are enabled
  bool get isEnabled => animationDuration.inMilliseconds > 0;
}

/// Notifier for managing algorithm animation state
class AlgorithmAnimationNotifier
    extends StateNotifier<AlgorithmAnimationState> {
  AlgorithmAnimationNotifier() : super(const AlgorithmAnimationState());

  /// Start an animation
  void startAnimation() {
    state = state.copyWith(isAnimating: true);
  }

  /// Stop the current animation
  void stopAnimation() {
    state = state.copyWith(isAnimating: false);
  }

  /// Set animation duration
  void setDuration(Duration duration) {
    state = state.copyWith(animationDuration: duration);
  }

  /// Set animation curve
  void setCurve(Curve curve) {
    state = state.copyWith(animationCurve: curve);
  }

  /// Set animation duration in milliseconds
  void setDurationMilliseconds(int milliseconds) {
    setDuration(Duration(milliseconds: milliseconds));
  }

  /// Preset: Fast animations (200ms)
  void setFast() {
    state = state.copyWith(
      animationDuration: const Duration(milliseconds: 200),
      animationCurve: Curves.easeInOut,
    );
  }

  /// Preset: Normal animations (400ms - default)
  void setNormal() {
    state = state.copyWith(
      animationDuration: const Duration(milliseconds: 400),
      animationCurve: Curves.easeInOut,
    );
  }

  /// Preset: Slow animations (600ms)
  void setSlow() {
    state = state.copyWith(
      animationDuration: const Duration(milliseconds: 600),
      animationCurve: Curves.easeInOut,
    );
  }

  /// Disable animations
  void disable() {
    state = state.copyWith(
      animationDuration: Duration.zero,
    );
  }

  /// Enable animations with default duration
  void enable() {
    state = state.copyWith(
      animationDuration: const Duration(milliseconds: 400),
    );
  }

  /// Reset to default state
  void reset() {
    state = state.reset();
  }
}

/// Provider for algorithm animation state
final algorithmAnimationProvider =
    StateNotifierProvider<AlgorithmAnimationNotifier, AlgorithmAnimationState>(
  (ref) => AlgorithmAnimationNotifier(),
);
