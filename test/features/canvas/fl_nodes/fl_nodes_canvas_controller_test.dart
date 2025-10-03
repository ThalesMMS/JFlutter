import 'dart:async';
import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
// ignore: implementation_imports
import 'package:fl_nodes/src/core/models/events.dart'
    show DragSelectionEndEvent, NodeEditorEvent;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';

class _FakeLayoutRepository implements LayoutRepository {
  Future<AutomatonResult> _unsupported() async {
    return ResultFactory.failure('unsupported');
  }

  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) =>
      _unsupported();

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) =>
      _unsupported();

  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) =>
      _unsupported();

  @override
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton) =>
      _unsupported();

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) =>
      _unsupported();

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) =>
      _unsupported();
}

class _RecordingAutomatonProvider extends AutomatonProvider {
  _RecordingAutomatonProvider()
      : super(
          automatonService: AutomatonService(),
          layoutRepository: _FakeLayoutRepository(),
        );

  final List<Map<String, Object?>> addStateCalls = [];
  final List<Map<String, Object?>> updateLabelCalls = [];
  final List<Map<String, Object?>> transitionCalls = [];
  final List<Map<String, Object?>> moveStateCalls = [];

  @override
  void addState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    addStateCalls.add({
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    });
    super.addState(
      id: id,
      label: label,
      x: x,
      y: y,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
  }

  @override
  void removeState({required String id}) {
    // Intentionally left blank for tests.
  }

  @override
  void moveState({
    required String id,
    required double x,
    required double y,
  }) {
    moveStateCalls.add({
      'id': id,
      'x': x,
      'y': y,
    });
  }

  @override
  void updateStateLabel({
    required String id,
    required String label,
  }) {
    updateLabelCalls.add({'id': id, 'label': label});
  }

  @override
  void addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    String? label,
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
  }

  @override
  void removeTransition({required String id}) {
    // Intentionally left blank for tests.
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

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
}

