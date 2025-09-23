import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/models/fsa_transition.dart';
import '../../../core/models/state.dart' as automaton_state;
import '../transition_geometry.dart';

/// Painter responsável por renderizar estados e transições do autômato,
/// incluindo pré-visualizações, setas iniciais e rótulos.
class AutomatonPainter extends CustomPainter {
  final List<automaton_state.State> states;
  final List<FSATransition> transitions;
  final automaton_state.State? selectedState;
  final automaton_state.State? transitionStart;
  final Offset? transitionPreviewPosition;
  final double stateRadius;

  AutomatonPainter({
    required this.states,
    required this.transitions,
    required this.selectedState,
    required this.transitionStart,
    required this.transitionPreviewPosition,
    this.stateRadius = 30,
  });

  static const double _selfLoopBaseRadius = 40;
  static const double _selfLoopSpacing = 12;

  @override
  void paint(Canvas canvas, Size size) {
    _drawTransitions(canvas);
    _drawInitialArrows(canvas);
    _drawTransitionPreview(canvas);
    _drawStates(canvas);
  }

  void _drawTransitions(Canvas canvas) {
    for (final transition in transitions) {
      if (transition.fromState.id == transition.toState.id) {
        _drawSelfLoop(canvas, transition);
      } else {
        _drawDirectedTransition(canvas, transition);
      }
    }
  }

  // Desenha transições direcionadas utilizando uma curva quadrática de Bézier,
  // onde o ponto de controle é calculado pela `TransitionCurve` para manter o
  // afastamento visual entre múltiplas arestas entre os mesmos estados.
  void _drawDirectedTransition(Canvas canvas, FSATransition transition) {
    final geometry = TransitionCurve.compute(
      transitions,
      transition,
      stateRadius: stateRadius,
    );

    final path = Path()
      ..moveTo(geometry.start.dx, geometry.start.dy)
      ..quadraticBezierTo(
        geometry.control.dx,
        geometry.control.dy,
        geometry.end.dx,
        geometry.end.dy,
      );

    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
    _drawArrowhead(canvas, geometry.end, geometry.tangentAngle, paint.color);
    _drawTransitionLabel(canvas, transition, geometry.labelPosition);
  }

  // Constrói laços próprios posicionando um arco acima do estado; o raio base
  // (_selfLoopBaseRadius) e o espaçamento incremental (_selfLoopSpacing)
  // garantem que múltiplos loops sejam deslocados radialmente para evitar
  // sobreposição.
  void _drawSelfLoop(Canvas canvas, FSATransition transition) {
    final center = Offset(
      transition.fromState.position.x,
      transition.fromState.position.y,
    );

    final selfLoops = transitions
        .where((t) =>
            t.fromState.id == transition.fromState.id &&
            t.toState.id == transition.toState.id)
        .toList();
    final loopIndex = selfLoops.indexOf(transition);
    final loopRadius =
        _selfLoopBaseRadius + loopIndex * _selfLoopSpacing;

    const startAngle = -3 * math.pi / 4;
    const sweepAngle = 1.5 * math.pi;
    final loopCenter = center + Offset(0, -loopRadius);
    final rect = Rect.fromCircle(center: loopCenter, radius: loopRadius);

    final paint = Paint()
      ..color = Colors.grey[800]!
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final path = Path()..addArc(rect, startAngle, sweepAngle);
    canvas.drawPath(path, paint);

    final endAngle = startAngle + sweepAngle;
    final endPoint = Offset(
      loopCenter.dx + loopRadius * math.cos(endAngle),
      loopCenter.dy + loopRadius * math.sin(endAngle),
    );

    final tangentAngle = endAngle + math.pi / 2;
    _drawArrowhead(canvas, endPoint, tangentAngle, paint.color);

    final labelAngle = startAngle + sweepAngle / 2;
    final labelPoint = Offset(
      loopCenter.dx + loopRadius * math.cos(labelAngle),
      loopCenter.dy + loopRadius * math.sin(labelAngle),
    );
    final offsetDirection = Offset(
      math.cos(labelAngle),
      math.sin(labelAngle),
    );
    final labelPosition = labelPoint + offsetDirection * 16;
    _drawTransitionLabel(canvas, transition, labelPosition);
  }

