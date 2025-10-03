import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/fl_nodes_canvas_toolbar.dart';

void main() {
  testWidgets('FlNodesCanvasToolbar renders provided status message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlNodesCanvasToolbar(
            onAddState: _noop,
            onZoomIn: _noop,
            onZoomOut: _noop,
            onFitToContent: _noop,
            onResetView: _noop,
            statusMessage: '3 states · 4 transitions',
          ),
        ),
      ),
    );

    expect(find.text('3 states · 4 transitions'), findsOneWidget);
  });

  testWidgets('FlNodesCanvasToolbar hides status message when absent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlNodesCanvasToolbar(
            onAddState: _noop,
            onZoomIn: _noop,
            onZoomOut: _noop,
            onFitToContent: _noop,
            onResetView: _noop,
          ),
        ),
      ),
    );

    expect(find.textContaining('states'), findsNothing);
    expect(find.textContaining('transitions'), findsNothing);
  });
}

void _noop() {}
