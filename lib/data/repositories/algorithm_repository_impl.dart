import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/models/automaton.dart' as model_automaton;
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/transition.dart' as model_transition;
import '../../core/models/fsa.dart';
import '../../core/algorithms.dart' as algorithms;
import '../../core/dfa_algorithms.dart' as dfa_alg;
import '../../core/regex.dart' as regex_alg;
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../core/algorithms/equivalence_checker.dart';
import '../../core/algorithms/fsa_to_grammar_converter.dart';
import '../../core/entities/grammar_entity.dart';
import '../../core/models/grammar.dart' as model_grammar;

/// Implementation of AlgorithmRepository
class AlgorithmRepositoryImpl implements AlgorithmRepository {
  @override
  Future<Result<AutomatonEntity>> nfaToDfa(AutomatonEntity nfaEntity) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity) as FSA; // Converte para o modelo
      final result = algorithms.NFAToDFAConverter.convert(nfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa); // Converte de volta
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
      final nfa = _entityToAutomaton(nfaEntity) as FSA; // Converte para o modelo
      // For now, return the same NFA as lambda removal is not implemented
      final result = nfa;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na remoção de transições lambda: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> minimizeDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = dfa_alg.DFAMinimizer.minimize(dfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa); // Converte de volta
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
      final dfa = _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = dfa_alg.DFACompleter.complete(dfa);
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na completação do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> complementDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      // For now, return the same DFA as complement is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no complemento do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> unionDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA; // Converte para o modelo
      final b = _entityToAutomaton(bEntity) as FSA; // Converte para o modelo
      // For now, return the first DFA as union is not implemented
      final result = a;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na união de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> intersectionDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA; // Converte para o modelo
      final b = _entityToAutomaton(bEntity) as FSA; // Converte para o modelo
      // For now, return the first DFA as intersection is not implemented
      final result = a;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na interseção de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> differenceDfa(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA; // Converte para o modelo
      final b = _entityToAutomaton(bEntity) as FSA; // Converte para o modelo
      // For now, return the first DFA as difference is not implemented
      final result = a;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na diferença de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> prefixClosureDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      // For now, return the same DFA as prefix closure is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro no fecho por prefixos: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> suffixClosureDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      // For now, return the same DFA as suffix closure is not implemented
      final result = dfa;
      final resultEntity = _automatonToEntity(result, model_automaton.AutomatonType.fsa); // Converte de volta
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
        final resultEntity = _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa); // Converte de volta
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
  Future<GrammarResult> fsaToGrammar(AutomatonEntity fsaEntity) async {
    try {
      final fsa = _entityToAutomaton(fsaEntity) as FSA;
      final result = FSAToGrammarConverter.convert(fsa);
      final resultEntity = _grammarToEntity(result);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na conversão FSA → Gramática: $e');
    }
  }

  @override
  Future<BoolResult> areEquivalent(AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA;
      final b = _entityToAutomaton(bEntity) as FSA;
      final result = EquivalenceChecker.areEquivalent(a, b);
      return Success(result);
    } catch (e) {
      return Failure('Erro na verificação de equivalência: $e');
    }
  }

  @override
  Future<Result<SimulationResult>> simulateWord(AutomatonEntity automatonEntity, String word) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA; // Converte para o modelo
      // For now, return false as word running is not implemented
      final runResult = false;
      final simulationResult = SimulationResult.success(
        inputString: word,
        steps: [],
        executionTime: Duration.zero,
      );
      return Success(simulationResult);
    } catch (e) {
      return Failure('Erro na simulação da palavra: $e');
    }
  }

  @override
  Future<Result<List<SimulationStep>>> createStepByStepSimulation(
    AutomatonEntity automatonEntity,
    String word,
  ) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA; // Converte para o modelo
      final simResult = algorithms.AutomatonSimulator.simulate(automaton, word);

      if (simResult.isFailure) {
        return Failure(simResult.error!);
      }

      return Success(simResult.data!.steps);
    } catch (e) {
      return Failure('Erro na simulação passo-a-passo: $e');
    }
  }

  // Helper methods for conversion between entities and core automaton objects
  model_automaton.Automaton _entityToAutomaton(AutomatonEntity entity) {
    final states = entity.states.map((s) => automaton_state.State(
      id: s.id,
      label: s.name,
      position: Vector2(s.x, s.y),
      isInitial: s.isInitial,
      isAccepting: s.isFinal,
    )).toSet();

    // Mapeia o estado inicial corretamente
    final initialState = entity.initialId != null 
      ? states.firstWhere((s) => s.id == entity.initialId) 
      : null;

    final transitions = <model_transition.Transition>{};

    final stateById = {for (final state in states) state.id: state};
    var transitionId = 1;

    entity.transitions.forEach((key, destinations) {
      final parts = key.split('|');
      if (parts.length != 2) {
        return;
      }

      final fromState = stateById[parts[0]];
      if (fromState == null) {
        return;
      }

      final symbol = parts[1];
      final isLambda = symbol == 'λ' || symbol == 'ε';

      for (final destinationId in destinations) {
        final toState = stateById[destinationId];
        if (toState == null) {
          continue;
        }

        transitions.add(FSATransition(
          id: 't${transitionId++}',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: isLambda ? const {} : {symbol},
          lambdaSymbol: isLambda ? symbol : null,
          type: isLambda
              ? model_transition.TransitionType.epsilon
              : model_transition.TransitionType.deterministic,
        ));
      }
    });

    return FSA(
      id: entity.id,
      name: entity.name,
      states: states,
      transitions: transitions,
      alphabet: entity.alphabet,
      initialState: initialState,
      acceptingStates: states.where((s) => s.isAccepting).toSet(),
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: const math.Rectangle(0, 0, 800, 600),
    );
  }

  AutomatonEntity _automatonToEntity(model_automaton.Automaton automaton, model_automaton.AutomatonType type) {
    final states = automaton.states.map((s) => StateEntity(
      id: s.id,
      name: s.label,
      x: s.position.x,
      y: s.position.y,
      isInitial: s.isInitial,
      isFinal: s.isAccepting,
    )).toList();

    final transitions = <String, List<String>>{};

    for (final transition in automaton.transitions) {
      if (transition is FSATransition) {
        final symbols = <String>{};
        if (transition.lambdaSymbol != null) {
          symbols.add(transition.lambdaSymbol!);
        } else {
          symbols.addAll(transition.inputSymbols);
        }

        for (final symbol in symbols) {
          final key = '${transition.fromState.id}|$symbol';
          transitions.putIfAbsent(key, () => <String>[]);
          transitions[key]!.add(transition.toState.id);
        }
      }
    }

    transitions.updateAll((key, value) {
      value.sort();
      return value;
    });

    return AutomatonEntity(
      id: automaton.id,
      name: automaton.name,
      type: AutomatonType.values.byName(type.name),
      states: states,
      transitions: transitions,
      alphabet: automaton.alphabet,
      initialId: automaton.initialState?.id,
      nextId: states.length, // Estimativa simples
    );
  }

  GrammarEntity _grammarToEntity(model_grammar.Grammar grammar) {
    final productions = grammar.productions.map((p) => ProductionEntity(
      id: p.id,
      leftSide: p.leftSide,
      rightSide: p.rightSide,
    )).toList();

    return GrammarEntity(
      id: grammar.id,
      name: grammar.name,
      terminals: grammar.terminals,
      nonTerminals: grammar.nonterminals,
      startSymbol: grammar.startSymbol,
      productions: productions,
    );
  }
}

