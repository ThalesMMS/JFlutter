import 'dart:async';
import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/features/canvas/fl_nodes/base_fl_nodes_canvas_controller.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_tm_canvas_controller.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';

class _RecordingTmEditorNotifier extends TMEditorNotifier {
  final List<Map<String, Object?>> upsertStateCalls = [];
  final List<Map<String, Object?>> updateStateLabelCalls = [];
  final List<Map<String, Object?>> transitionCalls = [];
  final List<Map<String, Object?>> moveStateCalls = [];

  @override
  TM? upsertState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    upsertStateCalls.add({
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    });
    return null;
  }

  @override
  TM? moveState({
    required String id,
    required double x,
    required double y,
  }) {
    moveStateCalls.add({
      'id': id,
      'x': x,
      'y': y,
    });
    return null;
  }

  @override
  TM? updateStateLabel({
    required String id,
    required String label,
  }) {
    updateStateLabelCalls.add({'id': id, 'label': label});
    return null;
  }

  @override
  TM? addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    Vector2? controlPoint,
  }) {
    transitionCalls.add({
      'id': id,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'readSymbol': readSymbol,
      'writeSymbol': writeSymbol,
      'direction': direction,
      'controlPoint': controlPoint,
    });
    return null;
  }

  @override
  TM? removeTransition({required String id}) {
    return null;
  }
}

class _FakeLinkGeometryEvent extends NodeEditorEvent {
  _FakeLinkGeometryEvent({
    required this.linkId,
    required this.controlPoint,
  }) : super(id: 'geometry');

  final String linkId;
  final Offset? controlPoint;
}

class DragSelectionEndEvent extends NodeEditorEvent {
  DragSelectionEndEvent(
    this.position,
    this.nodeIds, {
    required super.id,
  });

  final Offset position;
  final Set<String> nodeIds;
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
}

