part of 'pda_simulator.dart';

/// Summary of the PDA simplification step.
class PDASimplificationSummary {
  final PDA minimizedPda;
  final Set<State> removedStates;
  final Set<State> unreachableStates;
  final Set<State> nonProductiveStates;
  final Set<String> removedTransitionIds;
  final List<PDAMergeGroup> mergeGroups;
  final bool changed;
  final List<String> warnings;

  PDASimplificationSummary({
    required this.minimizedPda,
    required Set<State> removedStates,
    required Set<State> unreachableStates,
    required Set<State> nonProductiveStates,
    required Set<String> removedTransitionIds,
    required List<PDAMergeGroup> mergeGroups,
    required this.changed,
    required List<String> warnings,
  })  : removedStates = Set.unmodifiable(removedStates),
        unreachableStates = Set.unmodifiable(unreachableStates),
        nonProductiveStates = Set.unmodifiable(nonProductiveStates),
        removedTransitionIds = Set.unmodifiable(removedTransitionIds),
        mergeGroups = List.unmodifiable(mergeGroups),
        warnings = List.unmodifiable(warnings);

  bool get hasMerges =>
      mergeGroups.any((group) => group.mergedStates.isNotEmpty);
}

/// Represents a group of states merged into a representative state.
class PDAMergeGroup {
  final State representative;
  final Set<State> mergedStates;

  PDAMergeGroup({
    required this.representative,
    required Set<State> mergedStates,
  }) : mergedStates = Set.unmodifiable(mergedStates);

  bool get isMeaningful => mergedStates.isNotEmpty;
}
