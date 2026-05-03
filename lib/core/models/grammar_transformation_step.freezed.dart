// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'grammar_transformation_step.dart';

mixin _$GrammarTransformationStep {
  String get id;
  String get operation;
  String get rationale;
  Grammar get before;
  Grammar get after;
  Set<String> get changedSymbols;
  Set<String> get changedProductionIds;

  Map<String, dynamic> toJson();
}

class _GrammarTransformationStep extends GrammarTransformationStep {
  const _GrammarTransformationStep({
    required this.id,
    required this.operation,
    required this.rationale,
    required this.before,
    required this.after,
    this.changedSymbols = const <String>{},
    this.changedProductionIds = const <String>{},
  }) : super._();

  @override
  final String id;
  @override
  final String operation;
  @override
  final String rationale;
  @override
  final Grammar before;
  @override
  final Grammar after;
  @override
  final Set<String> changedSymbols;
  @override
  final Set<String> changedProductionIds;

  @override
  Map<String, dynamic> toJson() => _$GrammarTransformationStepToJson(this);

  @override
  String toString() {
    return 'GrammarTransformationStep(id: $id, operation: $operation, rationale: $rationale, before: $before, after: $after, changedSymbols: $changedSymbols, changedProductionIds: $changedProductionIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is GrammarTransformationStep &&
            other.id == id &&
            other.operation == operation &&
            other.rationale == rationale &&
            other.before == before &&
            other.after == after &&
            _grammarTransformationStepSetEquals(
              other.changedSymbols,
              changedSymbols,
            ) &&
            _grammarTransformationStepSetEquals(
              other.changedProductionIds,
              changedProductionIds,
            );
  }

  @override
  int get hashCode => Object.hash(
        id,
        operation,
        rationale,
        before,
        after,
        Object.hashAllUnordered(changedSymbols),
        Object.hashAllUnordered(changedProductionIds),
      );
}

bool _grammarTransformationStepSetEquals<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final item in a) {
    if (!b.contains(item)) return false;
  }
  return true;
}
