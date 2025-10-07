/// ---------------------------------------------------------------------------
/// Teste: toolbar do canvas GraphView e integração com controlador.
/// Resumo: Exercita botões de zoom, ajuste e undo/redo, além de ferramentas de
/// edição, confirmando o disparo das ações no controlador associado.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_tool.dart';
import 'package:jflutter/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_controller.dart';

class _TestGraphViewCanvasController extends GraphViewCanvasController {
  _TestGraphViewCanvasController({required AutomatonProvider automatonProvider})
    : super(automatonProvider: automatonProvider);

  int zoomInCount = 0;
  int zoomOutCount = 0;
  int fitCount = 0;
  int resetCount = 0;
  int undoCount = 0;
  int redoCount = 0;

  @override
  void zoomIn() {
    zoomInCount++;
    super.zoomIn();
  }

  @override
  void zoomOut() {
    zoomOutCount++;
    super.zoomOut();
  }

  @override
  void fitToContent() {
    fitCount++;
    super.fitToContent();
  }

  @override
  void resetView() {
    resetCount++;
    super.resetView();
  }

  @override
  bool undo() {
    undoCount++;
    return super.undo();
  }

  @override
  bool redo() {
    redoCount++;
    return super.redo();
  }
}

void main() {
  late AutomatonProvider provider;
  late _TestGraphViewCanvasController controller;

  setUp(() {
    provider = AutomatonProvider(
      automatonService: AutomatonService(),
      layoutRepository: LayoutRepositoryImpl(),
    );
    controller = _TestGraphViewCanvasController(automatonProvider: provider)
      ..synchronize(provider.state.currentAutomaton);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('GraphViewCanvasToolbar renders provided status message', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            onAddState: () {},
            statusMessage: '2 states · 1 transition',
            layout: GraphViewCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.text('2 states · 1 transition'), findsOneWidget);
  });

  testWidgets('GraphViewCanvasToolbar hides status message when absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            onAddState: () {},
            layout: GraphViewCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.textContaining('states'), findsNothing);
    expect(find.textContaining('transition'), findsNothing);
  });

  testWidgets('Desktop layout renders expected actions', (tester) async {
    bool addStateInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            onAddState: () => addStateInvoked = true,
            layout: GraphViewCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(5));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(addStateInvoked, isTrue);
  });

  testWidgets('Mobile layout renders filled buttons with labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            onAddState: () {},
            layout: GraphViewCanvasToolbarLayout.mobile,
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNWidgets(5));
    expect(find.text('Add state'), findsOneWidget);
    expect(find.text('Fit to content'), findsOneWidget);
    expect(find.text('Reset view'), findsOneWidget);
  });

  testWidgets('invokes controller commands when action buttons pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            onAddState: () {},
            layout: GraphViewCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    await tester.tap(find.widgetWithIcon(IconButton, Icons.fit_screen));
    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.center_focus_strong),
    );
    await tester.pump();

    expect(controller.fitCount, 1);
    expect(controller.resetCount, 1);
  });

  testWidgets('renders undo and redo buttons respecting history state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            onAddState: controller.addStateAtCenter,
            layout: GraphViewCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    final undoFinder = find.widgetWithIcon(IconButton, Icons.undo);
    final redoFinder = find.widgetWithIcon(IconButton, Icons.redo);

    expect(tester.widget<IconButton>(undoFinder).onPressed, isNull);
    expect(tester.widget<IconButton>(redoFinder).onPressed, isNull);

    controller.addStateAtCenter();
    await tester.pump();

    expect(tester.widget<IconButton>(undoFinder).onPressed, isNotNull);

    controller.undo();
    await tester.pump();

    expect(tester.widget<IconButton>(redoFinder).onPressed, isNotNull);
  });

  testWidgets('renders editing tool toggles when enabled', (tester) async {
    bool addStateInvoked = false;
    bool transitionInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewCanvasToolbar(
            controller: controller,
            enableToolSelection: true,
            activeTool: AutomatonCanvasTool.transition,
            onAddState: () => addStateInvoked = true,
            onAddTransition: () => transitionInvoked = true,
            layout: GraphViewCanvasToolbarLayout.desktop,
          ),
        ),
      ),
    );

    expect(find.widgetWithIcon(IconButton, Icons.pan_tool), findsNothing);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_right_alt));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(transitionInvoked, isTrue);
  });
}
