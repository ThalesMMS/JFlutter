import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/data/services/automaton_service.dart';
import 'package:jflutter/features/layout/layout_repository_impl.dart';
import 'package:jflutter/presentation/providers/automaton_provider.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas_native.dart';

void main() {
  testWidgets('Long press shows canvas actions before adding a state',
      (tester) async {
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
            return automatonNotifier;
          }),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              final automatonState = ref.watch(automatonProvider);
              return Scaffold(
                body: SizedBox(
                  width: 600,
                  height: 400,
                  child: AutomatonCanvas(
                    automaton: automatonState.currentAutomaton,
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

    final canvasRect = tester.getRect(find.byKey(canvasKey));
    final pressPosition = canvasRect.center + const Offset(40, -30);

    await tester.longPressAt(pressPosition);
    await tester.pumpAndSettle();

    expect(find.text('Canvas actions'), findsOneWidget);
    expect(find.text('Add state'), findsOneWidget);
    expect(automatonNotifier.state.currentAutomaton?.states, isEmpty);

    await tester.tap(find.text('Add state'));
    await tester.pumpAndSettle();

    final automaton = automatonNotifier.state.currentAutomaton;
    expect(automaton, isNotNull);
    expect(automaton!.states.length, 1);
  });
}
