import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;
import '../../core/mealy_moore.dart';

/// Canvas for visualizing Mealy and Moore machines
class MealyMooreCanvas extends StatefulWidget {
  final dynamic machine; // MealyMachine or MooreMachine
  final Function(String)? onStateSelected;
  final Function(String)? onTransitionSelected;
  final List<String> selectedStates;
  final List<String> selectedTransitions;
  final bool isMealy;

  const MealyMooreCanvas({
    super.key,
    required this.machine,
    this.onStateSelected,
    this.onTransitionSelected,
    this.selectedStates = const [],
    this.selectedTransitions = const [],
    required this.isMealy,
  });

  @override
  State<MealyMooreCanvas> createState() => _MealyMooreCanvasState();
}

class _MealyMooreCanvasState extends State<MealyMooreCanvas> {
  final TransformationController _transformationController = TransformationController();
  Offset? _panStart;
  double _scale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: 0.1,
        maxScale: 5.0,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onTap: () => _onCanvasTap(),
          child: CustomPaint(
            painter: _MealyMoorePainter(
              machine: widget.machine,
              selectedStates: widget.selectedStates,
              selectedTransitions: widget.selectedTransitions,
              isMealy: widget.isMealy,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    _panStart = details.localPosition;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_panStart != null) {
      final delta = details.localPosition - _panStart!;
      final currentMatrix = _transformationController.value.clone();
      currentMatrix.translateByVector3(vector_math.Vector3(delta.dx, delta.dy, 0));
      _transformationController.value = currentMatrix;
      _panStart = details.localPosition;
    }
  }

  void _onCanvasTap() {
    // Handle canvas tap - could be used for adding new states
    if (widget.onStateSelected != null) {
      widget.onStateSelected!('');
    }
  }
}

class _MealyMoorePainter extends CustomPainter {
  final dynamic machine;
  final List<String> selectedStates;
  final List<String> selectedTransitions;
  final bool isMealy;

