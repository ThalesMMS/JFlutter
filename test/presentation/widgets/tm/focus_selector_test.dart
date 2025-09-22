import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/providers/tm_algorithm_view_model.dart';
import 'package:jflutter/presentation/widgets/tm/focus_selector.dart';

void main() {
  testWidgets('invokes callback when focus option is tapped', (tester) async {
    TMAnalysisFocus? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusSelector(
            isAnalyzing: false,
            selectedFocus: null,
            onFocusSelected: (focus) async {
              selected = focus;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Check Decidability'));
    expect(selected, TMAnalysisFocus.decidability);
  });

  testWidgets('shows progress indicators while analyzing and disables taps', (tester) async {
    TMAnalysisFocus? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusSelector(
            isAnalyzing: true,
            selectedFocus: TMAnalysisFocus.language,
            onFocusSelected: (focus) async {
              selected = focus;
            },
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNWidgets(6));

    await tester.tap(find.text('Language Analysis'));
    expect(selected, isNull);
  });
}
