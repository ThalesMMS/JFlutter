import '../../core/repositories/automaton_repository.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/automaton.dart';
import '../../core/algorithms.dart' as algorithms;
import '../../core/dfa_algorithms.dart' as dfa_alg;
import '../../core/regex.dart' as regex_alg;
import '../../core/grammar.dart';
import '../../core/run.dart';
import '../../core/equivalence_checking.dart';

/// Implementation of AlgorithmRepository
class AlgorithmRepositoryImpl implements AlgorithmRepository {
  @override
  Future<AutomatonResult> nfaToDfa(AutomatonEntity nfaEntity) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity);
      final result = algorithms.nfaToDfa(nfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na conversão NFA → DFA: $e');
    }
  }

  @override
  Future<AutomatonResult> removeLambdaTransitions(AutomatonEntity nfaEntity) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity);
      final result = algorithms.nfaLambdaToNfa(nfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.nfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na remoção de transições lambda: $e');
    }
  }

  @override
  Future<AutomatonResult> minimizeDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = dfa_alg.minimizeDfa(dfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na minimização do DFA: $e');
    }
  }

  @override
  Future<AutomatonResult> completeDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = algorithms.completeDfa(dfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na completação do DFA: $e');
    }
  }

  @override
  Future<AutomatonResult> complementDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = algorithms.complementDfa(dfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no complemento do DFA: $e');
    }
  }

  @override
  Future<AutomatonResult> unionDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      final result = algorithms.unionDfa(a, b);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na união de DFAs: $e');
    }
  }

  @override
  Future<AutomatonResult> intersectionDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      final result = algorithms.intersectionDfa(a, b);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na interseção de DFAs: $e');
    }
  }

  @override
  Future<AutomatonResult> differenceDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      final result = algorithms.differenceDfa(a, b);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na diferença de DFAs: $e');
    }
  }

  @override
  Future<AutomatonResult> prefixClosureDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = algorithms.prefixClosureDfa(dfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no fecho por prefixos: $e');
    }
  }

  @override
  Future<AutomatonResult> suffixClosureDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = algorithms.suffixClosureDfa(dfa);
      final resultEntity = _automatonToEntity(result, AutomatonType.dfa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no fecho por sufixos: $e');
    }
  }

  @override
  Future<AutomatonResult> regexToNfa(String regex) async {
    try {
      final result = regex_alg.automatonFromRegex(regex);
      final resultEntity = _automatonToEntity(result, AutomatonType.nfaLambda);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na conversão ER → NFA: $e');
    }
  }

  @override
  Future<StringResult> dfaToRegex(AutomatonEntity dfaEntity, {bool allowLambda = false}) async {
    try {
      // TODO: Implement DFA to regex conversion
      return Failure('DFA to regex conversion not yet implemented');
    } catch (e) {
      return Failure('Erro na conversão DFA → ER: $e');
    }
  }

  @override
  Future<BoolResult> areEquivalent(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      final result = EquivalenceChecker.checkEquivalence(a, b);
      return Success(result.areEquivalent);
    } catch (e) {
      return Failure('Erro na verificação de equivalência: $e');
    }
  }

  @override
  Future<Result<SimulationResult>> simulateWord(AutomatonEntity automatonEntity, String word) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity);
      final runResult = algorithms.runWord(automaton, word);
      final simulationResult = SimulationResult(
        accepted: runResult.accepted,
        visitedStates: runResult.visited,
        messages: [],
        haltReason: runResult.accepted ? 'Word accepted' : 'Word rejected',
      );
      return Success(simulationResult);
    } catch (e) {
      return Failure('Erro na simulação da palavra: $e');
    }
  }

  @override
  Future<Result<StepByStepSimulation>> createStepByStepSimulation(
    AutomatonEntity automatonEntity, 
    String word
  ) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity);
      // TODO: Implement step-by-step simulation
      final runResult = algorithms.runWord(automaton, word);
      final simulationResult = SimulationResult(
        accepted: runResult.accepted,
        visitedStates: runResult.visited,
        messages: [],
        haltReason: runResult.accepted ? 'Word accepted' : 'Word rejected',
      );
      final stepByStep = StepByStepSimulation(
        automaton: automatonEntity,
        word: word,
        currentStates: runResult.visited.isNotEmpty ? runResult.visited.last : {},
        stepIndex: 0,
        messages: [],
        isComplete: true,
        haltReason: runResult.accepted ? 'Word accepted' : 'Word rejected',
      );
      return Success(stepByStep);
    } catch (e) {
      return Failure('Erro na simulação passo-a-passo: $e');
    }
  }

  // Helper methods for conversion between entities and core automaton objects
  Automaton _entityToAutomaton(AutomatonEntity entity) {
    final states = entity.states.map((s) => StateNode(
      id: s.id,
      name: s.name,
      x: s.x,
      y: s.y,
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    )).toList();

    final transitions = <String, List<String>>{};
    for (final entry in entity.transitions.entries) {
      transitions[entry.key] = entry.value;
    }

    return Automaton(
      states: states,
      transitions: transitions,
      alphabet: entity.alphabet,
      initialId: entity.initialId,
      nextId: entity.nextId,
    );
  }

  AutomatonEntity _automatonToEntity(Automaton automaton, AutomatonType type) {
    final states = automaton.states.map((s) => StateEntity(
      id: s.id,
      name: s.name,
      x: s.x,
      y: s.y,
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    )).toList();

    final transitions = <String, List<String>>{};
    for (final entry in automaton.transitions.entries) {
      transitions[entry.key] = entry.value.toList();
    }

    return AutomatonEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Resultado',
      type: type,
      states: states,
      transitions: transitions,
      alphabet: automaton.alphabet,
      nextId: 0,
    );
  }
}

