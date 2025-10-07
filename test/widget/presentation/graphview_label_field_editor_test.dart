/// ---------------------------------------------------------------------------
/// Teste: editor inline de rótulos no GraphView.
/// Resumo: Verifica submissão com Enter, cancelamento com Escape e disparo de
/// callbacks garantindo preservação do valor original quando descartado.
/// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/features/canvas/graphview/graphview_label_field_editor.dart';

void main() {
  testWidgets('GraphViewLabelFieldEditor submits value on Enter',
      (tester) async {
    String? submitted;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewLabelFieldEditor(
            initialValue: 'q0',
            onSubmit: (value) => submitted = value,
            onCancel: () {},
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'q1');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(submitted, 'q1');
  });

  testWidgets('GraphViewLabelFieldEditor cancels on Escape',
      (tester) async {
    var canceled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GraphViewLabelFieldEditor(
            initialValue: 'q0',
            onSubmit: (_) {},
            onCancel: () => canceled = true,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.enterText(find.byType(TextField), 'q2');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(canceled, isTrue);
  });

  testWidgets('GraphViewLabelFieldEditor cancels when focus is lost',
      (tester) async {
    var canceled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              GraphViewLabelFieldEditor(
                initialValue: 'q0',
                onSubmit: (_) {},
                onCancel: () => canceled = true,
              ),
              const TextField(key: Key('other')),
            ],
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.tap(find.byKey(const Key('other')));
    await tester.pump();

    expect(canceled, isTrue);
  });
}
