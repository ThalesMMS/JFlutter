import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/algorithm_operations.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_analysis.dart';
import '../../core/result.dart';
import 'tm_editor_provider.dart';

enum TMAnalysisFocus {
  decidability,
  reachability,
  language,
  tape,
  time,
  space,
}

class TMAlgorithmState {
  final bool isAnalyzing;
  final TMAnalysis? analysis;
  final TM? analyzedTm;
  final String? errorMessage;
  final TMAnalysisFocus? focus;

  const TMAlgorithmState({
    this.isAnalyzing = false,
    this.analysis,
    this.analyzedTm,
    this.errorMessage,
    this.focus,
  });

  TMAlgorithmState copyWith({
    bool? isAnalyzing,
    TMAnalysis? analysis,
    TM? analyzedTm,
    String? errorMessage,
    TMAnalysisFocus? focus,
    bool clearAnalysis = false,
    bool clearError = false,
  }) {
    return TMAlgorithmState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      analysis: clearAnalysis ? null : analysis ?? this.analysis,
      analyzedTm: analyzedTm ?? this.analyzedTm,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      focus: focus ?? this.focus,
    );
  }
}

typedef TMAnalyzer = Result<TMAnalysis> Function(
  TM tm, {
  int maxInputLength,
  Duration timeout,
});

class TMAlgorithmViewModel extends StateNotifier<TMAlgorithmState> {
  TMAlgorithmViewModel(this._ref, {TMAnalyzer? analyzer})
      : _analyzer = analyzer ?? AlgorithmOperations.analyzeTm,
        super(const TMAlgorithmState());

  final Ref _ref;
  final TMAnalyzer _analyzer;

  Future<void> analyze(TMAnalysisFocus focus) async {
    state = state.copyWith(
      isAnalyzing: true,
      focus: focus,
      clearAnalysis: true,
      clearError: true,
    );

    final tm = _ref.read(tmEditorProvider).tm;
    if (tm == null) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage:
            'No Turing machine available. Draw states and transitions on the canvas to analyze.',
      );
      return;
    }

    Result<TMAnalysis> result;
    try {
      result = _analyzer(tm);
    } catch (error) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: 'Failed to analyze the Turing machine: $error',
      );
      return;
    }

    if (result.isSuccess) {
      state = state.copyWith(
        isAnalyzing: false,
        analysis: result.data,
        analyzedTm: tm,
      );
    } else {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: result.error ??
            'Analysis failed due to an unknown error. Please verify the machine configuration.',
      );
    }
  }
}

final tmAlgorithmViewModelProvider =
    StateNotifierProvider<TMAlgorithmViewModel, TMAlgorithmState>(
  (ref) => TMAlgorithmViewModel(ref),
);
