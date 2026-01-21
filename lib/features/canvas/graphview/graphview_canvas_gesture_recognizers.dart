//
//  graphview_canvas_gesture_recognizers.dart
//  JFlutter
//
//  Gesture recognizers responsáveis por gerenciar interações com o canvas
//  GraphView, incluindo arrastar estados, toques em nós e interações com
//  ferramentas.
//  Encapsula a lógica de detecção de gestos para manipular estados de
//  autômatos enquanto evita conflitos entre gestos de arrastar nós e
//  panorâmica do canvas.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'graphview_canvas_models.dart';
import '../../presentation/widgets/automaton_canvas_tool.dart';

typedef NodeHitTester = GraphViewCanvasNode? Function(Offset globalPosition);
typedef ToolResolver = AutomatonCanvasTool Function();

class NodePanGestureRecognizer extends PanGestureRecognizer {
  NodePanGestureRecognizer({
    required this.hitTester,
    required this.toolResolver,
    this.onPointerDown,
    this.onDragAccepted,
    this.onDragReleased,
  });

  final NodeHitTester hitTester;
  final ToolResolver toolResolver;
  final ValueChanged<Offset>? onPointerDown;
  final VoidCallback? onDragAccepted;
  final VoidCallback? onDragReleased;

  int? _activePointer;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    debugPrint(
      '[NodePanRecognizer] addAllowedPointer pointer ${event.pointer} '
      'tool=${toolResolver().name} active=$_activePointer '
      'position=${event.position} dragStart=$dragStartBehavior',
    );
    onPointerDown?.call(event.position);
    if (_activePointer != null) {
      debugPrint('[NodePanRecognizer] pointer already active -> ignore');
      return;
    }
    final tool = toolResolver();
    if (tool == AutomatonCanvasTool.transition) {
      debugPrint('[NodePanRecognizer] tool transition -> ignore');
      return;
    }
    final node = hitTester(event.position);
    if (node == null) {
      debugPrint('[NodePanRecognizer] no node hit -> ignore');
      return;
    }
    _activePointer = event.pointer;
    debugPrint(
      '[NodePanRecognizer] tracking pointer ${event.pointer} '
      'for node ${node.id}',
    );
    onDragAccepted?.call();
    super.addAllowedPointer(event);
    resolvePointer(event.pointer, GestureDisposition.accepted);
  }

  @override
  void rejectGesture(int pointer) {
    debugPrint('[NodePanRecognizer] rejectGesture pointer=$pointer');
    if (pointer == _activePointer) {
      _activePointer = null;
      onDragReleased?.call();
    }
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    debugPrint('[NodePanRecognizer] didStopTracking pointer=$pointer');
    if (pointer == _activePointer) {
      _activePointer = null;
      onDragReleased?.call();
    }
    super.didStopTrackingLastPointer(pointer);
  }
}
