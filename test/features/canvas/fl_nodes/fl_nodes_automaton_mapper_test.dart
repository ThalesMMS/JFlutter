import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_models.dart';

void main() {
  group('FlNodesAutomatonMapper', () {
    late FSA baseAutomaton;
    late State initialState;
    late State acceptingState;
    late FSATransition transition;

    setUp(() {
      initialState = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      acceptingState = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(160, 120),
        isInitial: false,
        isAccepting: true,
      );
      transition = FSATransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        inputSymbols: {'a'},
        label: 'a',
        controlPoint: Vector2(12, 18),
      );

      baseAutomaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: {'a'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );
    });

    test('toSnapshot captures nodes, edges and metadata', () {
      final snapshot = FlNodesAutomatonMapper.toSnapshot(baseAutomaton);

      expect(snapshot.metadata.id, equals('auto'));
      expect(snapshot.metadata.name, equals('Automaton'));
      expect(snapshot.metadata.alphabet, containsAll(['a']));

      expect(snapshot.nodes, hasLength(2));
      final nodeIds = snapshot.nodes.map((node) => node.id).toSet();
      expect(nodeIds, containsAll({'q0', 'q1'}));

      final acceptingNode =
          snapshot.nodes.firstWhere((node) => node.id == 'q1');
      expect(acceptingNode.isAccepting, isTrue);
      expect(acceptingNode.x, closeTo(160, 0.0001));
      expect(acceptingNode.y, closeTo(120, 0.0001));

      expect(snapshot.edges, hasLength(1));
      final edge = snapshot.edges.single;
      expect(edge.id, equals('t0'));
      expect(edge.fromStateId, equals('q0'));
      expect(edge.toStateId, equals('q1'));
      expect(edge.symbols, equals(['a']));
      expect(edge.controlPointX, closeTo(12, 0.0001));
      expect(edge.controlPointY, closeTo(18, 0.0001));
    });

    test('mergeIntoTemplate rebuilds automaton from snapshot', () {
      final snapshot = FlNodesAutomatonSnapshot(
        nodes: const [
          FlNodesCanvasNode(
            id: 'q0',
            label: 'Start',
            x: 40,
            y: 60,
            isInitial: true,
            isAccepting: false,
          ),
          FlNodesCanvasNode(
            id: 'q1',
            label: 'End',
            x: 220,
            y: 240,
            isInitial: false,
            isAccepting: true,
          ),
        ],
        edges: const [
          FlNodesCanvasEdge(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            symbols: ['b'],
            lambdaSymbol: null,
            controlPointX: 8,
            controlPointY: 12,
          ),
        ],
        metadata: const FlNodesAutomatonMetadata(
          id: 'auto',
          name: 'Automaton',
          alphabet: ['b'],
        ),
      );

      final rebuilt = FlNodesAutomatonMapper.mergeIntoTemplate(
        snapshot,
        baseAutomaton,
      );

      expect(rebuilt.states, hasLength(2));
      final rebuiltInitial =
          rebuilt.states.firstWhere((state) => state.id == 'q0');
      final rebuiltAccepting =
          rebuilt.states.firstWhere((state) => state.id == 'q1');

      expect(rebuiltInitial.label, equals('Start'));
      expect(rebuiltInitial.position.x, closeTo(40, 0.0001));
      expect(rebuiltInitial.position.y, closeTo(60, 0.0001));
      expect(rebuiltInitial.isInitial, isTrue);

      expect(rebuiltAccepting.label, equals('End'));
      expect(rebuiltAccepting.isAccepting, isTrue);

      final rebuiltTransition = rebuilt.fsaTransitions.single;
      expect(rebuiltTransition.label, equals('b'));
      expect(rebuiltTransition.inputSymbols, equals({'b'}));
      expect(rebuiltTransition.controlPoint.x, closeTo(8, 0.0001));
      expect(rebuiltTransition.controlPoint.y, closeTo(12, 0.0001));

      expect(rebuilt.alphabet, containsAll({'a', 'b'}));
      expect(rebuilt.initialState?.id, equals('q0'));
      expect(rebuilt.acceptingStates.map((state) => state.id), contains('q1'));
    });
  });
}
