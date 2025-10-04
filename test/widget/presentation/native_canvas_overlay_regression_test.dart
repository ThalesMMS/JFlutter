import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_native.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';

void main() {
  testWidgets(
    'Automaton overlay follows selection and viewport changes',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          automatonProvider.overrideWith(
            (ref) => AutomatonProvider(
              automatonService: AutomatonService(),
              layoutRepository: LayoutRepositoryImpl(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = FlNodesCanvasController(
        automatonProvider: container.read(automatonProvider.notifier),
      );
      addTearDown(controller.dispose);

      final canvasKey = GlobalKey();
      final automaton = _createSampleAutomaton();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 640,
                height: 360,
                child: AutomatonCanvas(
                  automaton: automaton,
                  canvasKey: canvasKey,
                  controller: controller,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const overlayKey = ValueKey('transition-editor-t0-a');
      expect(find.byKey(overlayKey), findsNothing);

      controller.controller.selectLinkById('t0');
      await tester.pump();

      final overlayFinder = find.byKey(overlayKey);
      expect(overlayFinder, findsOneWidget);

      final initialOffset = tester.getTopLeft(overlayFinder);

      controller.controller.viewportOffsetNotifier.value = const Offset(24, -12);
      await tester.pump();

      final shiftedOffset = tester.getTopLeft(overlayFinder);
      expect(shiftedOffset, isNot(equals(initialOffset)));

      controller.controller.clearSelection();
      await tester.pump();

      expect(overlayFinder, findsNothing);
    },
  );

  testWidgets('Automaton node headers react to highlight updates', (tester) async {
    final container = ProviderContainer(
      overrides: [
        automatonProvider.overrideWith(
          (ref) => AutomatonProvider(
            automatonService: AutomatonService(),
            layoutRepository: LayoutRepositoryImpl(),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = FlNodesCanvasController(
      automatonProvider: container.read(automatonProvider.notifier),
    );
    addTearDown(controller.dispose);

    final theme = ThemeData.from(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: theme,
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 360,
              child: AutomatonCanvas(
                automaton: _createSampleAutomaton(),
                canvasKey: GlobalKey(),
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final headerFinder = find.ancestor(
      of: find.byKey(const Key('automaton-node-q0-initial-toggle')),
      matching: find.byType(Container),
    ).first;

    Color? resolveHeaderColor() {
      final containerWidget = tester.widget<Container>(headerFinder);
      final decoration = containerWidget.decoration;
      return decoration is BoxDecoration ? decoration.color : null;
    }

    final initialColor = resolveHeaderColor();

    controller.highlightNotifier.value =
        const SimulationHighlight(stateIds: {'q0'});
    await tester.pump();

    final highlightedColor = resolveHeaderColor();
    expect(initialColor, isNotNull);
    expect(highlightedColor, isNotNull);
    expect(highlightedColor, isNot(equals(initialColor)));
  });

  testWidgets('TM canvas exposes transition editor when selecting a link',
      (tester) async {
    final tmNotifier = TMEditorNotifier();
    addTearDown(tmNotifier.dispose);

    tmNotifier.upsertState(
      id: 'q0',
      label: 'q0',
      x: 0,
      y: 0,
      isInitial: true,
    );
    tmNotifier.upsertState(
      id: 'q1',
      label: 'q1',
      x: 200,
      y: 0,
    );
    tmNotifier.addOrUpdateTransition(
      id: 't0',
      fromStateId: 'q0',
      toStateId: 'q1',
      readSymbol: 'a',
      writeSymbol: 'b',
      direction: TapeDirection.right,
      controlPoint: Vector2(100, -40),
    );

    final controller = FlNodesTmCanvasController(editorNotifier: tmNotifier);
    addTearDown(controller.dispose);

    final container = ProviderContainer(
      overrides: [tmEditorProvider.overrideWith((ref) => tmNotifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 360,
              child: TMCanvasNative(
                onTMModified: (_) {},
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    const overlayKey =
        ValueKey('tm-transition-editor-t0-a-b-right');
    expect(find.byKey(overlayKey), findsNothing);

    controller.controller.selectLinkById('t0');
    await tester.pump();

    expect(find.byKey(overlayKey), findsOneWidget);

    controller.controller.clearSelection();
    await tester.pump();

    expect(find.byKey(overlayKey), findsNothing);
  });

  testWidgets('PDA canvas exposes transition editor for selected links',
      (tester) async {
    final pdaNotifier = PDAEditorNotifier();
    addTearDown(pdaNotifier.dispose);

    pdaNotifier.upsertState(
      id: 'q0',
      label: 'q0',
      x: 0,
      y: 0,
      isInitial: true,
    );
    pdaNotifier.upsertState(
      id: 'q1',
      label: 'q1',
      x: 200,
      y: 0,
    );
    pdaNotifier.addOrUpdateTransition(
      id: 't0',
      fromStateId: 'q0',
      toStateId: 'q1',
      readSymbol: 'a',
      popSymbol: 'Z',
      pushSymbol: 'AZ',
      isLambdaInput: false,
      isLambdaPop: false,
      isLambdaPush: false,
      controlPoint: Vector2(100, -40),
    );

    final controller = FlNodesPdaCanvasController(
      editorNotifier: pdaNotifier,
    );
    addTearDown(controller.dispose);

    final container = ProviderContainer(
      overrides: [pdaEditorProvider.overrideWith((ref) => pdaNotifier)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 360,
              child: PDACanvasNative(
                onPdaModified: (_) {},
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    const overlayKey = ValueKey(
      'pda-transition-editor-t0-a-Z-AZ-false-false-false',
    );
    expect(find.byKey(overlayKey), findsNothing);

    controller.controller.selectLinkById('t0');
    await tester.pump();

    expect(find.byKey(overlayKey), findsOneWidget);

    controller.controller.clearSelection();
    await tester.pump();

    expect(find.byKey(overlayKey), findsNothing);
  });
}

FSA _createSampleAutomaton() {
  final q0 = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(200, 0),
    isAccepting: true,
  );
  final transition = FSATransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    inputSymbols: const {'a'},
    controlPoint: Vector2(100, -60),
  );

  final now = DateTime(2023, 1, 1);
  return FSA(
    id: 'fsa-test',
    name: 'Test',
    states: {q0, q1},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(-300, -200, 600, 400),
  );
}
