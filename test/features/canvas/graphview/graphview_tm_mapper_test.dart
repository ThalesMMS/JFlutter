/// ---------------------------------------------------------------------------
/// Teste: mapeamento de máquinas de Turing para modelos GraphView.
/// Resumo: Verifica a tradução de estados, transições e direções de fita para
/// estruturas visuais, incluindo múltiplas fitas e ajuste geométrico.
/// ---------------------------------------------------------------------------

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:jflutter/features/canvas/graphview/graphview_tm_mapper.dart';

void main() {
  group('GraphViewTmMapper', () {
    late State initialState;
    late State acceptingState;
    late TMTransition transition;
    late TM machine;

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
        position: Vector2(200, 140),
        isInitial: false,
        isAccepting: true,
      );
      transition = TMTransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'a/b,R',
        controlPoint: Vector2(32, 28),
        type: TransitionType.deterministic,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );
      machine = TM(
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
    });

    test('toSnapshot encodes TM states and transitions', () {
      final snapshot = GraphViewTmMapper.toSnapshot(machine);

      expect(snapshot.metadata.id, equals('tm-1'));
      expect(snapshot.metadata.name, equals('Sample TM'));
      expect(snapshot.metadata.alphabet, containsAll(['a', 'b']));

      expect(snapshot.nodes, hasLength(2));
      final nodeIds = snapshot.nodes.map((node) => node.id).toSet();
      expect(nodeIds, containsAll({'q0', 'q1'}));

      final edge = snapshot.edges.single;
      expect(edge.id, equals('t0'));
      expect(edge.readSymbol, equals('a'));
      expect(edge.writeSymbol, equals('b'));
      expect(edge.direction, equals(TapeDirection.right));
    });

    test('mergeIntoTemplate rebuilds TM from snapshot', () {
      final template = machine.copyWith(
        states: {initialState},
        transitions: {},
        acceptingStates: {initialState},
      );

      final snapshot = GraphViewAutomatonSnapshot(
        nodes: const [
          GraphViewCanvasNode(
            id: 'q0',
            label: 'start',
            x: 10,
            y: 20,
            isInitial: true,
            isAccepting: false,
          ),
          GraphViewCanvasNode(
            id: 'q1',
            label: 'accept',
            x: 180,
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
            controlPointX: 24,
            controlPointY: 30,
            readSymbol: 'c',
            writeSymbol: 'd',
            direction: TapeDirection.left,
          ),
        ],
        metadata: const GraphViewAutomatonMetadata(
          id: 'tm-1',
          name: 'Updated TM',
          alphabet: ['a', 'b', 'c', 'd'],
        ),
      );

      final rebuilt = GraphViewTmMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.states.length, equals(2));
      final rebuiltInitial =
          rebuilt.states.firstWhere((state) => state.id == 'q0');
      expect(rebuiltInitial.position.x, closeTo(10, 0.0001));
      expect(rebuiltInitial.position.y, closeTo(20, 0.0001));

      final rebuiltTransition = rebuilt.tmTransitions.single;
      expect(rebuiltTransition.readSymbol, equals('c'));
      expect(rebuiltTransition.writeSymbol, equals('d'));
      expect(rebuiltTransition.direction, equals(TapeDirection.left));
      expect(rebuiltTransition.label, equals('c/d,L'));

      expect(rebuilt.alphabet, containsAll({'a', 'b', 'c', 'd'}));
      expect(rebuilt.initialState?.id, equals('q0'));
      expect(rebuilt.acceptingStates.single.id, equals('q1'));
    });
  });
}
