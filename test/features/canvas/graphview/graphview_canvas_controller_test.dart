//
//  graphview_canvas_controller_test.dart
//  JFlutter
//
//  Testa o controlador base do canvas GraphView para autômatos, coordenando providers, repositórios
//  de layout e atualizações de seleção. Inspeciona comandos de layout, zoom e sincronização de
//  transições para garantir que o estado visual reflita o modelo lógico.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_controller.dart';
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
    super.moveState(id: id, x: x, y: y);
  }

  @override
  void updateStateLabel({
    required String id,
    required String label,
  }) {
    updateLabelCalls.add({'id': id, 'label': label});
    super.updateStateLabel(id: id, label: label);
  }

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewCanvasController', () {
    late _RecordingAutomatonProvider provider;
    late GraphViewCanvasController controller;

    setUp(() {
      provider = _RecordingAutomatonProvider();
      controller = GraphViewCanvasController(automatonProvider: provider);
      provider.updateAutomaton(
        FSA(
          id: 'auto',
          name: 'Automaton',
          states: const {},
          transitions: const {},
          alphabet: const {},
          initialState: null,
          acceptingStates: const {},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          panOffset: Vector2.zero(),
          zoomLevel: 1,
        ),
      );
    });

    test('addStateAt generates id and forwards to provider', () {
      controller.addStateAt(const Offset(120, 80));

      expect(provider.addStateCalls, hasLength(1));
      final call = provider.addStateCalls.single;
      expect(call['id'], isNotEmpty);
      expect(call['label'], equals('q0'));
      expect(call['x'], closeTo(120, 0.0001));
      expect(call['y'], closeTo(80, 0.0001));
      expect(call['isInitial'], isTrue);
    });

    test('addStateAtCenter converts viewport centre into world coordinates', () {
      final transformation = controller.graphController.transformationController;
      expect(transformation, isNotNull);
      controller.updateViewportSize(const Size(800, 600));

      transformation!.value = Matrix4.identity();
      controller.addStateAtCenter();

      expect(provider.addStateCalls, hasLength(1));
      final firstCall = provider.addStateCalls.first;
      expect(firstCall['x'], closeTo(400, 0.0001));
      expect(firstCall['y'], closeTo(300, 0.0001));

      transformation.value = Matrix4.identity()
        ..translate(150.0, -50.0)
        ..scale(1.5);
      controller.addStateAtCenter();

      expect(provider.addStateCalls, hasLength(2));
      final secondCall = provider.addStateCalls.last;
      expect(secondCall['x'], closeTo((400 - 150) / 1.5, 0.0001));
      expect(secondCall['y'], closeTo((300 - (-50)) / 1.5, 0.0001));
    });

    test('moveState forwards coordinates to provider', () {
      controller.addStateAt(const Offset(0, 0));
      final id = provider.addStateCalls.first['id'] as String;

      controller.moveState(id, const Offset(240, 160));

      expect(provider.moveStateCalls, hasLength(1));
      final call = provider.moveStateCalls.single;
      expect(call['id'], equals(id));
      expect(call['x'], closeTo(240, 0.0001));
      expect(call['y'], closeTo(160, 0.0001));
    });

    test('updateStateLabel normalises empty labels', () {
      controller.addStateAt(const Offset(0, 0));
      final id = provider.addStateCalls.first['id'] as String;

      controller.updateStateLabel(id, '');

      expect(provider.updateLabelCalls, hasLength(1));
      expect(provider.updateLabelCalls.single['label'], equals(id));
    });

    test('addOrUpdateTransition sends payload to provider', () {
      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(200, 0));
      final fromId = provider.addStateCalls[0]['id'] as String;
      final toId = provider.addStateCalls[1]['id'] as String;

      controller.addOrUpdateTransition(
        fromStateId: fromId,
        toStateId: toId,
        label: 'a',
        controlPointX: 100,
        controlPointY: -40,
      );

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['fromStateId'], equals(fromId));
      expect(call['toStateId'], equals(toId));
      expect(call['label'], equals('a'));
      expect(call['controlPointX'], closeTo(100, 0.0001));
      expect(call['controlPointY'], closeTo(-40, 0.0001));
    });

    test('synchronize mirrors provider state into controller caches', () {
      final stateA = automaton_state.State(
        id: 'qa',
        label: 'qa',
        position: Vector2(32, 64),
        isInitial: true,
        isAccepting: false,
      );
      final stateB = automaton_state.State(
        id: 'qb',
        label: 'qb',
        position: Vector2(180, 120),
        isInitial: false,
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: stateA,
        toState: stateB,
        inputSymbols: {'a'},
        label: 'a',
        controlPoint: Vector2(120, 40),
      );

      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {stateA, stateB},
        transitions: {transition},
        alphabet: {'a'},
        initialState: stateA,
        acceptingStates: {stateB},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      controller.synchronize(automaton);

      final cachedNode = controller.nodeById('qa');
      expect(cachedNode, isNotNull);
      expect(cachedNode!.x, closeTo(32, 0.0001));
      expect(cachedNode.y, closeTo(64, 0.0001));

      final cachedEdge = controller.edgeById('t0');
      expect(cachedEdge, isNotNull);
      expect(cachedEdge!.fromStateId, equals('qa'));
      expect(cachedEdge.toStateId, equals('qb'));
      expect(cachedEdge.controlPointX, closeTo(120, 0.0001));
      expect(cachedEdge.controlPointY, closeTo(40, 0.0001));
    });

    test('external synchronize clears undo history and notifies listeners', () {
      final stateA = automaton_state.State(
        id: 'qa',
        label: 'qa',
        position: Vector2(0, 0),
        isInitial: true,
        isAccepting: false,
      );
      final automatonA = FSA(
        id: 'auto_a',
        name: 'Automaton A',
        states: {stateA},
        transitions: const {},
        alphabet: const {'a'},
        initialState: stateA,
        acceptingStates: const {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      provider.updateAutomaton(automatonA);
      controller.synchronize(automatonA);

      controller.addStateAt(const Offset(120, 80));
      expect(controller.canUndo, isTrue);

      final stateB = automaton_state.State(
        id: 'qb',
        label: 'qb',
        position: Vector2(200, 0),
        isInitial: true,
        isAccepting: false,
      );
      final automatonB = FSA(
        id: 'auto_b',
        name: 'Automaton B',
        states: {stateB},
        transitions: const {},
        alphabet: const {'b'},
        initialState: stateB,
        acceptingStates: const {},
        created: DateTime.utc(2024, 2, 1),
        modified: DateTime.utc(2024, 2, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      provider.updateAutomaton(automatonB);
      final revisionBeforeExternalSync = controller.graphRevision.value;
      controller.synchronize(automatonB);

      expect(controller.canUndo, isFalse);
      expect(controller.undo(), isFalse);
      expect(provider.state.currentAutomaton?.id, equals('auto_b'));
      expect(controller.graphRevision.value, greaterThan(revisionBeforeExternalSync));
    });
  });
}
