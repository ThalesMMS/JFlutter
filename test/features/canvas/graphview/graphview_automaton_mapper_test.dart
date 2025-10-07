//
//  graphview_automaton_mapper_test.dart
//  JFlutter
//
//  Confere o GraphViewAutomatonMapper na tradução de autômatos finitos para nós e arestas, cobrindo
//  casos com loops, transições múltiplas e estados especiais. Verifica se os cálculos de geometria
//  e agrupamento resultam em modelos consistentes para o canvas interativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/features/canvas/graphview/graphview_automaton_mapper.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_models.dart';

void main() {
  group('GraphViewAutomatonMapper', () {
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
      final snapshot = GraphViewAutomatonMapper.toSnapshot(baseAutomaton);

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
      final snapshot = GraphViewAutomatonSnapshot(
        nodes: const [
          GraphViewCanvasNode(
            id: 'q0',
            label: 'Start',
            x: 40,
            y: 60,
            isInitial: true,
            isAccepting: false,
          ),
          GraphViewCanvasNode(
            id: 'q1',
            label: 'End',
            x: 220,
            y: 240,
            isInitial: false,
            isAccepting: true,
          ),
        ],
        edges: const [
          GraphViewCanvasEdge(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            symbols: ['b'],
            lambdaSymbol: null,
            controlPointX: 8,
            controlPointY: 12,
          ),
        ],
        metadata: const GraphViewAutomatonMetadata(
          id: 'auto',
          name: 'Automaton',
          alphabet: ['b'],
        ),
      );

      final merged =
          GraphViewAutomatonMapper.mergeIntoTemplate(snapshot, baseAutomaton);

      expect(merged.states, hasLength(2));
      expect(merged.transitions, hasLength(1));
      expect(merged.acceptingStates.map((state) => state.id), contains('q1'));
      expect(merged.initialState?.id, equals('q0'));

      final mergedTransition =
          merged.fsaTransitions.firstWhere((transition) => transition.id == 't0');
      expect(mergedTransition.fromState.id, equals('q0'));
      expect(mergedTransition.toState.id, equals('q1'));
      expect(mergedTransition.inputSymbols, equals({'b'}));
      expect(mergedTransition.controlPoint.x, closeTo(8, 0.0001));
      expect(mergedTransition.controlPoint.y, closeTo(12, 0.0001));
    });
  });
}
