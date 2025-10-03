import 'dart:async';
import 'dart:math' as math;

import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
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
    // Intentionally left blank for tests.
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
  }) {
    transitionCalls.add({
      'id': id,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'label': label,
    });
  }

  @override
  void removeTransition({required String id}) {
    // Intentionally left blank for tests.
  }
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
          to: 'outgoing',
          fromPort: 'q1',
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
    });
  });
}
