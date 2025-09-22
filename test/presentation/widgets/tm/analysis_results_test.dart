import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/presentation/providers/tm_algorithm_view_model.dart';
import 'package:jflutter/presentation/widgets/tm/analysis_results.dart';
import '../../test_utils/tm_test_utils.dart';

void main() {
  testWidgets('shows placeholder when there are no results', (tester) async {
    const state = TMAlgorithmState();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: Column(
              children: [
                AnalysisResults(state: state),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('No analysis results yet'), findsOneWidget);
    expect(find.textContaining('Select an algorithm'), findsOneWidget);
  });

  testWidgets('renders error message when state contains error', (tester) async {
    const state = TMAlgorithmState(errorMessage: 'Something went wrong');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: Column(
              children: [
                AnalysisResults(state: state),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('displays computed metrics for a successful analysis', (tester) async {
    final TM tm = TmTestData.createTm();
    final analysis = TmTestData.createAnalysis(tm);
    final state = TMAlgorithmState(
      analysis: analysis,
      analyzedTm: tm,
      focus: TMAnalysisFocus.tape,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 600,
            child: Column(
              children: [
                AnalysisResults(state: state),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Analysis focus: Tape operations'), findsOneWidget);
    expect(find.text('Total states'), findsOneWidget);
    expect(find.text('2'), findsWidgets);
    expect(find.text('Reachable'), findsOneWidget);
    expect(find.text('No structural issues detected.'), findsOneWidget);
  });
}
