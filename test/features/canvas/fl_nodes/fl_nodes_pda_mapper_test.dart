import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_models.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_pda_mapper.dart';

void main() {
  group('FlNodesPdaMapper', () {
    late State initialState;
    late State acceptingState;
    late PDATransition transition;
    late PDA basePda;

    setUp(() {
      initialState = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      acceptingState = State(
        id: 'q1',
        label: 'accept',
        position: Vector2(160, 120),
        isInitial: false,
        isAccepting: true,
      );
      transition = PDATransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'read a push Z',
        controlPoint: Vector2(30, 40),
        type: TransitionType.deterministic,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      basePda = PDA(
        id: 'pda1',
        name: 'Sample PDA',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: {'a'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: {'Z', 'A'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
    });

    test('toSnapshot encodes states and transitions with PDA metadata', () {
      final snapshot = FlNodesPdaMapper.toSnapshot(basePda);

      expect(snapshot.metadata.id, equals('pda1'));
      expect(snapshot.metadata.name, equals('Sample PDA'));
      expect(snapshot.metadata.alphabet, contains('a'));

      expect(snapshot.nodes, hasLength(2));
      final nodeIds = snapshot.nodes.map((node) => node.id).toSet();
      expect(nodeIds, containsAll({'q0', 'q1'}));

      final encodedInitial =
          snapshot.nodes.firstWhere((node) => node.id == 'q0');
      expect(encodedInitial.isInitial, isTrue);
      expect(encodedInitial.x, closeTo(0, 0.0001));
      expect(encodedInitial.y, closeTo(0, 0.0001));

      expect(snapshot.edges, hasLength(1));
      final edge = snapshot.edges.single;
      expect(edge.id, equals('t0'));
      expect(edge.fromStateId, equals('q0'));
      expect(edge.toStateId, equals('q1'));
      expect(edge.readSymbol, equals('a'));
      expect(edge.popSymbol, equals('Z'));
      expect(edge.pushSymbol, equals('AZ'));
      expect(edge.controlPointX, closeTo(30, 0.0001));
      expect(edge.controlPointY, closeTo(40, 0.0001));
      expect(edge.isLambdaInput, isFalse);
      expect(edge.isLambdaPop, isFalse);
      expect(edge.isLambdaPush, isFalse);
    });

    test('mergeIntoTemplate rebuilds PDA from snapshot', () {
      final template = basePda.copyWith(
        states: {initialState},
        transitions: {},
        alphabet: {'a'},
        acceptingStates: {initialState},
      );

      final snapshot = FlNodesAutomatonSnapshot(
        nodes: const [
          FlNodesCanvasNode(
            id: 'q0',
            label: 'start',
            x: 10,
            y: 20,
            isInitial: true,
            isAccepting: false,
          ),
          FlNodesCanvasNode(
            id: 'q1',
            label: 'accept',
            x: 200,
            y: 160,
            isInitial: false,
            isAccepting: true,
          ),
        ],
        edges: const [
          FlNodesCanvasEdge(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            symbols: <String>[],
            controlPointX: 18,
            controlPointY: 24,
            readSymbol: 'b',
            popSymbol: 'Z',
            pushSymbol: 'XZ',
            isLambdaInput: false,
            isLambdaPop: false,
            isLambdaPush: false,
          ),
        ],
        metadata: const FlNodesAutomatonMetadata(
          id: 'pda1',
          name: 'Sample PDA',
          alphabet: ['a', 'b'],
        ),
      );

      final rebuilt = FlNodesPdaMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.states.length, equals(2));
      final rebuiltInitial =
          rebuilt.states.firstWhere((state) => state.id == 'q0');
      final rebuiltAccepting =
          rebuilt.states.firstWhere((state) => state.id == 'q1');
      expect(rebuiltInitial.position.x, closeTo(10, 0.0001));
      expect(rebuiltInitial.position.y, closeTo(20, 0.0001));
      expect(rebuiltAccepting.isAccepting, isTrue);

      final rebuiltTransition = rebuilt.pdaTransitions.single;
      expect(rebuiltTransition.inputSymbol, equals('b'));
      expect(rebuiltTransition.popSymbol, equals('Z'));
      expect(rebuiltTransition.pushSymbol, equals('XZ'));
      expect(rebuiltTransition.controlPoint.x, closeTo(18, 0.0001));
      expect(rebuiltTransition.controlPoint.y, closeTo(24, 0.0001));
      expect(rebuiltTransition.isLambdaInput, isFalse);
      expect(rebuiltTransition.isLambdaPop, isFalse);
      expect(rebuiltTransition.isLambdaPush, isFalse);

      expect(rebuilt.alphabet, containsAll({'a', 'b'}));
      expect(rebuilt.stackAlphabet, containsAll({'Z', 'A', 'XZ'}));
      expect(rebuilt.initialState?.id, equals('q0'));
      expect(rebuilt.acceptingStates.map((state) => state.id), contains('q1'));
    });
  });
}
