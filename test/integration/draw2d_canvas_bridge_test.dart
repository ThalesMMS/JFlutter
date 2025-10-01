import 'dart:convert';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart';
import 'package:jflutter/features/canvas_bridge/draw2d_canvas_bridge.dart';

class _FakeBridgeMessenger implements BridgeMessenger {
  final List<BridgeCommand> commands = [];

  @override
  Future<void> postMessage(BridgeCommand command) async {
    commands.add(command);
  }
}

void main() {
  test('Draw2dCanvasBridge processes add, move, and link events', () async {
    final messenger = _FakeBridgeMessenger();
    FSA? lastAutomaton;
    final bridge = Draw2dCanvasBridge(
      messenger: messenger,
      onAutomatonChanged: (automaton) => lastAutomaton = automaton,
      clock: () => DateTime.utc(2024, 1, 1),
    );

    final initialState = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
    );
    final baseAutomaton = FSA(
      id: 'base',
      name: 'Base',
      states: {initialState},
      transitions: const {},
      alphabet: const {},
      initialState: initialState,
      acceptingStates: const {},
      created: DateTime.utc(2024, 1, 1),
      modified: DateTime.utc(2024, 1, 1),
      bounds: const math.Rectangle(0, 0, 400, 300),
    );

    await bridge.synchronize(baseAutomaton);
    expect(messenger.commands, hasLength(1));
    final loadPayload = messenger.commands.single.payload;
    expect((loadPayload['nodes'] as List).length, equals(1));

    bridge.handleRawMessage(
      jsonEncode({
        'type': 'node:add',
        'payload': {
          'id': 'q1',
          'label': 'q1',
          'x': 160,
          'y': 120,
          'isInitial': false,
          'isAccepting': true,
        },
      }),
    );

    expect(lastAutomaton, isNotNull);
    expect(lastAutomaton!.states.length, equals(2));
    expect(lastAutomaton!.acceptingStates.single.id, equals('q1'));

    bridge.handleRawMessage(
      jsonEncode({
        'type': 'node:move',
        'payload': {
          'id': 'q1',
          'label': 'q1',
          'x': 200,
          'y': 150,
          'isInitial': false,
          'isAccepting': true,
        },
      }),
    );

    final movedState = lastAutomaton!.states.firstWhere(
      (state) => state.id == 'q1',
    );
    expect(movedState.position.x, closeTo(200, 0.0001));
    expect(movedState.position.y, closeTo(150, 0.0001));

    bridge.handleRawMessage(
      jsonEncode({
        'type': 'edge:link',
        'payload': {
          'id': 't1',
          'from': 'q0',
          'to': 'q1',
          'symbols': ['b'],
        },
      }),
    );

    final transitions = lastAutomaton!.fsaTransitions;
    expect(transitions.length, equals(1));
    final newTransition = transitions.single;
    expect(newTransition.fromState.id, equals('q0'));
    expect(newTransition.toState.id, equals('q1'));
    expect(newTransition.inputSymbols, equals({'b'}));
    expect(lastAutomaton!.alphabet.contains('b'), isTrue);
  });
}