NodeInstance _buildNode(
  FlNodesCanvasController controller, {
  required String id,
  required String label,
  required Offset offset,
}) {
  final prototype = controller.controller.nodePrototypes['automaton_state']!;
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

  group('FlNodesCanvasController', () {
    late _RecordingAutomatonProvider provider;
    late FlNodesCanvasController controller;

    setUp(() {
      provider = _RecordingAutomatonProvider();
      controller = FlNodesCanvasController(
        automatonProvider: provider,
        editorController: FlNodeEditorController(),
      );
    });

    tearDown(() {
      controller.dispose();
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

      controller.controller.setViewportOffset(const Offset(12, -24));
      controller.controller.setViewportZoom(1.5);

      controller.resetView();
      expect(controller.controller.viewportOffset, equals(Offset.zero));
      expect(controller.controller.viewportZoom, closeTo(1.0, 1e-6));
    });

    test('fitToContent resets view when no nodes exist', () {
      controller.controller.setViewportOffset(const Offset(-48, 32));
      controller.controller.setViewportZoom(0.4);

      controller.fitToContent();

      expect(controller.controller.viewportOffset, equals(Offset.zero));
      expect(controller.controller.viewportZoom, closeTo(1.0, 1e-6));
    });

    test('highlight helpers update notifier state', () {
      const highlight = SimulationHighlight(transitionIds: {'t42'});

      controller.applyHighlight(highlight);
      expect(
        controller.highlightNotifier.value.transitionIds,
        contains('t42'),
      );

      controller.clearHighlight();
      expect(controller.highlightNotifier.value.transitionIds, isEmpty);
    });

    test('synchronize populates nodes and edges from automaton', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      );
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      controller.synchronize(automaton);

      final encodedInitial = controller.nodeById('q0');
      final encodedEdge = controller.edgeById('t0');

      expect(encodedInitial, isNotNull);
      expect(encodedInitial!.isInitial, isTrue);
      expect(encodedInitial.x, closeTo(0, 0.0001));
      expect(encodedInitial.y, closeTo(0, 0.0001));

      expect(encodedEdge, isNotNull);
      expect(encodedEdge!.fromStateId, equals('q0'));
      expect(encodedEdge.toStateId, equals('q1'));
      expect(encodedEdge.symbols, equals(['a']));
    });

    test('updates control points when link geometry changes', () async {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(120, 60),
      );
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a',
      );
      final automaton = FSA(
        id: 'a1',
        name: 'control point test',
        states: {q0, q1},
        transitions: {transition},
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: const {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      controller.synchronize(automaton);
      provider.transitionCalls.clear();

      controller.controller.eventBus.emit(
        _FakeLinkGeometryEvent(
          linkId: 't0',
          controlPoint: const Offset(48, 16),
        ),
      );

      await _flushEvents();

      final edge = controller.edgeById('t0');
      expect(edge, isNotNull);
      expect(edge!.controlPointX, closeTo(48, 1e-6));
      expect(edge.controlPointY, closeTo(16, 1e-6));

      expect(provider.transitionCalls, isNotEmpty);
      final lastCall = provider.transitionCalls.last;
      expect(lastCall['controlPointX'], closeTo(48, 1e-6));
      expect(lastCall['controlPointY'], closeTo(16, 1e-6));
    });

    test('propagates AddNodeEvent payload to provider', () async {
      final node = _buildNode(
        controller,
        id: 'q2',
        label: 'S',
        offset: const Offset(42, 24),
      );

      controller.controller.eventBus.emit(
        AddNodeEvent(node, id: 'event-add-node'),
      );

      await _flushEvents();

      expect(provider.addStateCalls, hasLength(1));
      final call = provider.addStateCalls.single;
      expect(call['id'], equals('q2'));
      expect(call['label'], equals('S'));
      expect(call['x'], equals(42.0));
      expect(call['y'], equals(24.0));
      expect(call['isInitial'], isTrue);

      final automaton = provider.state.currentAutomaton;
      expect(automaton, isNotNull);
      expect(automaton!.initialState, isNotNull);
      expect(automaton.initialState!.id, equals('q2'));
    });

    test('ignores DragSelectionEndEvent when position does not change', () async {
      final node = _buildNode(
        controller,
        id: 'q3',
        label: 'idle',
        offset: const Offset(10, 20),
      );

      controller.controller.eventBus.emit(
        AddNodeEvent(node, id: 'seed-drag'),
      );

      await _flushEvents();

      provider.moveStateCalls.clear();

      final instance = controller.controller.nodes['q3']!;
      controller.controller.eventBus.emit(
        DragSelectionEndEvent(
          instance.offset,
          {'q3'},
          id: 'drag-noop',
        ),
      );

      await _flushEvents();

      expect(provider.moveStateCalls, isEmpty);
      final cached = controller.nodeById('q3');
      expect(cached, isNotNull);
      expect(cached!.x, equals(10.0));
      expect(cached.y, equals(20.0));
    });

    test('updates labels on NodeFieldEvent submissions', () async {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {q0},
        transitions: {},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      controller.synchronize(automaton);

      controller.controller.eventBus.emit(
        const NodeFieldEvent(
          'q0',
          '  renamed  ',
          FieldEventType.submit,
          id: 'event-field',
        ),
      );

      await _flushEvents();

      expect(provider.updateLabelCalls, hasLength(1));
      final call = provider.updateLabelCalls.single;
      expect(call['id'], equals('q0'));
      expect(call['label'], equals('renamed'));
      expect(controller.nodeById('q0')!.label, equals('renamed'));
    });

    test('delegates AddLinkEvent to provider', () async {
      controller.synchronize(null);
      final node = _buildNode(
        controller,
        id: 'q0',
        label: 'q0',
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

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], equals('t0'));
      expect(call['fromStateId'], equals('q0'));
      expect(call['toStateId'], equals('q1'));
      final storedEdge = controller.edgeById('t0');
      expect(storedEdge, isNotNull);
      expect(storedEdge!.fromStateId, equals('q0'));
      expect(storedEdge.toStateId, equals('q1'));
    });

    test('applyHighlight toggles link selection state without altering manual selection', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      );
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      controller.synchronize(automaton);

      final editor = controller.controller;
      expect(editor.linksById['t0']!.state.isSelected, isFalse);

      controller.applyHighlight(
        const SimulationHighlight(transitionIds: {'t0'}),
      );

      expect(editor.linksById['t0']!.state.isSelected, isTrue);
      expect(editor.selectedLinkIds, isEmpty);

      controller.synchronize(automaton);
      expect(editor.linksById['t0']!.state.isSelected, isTrue);

      controller.clearHighlight();
      expect(editor.linksById['t0']!.state.isSelected, isFalse);
    });

    test('clearHighlight preserves user-selected links', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: {'a'},
        label: 'a',
      );
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 2),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      controller.synchronize(automaton);
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