  // Posiciona o rótulo da transição no ponto médio da curva, deslocando o
  // texto na direção do vetor tangente para manter legibilidade em curvas
  // inclinadas e loops.
  void _drawTransitionLabel(
    Canvas canvas,
    FSATransition transition,
    Offset position,
  ) {
    final label = _formatTransitionLabel(transition);
    if (label.isEmpty) {
      return;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )
      ..layout();

    final offset = position - Offset(textPainter.width / 2, textPainter.height / 2);
    textPainter.paint(canvas, offset);
  }

  String _formatTransitionLabel(FSATransition transition) {
    if (transition.lambdaSymbol != null) {
      return transition.lambdaSymbol!;
    }

    if (transition.label.isNotEmpty) {
      return transition.label;
    }

    if (transition.inputSymbols.isNotEmpty) {
      return transition.inputSymbols.join(', ');
    }

    return '';
  }

  // Calcula o triângulo da seta deslocando-se a partir do ponto final na
  // direção da tangente e aplicando rotação simétrica pelo ângulo da seta.
  void _drawArrowhead(
    Canvas canvas,
    Offset tip,
    double angle,
    Color color,
  ) {
    const double arrowLength = 12;
    const double arrowAngle = math.pi / 7;

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * math.cos(angle - arrowAngle),
        tip.dy - arrowLength * math.sin(angle - arrowAngle),
      )
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(
        tip.dx - arrowLength * math.cos(angle + arrowAngle),
        tip.dy - arrowLength * math.sin(angle + arrowAngle),
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paint);
  }

  void _drawInitialArrows(Canvas canvas) {
    for (final state in states.where((s) => s.isInitial)) {
      final center = Offset(state.position.x, state.position.y);
      final start = center - Offset(stateRadius + 30, 0);
      final end = center - Offset(stateRadius, 0);

      final paint = Paint()
        ..color = Colors.blueGrey
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawLine(start, end, paint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      _drawArrowhead(canvas, end, angle, paint.color);
    }
  }

  void _drawTransitionPreview(Canvas canvas) {
    if (transitionStart == null || transitionPreviewPosition == null) {
      return;
    }

    final startCenter = Offset(
      transitionStart!.position.x,
      transitionStart!.position.y,
    );
    final preview = transitionPreviewPosition!;
    final direction = preview - startCenter;
    if (direction.distance <= 1) {
      return;
    }

    final unit = Offset(
      direction.dx / direction.distance,
      direction.dy / direction.distance,
    );
    final start = startCenter + unit * stateRadius;
    final end = preview;

    final paint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    canvas.drawPath(path, paint);
    final angle = math.atan2(direction.dy, direction.dx);
    _drawArrowhead(canvas, end, angle, paint.color);
  }

  void _drawStates(Canvas canvas) {
    for (final state in states) {
      final center = Offset(state.position.x, state.position.y);

      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.08)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(center + const Offset(2, 2), stateRadius, shadowPaint);

      final fillPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      final borderPaint = Paint()
        ..color = selectedState?.id == state.id
            ? Colors.blueAccent
            : Colors.grey[800]!
        ..strokeWidth = selectedState?.id == state.id ? 3 : 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      canvas.drawCircle(center, stateRadius, fillPaint);
      canvas.drawCircle(center, stateRadius, borderPaint);

      if (state.isAccepting) {
        final acceptingPaint = Paint()
          ..color = borderPaint.color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..isAntiAlias = true;
        canvas.drawCircle(center, stateRadius - 6, acceptingPaint);
      }

      final label = state.label.isNotEmpty ? state.label : state.id;
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 2,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: stateRadius * 1.8);

      final textOffset = center -
          Offset(textPainter.width / 2, textPainter.height / 2);
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant AutomatonPainter oldDelegate) {
    return !listEquals(oldDelegate.states, states) ||
        !listEquals(oldDelegate.transitions, transitions) ||
        oldDelegate.selectedState?.id != selectedState?.id ||
        oldDelegate.transitionStart?.id != transitionStart?.id ||
        oldDelegate.transitionPreviewPosition != transitionPreviewPosition ||
        oldDelegate.stateRadius != stateRadius;
  }
}
