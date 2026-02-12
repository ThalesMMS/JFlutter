import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/algorithms/pda_simulator.dart';
import 'package:jflutter/data/examples/pda_examples.dart';

void main() {
  test('PDA a^n b^n accepts aabb', () {
    final pda = PDAExamples.aNbN();

    final result = PDASimulator.simulate(pda, 'aabb', stepByStep: true);
    expect(result.isSuccess, isTrue, reason: 'Simulation should succeed');

    final sim = result.data!;
    // Print steps for debugging
    for (final step in sim.steps) {
      // ignore: avoid_print
      print(
        'Step ${step.stepNumber}: state=${step.currentState} '
        'stack="${step.stackContents}" '
        'remaining="${step.remainingInput}" '
        'transition="${step.usedTransition}"',
      );
    }

    expect(sim.accepted, isTrue, reason: 'aabb should be accepted by a^n b^n');
  });

  test('PDA a^n b^n rejects aab', () {
    final pda = PDAExamples.aNbN();
    final result = PDASimulator.simulate(pda, 'aab', stepByStep: true);
    expect(result.isSuccess, isTrue);
    expect(result.data!.accepted, isFalse);
  });
}
