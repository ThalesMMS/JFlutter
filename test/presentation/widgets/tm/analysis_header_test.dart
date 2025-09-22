import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/presentation/widgets/tm/analysis_header.dart';

void main() {
  testWidgets('shows TM analysis title and icon', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AnalysisHeader(),
        ),
      ),
    );

    expect(find.text('TM Analysis'), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });
}
