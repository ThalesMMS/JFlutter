import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/tm_algorithm_view_model.dart';
import 'tm/analysis_header.dart';
import 'tm/analysis_results.dart';
import 'tm/focus_selector.dart';

/// Panel for Turing Machine analysis algorithms
class TMAlgorithmPanel extends ConsumerWidget {
  const TMAlgorithmPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tmAlgorithmViewModelProvider);
    final notifier = ref.read(tmAlgorithmViewModelProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AnalysisHeader(),
            const SizedBox(height: 16),
            FocusSelector(
              isAnalyzing: state.isAnalyzing,
              selectedFocus: state.focus,
              onFocusSelected: notifier.analyze,
            ),
            const SizedBox(height: 16),
            AnalysisResults(state: state),
          ],
        ),
      ),
    );
  }
}
