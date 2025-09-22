import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:jflutter/core/models/tm.dart';
import 'package:jflutter/core/result.dart';
import 'package:jflutter/presentation/providers/tm_algorithm_view_model.dart';
import 'package:jflutter/presentation/providers/tm_editor_provider.dart';
import '../../test_utils/tm_test_utils.dart';

class _FakeTmEditorNotifier extends StateNotifier<TMEditorState> {
  _FakeTmEditorNotifier(TMEditorState state) : super(state);
}

void main() {
  group('TMAlgorithmViewModel', () {
    test('exposes error when no TM is available', () async {
      final container = ProviderContainer(overrides: [
        tmEditorProvider.overrideWith(() => _FakeTmEditorNotifier(const TMEditorState())),
        tmAlgorithmViewModelProvider.overrideWith(
          (ref) => TMAlgorithmViewModel(ref, analyzer: _successAnalyzer()),
        ),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(tmAlgorithmViewModelProvider.notifier);
      await notifier.analyze(TMAnalysisFocus.decidability);

      final state = container.read(tmAlgorithmViewModelProvider);
      expect(state.isAnalyzing, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.analysis, isNull);
    });

    test('stores analysis result on success', () async {
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

      final notifier = container.read(tmAlgorithmViewModelProvider.notifier);
      await notifier.analyze(TMAnalysisFocus.tape);

      final state = container.read(tmAlgorithmViewModelProvider);
      expect(state.isAnalyzing, isFalse);
      expect(state.analysis, equals(analysis));
      expect(state.analyzedTm, equals(tm));
      expect(state.errorMessage, isNull);
      expect(state.focus, TMAnalysisFocus.tape);
    });

    test('captures analyzer exceptions', () async {
      final tm = TmTestData.createTm();

      final container = ProviderContainer(overrides: [
        tmEditorProvider.overrideWith(
          () => _FakeTmEditorNotifier(TMEditorState(tm: tm)),
        ),
        tmAlgorithmViewModelProvider.overrideWith(
          (ref) => TMAlgorithmViewModel(
            ref,
            analyzer: (machine, {int maxInputLength = 10, Duration timeout = const Duration(seconds: 10)}) {
              throw Exception('boom');
            },
          ),
        ),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(tmAlgorithmViewModelProvider.notifier);
      await notifier.analyze(TMAnalysisFocus.reachability);

      final state = container.read(tmAlgorithmViewModelProvider);
      expect(state.isAnalyzing, isFalse);
      expect(state.errorMessage, contains('Failed to analyze'));
      expect(state.analysis, isNull);
    });
  });
}

TMAnalyzer _successAnalyzer() {
  return (tm, {int maxInputLength = 10, Duration timeout = const Duration(seconds: 10)}) {
    final analysis = TmTestData.createAnalysis(tm);
    return ResultFactory.success(analysis);
  };
}
