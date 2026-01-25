//
//  animated_state_transition.dart
//  JFlutter
//
//  Provê animações suaves para transições de estado durante simulações de
//  autômatos, com velocidade configurável e suporte a Material 3. Encapsula
//  lógica de fade-in/fade-out e destacamento de estados ativos, reutilizável
//  por FA, PDA e TM.
//
//  Created for Phase 3 improvements - Enhanced Step-by-Step Visualization
//

import 'package:flutter/material.dart';

/// Widget que anima transições de destaque de estado durante simulações.
///
/// Fornece feedback visual suave quando um estado é destacado ou não destacado,
/// com duração ajustável pela velocidade de animação configurada pelo usuário.
/// Integra-se com Material 3 e suporta qualquer widget filho.
class AnimatedStateTransition extends StatefulWidget {
  /// Widget filho a ser animado (tipicamente um estado do autômato)
  final Widget child;

  /// Se o estado está atualmente destacado
  final bool isHighlighted;

  /// Velocidade da animação (1.0 = normal, 2.0 = 2x mais rápido, etc.)
  final double animationSpeed;

  /// Curva de animação a ser usada
  final Curve curve;

  /// Callback opcional quando a animação completa
  final VoidCallback? onTransitionComplete;

  const AnimatedStateTransition({
    super.key,
    required this.child,
    required this.isHighlighted,
    this.animationSpeed = 1.0,
    this.curve = Curves.easeInOut,
    this.onTransitionComplete,
  }) : assert(animationSpeed > 0, 'Animation speed must be positive');

  @override
  State<AnimatedStateTransition> createState() =>
      _AnimatedStateTransitionState();
}

class _AnimatedStateTransitionState extends State<AnimatedStateTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    if (widget.isHighlighted) {
      _controller.value = 1.0;
    }
  }

  void _initializeAnimations() {
    final duration = Duration(
      milliseconds: (300 / widget.animationSpeed).round(),
    );

    _controller = AnimationController(vsync: this, duration: duration)
      ..addStatusListener(_handleAnimationStatus);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      widget.onTransitionComplete?.call();
    }
  }

  @override
  void didUpdateWidget(AnimatedStateTransition oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Atualiza duração se velocidade mudou
    if (oldWidget.animationSpeed != widget.animationSpeed) {
      _controller.dispose();
      _initializeAnimations();
      if (widget.isHighlighted) {
        _controller.value = 1.0;
      }
    }

    // Anima transição de destaque
    if (oldWidget.isHighlighted != widget.isHighlighted) {
      if (widget.isHighlighted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isHighlighted ? _scaleAnimation.value : 1.0,
          child: Opacity(
            opacity: widget.isHighlighted ? _opacityAnimation.value : 1.0,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Widget simplificado para animar apenas opacidade (sem escala).
///
/// Útil quando animações de escala causam problemas de layout ou quando
/// apenas feedback de opacidade é desejado.
class AnimatedStateFade extends StatefulWidget {
  /// Widget filho a ser animado
  final Widget child;

  /// Se o estado está atualmente destacado
  final bool isHighlighted;

  /// Velocidade da animação (1.0 = normal, 2.0 = 2x mais rápido, etc.)
  final double animationSpeed;

  /// Opacidade quando não destacado
  final double dimmedOpacity;

  /// Opacidade quando destacado
  final double highlightedOpacity;

  /// Curva de animação a ser usada
  final Curve curve;

  const AnimatedStateFade({
    super.key,
    required this.child,
    required this.isHighlighted,
    this.animationSpeed = 1.0,
    this.dimmedOpacity = 0.5,
    this.highlightedOpacity = 1.0,
    this.curve = Curves.easeInOut,
  }) : assert(animationSpeed > 0, 'Animation speed must be positive'),
       assert(
         dimmedOpacity >= 0.0 && dimmedOpacity <= 1.0,
         'Dimmed opacity must be between 0.0 and 1.0',
       ),
       assert(
         highlightedOpacity >= 0.0 && highlightedOpacity <= 1.0,
         'Highlighted opacity must be between 0.0 and 1.0',
       );

  @override
  State<AnimatedStateFade> createState() => _AnimatedStateFadeState();
}

class _AnimatedStateFadeState extends State<AnimatedStateFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    if (widget.isHighlighted) {
      _controller.value = 1.0;
    }
  }

  void _initializeAnimation() {
    final duration = Duration(
      milliseconds: (300 / widget.animationSpeed).round(),
    );

    _controller = AnimationController(vsync: this, duration: duration);

    _opacityAnimation = Tween<double>(
      begin: widget.dimmedOpacity,
      end: widget.highlightedOpacity,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void didUpdateWidget(AnimatedStateFade oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Atualiza duração se velocidade mudou
    if (oldWidget.animationSpeed != widget.animationSpeed) {
      _controller.dispose();
      _initializeAnimation();
      if (widget.isHighlighted) {
        _controller.value = 1.0;
      }
    }

    // Anima transição de destaque
    if (oldWidget.isHighlighted != widget.isHighlighted) {
      if (widget.isHighlighted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(opacity: _opacityAnimation.value, child: child);
      },
      child: widget.child,
    );
  }
}