NodeInstance _buildNode(
  FlNodesTmCanvasController controller, {
  required String id,
  required String label,
  required Offset offset,
}) {
  final prototype = controller.controller.nodePrototypes['tm_state']!;
  final inputPort =
      prototype.ports.firstWhere((port) => port.idName == 'incoming');
  final outputPort =
      prototype.ports.firstWhere((port) => port.idName == 'outgoing');
  final labelField =
      prototype.fields.firstWhere((field) => field.idName == 'label');

  return NodeInstance(
    id: id,
    prototype: prototype,
    ports: {
      'incoming': PortInstance(prototype: inputPort, state: PortState()),
      'outgoing': PortInstance(prototype: outputPort, state: PortState()),
    },
    fields: {
      'label': FieldInstance(prototype: labelField, data: label),
    },
    state: NodeState(),
    offset: offset,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlNodesTmCanvasController', () {
    late _RecordingTmEditorNotifier notifier;
    late FlNodesTmCanvasController controller;

    setUp(() {
      notifier = _RecordingTmEditorNotifier();
      controller = FlNodesTmCanvasController(
        editorNotifier: notifier,
        editorController: FlNodeEditorController(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('inherits from BaseFlNodesCanvasController', () {
      expect(controller, isA<BaseFlNodesCanvasController>());
    });

    test('viewport helpers adjust zoom and offset', () {
      controller.resetView();
      final initialZoom = controller.controller.viewportZoom;

      controller.zoomIn();
      expect(controller.controller.viewportZoom, greaterThan(initialZoom));

      controller.zoomOut();
      expect(
        controller.controller.viewportZoom,
        closeTo(initialZoom, 1e-6),
      );

      controller.controller.setViewportOffset(const Offset(18, -30));
      controller.controller.setViewportZoom(1.3);

      controller.resetView();
      expect(controller.controller.viewportOffset, equals(Offset.zero));
      expect(controller.controller.viewportZoom, closeTo(1.0, 1e-6));
    });

    test('fitToContent resets view when no nodes exist', () {
      controller.controller.setViewportOffset(const Offset(-28, 16));
      controller.controller.setViewportZoom(0.6);

      controller.fitToContent();

      expect(controller.controller.viewportOffset, equals(Offset.zero));
      expect(controller.controller.viewportZoom, closeTo(1.0, 1e-6));
    });

    test('highlight helpers update notifier state', () {
      const highlight = SimulationHighlight(transitionIds: {'edge'});

      controller.applyHighlight(highlight);
      expect(
        controller.highlightNotifier.value.transitionIds,
        contains('edge'),
      );

      controller.clearHighlight();
      expect(controller.highlightNotifier.value.transitionIds, isEmpty);
    });

    test('synchronize rebuilds controller state from TM', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'halt',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: '1/0,R',
        controlPoint: Vector2(60, 20),
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
      );
      final tm = TM(
        id: 'tm1',
        name: 'Binary inverter',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'0', '1'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: {'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      controller.synchronize(tm);

      final encodedNode = controller.nodeById('q0');
      final encodedEdge = controller.edgeById('t0');

      expect(encodedNode, isNotNull);
      expect(encodedNode!.isInitial, isTrue);
      expect(encodedNode.x, closeTo(0, 0.0001));
      expect(encodedNode.y, closeTo(0, 0.0001));

      expect(encodedEdge, isNotNull);
      expect(encodedEdge!.readSymbol, equals('1'));
      expect(encodedEdge.writeSymbol, equals('0'));
      expect(encodedEdge.direction, equals(TapeDirection.right));
      expect(encodedEdge.controlPointX, closeTo(60, 0.0001));
      expect(encodedEdge.controlPointY, closeTo(20, 0.0001));
    });

    test('captures control point drags for TM transitions', () async {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'halt',
        position: Vector2(160, 90),
      );
      final transition = TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: '1/0,R',
        controlPoint: Vector2.zero(),
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
      );
      final tm = TM(
        id: 'tm-ctrl',
        name: 'control point test',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'0', '1'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: {'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      controller.synchronize(tm);
      notifier.transitionCalls.clear();

      controller.controller.eventBus.emit(
        _FakeLinkGeometryEvent(
          linkId: 't0',
          controlPoint: const Offset(72, 24),
        ),
      );

      await _flushEvents();

      final edge = controller.edgeById('t0');
      expect(edge, isNotNull);
      expect(edge!.controlPointX, closeTo(72, 1e-6));
      expect(edge.controlPointY, closeTo(24, 1e-6));

      expect(notifier.transitionCalls, isNotEmpty);
      final lastCall = notifier.transitionCalls.last;
      final Vector2? recorded = lastCall['controlPoint'] as Vector2?;
      expect(recorded, isNotNull);
      expect(recorded!.x, closeTo(72, 1e-6));
      expect(recorded.y, closeTo(24, 1e-6));
    });

    test('records AddNodeEvent invocations', () async {
      final node = _buildNode(
        controller,
        id: 'q2',
        label: 'mid',
        offset: const Offset(30, 18),
      );

      controller.controller.eventBus.emit(
        AddNodeEvent(node, id: 'event-add'),
      );

      await _flushEvents();

      expect(notifier.upsertStateCalls, hasLength(1));
      final call = notifier.upsertStateCalls.single;
      expect(call['id'], equals('q2'));
      expect(call['label'], equals('mid'));
      expect(call['x'], equals(30.0));
      expect(call['y'], equals(18.0));
    });

    test('skips moveState when drag ends at original offset', () async {
      final node = _buildNode(
        controller,
        id: 'q3',
        label: 'idle',
        offset: const Offset(50, 60),
      );

      controller.controller.eventBus.emit(
        AddNodeEvent(node, id: 'seed-static'),
      );

      await _flushEvents();

      notifier.moveStateCalls.clear();

      final instance = controller.controller.nodes['q3']!;
      controller.controller.eventBus.emit(
        DragSelectionEndEvent(
          instance.offset,
          {'q3'},
          id: 'drag-static',
        ),
      );

      await _flushEvents();

      expect(notifier.moveStateCalls, isEmpty);
      final cached = controller.nodeById('q3');
      expect(cached, isNotNull);
      expect(cached!.x, equals(50.0));
      expect(cached.y, equals(60.0));
    });

    test('delegates label submissions through NodeFieldEvent', () async {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final tm = TM(
        id: 'tm1',
        name: 'Binary inverter',
        states: {q0},
        transitions: {},
        alphabet: {'0', '1'},
        initialState: q0,
        acceptingStates: {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: {'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      controller.synchronize(tm);

      controller.controller.eventBus.emit(
        const NodeFieldEvent(
          'q0',
          '  renamed  ',
          FieldEventType.submit,
          id: 'event-field',
        ),
      );

      await _flushEvents();

      expect(notifier.updateStateLabelCalls, hasLength(1));
      final call = notifier.updateStateLabelCalls.single;
      expect(call['id'], equals('q0'));
      expect(call['label'], equals('renamed'));
      expect(controller.nodeById('q0')!.label, equals('renamed'));
    });

    test('creates TM transition stubs on AddLinkEvent', () async {
      final node = _buildNode(
        controller,
        id: 'q0',
        label: 'start',
        offset: Offset.zero,
      );
      controller.controller.eventBus.emit(
        AddNodeEvent(node, id: 'seed'),
      );
      await _flushEvents();

      final link = Link(
        id: 't0',
        fromTo: (
          from: 'q0',
          to: 'q1',
          fromPort: 'outgoing',
          toPort: 'incoming',
        ),
        state: LinkState(),
      );

      controller.controller.eventBus.emit(
        AddLinkEvent(link, id: 'event-link'),
      );

      await _flushEvents();

      expect(notifier.transitionCalls, hasLength(1));
      final call = notifier.transitionCalls.single;
      expect(call['id'], equals('t0'));
      expect(call['fromStateId'], equals('q0'));
      expect(call['toStateId'], equals('q1'));
      expect(call['readSymbol'], equals(''));
      expect(call['writeSymbol'], equals(''));
      expect(call['direction'], equals(TapeDirection.right));
      final storedEdge = controller.edgeById('t0');
      expect(storedEdge, isNotNull);
      expect(storedEdge!.fromStateId, equals('q0'));
      expect(storedEdge.toStateId, equals('q1'));
    });

    test('applyHighlight toggles TM transitions without changing selection', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'halt',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: '1/0,R',
        controlPoint: Vector2(60, 20),
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
      );
      final tm = TM(
        id: 'tm1',
        name: 'Binary inverter',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'0', '1'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: {'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      controller.synchronize(tm);
      final editor = controller.controller;

      controller.applyHighlight(
        const SimulationHighlight(transitionIds: {'t0'}),
      );

      expect(editor.linksById['t0']!.state.isSelected, isTrue);
      expect(editor.selectedLinkIds, isEmpty);

      controller.synchronize(tm);
      expect(editor.linksById['t0']!.state.isSelected, isTrue);

      controller.clearHighlight();
      expect(editor.linksById['t0']!.state.isSelected, isFalse);
    });

    test('clearHighlight retains TM manual selections', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'halt',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: '1/0,R',
        controlPoint: Vector2(60, 20),
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
      );
      final tm = TM(
        id: 'tm1',
        name: 'Binary inverter',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'0', '1'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
        tapeAlphabet: {'0', '1', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
      );

      controller.synchronize(tm);
      final editor = controller.controller;

      editor.selectLinkById('t0');
      controller.applyHighlight(
        const SimulationHighlight(transitionIds: {'t0'}),
      );
      controller.clearHighlight();

      expect(editor.selectedLinkIds, contains('t0'));
      expect(editor.linksById['t0']!.state.isSelected, isTrue);
    });
  });
}
