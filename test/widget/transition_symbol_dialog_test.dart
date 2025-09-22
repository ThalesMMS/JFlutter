import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas/transition_symbol_input.dart';

void main() {
  testWidgets('invalid input shows error and prevents dialog dismissal', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AutomatonCanvas(
            automaton: null,
            canvasKey: GlobalKey(),
            onAutomatonChanged: (_) {},
          ),
        ),
      ),
    );

    final state = tester.state(find.byType(AutomatonCanvas)) as dynamic;
    final Future<TransitionSymbolInput?> future =
        state.showTransitionSymbolDialogForTest();

    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Please enter at least one symbol or ε.'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a, b');
    await tester.tap(find.text('Save'));

    await tester.pumpAndSettle();

    final result = await future;
    expect(result, isNotNull);
    expect(result!.label, 'a, b');
    expect(result.inputSymbols.containsAll(<String>['a', 'b']), isTrue);
    expect(result.lambdaSymbol, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
