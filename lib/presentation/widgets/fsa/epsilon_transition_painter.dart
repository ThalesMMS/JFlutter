//
//  epsilon_transition_painter.dart
//  JFlutter
//
//  Custom edge renderer para transições epsilon (λ/ε) com linha tracejada e
//  estilo visual diferenciado.
//
//  Created for Phase 1 improvements - November 2025
//

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import '../../../core/models/fsa_transition.dart';

/// Renderer customizado para transições FSA com suporte a epsilon
class EpsilonTransitionPainter extends EdgeRenderer {
  final FSATransition? fsaTransition;
  final Paint paint;
  final bool isHighlighted;

  EpsilonTransitionPainter({
    this.fsaTransition,
    Paint? customPaint,
    this.isHighlighted = false,
  }) : paint = customPaint ?? Paint();

  @override
  void render(Canvas canvas, Edge edge, Paint paint) {
    final isEpsilon = fsaTransition?.isEpsilonTransition ?? false;

    // Configurar paint baseado no tipo de transição
    final effectivePaint = Paint()
      ..color = isEpsilon
          ? (isHighlighted
              ? Colors.purple
              : Colors.grey[600]!)
          : (isHighlighted
              ? Theme.of(canvas as BuildContext).colorScheme.primary
              : Colors.black)
      ..strokeWidth = isHighlighted ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;

    // Aplicar PathEffect para linha tracejada se for epsilon
    if (isEpsilon) {
      effectivePaint.pathEffect = _createDashPathEffect();
    }

    // Desenhar a linha
    final path = _createEdgePath(edge);
    canvas.drawPath(path, effectivePaint);

    // Desenhar a seta
    _drawArrowHead(canvas, edge, effectivePaint);
  }

  /// Cria PathEffect para linha tracejada
  ui.PathEffect _createDashPathEffect() {
    // Padrão: 8px linha, 4px espaço
    return ui.PathEffect.dash([8.0, 4.0]);
  }

  /// Cria o caminho da transição
  Path _createEdgePath(Edge edge) {
    final path = Path();

    // Para self-loops
    if (edge.source == edge.destination) {
      return _createSelfLoopPath(edge);
    }

    // Linha reta ou curva dependendo se há control point
    final sourcePos = edge.source.position;
    final destPos = edge.destination.position;

    path.moveTo(sourcePos.dx, sourcePos.dy);
    path.lineTo(destPos.dx, destPos.dy);

    return path;
  }

  /// Cria caminho para self-loop
  Path _createSelfLoopPath(Edge edge) {
    final path = Path();
    final pos = edge.source.position;
    const radius = 30.0;

    // Arco acima do estado
    path.addArc(
      Rect.fromCircle(
        center: Offset(pos.dx, pos.dy - radius),
        radius: radius,
      ),
      0,
      3.14, // 180 graus
    );

    return path;
  }

  /// Desenha a ponta da seta
  void _drawArrowHead(Canvas canvas, Edge edge, Paint paint) {
    final sourcePos = edge.source.position;
    final destPos = edge.destination.position;

    if (edge.source == edge.destination) {
      // Self-loop: seta no topo do loop
      _drawSelfLoopArrow(canvas, sourcePos, paint);
      return;
    }

    // Calcular ângulo e posição da seta
    final dx = destPos.dx - sourcePos.dx;
    final dy = destPos.dy - sourcePos.dy;
    final angle = math.atan2(dy, dx);

    // Ponta da seta
    const arrowSize = 12.0;
    final arrowPath = Path();

    arrowPath.moveTo(
      destPos.dx - arrowSize * math.cos(angle - math.pi / 6),
      destPos.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    arrowPath.lineTo(destPos.dx, destPos.dy);
    arrowPath.lineTo(
      destPos.dx - arrowSize * math.cos(angle + math.pi / 6),
      destPos.dy - arrowSize * math.sin(angle + math.pi / 6),
    );

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }

  void _drawSelfLoopArrow(Canvas canvas, Offset pos, Paint paint) {
    const arrowSize = 12.0;
    final arrowPath = Path();

    // Seta apontando para baixo no topo do loop
    final arrowPos = Offset(pos.dx, pos.dy - 60);

    arrowPath.moveTo(arrowPos.dx - arrowSize / 2, arrowPos.dy - arrowSize);
    arrowPath.lineTo(arrowPos.dx, arrowPos.dy);
    arrowPath.lineTo(arrowPos.dx + arrowSize / 2, arrowPos.dy - arrowSize);

    canvas.drawPath(arrowPath, paint..style = PaintingStyle.fill);
  }
}

/// Helper para criar paint de transição epsilon
class EpsilonTransitionPaintHelper {
  /// Cria paint para transição epsilon
  static Paint createEpsilonPaint({
    bool isHighlighted = false,
    Color? color,
  }) {
    return Paint()
      ..color = color ?? (isHighlighted ? Colors.purple : Colors.grey[600]!)
      ..strokeWidth = isHighlighted ? 2.5 : 2.0
      ..style = PaintingStyle.stroke
      ..pathEffect = ui.PathEffect.dash([8.0, 4.0]);
  }

  /// Cria paint para transição regular
  static Paint createRegularPaint({
    bool isHighlighted = false,
    Color? color,
  }) {
    return Paint()
      ..color = color ?? (isHighlighted ? Colors.blue : Colors.black)
      ..strokeWidth = isHighlighted ? 2.5 : 2.0
      ..style = PaintingStyle.stroke;
  }

  /// Retorna paint apropriado baseado no tipo de transição
  static Paint getPaintForTransition(
    FSATransition transition, {
    bool isHighlighted = false,
  }) {
    return transition.isEpsilonTransition
        ? createEpsilonPaint(isHighlighted: isHighlighted)
        : createRegularPaint(isHighlighted: isHighlighted);
  }
}

/// Extension para aplicar estilo epsilon em edges do GraphView
extension EpsilonEdgeStyle on Edge {
  /// Aplica estilo epsilon nesta edge
  void applyEpsilonStyle(FSATransition? transition) {
    if (transition == null) return;

    final isEpsilon = transition.isEpsilonTransition;

    // Configurar paint da edge
    paint = isEpsilon
        ? EpsilonTransitionPaintHelper.createEpsilonPaint()
        : EpsilonTransitionPaintHelper.createRegularPaint();
  }
}
