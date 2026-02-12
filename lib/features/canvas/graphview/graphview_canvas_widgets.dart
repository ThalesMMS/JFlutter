//
//  graphview_canvas_widgets.dart
//  JFlutter
//
//  Declara widgets auxiliares e modelos internos utilizados pelo canvas GraphView
//  para renderizar estados de autômato, gerenciar overlays de edição de transição
//  e encapsular estados transitórios durante interações do usuário. Esses componentes
//  são privados ao módulo do canvas e suportam a visualização e edição de FSA, PDA e TM.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../core/constants/automaton_canvas.dart';
import 'graphview_canvas_models.dart';
import 'graphview_canvas_painters.dart';
import 'graphview_transition_models.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;
const Size _kInitialArrowSize = Size(24, 12);

/// Internal model representing a user's choice when initiating transition editing:
/// either creating a new transition or editing an existing one.
class TransitionEditChoice {
  const TransitionEditChoice._({required this.createNew, this.edge});

  const TransitionEditChoice.edit(GraphViewCanvasEdge edge)
    : this._(createNew: false, edge: edge);

  const TransitionEditChoice.createNew() : this._(createNew: true);

  final bool createNew;
  final GraphViewCanvasEdge? edge;
}

/// Internal model holding the current state of a transition overlay during editing,
/// including the overlay data and its on-screen position.
class GraphViewTransitionOverlayState {
  const GraphViewTransitionOverlayState({
    required this.data,
    required this.overlayPosition,
  });

  final AutomatonTransitionOverlayData data;
  final Offset overlayPosition;

  GraphViewTransitionOverlayState copyWith({
    AutomatonTransitionOverlayData? data,
    Offset? overlayPosition,
  }) {
    return GraphViewTransitionOverlayState(
      data: data ?? this.data,
      overlayPosition: overlayPosition ?? this.overlayPosition,
    );
  }
}

/// Widget that renders a single automaton state node with optional initial and
/// accepting decorations. Integrates with Material 3 theming and supports
/// highlighting during simulations with smooth fade-in animations.
class AutomatonGraphNode extends StatelessWidget {
  const AutomatonGraphNode({
    super.key,
    required this.label,
    required this.isInitial,
    required this.isAccepting,
    required this.isHighlighted,
  });

  final String label;
  final bool isInitial;
  final bool isAccepting;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isHighlighted
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final backgroundColor = isHighlighted
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surface;

    final badgeColor = theme.colorScheme.primary;

    return SizedBox(
      width: _kNodeDiameter,
      height: _kNodeDiameter,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 3),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isInitial)
            Positioned(
              left: -_kInitialArrowSize.width + 1,
              top: _kNodeRadius - (_kInitialArrowSize.height / 2),
              child: CustomPaint(
                size: _kInitialArrowSize,
                painter: InitialStateArrowPainter(color: borderColor),
              ),
            ),
          if (isAccepting)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: badgeColor, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
