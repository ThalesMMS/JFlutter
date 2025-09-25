import 'dart:collection';

import '../core_base/trace.dart';
import '../../models/pda.dart';
import '../../models/simulation_step.dart';
import 'acceptance_criterion.dart';

/// Witness branch collected during PDA simulation.
class PDASimulationWitness implements Trace<SimulationStep> {
  PDASimulationWitness({
    required List<SimulationStep> steps,
    required Set<PDAAcceptanceCriterion> criteria,
  })  : configurations = UnmodifiableListView(steps),
        criteria = UnmodifiableSetView(criteria);

  @override
  final UnmodifiableListView<SimulationStep> configurations;
  final UnmodifiableSetView<PDAAcceptanceCriterion> criteria;

  @override
  SimulationStep get terminal => configurations.isNotEmpty
      ? configurations.last
      : throw StateError('Witness trace is empty');

  @override
  Trace<SimulationStep> append(SimulationStep configuration) {
    return PDASimulationWitness(
      steps: [...configurations, configuration],
      criteria: criteria.toSet(),
    );
  }

  bool get acceptedByFinalState =>
      criteria.contains(PDAAcceptanceCriterion.finalState);
  bool get acceptedByEmptyStack =>
      criteria.contains(PDAAcceptanceCriterion.emptyStack);

  @override
  bool get accepted => terminal.isAccepting;
}

/// Details about conflicting transitions in a PDA.
class PDADeterminismConflict {
  PDADeterminismConflict({
    required this.stateId,
    required this.inputSymbol,
    required this.stackSymbol,
    required List<String> transitionIds,
  }) : transitionIds = UnmodifiableListView(transitionIds);

  final String stateId;
  final String inputSymbol;
  final String stackSymbol;
  final UnmodifiableListView<String> transitionIds;

  bool get involvesLambdaInput => inputSymbol == 'λ';
  bool get involvesLambdaPop => stackSymbol == 'λ';
}

/// Result of simulating a PDA.
class PDASimulationResult {
  PDASimulationResult._({
    required this.inputString,
    required this.accepted,
    required List<SimulationStep> steps,
    this.errorMessage,
    required this.executionTime,
    required this.acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
    this.branchesTruncated = false,
  })  : steps = UnmodifiableListView(steps),
        acceptedBranches =
            UnmodifiableListView(acceptedBranches ?? const <PDASimulationWitness>[]),
        determinismConflicts = UnmodifiableListView(
          determinismConflicts ?? const <PDADeterminismConflict>[],
        );

  final String inputString;
  final bool accepted;
  final UnmodifiableListView<SimulationStep> steps;
  final String? errorMessage;
  final Duration executionTime;
  final PDAAcceptanceMode acceptanceMode;
  final UnmodifiableListView<PDASimulationWitness> acceptedBranches;
  final bool branchesTruncated;
  final UnmodifiableListView<PDADeterminismConflict> determinismConflicts;

  bool get isDeterministic => determinismConflicts.isEmpty;
  bool get hasMultipleAcceptingBranches => acceptedBranches.length > 1;

  factory PDASimulationResult.success({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    required PDAAcceptanceMode acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    List<PDADeterminismConflict>? determinismConflicts,
    bool branchesTruncated = false,
  }) {
    final accepted = acceptedBranches?.isNotEmpty ?? false;
    return PDASimulationResult._(
      inputString: inputString,
      accepted: accepted,
      steps: steps,
      executionTime: executionTime,
      acceptanceMode: acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
      branchesTruncated: branchesTruncated,
    );
  }

  factory PDASimulationResult.failure({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    required String errorMessage,
    required PDAAcceptanceMode acceptanceMode,
    List<PDADeterminismConflict>? determinismConflicts,
    List<PDASimulationWitness>? acceptedBranches,
    bool branchesTruncated = false,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: false,
      steps: steps,
      executionTime: executionTime,
      errorMessage: errorMessage,
      acceptanceMode: acceptanceMode,
      determinismConflicts: determinismConflicts,
      acceptedBranches: acceptedBranches,
      branchesTruncated: branchesTruncated,
    );
  }

  factory PDASimulationResult.timeout({
    required String inputString,
    required List<SimulationStep> steps,
    required Duration executionTime,
    required PDAAcceptanceMode acceptanceMode,
    required List<PDASimulationWitness> acceptedBranches,
    required List<PDADeterminismConflict> determinismConflicts,
    required bool branchesTruncated,
  }) {
    return PDASimulationResult._(
      inputString: inputString,
      accepted: acceptedBranches.isNotEmpty,
      steps: steps,
      executionTime: executionTime,
      acceptanceMode: acceptanceMode,
      acceptedBranches: acceptedBranches,
      determinismConflicts: determinismConflicts,
      branchesTruncated: branchesTruncated,
      errorMessage: 'Simulation timed out',
    );
  }

  PDASimulationResult copyWith({
    String? inputString,
    bool? accepted,
    List<SimulationStep>? steps,
    String? errorMessage,
    Duration? executionTime,
    PDAAcceptanceMode? acceptanceMode,
    List<PDASimulationWitness>? acceptedBranches,
    bool? branchesTruncated,
    List<PDADeterminismConflict>? determinismConflicts,
  }) {
    return PDASimulationResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      steps: steps ?? this.steps,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
      acceptanceMode: acceptanceMode ?? this.acceptanceMode,
      acceptedBranches: acceptedBranches ?? this.acceptedBranches,
      determinismConflicts: determinismConflicts ?? this.determinismConflicts,
      branchesTruncated: branchesTruncated ?? this.branchesTruncated,
    );
  }
}
