//
//  graphview_canvas_toolbar_test.dart
//  JFlutter
//
//  Conjunto de testes de widget que exercita o GraphViewCanvasToolbar,
//  validando exibição de mensagens de status e disparo dos callbacks de zoom,
//  enquadramento, reset e histórico no controlador falso durante interações.
//  Os cenários confirmam que botões opcionais e ferramentas adicionais aparecem
//  apenas quando fornecidos, mantendo o contrato da interface responsiva.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/presentation/providers/automaton_state_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_tool.dart';
import 'package:jflutter/presentation/widgets/graphview_canvas_toolbar.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_controller.dart';

class _TestGraphViewCanvasController extends GraphViewCanvasController {
  _TestGraphViewCanvasController({required super.automatonStateNotifier});

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
  late AutomatonStateNotifier provider;
  late _TestGraphViewCanvasController controller;

  setUp(() {
    provider = AutomatonStateNotifier(automatonService: AutomatonService());
    controller = _TestGraphViewCanvasController(
      automatonStateNotifier: provider,
    )..synchronize(provider.state.currentAutomaton);
  });

  tearDown(() {
    controller.dispose();
  });

  testWidgets('GraphViewCanvasToolbar renders provided status message', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              statusMessage: '2 states · 1 transition',
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
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
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
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
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () => addStateInvoked = true,
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsNWidgets(6));

    await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
    await tester.pump();

    expect(addStateInvoked, isTrue);
  });

  testWidgets('Mobile layout renders filled buttons with labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.mobile,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Add state'), findsOneWidget);
    expect(find.text('Redo'), findsOneWidget);
    expect(find.text('Fit to content'), findsOneWidget);
    expect(find.text('Reset view'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('invokes controller commands when action buttons pressed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: () {},
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    final initialFitCount = controller.fitCount;
    final initialResetCount = controller.resetCount;

    await tester.tap(find.widgetWithIcon(IconButton, Icons.fit_screen));
    await tester.pump();

    expect(controller.fitCount, initialFitCount + 1);

    await tester.tap(
      find.widgetWithIcon(IconButton, Icons.center_focus_strong),
    );
    await tester.pump();

    expect(controller.resetCount, greaterThan(initialResetCount));
  });

  testWidgets('renders undo and redo buttons respecting history state', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: GraphViewCanvasToolbar(
              controller: controller,
              onAddState: controller.addStateAtCenter,
              layout: GraphViewCanvasToolbarLayout.desktop,
            ),
          ),
        ),
      ),
    );

    final undoFinder = find.widgetWithIcon(IconButton, Icons.undo);
    final redoFinder = find.widgetWithIcon(IconButton, Icons.redo);

    expect(tester.widget<IconButton>(undoFinder).onPressed, isNull);
    expect(tester.widget<IconButton>(redoFinder).onPressed, isNull);

    controller.addStateAtCenter();
    await tester.pumpAndSettle();

    expect(tester.widget<IconButton>(undoFinder).onPressed, isNotNull);
  });

  testWidgets('renders editing tool toggles when enabled', (tester) async {
    bool addStateInvoked = false;
    bool transitionInvoked = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
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
