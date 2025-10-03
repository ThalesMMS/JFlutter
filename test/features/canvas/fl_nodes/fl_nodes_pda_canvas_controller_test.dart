import 'dart:async';
import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/simulation_highlight.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_pda_canvas_controller.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';

class _RecordingPdaEditorNotifier extends PDAEditorNotifier {
  final List<Map<String, Object?>> stateCalls = [];
  final List<Map<String, Object?>> transitionCalls = [];

  @override
  PDA? addOrUpdateState({
    required String id,
    required String label,
    required double x,
    required double y,
  }) {
    stateCalls.add({
      'type': 'upsert',
      'id': id,
      'label': label,
      'x': x,
      'y': y,
    });
    return null;
  }

  @override
  PDA? removeState({required String id}) {
    return null;
  }

  @override
  PDA? updateStateLabel({
    required String id,
    required String label,
  }) {
    stateCalls.add({
      'type': 'label',
      'id': id,
      'label': label,
    });
    return null;
  }

  @override
  PDA? moveState({
    required String id,
    required double x,
    required double y,
  }) {
    stateCalls.add({
      'type': 'move',
      'id': id,
      'x': x,
      'y': y,
    });
    return null;
  }

  @override
  PDA? upsertTransition({
    required String id,
    String? fromStateId,
    String? toStateId,
    String? label,
    String? readSymbol,
    String? popSymbol,
    String? pushSymbol,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
  }) {
    transitionCalls.add({
      'id': id,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'label': label,
      'readSymbol': readSymbol,
      'popSymbol': popSymbol,
      'pushSymbol': pushSymbol,
      'isLambdaInput': isLambdaInput,
      'isLambdaPop': isLambdaPop,
      'isLambdaPush': isLambdaPush,
    });
    return null;
  }

  @override
  PDA? removeTransition({required String id}) {
    return null;
  }
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
}

NodeInstance _buildNode(
  FlNodesPdaCanvasController controller, {
  required String id,
  required String label,
  required Offset offset,
}) {
  final prototype = controller.controller.nodePrototypes['pda_state']!;
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

  group('FlNodesPdaCanvasController', () {
    late _RecordingPdaEditorNotifier notifier;
    late FlNodesPdaCanvasController controller;

    setUp(() {
      notifier = _RecordingPdaEditorNotifier();
      controller = FlNodesPdaCanvasController(
        editorNotifier: notifier,
        editorController: FlNodeEditorController(),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('synchronize mirrors PDA data into controller state', () {
      final q0 = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'accept',
        position: Vector2(100, 80),
        isAccepting: true,
      );
      final transition = PDATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a,Z/AZ',
        controlPoint: Vector2(24, 32),
        type: TransitionType.deterministic,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      final pda = PDA(
        id: 'pda1',
        name: 'Sample PDA',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: {'Z', 'A'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      controller.synchronize(pda);

      final encodedNode = controller.nodeById('q0');
      final encodedEdge = controller.edgeById('t0');

      expect(encodedNode, isNotNull);
      expect(encodedNode!.isInitial, isTrue);
      expect(encodedNode.x, closeTo(0, 0.0001));
      expect(encodedNode.y, closeTo(0, 0.0001));

      expect(encodedEdge, isNotNull);
      expect(encodedEdge!.readSymbol, equals('a'));
      expect(encodedEdge.popSymbol, equals('Z'));
      expect(encodedEdge.pushSymbol, equals('AZ'));
      expect(encodedEdge.isLambdaInput, isFalse);
      expect(encodedEdge.isLambdaPop, isFalse);
      expect(encodedEdge.isLambdaPush, isFalse);
      expect(encodedEdge.controlPointX, closeTo(24, 0.0001));
      expect(encodedEdge.controlPointY, closeTo(32, 0.0001));
    });

    test('captures AddNodeEvent data for PDA states', () async {
      final node = _buildNode(
        controller,
        id: 'q2',
        label: 'mid',
        offset: const Offset(12, 18),
      );

      controller.controller.eventBus.emit(
        AddNodeEvent(node, id: 'event-add'),
      );

      await _flushEvents();

      expect(notifier.stateCalls, hasLength(1));
      final call = notifier.stateCalls.single;
      expect(call['type'], equals('upsert'));
      expect(call['id'], equals('q2'));
      expect(call['label'], equals('mid'));
      expect(call['x'], equals(12.0));
      expect(call['y'], equals(18.0));
    });

    test('updates labels via NodeFieldEvent submissions', () async {
      final q0 = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
      );
      final pda = PDA(
        id: 'pda1',
        name: 'Sample PDA',
        states: {q0},
        transitions: {},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      controller.synchronize(pda);

      controller.controller.eventBus.emit(
        const NodeFieldEvent(
          'q0',
          '  renamed  ',
          FieldEventType.submit,
          id: 'event-field',
        ),
      );

      await _flushEvents();

      expect(notifier.stateCalls.length, equals(1));
      final call = notifier.stateCalls.single;
      expect(call['type'], equals('label'));
      expect(call['id'], equals('q0'));
      expect(call['label'], equals('renamed'));
      expect(controller.nodeById('q0')!.label, equals('renamed'));
    });

    test('creates lambda PDA transitions on AddLinkEvent', () async {
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
      expect(call['popSymbol'], equals(''));
      expect(call['pushSymbol'], equals(''));
      expect(call['isLambdaInput'], isTrue);
      expect(call['isLambdaPop'], isTrue);
      expect(call['isLambdaPush'], isTrue);
      final storedEdge = controller.edgeById('t0');
      expect(storedEdge, isNotNull);
      expect(storedEdge!.fromStateId, equals('q0'));
      expect(storedEdge.toStateId, equals('q1'));
    });

    test('applyHighlight marks PDA transitions without mutating selection', () {
      final q0 = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'accept',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = PDATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a,Z/AZ',
        controlPoint: Vector2(24, 32),
        type: TransitionType.deterministic,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      final pda = PDA(
        id: 'pda1',
        name: 'Sample PDA',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: {'Z', 'A'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      controller.synchronize(pda);
      final editor = controller.controller;

      controller.applyHighlight(
        const SimulationHighlight(transitionIds: {'t0'}),
      );

      expect(editor.linksById['t0']!.state.isSelected, isTrue);
      expect(editor.selectedLinkIds, isEmpty);

      controller.synchronize(pda);
      expect(editor.linksById['t0']!.state.isSelected, isTrue);

      controller.clearHighlight();
      expect(editor.linksById['t0']!.state.isSelected, isFalse);
    });

    test('clearHighlight keeps PDA selections intact', () {
      final q0 = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'accept',
        position: Vector2(120, 80),
        isAccepting: true,
      );
      final transition = PDATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a,Z/AZ',
        controlPoint: Vector2(24, 32),
        type: TransitionType.deterministic,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      final pda = PDA(
        id: 'pda1',
        name: 'Sample PDA',
        states: {q0, q1},
        transitions: {transition},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: {'Z', 'A'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      controller.synchronize(pda);
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
