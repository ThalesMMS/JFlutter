import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/features/canvas_bridge/draw2d_canvas_bridge.dart';

void main() {
  final created = DateTime.utc(2024, 1, 1);
  final stateA = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final stateB = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(120, 80),
    isAccepting: true,
  );
  final transition = FSATransition(
    id: 't0',
    fromState: stateA,
    toState: stateB,
    inputSymbols: const {'a'},
  );
  final automaton = FSA(
    id: 'bridge-test',
    name: 'Bridge Test',
    states: {stateA, stateB},
    transitions: {transition},
    alphabet: {'a'},
    initialState: stateA,
    acceptingStates: {stateB},
    created: created,
    modified: created,
    bounds: const math.Rectangle(0, 0, 400, 300),
  );

  group('BridgeAutomatonMapper', () {
    test('toBridgeAutomaton serializes nodes and edges', () {
      final payload = BridgeAutomatonMapper.toBridgeAutomaton(automaton);

      final nodes = payload['nodes'] as List<dynamic>;
      final edges = payload['edges'] as List<dynamic>;

      expect(nodes, hasLength(2));
      expect(edges, hasLength(1));

      final nodeJson = nodes.cast<Map<String, dynamic>>();
      expect(
        nodeJson.where(
          (node) => node['isInitial'] == true && node['id'] == 'q0',
        ),
        isNotEmpty,
      );
      expect(
        nodeJson.where(
          (node) => node['isAccepting'] == true && node['id'] == 'q1',
        ),
        isNotEmpty,
      );

      final edgeJson = edges.cast<Map<String, dynamic>>().single;
      expect(edgeJson['from'], equals('q0'));
      expect(edgeJson['to'], equals('q1'));
      expect(edgeJson['symbols'], equals(['a']));
    });

    test('mergeIntoTemplate hydrates template automaton', () {
      final payload = BridgeAutomatonMapper.toBridgeAutomaton(automaton);
      final template = FSA(
        id: 'template',
        name: 'Template',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: null,
        acceptingStates: const {},
        created: created,
        modified: created,
        bounds: const math.Rectangle(0, 0, 500, 320),
      );

      final hydrated = BridgeAutomatonMapper.mergeIntoTemplate(
        payload,
        template,
      );

      expect(hydrated.states, hasLength(2));
      expect(hydrated.fsaTransitions, hasLength(1));
      expect(hydrated.initialState?.id, equals('q0'));
      expect(hydrated.acceptingStates.single.id, equals('q1'));
      expect(hydrated.alphabet.contains('a'), isTrue);
    });
  });
}
