import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/data/repositories/algorithm_repository_impl.dart';

AutomatonEntity _createLambdaNfa() {
  return AutomatonEntity(
    id: 'lambda_nfa',
    name: 'Lambda NFA',
    alphabet: {'a', 'ε'},
    states: const [
      StateEntity(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
      StateEntity(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: true),
    ],
    transitions: {
      'q0|ε': ['q1'],
      'q1|a': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.nfaLambda,
  );
}

AutomatonEntity _createEvenZeroDfa() {
  return AutomatonEntity(
    id: 'even_zero',
    name: 'Even number of 0s',
    alphabet: {'0', '1'},
    states: const [
      StateEntity(id: 'e0', name: 'e0', x: 0, y: 0, isInitial: true, isFinal: true),
      StateEntity(id: 'e1', name: 'e1', x: 100, y: 0, isInitial: false, isFinal: false),
    ],
    transitions: {
      'e0|0': ['e1'],
      'e0|1': ['e0'],
      'e1|0': ['e0'],
      'e1|1': ['e1'],
    },
    initialId: 'e0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createEndsWithOneDfa() {
  return AutomatonEntity(
    id: 'ends_with_one',
    name: 'Ends with 1',
    alphabet: {'0', '1'},
    states: const [
      StateEntity(id: 's0', name: 's0', x: 0, y: 0, isInitial: true, isFinal: false),
      StateEntity(id: 's1', name: 's1', x: 100, y: 0, isInitial: false, isFinal: true),
    ],
    transitions: {
      's0|0': ['s0'],
      's0|1': ['s1'],
      's1|0': ['s0'],
      's1|1': ['s1'],
    },
    initialId: 's0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

AutomatonEntity _createExactAbDfa() {
  return AutomatonEntity(
    id: 'exact_ab',
    name: 'Accepts only ab',
    alphabet: {'a', 'b'},
    states: const [
      StateEntity(id: 'q0', name: 'q0', x: 0, y: 0, isInitial: true, isFinal: false),
      StateEntity(id: 'q1', name: 'q1', x: 100, y: 0, isInitial: false, isFinal: false),
      StateEntity(id: 'q2', name: 'q2', x: 200, y: 0, isInitial: false, isFinal: true),
      StateEntity(id: 'dead', name: 'dead', x: 300, y: 0, isInitial: false, isFinal: false),
    ],
    transitions: {
      'q0|a': ['q1'],
      'q0|b': ['dead'],
      'q1|a': ['dead'],
      'q1|b': ['q2'],
      'q2|a': ['dead'],
      'q2|b': ['dead'],
      'dead|a': ['dead'],
      'dead|b': ['dead'],
    },
    initialId: 'q0',
    nextId: 4,
    type: AutomatonType.dfa,
  );
}

Future<bool> _accepts(
  AlgorithmRepositoryImpl repository,
  AutomatonEntity automaton,
  String word,
) async {
  final result = await repository.simulateWord(automaton, word);
  expect(result.isSuccess, isTrue, reason: result.error);
  final SimulationResult simulation = result.data!;
  return simulation.accepted;
}

void main() {
  group('AlgorithmRepositoryImpl algorithms', () {
    late AlgorithmRepositoryImpl repository;

    setUp(() {
      repository = AlgorithmRepositoryImpl();
    });

    test('removeLambdaTransitions removes epsilon transitions and updates acceptance', () async {
      final result = await repository.removeLambdaTransitions(_createLambdaNfa());
      expect(result.isSuccess, isTrue, reason: result.error);
      final automaton = result.data!;

      expect(automaton.alphabet.contains('ε'), isFalse);
      expect(automaton.transitions.keys.any((key) => key.contains('ε')), isFalse);

      final q0 = automaton.states.firstWhere((state) => state.id == 'q0');
      expect(q0.isFinal, isTrue);
      expect(automaton.transitions['q0|a'], contains('q1'));

      expect(await _accepts(repository, automaton, ''), isTrue);
      expect(await _accepts(repository, automaton, 'aa'), isTrue);
    });

    test('complementDfa toggles acceptance', () async {
      final dfa = _createEvenZeroDfa();
      final result = await repository.complementDfa(dfa);
      expect(result.isSuccess, isTrue, reason: result.error);
      final complement = result.data!;

      expect(await _accepts(repository, dfa, '00'), isTrue);
      expect(await _accepts(repository, complement, '00'), isFalse);
      expect(await _accepts(repository, dfa, '0'), isFalse);
      expect(await _accepts(repository, complement, '0'), isTrue);
    });

    test('unionDfa combines languages correctly', () async {
      final result = await repository.unionDfa(
        _createEvenZeroDfa(),
        _createEndsWithOneDfa(),
      );
      expect(result.isSuccess, isTrue, reason: result.error);
      final union = result.data!;

      expect(await _accepts(repository, union, '1'), isTrue);
      expect(await _accepts(repository, union, '00'), isTrue);
      expect(await _accepts(repository, union, '0'), isFalse);
    });

    test('intersectionDfa retains common language', () async {
      final result = await repository.intersectionDfa(
        _createEvenZeroDfa(),
        _createEndsWithOneDfa(),
      );
      expect(result.isSuccess, isTrue, reason: result.error);
      final intersection = result.data!;

      expect(await _accepts(repository, intersection, '1'), isTrue);
      expect(await _accepts(repository, intersection, '11'), isTrue);
      expect(await _accepts(repository, intersection, '10'), isFalse);
      expect(await _accepts(repository, intersection, '0'), isFalse);
    });

    test('differenceDfa subtracts second language from first', () async {
      final result = await repository.differenceDfa(
        _createEvenZeroDfa(),
        _createEndsWithOneDfa(),
      );
      expect(result.isSuccess, isTrue, reason: result.error);
      final difference = result.data!;

      expect(await _accepts(repository, difference, '00'), isTrue);
      expect(await _accepts(repository, difference, '1'), isFalse);
    });

    test('prefixClosureDfa marks prefixes leading to acceptance', () async {
      final result = await repository.prefixClosureDfa(_createExactAbDfa());
      expect(result.isSuccess, isTrue, reason: result.error);
      final closure = result.data!;

      expect(await _accepts(repository, closure, ''), isTrue);
      expect(await _accepts(repository, closure, 'a'), isTrue);
      expect(await _accepts(repository, closure, 'ab'), isTrue);
      expect(await _accepts(repository, closure, 'b'), isFalse);
    });

    test('suffixClosureDfa accepts suffixes of original language', () async {
      final result = await repository.suffixClosureDfa(_createExactAbDfa());
      expect(result.isSuccess, isTrue, reason: result.error);
      final closure = result.data!;

      expect(await _accepts(repository, closure, ''), isTrue);
      expect(await _accepts(repository, closure, 'b'), isTrue);
      expect(await _accepts(repository, closure, 'ab'), isTrue);
      expect(await _accepts(repository, closure, 'a'), isFalse);
    });

    test('simulateWord delegates to simulator and returns detailed result', () async {
      final result = await repository.simulateWord(_createEvenZeroDfa(), '01');
      expect(result.isSuccess, isTrue, reason: result.error);
      final simulation = result.data!;
      expect(simulation.steps.length, greaterThan(1));
      expect(simulation.accepted, isTrue);
    });

    test('dfaToRegex produces equivalent regex', () async {
      final regexResult = await repository.dfaToRegex(_createExactAbDfa());
      expect(regexResult.isSuccess, isTrue, reason: regexResult.error);
      final regexString = regexResult.data!;
      expect(regexString.isNotEmpty, isTrue);

      final nfaResult = await repository.regexToNfa(regexString);
      expect(nfaResult.isSuccess, isTrue, reason: nfaResult.error);
      final dfaResult = await repository.nfaToDfa(nfaResult.data!);
      expect(dfaResult.isSuccess, isTrue, reason: dfaResult.error);

      final equivalence = await repository.areEquivalent(
        _createExactAbDfa(),
        dfaResult.data!,
      );
      expect(equivalence.isSuccess, isTrue, reason: equivalence.error);
      expect(equivalence.data, isTrue);
    });
  });
}
