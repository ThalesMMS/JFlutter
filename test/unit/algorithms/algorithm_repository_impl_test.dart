import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/data/repositories/algorithm_repository_impl.dart';

void main() {
  group('AlgorithmRepositoryImpl conversions', () {
    test('round-trips automaton entity preserving transitions and alphabet', () async {
      final repository = AlgorithmRepositoryImpl();

      const states = [
        StateEntity(
          id: 's0',
          name: 'q0',
          x: 0,
          y: 0,
          isInitial: true,
          isFinal: false,
        ),
        StateEntity(
          id: 's1',
          name: 'q1',
          x: 100,
          y: 0,
          isInitial: false,
          isFinal: true,
        ),
        StateEntity(
          id: 's2',
          name: 'q2',
          x: 200,
          y: 0,
          isInitial: false,
          isFinal: false,
        ),
      ];

      final transitions = {
        's0|a': ['s1'],
        's1|b': ['s0', 's2'],
        's0|λ': ['s2'],
      };

      final entity = AutomatonEntity(
        id: 'a1',
        name: 'Automaton',
        alphabet: {'a', 'b', 'λ'},
        states: states,
        transitions: transitions,
        initialId: 's0',
        nextId: 3,
        type: AutomatonType.nfaLambda,
      );

      final result = await repository.removeLambdaTransitions(entity);

      expect(result.isSuccess, isTrue);
      final roundTripped = result.data!;

      Map<String, List<String>> normalize(Map<String, List<String>> input) {
        return input.map((key, value) {
          final sorted = [...value]..sort();
          return MapEntry(key, sorted);
        });
      }

      expect(roundTripped.alphabet, equals(entity.alphabet));
      expect(normalize(roundTripped.transitions), equals(normalize(transitions)));
    });
  });
}
