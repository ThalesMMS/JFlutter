import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/grammar_entity.dart';
import 'package:jflutter/core/models/production.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';

class FakeAutomatonRepository implements AutomatonRepository {
  @override
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton) async {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> loadAutomaton(String id) {
    throw UnimplementedError();
  }

  @override
  Future<ListResult<AutomatonEntity>> loadAllAutomatons() {
    throw UnimplementedError();
  }

  @override
  Future<BoolResult> deleteAutomaton(String id) {
    throw UnimplementedError();
  }

  @override
  Future<StringResult> exportAutomaton(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> importAutomaton(String jsonString) {
    throw UnimplementedError();
  }

  @override
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton) {
    throw UnimplementedError();
  }
}

class FakeAlgorithmRepository implements AlgorithmRepository {
  @override
  Future<AutomatonResult> nfaToDfa(AutomatonEntity nfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> removeLambdaTransitions(AutomatonEntity nfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> minimizeDfa(AutomatonEntity dfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> completeDfa(AutomatonEntity dfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> complementDfa(AutomatonEntity dfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> unionDfa(AutomatonEntity a, AutomatonEntity b) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> intersectionDfa(AutomatonEntity a, AutomatonEntity b) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> differenceDfa(AutomatonEntity a, AutomatonEntity b) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> prefixClosureDfa(AutomatonEntity dfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> suffixClosureDfa(AutomatonEntity dfa) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> regexToNfa(String regex) {
    throw UnimplementedError();
  }

  @override
  Future<StringResult> dfaToRegex(AutomatonEntity dfa, {bool allowLambda = false}) {
    throw UnimplementedError();
  }

  @override
  Future<GrammarResult> fsaToGrammar(AutomatonEntity fsa) {
    throw UnimplementedError();
  }

  @override
  Future<BoolResult> areEquivalent(AutomatonEntity a, AutomatonEntity b) {
    throw UnimplementedError();
  }

  @override
  Future<Result<SimulationResult>> simulateWord(AutomatonEntity automaton, String word) {
    throw UnimplementedError();
  }

  @override
  Future<Result<List<SimulationStep>>> createStepByStepSimulation(
    AutomatonEntity automaton,
    String word,
  ) {
    throw UnimplementedError();
  }
}

class FakeLayoutRepository implements LayoutRepository {
  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) {
    throw UnimplementedError();
  }

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) {
    throw UnimplementedError();
  }
}

AutomatonEntity buildAutomatonEntity({String id = '1'}) {
  return AutomatonEntity(
    id: id,
    name: 'Automaton$id',
    alphabet: {'0', '1'},
    states: const [
      StateEntity(
        id: 'q0',
        name: 'q0',
        x: 0,
        y: 0,
        isInitial: true,
        isFinal: false,
      ),
      StateEntity(
        id: 'q1',
        name: 'q1',
        x: 100,
        y: 0,
        isInitial: false,
        isFinal: true,
      ),
    ],
    transitions: const {
      'q0|0': ['q1'],
      'q1|1': ['q1'],
    },
    initialId: 'q0',
    nextId: 2,
    type: AutomatonType.dfa,
  );
}

GrammarEntity buildGrammarEntity({String id = 'g1'}) {
  return GrammarEntity(
    id: id,
    name: 'Grammar$id',
    terminals: const ['a'],
    nonTerminals: const ['S'],
    productions: const [
      Production(
        id: 'p1',
        leftSide: ['S'],
        rightSide: ['a'],
      ),
    ],
    startSymbol: 'S',
    type: GrammarType.regular,
  );
}
