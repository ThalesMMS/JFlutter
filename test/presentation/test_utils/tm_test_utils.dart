import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/models/models.dart';
import 'package:vector_math/vector_math_64.dart';

class TmTestData {
  static TM createTm() {
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(50, 50),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(150, 50),
      isAccepting: true,
    );

    final transition = TMTransition(
      id: 't1',
      fromState: q0,
      toState: q1,
      label: 'a,b,R',
      readSymbol: 'a',
      writeSymbol: 'b',
      direction: TMDirection.right,
    );

    return TM(
      id: 'tm1',
      name: 'Test TM',
      states: {q0, q1},
      transitions: {transition},
      alphabet: const Alphabet(symbols: {'a', 'b'}),
      initialState: q0,
      acceptingStates: {q1},
      metadata: AutomatonMetadata(
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        createdBy: 'test',
      ),
      bounds: const math.Rectangle(0, 0, 200, 100),
    );
  }

  static TMAnalysis createAnalysis(TM tm) {
    return TMAnalysis(
      tm: tm,
      acceptedStrings: {'ab'},
      rejectedStrings: {'a'},
      endlessLoopStrings: {},
      stepCount: 2,
      isDeterministic: true,
    );
  }
}
