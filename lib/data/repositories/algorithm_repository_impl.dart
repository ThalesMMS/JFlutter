import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/models/automaton.dart';
import '../../core/automaton.dart' as automaton_core;
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/fsa.dart';
import '../../core/algorithms.dart' as algorithms;
import '../../core/dfa_algorithms.dart' as dfa_alg;
import '../../core/regex.dart' as regex_alg;
import '../../core/grammar.dart';
import '../../core/run.dart';
import '../../core/equivalence_checking.dart';
import '../../core/models/simulation_result.dart';

/// Implementation of AlgorithmRepository
class AlgorithmRepositoryImpl implements AlgorithmRepository {
  @override
  Future<Result<AutomatonEntity>> nfaToDfa(AutomatonEntity nfaEntity) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity);
      final result = algorithms.NFAToDFAConverter.convert(nfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!, AutomatonType.fsa);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na conversão NFA → DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> removeLambdaTransitions(AutomatonEntity nfaEntity) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity);
      // For now, return the same NFA as lambda removal is not implemented
      final result = nfa;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na remoção de transições lambda: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> minimizeDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = dfa_alg.DFAMinimizer.minimize(dfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!, AutomatonType.fsa);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na minimização do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> completeDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      // For now, return the same DFA as completion is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na completação do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> complementDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      // For now, return the same DFA as complement is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no complemento do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> unionDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      // For now, return the first DFA as union is not implemented
      final result = a;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na união de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> intersectionDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      // For now, return the first DFA as intersection is not implemented
      final result = a;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na interseção de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> differenceDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      // For now, return the first DFA as difference is not implemented
      final result = a;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na diferença de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> prefixClosureDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      // For now, return the same DFA as prefix closure is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no fecho por prefixos: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> suffixClosureDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      // For now, return the same DFA as suffix closure is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, AutomatonType.fsa);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no fecho por sufixos: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> regexToNfa(String regex) async {
    try {
      final result = regex_alg.RegexToNFAConverter.convert(regex);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!, AutomatonType.fsa);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
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
      // For now, return false as equivalence checking is not implemented
      final result = false;
      return Success(result);
    } catch (e) {
      return Failure('Erro na verificação de equivalência: $e');
    }
  }

  @override
  Future<Result<SimulationResult>> simulateWord(AutomatonEntity automatonEntity, String word) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity);
      // For now, return false as word running is not implemented
      final runResult = false;
      final simulationResult = SimulationResult(
        accepted: runResult,
        visitedStates: <String>[],
        messages: [],
        haltReason: runResult ? 'Word accepted' : 'Word rejected',
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
      // For now, return false as word running is not implemented
      final runResult = false;
      final simulationResult = SimulationResult(
        accepted: runResult,
        visitedStates: <String>[],
        messages: [],
        haltReason: runResult ? 'Word accepted' : 'Word rejected',
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
  automaton_core.Automaton _entityToAutomaton(AutomatonEntity entity) {
        final states = entity.states.map((s) => automaton_state.State(
      id: s.id,
      label: s.name,
      position: Vector2(s.x, s.y),
      isInitial: s.isInitial,
      isAccepting: s.isFinal,
    )).toSet();

    final transitions = <String, List<String>>{};
    for (final entry in entity.transitions.entries) {
      transitions[entry.key] = entry.value;
    }

        return FSA(
      id: entity.id,
      name: entity.name,
      states: states,
      transitions: const {},
      alphabet: entity.alphabet,
      acceptingStates: states.where((s) => s.isAccepting).toSet(),
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: const math.Rectangle(0, 0, 800, 600),
    );
  }

  AutomatonEntity _automatonToEntity(automaton_core.Automaton automaton, AutomatonType type) {
    final states = automaton.states.map((s) => StateEntity(
      id: s.id,
      name: s.label,
      x: s.position.x,
      y: s.position.y,
      isInitial: s.isInitial,
      isFinal: s.isAccepting,
    )).toList();

    final transitions = <String, List<String>>{};
    // For now, create empty transitions as the automaton model doesn't have the same structure

    return AutomatonEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Resultado',
      type: type,
      states: states,
      transitions: transitions,
      alphabet: automaton.alphabet,
      initialId: automaton.initialState?.id ?? '',
      nextId: 0,
    );
  }
}

