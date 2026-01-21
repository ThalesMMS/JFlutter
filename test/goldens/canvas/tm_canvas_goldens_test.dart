//
//  tm_canvas_goldens_test.dart
//  JFlutter
//
//  Testes golden de regressão visual para TMCanvasGraphView, capturando
//  snapshots de estados críticos do canvas de máquinas de Turing: vazio, estados
//  únicos com marcações, múltiplos estados com transições TM (símbolos de
//  leitura, escrita e direção de movimento), e máquinas complexas. Garante
//  consistência visual entre mudanças e detecta regressões automáticas na
//  renderização de TMs.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_tool.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_graphview.dart';

class _TestTMEditorProvider extends TMEditorNotifier {
  _TestTMEditorProvider();
}

void main() {
  group('TMCanvasGraphView golden tests', () {
    testGoldens('renders empty canvas', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final tm = TM(
        id: 'empty',
        name: 'Empty TM',
        states: <automaton_state.State>{},
        transitions: <TMTransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_empty');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single normal state', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: false,
        isAccepting: false,
      );

      final tm = TM(
        id: 'single-state',
        name: 'Single State TM',
        states: <automaton_state.State>{state},
        transitions: <TMTransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_single_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single initial state', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: true,
        isAccepting: false,
      );

      final tm = TM(
        id: 'initial-state',
        name: 'Initial State TM',
        states: <automaton_state.State>{state},
        transitions: <TMTransition>{},
        alphabet: const <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_initial_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders single accepting state', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: false,
        isAccepting: true,
      );

      final tm = TM(
        id: 'accepting-state',
        name: 'Accepting State TM',
        states: <automaton_state.State>{state},
        transitions: <TMTransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{state},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_accepting_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders initial and accepting state', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: true,
        isAccepting: true,
      );

      final tm = TM(
        id: 'initial-accepting-state',
        name: 'Initial and Accepting State',
        states: <automaton_state.State>{state},
        transitions: <TMTransition>{},
        alphabet: const <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{state},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_initial_accepting_state');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders multiple states with TM transitions', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 150),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(300, 150),
        isInitial: false,
        isAccepting: true,
      );

      final transition = TMTransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
        label: 'a→b,R',
      );

      final tm = TM(
        id: 'two-states',
        name: 'Two States with TM Transition',
        states: <automaton_state.State>{q0, q1},
        transitions: <TMTransition>{transition},
        alphabet: const <String>{'a', 'b'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B', 'a', 'b'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(
        tester,
        'tm_canvas_multiple_states_with_transitions',
      );

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders self-loop transition', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(200, 150),
        isInitial: true,
        isAccepting: true,
      );

      final transition = TMTransition(
        id: 't1',
        fromState: q0,
        toState: q0,
        readSymbol: 'a',
        writeSymbol: 'a',
        direction: TapeDirection.right,
        label: 'a→a,R',
      );

      final tm = TM(
        id: 'self-loop',
        name: 'State with Self Loop',
        states: <automaton_state.State>{q0},
        transitions: <TMTransition>{transition},
        alphabet: const <String>{'a'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q0},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B', 'a'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_self_loop');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders binary incrementer TM', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 150),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(300, 150),
        isInitial: false,
        isAccepting: true,
      );

      final t1 = TMTransition(
        id: 't1',
        fromState: q0,
        toState: q0,
        readSymbol: '0',
        writeSymbol: '0',
        direction: TapeDirection.right,
        label: '0→0,R',
      );

      final t2 = TMTransition(
        id: 't2',
        fromState: q0,
        toState: q0,
        readSymbol: '1',
        writeSymbol: '1',
        direction: TapeDirection.right,
        label: '1→1,R',
      );

      final t3 = TMTransition(
        id: 't3',
        fromState: q0,
        toState: q1,
        readSymbol: 'B',
        writeSymbol: 'B',
        direction: TapeDirection.left,
        label: 'B→B,L',
      );

      final tm = TM(
        id: 'binary-incrementer',
        name: 'Binary Incrementer',
        states: <automaton_state.State>{q0, q1},
        transitions: <TMTransition>{t1, t2, t3},
        alphabet: const <String>{'0', '1'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B', '0', '1'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_binary_incrementer');

      controller.dispose();
      toolController.dispose();
    });

    testGoldens('renders complex TM with multiple transitions', (tester) async {
      final provider = _TestTMEditorProvider();
      final controller = GraphViewTmCanvasController(editorNotifier: provider);
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.selection,
      );

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(100, 150),
        isInitial: true,
        isAccepting: false,
      );

      final q1 = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(300, 100),
        isInitial: false,
        isAccepting: false,
      );

      final q2 = automaton_state.State(
        id: 'q2',
        label: 'q2',
        position: Vector2(300, 200),
        isInitial: false,
        isAccepting: true,
      );

      final t1 = TMTransition(
        id: 't1',
        fromState: q0,
        toState: q1,
        readSymbol: 'a',
        writeSymbol: 'X',
        direction: TapeDirection.right,
        label: 'a→X,R',
      );

      final t2 = TMTransition(
        id: 't2',
        fromState: q0,
        toState: q2,
        readSymbol: 'b',
        writeSymbol: 'Y',
        direction: TapeDirection.left,
        label: 'b→Y,L',
      );

      final t3 = TMTransition(
        id: 't3',
        fromState: q1,
        toState: q2,
        readSymbol: 'b',
        writeSymbol: 'Y',
        direction: TapeDirection.stay,
        label: 'b→Y,S',
      );

      final tm = TM(
        id: 'complex',
        name: 'Complex TM',
        states: <automaton_state.State>{q0, q1, q2},
        transitions: <TMTransition>{t1, t2, t3},
        alphabet: const <String>{'a', 'b'},
        initialState: q0,
        acceptingStates: <automaton_state.State>{q2},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: const {'B', 'a', 'b', 'X', 'Y'},
        blankSymbol: 'B',
      );

      provider.setTm(tm);
      controller.synchronize(tm);

      final widget = ProviderScope(
        overrides: [tmEditorProvider.overrideWith((ref) => provider)],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 300,
              child: TMCanvasGraphView(
                controller: controller,
                toolController: toolController,
                onTmModified: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidgetBuilder(widget);

      await screenMatchesGolden(tester, 'tm_canvas_complex');

      controller.dispose();
      toolController.dispose();
    });
  });
}
