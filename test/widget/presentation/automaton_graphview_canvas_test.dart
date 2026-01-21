//
//  automaton_graphview_canvas_test.dart
//  JFlutter
//
//  Suite abrangente que examina o AutomatonGraphViewCanvas, garantindo
//  integração com provedores simulados, controlador personalizado e repositório
//  de layout em cenários de interação por gestos. Os testes validam adição e
//  movimentação de estados, edição inline de transições e respostas a layouts
//  não suportados, assegurando consistência entre a interface e o estado do
//  autômato.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:jflutter/features/canvas/graphview/graphview_label_field_editor.dart';
import 'package:jflutter/presentation/providers/automaton_state_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_tool.dart';
import 'package:jflutter/presentation/widgets/automaton_graphview_canvas.dart';

class _RecordingAutomatonStateNotifier extends AutomatonStateNotifier {
  _RecordingAutomatonStateNotifier()
    : super(automatonService: AutomatonService());

  final List<Map<String, Object?>> transitionCalls = [];

  @override
  void addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    double? controlPointX,
    double? controlPointY,
  }) {
    transitionCalls.add({
      'id': id,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'label': label,
      'controlPointX': controlPointX,
      'controlPointY': controlPointY,
    });
    super.addOrUpdateTransition(
      id: id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      label: label,
      controlPointX: controlPointX,
      controlPointY: controlPointY,
    );
  }
}

class _RecordingGraphViewCanvasController extends GraphViewCanvasController {
  _RecordingGraphViewCanvasController({
    required super.automatonStateNotifier,
  });

  int addStateAtCallCount = 0;
  Offset? lastAddStateWorldOffset;
  int moveStateCallCount = 0;
  String? lastMoveStateId;
  Offset? lastMoveStatePosition;

  @override
  void addStateAt(Offset worldPosition) {
    addStateAtCallCount++;
    lastAddStateWorldOffset = worldPosition;
  }

  @override
  void moveState(String id, Offset position) {
    moveStateCallCount++;
    lastMoveStateId = id;
    lastMoveStatePosition = position;
    super.moveState(id, position);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonGraphViewCanvas gestures', () {
    late _RecordingAutomatonStateNotifier provider;
    late _RecordingGraphViewCanvasController controller;
    late AutomatonCanvasToolController toolController;

    setUp(() {
      provider = _RecordingAutomatonStateNotifier();
      controller = _RecordingGraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.addState,
      );
    });

    tearDown(() {
      controller.dispose();
      toolController.dispose();
    });

    testWidgets(
      'delegates taps on empty background to controller when add-state tool is active',
      (tester) async {
        final automaton = FSA(
          id: 'empty',
          name: 'Empty Automaton',
          states: <automaton_state.State>{},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: null,
          acceptingStates: <automaton_state.State>{},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);
        controller.synchronize(automaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byType(AutomatonGraphViewCanvas));
        await tester.pump();

        expect(controller.addStateAtCallCount, equals(1));
        expect(controller.lastAddStateWorldOffset, isNotNull);
      },
    );

    for (final tool in [
      AutomatonCanvasTool.addState,
      AutomatonCanvasTool.transition,
    ]) {
      testWidgets(
        "ignores drag gestures when ${tool.toString().split('.').last} tool is active",
        (tester) async {
          toolController.setActiveTool(tool);
          final state = automaton_state.State(
            id: 'A',
            label: 'A',
            position: Vector2(40, 40),
            isInitial: true,
          );
          final automaton = FSA(
            id: 'drag',
            name: 'Automaton',
            states: {state},
            transitions: const <FSATransition>{},
            alphabet: const <String>{'a'},
            initialState: state,
            acceptingStates: <automaton_state.State>{},
            created: DateTime.utc(2024, 1, 1),
            modified: DateTime.utc(2024, 1, 1),
            bounds: const math.Rectangle<double>(0, 0, 400, 300),
            zoomLevel: 1,
            panOffset: Vector2.zero(),
          );

          provider.updateAutomaton(automaton);
          controller.synchronize(automaton);

          final canvasKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AutomatonGraphViewCanvas(
                  automaton: automaton,
                  canvasKey: canvasKey,
                  controller: controller,
                  toolController: toolController,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final transformation =
              controller.graphController.transformationController;
          expect(transformation, isNotNull);
          final initialMatrix = List<double>.from(
            transformation!.value.storage,
          );

          await tester.drag(find.text('A'), const Offset(32, 0));
          await tester.pump();

          await tester.drag(find.byKey(canvasKey), const Offset(48, -16));
          await tester.pump();

          expect(controller.moveStateCallCount, equals(0));
          expect(controller.lastMoveStateId, isNull);
          expect(
            List<double>.from(transformation.value.storage),
            equals(initialMatrix),
          );
        },
      );
    }
  });

  group('AutomatonGraphViewCanvas', () {
    late _RecordingAutomatonStateNotifier provider;
    late GraphViewCanvasController controller;
    late AutomatonCanvasToolController toolController;
    late automaton_state.State stateA;
    late automaton_state.State stateB;

    setUp(() {
      provider = _RecordingAutomatonStateNotifier();
      controller = GraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );

      stateA = automaton_state.State(
        id: 'A',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      stateB = automaton_state.State(
        id: 'B',
        label: 'B',
        position: Vector2(200, 160),
        isAccepting: true,
      );
    });

    tearDown(() {
      controller.dispose();
      toolController.dispose();
    });

    FSA buildAutomaton(Set<FSATransition> transitions) {
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {stateA, stateB},
        transitions: transitions,
        alphabet: const {'a', 'b'},
        initialState: stateA,
        acceptingStates: {stateB},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      return automaton;
    }

    Future<void> pumpCanvas(WidgetTester tester, FSA automaton) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'shows transition editor after jittery taps when transition tool is active',
      (tester) async {
        final automaton = buildAutomaton({});

        await pumpCanvas(tester, automaton);

        final sourceGesture = await tester.startGesture(
          tester.getCenter(find.text('A')),
        );
        await sourceGesture.moveBy(const Offset(1, 1));
        await sourceGesture.up();
        await tester.pump();

        final targetGesture = await tester.startGesture(
          tester.getCenter(find.text('B')),
        );
        await targetGesture.moveBy(const Offset(1, -1));
        await targetGesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
      },
    );

    testWidgets('allows creating a new edge when one already exists', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      final createNewFinder = find.byKey(
        const ValueKey('automaton-transition-choice-create-new'),
      );
      expect(createNewFinder, findsOneWidget);
      await tester.tap(createNewFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'b');
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], isNot(equals(existingId)));
      expect(call['fromStateId'], equals('A'));
      expect(call['toStateId'], equals('B'));
      expect(call['label'], equals('b'));
    });

    testWidgets('edits an existing transition selected from the dialog', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();

      final existingOptionFinder = find.byKey(
        const ValueKey('automaton-transition-choice-transition_existing'),
      );
      expect(existingOptionFinder, findsOneWidget);
      await tester.tap(existingOptionFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, equals('x'));

      await tester.enterText(textFieldFinder, 'edited');
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], equals(existingId));
      expect(call['label'], equals('edited'));
    });
  });
}
