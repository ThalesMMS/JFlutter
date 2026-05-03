//
//  automaton_state_update_automaton_test.dart
//  JFlutter
//
//  Unit tests for AutomatonStateNotifier.updateAutomaton.
//

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/presentation/providers/automaton_state_provider.dart';

void main() {
  group('AutomatonStateNotifier.updateAutomaton', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          automatonStateProvider.overrideWith((ref) {
            return AutomatonStateNotifier(automatonService: AutomatonService());
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('sets currentAutomaton to the provided automaton', () {
      final notifier = container.read(automatonStateProvider.notifier);

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: true,
      );

      final automaton = FSA(
        id: 'dfa-test',
        name: 'DFA Test',
        states: {q0},
        transitions: const {},
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q0},
        created: DateTime(2026, 1, 1),
        modified: DateTime(2026, 1, 1),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      expect(container.read(automatonStateProvider).currentAutomaton, isNull);

      notifier.updateAutomaton(automaton);

      final state = container.read(automatonStateProvider);
      expect(state.currentAutomaton, isNotNull);
      expect(state.currentAutomaton!.id, 'dfa-test');
      expect(state.currentAutomaton, same(automaton));
    });
  });
}
