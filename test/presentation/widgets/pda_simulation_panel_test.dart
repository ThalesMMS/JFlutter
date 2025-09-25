import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/pda_transition.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/core/packages/core_pda/simulation.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/widgets/pda_simulation_panel.dart';

class _FakePDAEditorNotifier extends StateNotifier<PDAEditorState> {
  _FakePDAEditorNotifier({PDA? pda}) : super(PDAEditorState(pda: pda));
}

ProviderScope _buildPanelWithFakeEditor({
  PDA? pda,
  PDASimulatorRunner? overrideSimulator,
}) {
  return ProviderScope(
    overrides: [
      pdaEditorProvider.overrideWith(
        (ref) => _FakePDAEditorNotifier(pda: pda),
      ),
      if (overrideSimulator != null)
        pdaSimulatorRunnerProvider.overrideWithValue(overrideSimulator),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: PDASimulationPanel(),
      ),
    ),
  );
}

class _StubSimulator {
  Result<PDASimulationResult> call(
    PDA pda,
    String input, {
    bool stepByStep = false,
    Duration timeout = const Duration(seconds: 5),
    int maxAcceptedPaths = 5,
  }) {
    final steps = <SimulationStep>[
      SimulationStep.initial(
        initialState: pda.initialState!.id,
        inputString: input,
        initialStackSymbol: pda.initialStackSymbol,
      ),
      SimulationStep(
        currentState: pda.acceptingStates.first.id,
        remainingInput: '',
        stackContents: pda.initialStackSymbol,
        stepNumber: 1,
      ),
    ];

    return Success(
      PDASimulationResult.success(
        inputString: input,
        steps: steps,
        executionTime: const Duration(milliseconds: 3),
        acceptanceMode: pda.acceptanceMode,
      ),
    );
  }
}

Future<void> _fillInputField(WidgetTester tester, String value) async {
  final inputField = find.widgetWithText(TextField, 'Input String');
  expect(inputField, findsOneWidget);
  await tester.enterText(inputField, value);
  await tester.pumpAndSettle();
}

Future<void> _tapSimulateButton(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Simulate PDA');
  expect(button, findsOneWidget);
  await tester.tap(button);
}

PDA _createAcceptingPda() {
  final initialState = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );

  final acceptingState = automaton_state.State(
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
    transitions: Set<Transition>.from({transition}),
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
  testWidgets('shows error when input is empty and surfaces failure layout',
      (tester) async {
    final stub = _StubSimulator();
    await tester.pumpWidget(
      _buildPanelWithFakeEditor(
        pda: _createAcceptingPda(),
        overrideSimulator: stub.call,
      ),
    );
    await tester.pumpAndSettle();

    await _tapSimulateButton(tester);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please enter an input string'), findsWidgets);

    await tester.pumpAndSettle();

    expect(find.text('Simulation failed'), findsOneWidget);
  });

  testWidgets('shows error when no PDA is available', (tester) async {
    await tester.pumpWidget(_buildPanelWithFakeEditor());
    await tester.pumpAndSettle();

    await _fillInputField(tester, 'a');
    await _tapSimulateButton(tester);
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(
      find.text('Create a PDA on the canvas before simulating.'),
      findsWidgets,
    );

    await tester.pumpAndSettle();

    expect(find.text('Simulation failed'), findsOneWidget);
  });

  testWidgets('renders acceptance summary and step trace on success',
      (tester) async {
    final stub = _StubSimulator();
    await tester.pumpWidget(
      _buildPanelWithFakeEditor(
        pda: _createAcceptingPda(),
        overrideSimulator: stub.call,
      ),
    );
    await tester.pumpAndSettle();

    await _fillInputField(tester, 'a');
    await _tapSimulateButton(tester);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Simulation Steps:'), findsOneWidget);
    expect(find.textContaining('State q1'), findsWidgets);
  });
}
