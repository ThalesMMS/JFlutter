//
//  graphview_layout_algorithm.dart
//  JFlutter
//
//  Custom layout algorithm for automaton graphs that preserves node positions
//  from the controller cache, ensuring user-placed states remain in their
//  configured locations during graph rendering and layout operations.
//
//  Extracted from automaton_graphview_canvas.dart - January 2026
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/constants/automaton_canvas.dart';
import 'base_graphview_canvas_controller.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;

/// Custom Sugiyama layout algorithm that preserves node positions from the
/// controller's cache rather than computing new positions automatically.
///
/// This ensures that user-placed automaton states remain exactly where they
/// were positioned, maintaining the visual layout across re-renders and
/// graph updates.
class AutomatonGraphSugiyamaAlgorithm extends SugiyamaAlgorithm {
  AutomatonGraphSugiyamaAlgorithm({
    required this.controller,
    required SugiyamaConfiguration configuration,
  }) : super(configuration);

  final BaseGraphViewCanvasController<dynamic, dynamic> controller;

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in graph.nodes) {
      final position = node.position;

      node.position = position;

      minX = math.min(minX, position.dx);
      minY = math.min(minY, position.dy);
      maxX = math.max(maxX, position.dx + node.width);
      maxY = math.max(maxY, position.dy + node.height);
    }

    if (minX == double.infinity || minY == double.infinity) {
      return Size.zero;
    }

    final width = (maxX - minX).clamp(0.0, double.infinity) + _kNodeDiameter;
    final height = (maxY - minY).clamp(0.0, double.infinity) + _kNodeDiameter;

    return Size(width, height);
  }
}
