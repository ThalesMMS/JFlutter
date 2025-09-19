import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/presentation/pages/pda_page.dart';
import 'package:jflutter/presentation/widgets/pda_canvas.dart';

void main() {
  group('PDAPage', () {
    testWidgets('updates info panel when PDA canvas notifies changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PDAPage(),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('pda_info_current_name')), findsOneWidget);
      expect(find.textContaining('Current PDA: None'), findsOneWidget);
      expect(find.byKey(const ValueKey('pda_info_unsaved_changes')), findsNothing);

      final canvas = tester.widget<PDACanvas>(find.byType(PDACanvas));
      final samplePda = _buildSamplePda();

      canvas.onPDAModified(samplePda);
      await tester.pump();

      expect(find.textContaining('Current PDA: ${samplePda.name}'), findsOneWidget);
      expect(find.byKey(const ValueKey('pda_info_state_count')), findsOneWidget);
      expect(find.byKey(const ValueKey('pda_info_transition_count')), findsOneWidget);
      expect(find.byKey(const ValueKey('pda_info_stack_count')), findsOneWidget);
      expect(find.byKey(const ValueKey('pda_info_unsaved_changes')), findsOneWidget);
    });
  });
}

PDA _buildSamplePda() {
  final now = DateTime.now();
  final stateA = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final stateB = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );

  final transition = PDATransition(
    id: 't0',
    fromState: stateA,
    toState: stateB,
    label: 'a, Z -> AZ',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'AZ',
  );

  return PDA(
    id: 'editor-pda',
    name: 'Canvas PDA',
    states: {stateA, stateB},
    transitions: {transition},
    alphabet: {'a'},
    initialState: stateA,
    acceptingStates: {stateB},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 300, 200),
    stackAlphabet: {'A', 'Z'},
    initialStackSymbol: 'Z',
  );
}
