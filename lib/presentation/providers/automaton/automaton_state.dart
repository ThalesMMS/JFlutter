import '../../../core/models/fsa.dart';
import '../../../core/models/grammar.dart';
import '../../../core/models/simulation_result.dart' as sim_result;

class AutomatonState {
  final FSA? currentAutomaton;
  final sim_result.SimulationResult? simulationResult;
  final String? regexResult;
  final Grammar? grammarResult;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final bool isLoading;
  final String? error;

  const AutomatonState({
    this.currentAutomaton,
    this.simulationResult,
    this.regexResult,
    this.grammarResult,
    this.equivalenceResult,
    this.equivalenceDetails,
    this.isLoading = false,
    this.error,
  });

  static const _unset = Object();

  AutomatonState copyWith({
    Object? currentAutomaton = _unset,
    Object? simulationResult = _unset,
    Object? regexResult = _unset,
    Object? grammarResult = _unset,
    Object? equivalenceResult = _unset,
    Object? equivalenceDetails = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return AutomatonState(
      currentAutomaton: currentAutomaton == _unset
          ? this.currentAutomaton
          : currentAutomaton as FSA?,
      simulationResult: simulationResult == _unset
          ? this.simulationResult
          : simulationResult as sim_result.SimulationResult?,
      regexResult:
          regexResult == _unset ? this.regexResult : regexResult as String?,
      grammarResult: grammarResult == _unset
          ? this.grammarResult
          : grammarResult as Grammar?,
      equivalenceResult: equivalenceResult == _unset
          ? this.equivalenceResult
          : equivalenceResult as bool?,
      equivalenceDetails: equivalenceDetails == _unset
          ? this.equivalenceDetails
          : equivalenceDetails as String?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }
}