  _MealyMoorePainter({
    required this.machine,
    required this.selectedStates,
    required this.selectedTransitions,
    required this.isMealy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (machine == null) {
      _drawEmptyCanvas(canvas, size);
      return;
    }

    _drawStates(canvas);
    _drawTransitions(canvas);
  }

  void _drawEmptyCanvas(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Nenhuma máquina definida',
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 16,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  void _drawStates(Canvas canvas) {
    if (isMealy && machine is MealyMachine) {
      _drawMealyStates(canvas, machine as MealyMachine);
    } else if (!isMealy && machine is MooreMachine) {
      _drawMooreStates(canvas, machine as MooreMachine);
    }
  }

  void _drawMealyStates(Canvas canvas, MealyMachine mealy) {
    for (final state in mealy.states) {
      final isSelected = selectedStates.contains(state.id);
      final isInitial = state.isInitial;
      final isFinal = state.isFinal;

      _drawState(
        canvas,
        Offset(state.x, state.y),
        state.name,
        isSelected: isSelected,
        isInitial: isInitial,
        isFinal: isFinal,
      );
    }
  }

  void _drawMooreStates(Canvas canvas, MooreMachine moore) {
    for (final state in moore.states) {
      final isSelected = selectedStates.contains(state.id);
      final isInitial = state.isInitial;
      final isFinal = state.isFinal;

      _drawState(
        canvas,
        Offset(state.x, state.y),
        state.name,
        output: state.output,
        isSelected: isSelected,
        isInitial: isInitial,
        isFinal: isFinal,
      );
    }
  }

  void _drawState(
    Canvas canvas,
    Offset position,
    String name, {
    String? output,
    bool isSelected = false,
    bool isInitial = false,
    bool isFinal = false,
  }) {
    final paint = Paint()
      ..color = isSelected ? Colors.blue.shade300 : Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = isSelected ? Colors.blue.shade700 : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;

    // Draw state circle
    canvas.drawCircle(position, 25, paint);
    canvas.drawCircle(position, 25, borderPaint);

    // Draw initial arrow
    if (isInitial) {
      final arrowStart = Offset(position.dx - 40, position.dy);
      final arrowEnd = Offset(position.dx - 25, position.dy);
      
      final arrowPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawLine(arrowStart, arrowEnd, arrowPaint);
      
      // Draw arrowhead
      final arrowHead = Path();
      arrowHead.moveTo(arrowEnd.dx, arrowEnd.dy);
      arrowHead.lineTo(arrowEnd.dx - 8, arrowEnd.dy - 4);
      arrowHead.lineTo(arrowEnd.dx - 8, arrowEnd.dy + 4);
      arrowHead.close();
      
      canvas.drawPath(arrowHead, arrowPaint);
    }

    // Draw final state double circle
    if (isFinal) {
      canvas.drawCircle(position, 30, borderPaint);
    }

    // Draw state name
    final textPainter = TextPainter(
      text: TextSpan(
        text: name,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );

    // Draw output for Moore states
    if (output != null && output.isNotEmpty) {
      final outputPainter = TextPainter(
        text: TextSpan(
          text: '/$output',
          style: TextStyle(
            color: Colors.green.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      outputPainter.layout();
      outputPainter.paint(
        canvas,
        Offset(
          position.dx - outputPainter.width / 2,
          position.dy + 15,
        ),
      );
    }
  }

  void _drawTransitions(Canvas canvas) {
    if (isMealy && machine is MealyMachine) {
      _drawMealyTransitions(canvas, machine as MealyMachine);
    } else if (!isMealy && machine is MooreMachine) {
      _drawMooreTransitions(canvas, machine as MooreMachine);
    }
  }

  void _drawMealyTransitions(Canvas canvas, MealyMachine mealy) {
    for (final transition in mealy.transitions) {
      final fromState = mealy.getState(transition.fromState);
      final toState = mealy.getState(transition.toState);
      
      if (fromState != null && toState != null) {
        _drawTransition(
          canvas,
          Offset(fromState.x, fromState.y),
          Offset(toState.x, toState.y),
          '${transition.input}/${transition.output}',
          isSelected: selectedTransitions.contains('${transition.fromState}-${transition.toState}-${transition.input}'),
        );
      }
    }
  }

  void _drawMooreTransitions(Canvas canvas, MooreMachine moore) {
    for (final transition in moore.transitions) {
      final fromState = moore.getState(transition.fromState);
      final toState = moore.getState(transition.toState);
      
      if (fromState != null && toState != null) {
        _drawTransition(
          canvas,
          Offset(fromState.x, fromState.y),
          Offset(toState.x, toState.y),
          transition.input,
          isSelected: selectedTransitions.contains('${transition.fromState}-${transition.toState}-${transition.input}'),
        );
      }
    }
  }

  void _drawTransition(
    Canvas canvas,
    Offset from,
    Offset to,
    String label, {
    bool isSelected = false,
  }) {
    final paint = Paint()
      ..color = isSelected ? Colors.blue.shade700 : Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : 2.0;

    // Calculate arrow position
    final direction = (to - from).direction;
    final distance = (to - from).distance;
    final arrowLength = 20.0;
    final arrowStart = from + Offset.fromDirection(direction, distance - 25 - arrowLength);
    final arrowEnd = from + Offset.fromDirection(direction, distance - 25);

    // Draw arrow line
    canvas.drawLine(arrowStart, arrowEnd, paint);

    // Draw arrowhead
    final arrowHead = Path();
    arrowHead.moveTo(arrowEnd.dx, arrowEnd.dy);
    arrowHead.lineTo(arrowEnd.dx - 8 * math.cos(direction), arrowEnd.dy - 8 * math.sin(direction));
    arrowHead.lineTo(arrowEnd.dx - 8 * math.cos(direction), arrowEnd.dy + 8 * math.sin(direction));
    arrowHead.close();
    
    canvas.drawPath(arrowHead, paint);

    // Draw label
    final labelPosition = from + Offset.fromDirection(direction, distance / 2);
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: isSelected ? Colors.blue.shade700 : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        labelPosition.dx - textPainter.width / 2,
        labelPosition.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
