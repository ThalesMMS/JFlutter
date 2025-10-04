import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/fl_nodes_canvas_toolbar.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_tool.dart';

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
            layout: FlNodesCanvasToolbarLayout.desktop,
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
            layout: FlNodesCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.textContaining('states'), findsNothing);
    expect(find.textContaining('transitions'), findsNothing);
  });

  testWidgets('Desktop layout renders compact icon buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlNodesCanvasToolbar(
            onAddState: _noop,
            onZoomIn: _noop,
            onZoomOut: _noop,
            onFitToContent: _noop,
            onResetView: _noop,
            layout: FlNodesCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(5));
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('Mobile layout renders filled buttons with labels', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FlNodesCanvasToolbar(
            onAddState: _noop,
            onZoomIn: _noop,
            onZoomOut: _noop,
            onFitToContent: _noop,
            onResetView: _noop,
            layout: FlNodesCanvasToolbarLayout.mobile,
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNWidgets(5));
    expect(find.text('Add state'), findsOneWidget);
    expect(find.text('Zoom in'), findsOneWidget);
  });

  testWidgets('renders undo and redo buttons with enabled state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlNodesCanvasToolbar(
            onAddState: _noop,
            onZoomIn: _noop,
            onZoomOut: _noop,
            onFitToContent: _noop,
            onResetView: _noop,
            onUndo: _noop,
            onRedo: _noop,
            canUndo: false,
            canRedo: true,
            layout: FlNodesCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    final undoButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo));
    final redoButton =
        tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.redo));

    expect(undoButton.onPressed, isNull);
    expect(redoButton.onPressed, isNotNull);
  });

  testWidgets('renders editing tool toggles when enabled', (tester) async {
    var selectionInvoked = false;
    var addStateInvoked = false;
    var transitionInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlNodesCanvasToolbar(
            enableToolSelection: true,
            activeTool: AutomatonCanvasTool.transition,
            onSelectTool: () => selectionInvoked = true,
            onAddState: () => addStateInvoked = true,
            onAddTransition: () => transitionInvoked = true,
            onZoomIn: _noop,
            onZoomOut: _noop,
            onFitToContent: _noop,
            onResetView: _noop,
            layout: FlNodesCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.widgetWithIcon(IconButton, Icons.pan_tool), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.arrow_right_alt), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.pan_tool));
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_right_alt));
    await tester.pump();

    expect(selectionInvoked, isTrue);
    expect(addStateInvoked, isTrue);
    expect(transitionInvoked, isTrue);
  });
}

void _noop() {}
