
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/result.dart';

class LayoutRepositoryImpl implements LayoutRepository {
  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) async {
    final states = automaton.states;
    if (states.isEmpty) {
      return Success(automaton);
    }

    final center = Vector2(400, 300); // Assuming a canvas center
    final radius = math.min(center.x, center.y) - 50;
    final angleStep = (2 * math.pi) / states.length;

    final newStates = <StateEntity>[];
    for (int i = 0; i < states.length; i++) {
      final angle = i * angleStep;
      final x = center.x + radius * math.cos(angle);
      final y = center.y + radius * math.sin(angle);
      newStates.add(states[i].copyWith(x: x, y: y));
    }

    return Success(automaton.copyWith(states: newStates));
  }

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) async {
    return Failure('Balanced layout not implemented');
  }

  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) async {
    return Failure('Compact layout not implemented');
  }

  @override
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton) async {
    return Failure('Hierarchical layout not implemented');
  }

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) async {
    return Failure('Spread layout not implemented');
  }

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) async {
    return Failure('Center automaton not implemented');
  }
}
