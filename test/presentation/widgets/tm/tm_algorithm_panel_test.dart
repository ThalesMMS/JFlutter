import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/result.dart';
import 'package:jflutter/presentation/providers/tm_algorithm_view_model.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import 'package:jflutter/presentation/widgets/tm_algorithm_panel.dart';
import '../../../test_utils/tm_test_utils.dart';

class _FakeTmEditorNotifier extends StateNotifier<TMEditorState> {
  _FakeTmEditorNotifier(TMEditorState state) : super(state);
}

void main() {
  testWidgets('renders header and placeholder when idle', (tester) async {
    final container = ProviderContainer(overrides: [
      tmEditorProvider.overrideWith(
        () => _FakeTmEditorNotifier(const TMEditorState()),
      ),
      tmAlgorithmViewModelProvider.overrideWith(
        (ref) => TMAlgorithmViewModel(
          ref,
          analyzer: (tm, {int maxInputLength = 10, Duration timeout = const Duration(seconds: 10)}) {
            return ResultFactory.failure('not used');
          },
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: TMAlgorithmPanel(),
          ),
        ),
      ),
    );

    expect(find.text('TM Analysis'), findsOneWidget);
    expect(find.text('Analysis Results'), findsOneWidget);
    expect(find.text('No analysis results yet'), findsOneWidget);
  });

  testWidgets('triggers analysis when selecting a focus option', (tester) async {
    final tm = TmTestData.createTm();
    final analysis = TmTestData.createAnalysis(tm);

    final container = ProviderContainer(overrides: [
      tmEditorProvider.overrideWith(
        () => _FakeTmEditorNotifier(TMEditorState(tm: tm)),
      ),
      tmAlgorithmViewModelProvider.overrideWith(
        (ref) => TMAlgorithmViewModel(
          ref,
          analyzer: (machine, {int maxInputLength = 10, Duration timeout = const Duration(seconds: 10)}) {
            expect(machine, equals(tm));
            return ResultFactory.success(analysis);
          },
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: TMAlgorithmPanel(),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Check Decidability'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Analysis focus: Decidability'), findsOneWidget);
    expect(find.text('Total states'), findsOneWidget);
  });
}
