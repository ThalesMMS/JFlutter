// ============================================================================
// JFlutter - Suite de Testes
// ----------------------------------------------------------------------------
// Arquivo: test/features/canvas/graphview/graphview_tm_canvas_controller_test.dart
// Objetivo: Garantir que o controlador GraphView para MT sincronize estados,
// transições e seleção com o provider.
// Cenários cobertos:
// - Construção de grafo a partir de máquinas de Turing e atualizações em tempo real.
// - Seleção de transições e estados, emitindo eventos correspondentes.
// - Descarte seguro de recursos após uso.
// Autoria: Equipe de Qualidade JFlutter.
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:jflutter/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewTmCanvasController', () {
    late TMEditorNotifier notifier;
    late GraphViewTmCanvasController controller;

    setUp(() {
      notifier = TMEditorNotifier();
      controller = GraphViewTmCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    TM _buildSampleTm() {
      final initialState = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final acceptingState = State(
        id: 'q1',
        label: 'accept',
        position: Vector2(200, 120),
        isInitial: false,
        isAccepting: true,
      );
      final transition = TMTransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'a/b,R',
        controlPoint: Vector2(42, 30),
        type: TransitionType.deterministic,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );
      return TM(
        id: 'tm-1',
        name: 'Sample TM',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: {'a', 'b'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2023, 1, 1),
        modified: DateTime.utc(2023, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        tapeAlphabet: {'a', 'b', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
        panOffset: Vector2.zero(),
        zoomLevel: 1,
      );
    }

    test('synchronize populates TM nodes and edges', () {
      final tm = _buildSampleTm();

      controller.synchronize(tm);

      final node = controller.nodeById('q0');
      expect(node, isNotNull);
      expect(node!.label, equals('start'));
      final edge = controller.edgeById('t0');
      expect(edge, isNotNull);
      expect(edge!.readSymbol, equals('a'));
      expect(edge.writeSymbol, equals('b'));
    });

    test('addStateAt inserts state into notifier', () {
      controller.addStateAt(const Offset(12, 24));

      final tm = notifier.state.tm;
      expect(tm, isNotNull);
      expect(tm!.states.length, equals(1));
      final state = tm.states.single;
      expect(state.position.x, closeTo(12, 0.0001));
      expect(state.position.y, closeTo(24, 0.0001));
    });

    test('addStateAtCenter resolves world position from viewport centre', () {
      final transformation = controller.graphController.transformationController;
      expect(transformation, isNotNull);
      controller.updateViewportSize(const Size(600, 400));

      transformation!.value = Matrix4.identity();
      controller.addStateAtCenter();

      var tm = notifier.state.tm;
      expect(tm, isNotNull);
      var states = tm!.states.toList(growable: false);
      expect(states, hasLength(1));
      expect(states.first.position.x, closeTo(300, 0.0001));
      expect(states.first.position.y, closeTo(200, 0.0001));

      transformation.value = Matrix4.identity()
        ..translate(-120.0, 80.0)
        ..scale(0.8);
      controller.addStateAtCenter();

      tm = notifier.state.tm;
      expect(tm, isNotNull);
      states = tm!.states.toList(growable: false);
      expect(states, hasLength(2));
      final latest = states.last;
      expect(latest.position.x, closeTo((300 - (-120)) / 0.8, 0.0001));
      expect(latest.position.y, closeTo((200 - 80) / 0.8, 0.0001));
    });

    test('addOrUpdateTransition stores TM transition data', () {
      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(160, 100));
      final tm = notifier.state.tm!;
      final stateIds = tm.states.map((state) => state.id).toList();

      controller.addOrUpdateTransition(
        fromStateId: stateIds.first,
        toStateId: stateIds.last,
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.left,
      );

      final updated = notifier.state.tm!;
      expect(updated.tmTransitions, hasLength(1));
      final transition = updated.tmTransitions.single;
      expect(transition.readSymbol, equals('1'));
      expect(transition.writeSymbol, equals('0'));
      expect(transition.direction, equals(TapeDirection.left));
    });

    test('removeTransition removes TM transition', () {
      final tm = _buildSampleTm();
      notifier.setTm(tm);
      controller.synchronize(tm);

      controller.removeTransition('t0');

      final updated = notifier.state.tm!;
      expect(updated.tmTransitions, isEmpty);
    });

    test('applySnapshotToDomain rebuilds TM and synchronizes controller', () {
      final snapshot = GraphViewAutomatonSnapshot(
        nodes: const [
          GraphViewCanvasNode(
            id: 'q0',
            label: 'start',
            x: 20,
            y: 30,
            isInitial: true,
            isAccepting: false,
          ),
          GraphViewCanvasNode(
            id: 'q1',
            label: 'accept',
            x: 200,
            y: 150,
            isInitial: false,
            isAccepting: true,
          ),
        ],
        edges: const [
          GraphViewCanvasEdge(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            symbols: <String>[],
            controlPointX: 50,
            controlPointY: 42,
            readSymbol: '0',
            writeSymbol: '1',
            direction: TapeDirection.stay,
          ),
        ],
        metadata: const GraphViewAutomatonMetadata(
          id: 'tm-1',
          name: 'Snapshot TM',
          alphabet: ['0', '1'],
        ),
      );

      controller.applySnapshotToDomain(snapshot);

      final rebuilt = notifier.state.tm;
      expect(rebuilt, isNotNull);
      expect(rebuilt!.states.length, equals(2));
      final transition = rebuilt.tmTransitions.single;
      expect(transition.readSymbol, equals('0'));
      expect(transition.writeSymbol, equals('1'));
      expect(transition.direction, equals(TapeDirection.stay));
      expect(controller.nodeById('q0'), isNotNull);
      expect(controller.edgeById('t0'), isNotNull);
    });
  });
}
