import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/tm_transition.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_canvas_models.dart';
import 'package:jflutter/features/canvas/fl_nodes/fl_nodes_tm_mapper.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FlNodesTmMapper', () {
    test('encodes TM data into a snapshot consumable by fl_nodes', () {
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

      final machine = TM(
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

      final snapshot = FlNodesTmMapper.toSnapshot(machine);

      expect(snapshot.metadata.id, equals('tm1'));
      expect(snapshot.metadata.name, equals('Binary inverter'));
      expect(snapshot.metadata.alphabet, containsAll(<String>['0', '1', 'B']));
      expect(snapshot.nodes, hasLength(2));
      expect(snapshot.edges, hasLength(1));

      final edge = snapshot.edges.first;
      expect(edge.fromStateId, equals('q0'));
      expect(edge.toStateId, equals('q1'));
      expect(edge.readSymbol, equals('1'));
      expect(edge.writeSymbol, equals('0'));
      expect(edge.direction, equals(TapeDirection.right));
      expect(edge.controlPointX, closeTo(60, 0.001));
      expect(edge.controlPointY, closeTo(20, 0.001));
    });

    test('merges a snapshot back into a TM template', () {
      final template = TM(
        id: 'template',
        name: 'Template',
        states: {},
        transitions: {},
        alphabet: {'0', '1'},
        initialState: null,
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
            label: 'halt',
            x: 200,
            y: 120,
            isInitial: false,
            isAccepting: true,
          ),
        ],
        edges: const [
          FlNodesCanvasEdge(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            symbols: <String>['1'],
            readSymbol: '1',
            writeSymbol: '0',
            direction: TapeDirection.left,
            controlPointX: 120,
            controlPointY: 60,
          ),
        ],
        metadata: const FlNodesAutomatonMetadata(
          id: 'template',
          name: 'Template',
          alphabet: <String>['0', '1'],
        ),
      );

      final rebuilt = FlNodesTmMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.states.length, equals(2));
      expect(rebuilt.transitions.length, equals(1));
      final rebuiltTransition = rebuilt.transitions.first as TMTransition;
      expect(rebuiltTransition.readSymbol, equals('1'));
      expect(rebuiltTransition.writeSymbol, equals('0'));
      expect(rebuiltTransition.direction, equals(TapeDirection.left));
      expect(rebuiltTransition.controlPoint.x, closeTo(120, 0.001));
      expect(rebuiltTransition.controlPoint.y, closeTo(60, 0.001));
      expect(rebuilt.acceptingStates.map((s) => s.id), contains('q1'));
      expect(rebuilt.initialState?.id, equals('q0'));
      expect(rebuilt.tapeAlphabet, contains('0'));
      expect(rebuilt.tapeAlphabet, contains('1'));
      expect(rebuilt.tapeAlphabet, contains('B'));
    });
  });
}
