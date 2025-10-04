import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/fsa.dart';
import 'package:jflutter/core/models/pda.dart';
import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/models/transition.dart';
import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/providers/pda_editor_provider.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';
import 'package:jflutter/presentation/widgets/pda_canvas_native.dart';
import 'package:jflutter/presentation/widgets/tm_canvas_native.dart';

void main() {
  testWidgets('Automaton node header toggles initial and accepting flags',
      (tester) async {
    final q0 = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = automaton_state.State(
      id: 'q1',
      label: 'q1',
      position: Vector2(120, 0),
      isInitial: false,
      isAccepting: false,
    );
    final automaton = FSA(
      id: 'test-fsa',
      name: 'Test FSA',
      states: {q0, q1},
      transitions: <Transition>{},
      alphabet: const {'a'},
      initialState: q0,
      acceptingStates: <automaton_state.State>{},
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: math.Rectangle<double>(0, 0, 400, 400),
      zoomLevel: 1,
      panOffset: Vector2.zero(),
    );

    late AutomatonProvider automatonNotifier;
    final canvasKey = GlobalKey();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          automatonProvider.overrideWith((ref) {
            automatonNotifier = AutomatonProvider(
              automatonService: AutomatonService(),
              layoutRepository: LayoutRepositoryImpl(),
            );
            automatonNotifier.state =
                AutomatonState(currentAutomaton: automaton);
            return automatonNotifier;
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(automatonProvider);
              return Scaffold(
                body: SizedBox(
                  width: 600,
                  height: 400,
                  child: AutomatonCanvas(
                    automaton: state.currentAutomaton,
                    canvasKey: canvasKey,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final initialToggleFinder =
        find.byKey(const Key('automaton-node-q1-initial-toggle'));
    final acceptingToggleFinder =
        find.byKey(const Key('automaton-node-q1-accepting-toggle'));

    expect(initialToggleFinder, findsOneWidget);
    expect(acceptingToggleFinder, findsOneWidget);

    final automatonNodeTooltipFinder = find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == 'q1',
    );
    final automatonNodeBodyFinder = find.descendant(
      of: automatonNodeTooltipFinder,
      matching: find.byType(AnimatedContainer),
    );

    final initialRect = tester.getRect(automatonNodeBodyFinder);

    final initialIconBefore = tester.widget<Icon>(
      find.descendant(
        of: initialToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );

    await tester.tap(initialToggleFinder);
    await tester.pumpAndSettle();

    expect(
      automatonNotifier.state.currentAutomaton?.initialState?.id,
      equals('q1'),
    );

    final initialIconAfter = tester.widget<Icon>(
      find.descendant(
        of: initialToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );
    expect(initialIconAfter.color!.opacity,
        greaterThan(initialIconBefore.color!.opacity));

    await tester.tap(acceptingToggleFinder);
    await tester.pumpAndSettle();

    final acceptingRect = tester.getRect(automatonNodeBodyFinder);

    final acceptingIcon = tester.widget<Icon>(
      find.descendant(
        of: acceptingToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );

    expect(
      automatonNotifier.state.currentAutomaton?.acceptingStates
          .any((state) => state.id == 'q1'),
      isTrue,
    );
    expect(acceptingRect.size, equals(initialRect.size));
    expect(acceptingRect.topLeft, equals(initialRect.topLeft));
    expect(acceptingIcon.color!.opacity, closeTo(1, 0.01));
  });

  testWidgets('TM node header toggles state flags via notifier', (tester) async {
    late TMEditorNotifier tmNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tmEditorProvider.overrideWith((ref) {
            tmNotifier = TMEditorNotifier();
            tmNotifier.upsertState(
              id: 'q0',
              label: 'q0',
              x: 60,
              y: 60,
              isInitial: true,
            );
            tmNotifier.upsertState(
              id: 'q1',
              label: 'q1',
              x: 200,
              y: 60,
            );
            return tmNotifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: TMCanvasNative(
                onTMModified: _noopOnTMModified,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final initialToggleFinder =
        find.byKey(const Key('tm-node-q1-initial-toggle'));
    final acceptingToggleFinder =
        find.byKey(const Key('tm-node-q1-accepting-toggle'));

    expect(initialToggleFinder, findsOneWidget);
    expect(acceptingToggleFinder, findsOneWidget);

    final tmNodeTooltipFinder = find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == 'q1',
    );
    final tmNodeBodyFinder = find.descendant(
      of: tmNodeTooltipFinder,
      matching: find.byType(AnimatedContainer),
    );

    final tmInitialRect = tester.getRect(tmNodeBodyFinder);

    final initialIconBefore = tester.widget<Icon>(
      find.descendant(
        of: initialToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );

    await tester.tap(initialToggleFinder);
    await tester.pumpAndSettle();

    expect(tmNotifier.state.tm?.initialState?.id, equals('q1'));

    final initialIconAfter = tester.widget<Icon>(
      find.descendant(
        of: initialToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );
    expect(initialIconAfter.color!.opacity,
        greaterThan(initialIconBefore.color!.opacity));

    await tester.tap(acceptingToggleFinder);
    await tester.pumpAndSettle();

    final tmAcceptingRect = tester.getRect(tmNodeBodyFinder);

    final acceptingIcon = tester.widget<Icon>(
      find.descendant(
        of: acceptingToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );

    expect(
      tmNotifier.state.tm?.acceptingStates.any((state) => state.id == 'q1'),
      isTrue,
    );
    expect(tmAcceptingRect.size, equals(tmInitialRect.size));
    expect(tmAcceptingRect.topLeft, equals(tmInitialRect.topLeft));
    expect(acceptingIcon.color!.opacity, closeTo(1, 0.01));
  });

  testWidgets('PDA node header toggles state flags via notifier',
      (tester) async {
    late PDAEditorNotifier pdaNotifier;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pdaEditorProvider.overrideWith((ref) {
            pdaNotifier = PDAEditorNotifier();
            pdaNotifier.addOrUpdateState(
              id: 'q0',
              label: 'q0',
              x: 80,
              y: 80,
            );
            pdaNotifier.addOrUpdateState(
              id: 'q1',
              label: 'q1',
              x: 220,
              y: 80,
            );
            return pdaNotifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: PDACanvasNative(
                onPdaModified: _noopOnPdaModified,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final initialToggleFinder =
        find.byKey(const Key('pda-node-q1-initial-toggle'));
    final acceptingToggleFinder =
        find.byKey(const Key('pda-node-q1-accepting-toggle'));

    expect(initialToggleFinder, findsOneWidget);
    expect(acceptingToggleFinder, findsOneWidget);

    final pdaNodeTooltipFinder = find.byWidgetPredicate(
      (widget) => widget is Tooltip && widget.message == 'q1',
    );
    final pdaNodeBodyFinder = find.descendant(
      of: pdaNodeTooltipFinder,
      matching: find.byType(AnimatedContainer),
    );

    final pdaInitialRect = tester.getRect(pdaNodeBodyFinder);

    final initialIconBefore = tester.widget<Icon>(
      find.descendant(
        of: initialToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );

    await tester.tap(initialToggleFinder);
    await tester.pumpAndSettle();

    expect(pdaNotifier.state.pda?.initialState?.id, equals('q1'));

    final initialIconAfter = tester.widget<Icon>(
      find.descendant(
        of: initialToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );
    expect(initialIconAfter.color!.opacity,
        greaterThan(initialIconBefore.color!.opacity));

    await tester.tap(acceptingToggleFinder);
    await tester.pumpAndSettle();

    final pdaAcceptingRect = tester.getRect(pdaNodeBodyFinder);

    final acceptingIcon = tester.widget<Icon>(
      find.descendant(
        of: acceptingToggleFinder,
        matching: find.byType(Icon),
      ).first,
    );

    expect(
      pdaNotifier.state.pda?.acceptingStates
          .any((state) => state.id == 'q1'),
      isTrue,
    );
    expect(pdaAcceptingRect.size, equals(pdaInitialRect.size));
    expect(pdaAcceptingRect.topLeft, equals(pdaInitialRect.topLeft));
    expect(acceptingIcon.color!.opacity, closeTo(1, 0.01));
  });
}

void _noopOnTMModified(TM _) {}

void _noopOnPdaModified(PDA _) {}
