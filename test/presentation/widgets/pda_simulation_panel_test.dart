import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/widgets/pda_simulation_panel.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/state.dart';

class _FakePDAEditorNotifier extends StateNotifier<PDAEditorState> {
  _FakePDAEditorNotifier({PDA? pda})
      : super(PDAEditorState(pda: pda));
}

ProviderScope _buildPanelWithFakeEditor({PDA? pda}) {
  return ProviderScope(
    overrides: [
      pdaEditorProvider.overrideWith(
        (ref) => _FakePDAEditorNotifier(pda: pda),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: PDASimulationPanel(),
      ),
    ),
  );
}

Future<void> _fillInputField(WidgetTester tester, String value) async {
  final inputField = find.widgetWithText(TextField, 'Input String');
  expect(inputField, findsOneWidget);
  await tester.enterText(inputField, value);
}

PDA _createAcceptingPda() {
  final initialState = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  final acceptingState = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(1, 0),
    isAccepting: true,
  );

  final transition = PDATransition(
    id: 't1',
    fromState: initialState,
    toState: acceptingState,
    label: 'a,Z;Z',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );

  return PDA(
    id: 'pda',
    name: 'Test PDA',
    states: {initialState, acceptingState},
    transitions: {transition},
    alphabet: {'a'},
    initialState: initialState,
    acceptingStates: {acceptingState},
    created: DateTime(2024, 1, 1),
    modified: DateTime(2024, 1, 1),
    bounds: const math.Rectangle(0.0, 0.0, 100.0, 100.0),
    stackAlphabet: {'Z'},
    initialStackSymbol: 'Z',
  );
}

void main() {
  testWidgets('shows error when input is empty and surfaces failure layout', (tester) async {
    await tester.pumpWidget(_buildPanelWithFakeEditor(pda: _createAcceptingPda()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulate PDA'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please enter an input string'), findsWidgets);
    expect(find.text('Simulation failed'), findsOneWidget);
  });

  testWidgets('shows error when no PDA is available', (tester) async {
    await tester.pumpWidget(_buildPanelWithFakeEditor());
    await tester.pumpAndSettle();

    await _fillInputField(tester, 'a');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulate PDA'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Create a PDA on the canvas before simulating.'),
      findsWidgets,
    );
    expect(find.text('Simulation failed'), findsOneWidget);
  });

  testWidgets('displays successful simulation summary and steps', (tester) async {
    await tester.pumpWidget(_buildPanelWithFakeEditor(pda: _createAcceptingPda()));
    await tester.pumpAndSettle();

    await _fillInputField(tester, 'a');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulate PDA'));
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Simulation Steps:'), findsOneWidget);
    expect(find.textContaining('State q1'), findsWidgets);
  });
}
