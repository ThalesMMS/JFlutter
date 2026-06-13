//
//  algorithm_repository_impl.dart
//  JFlutter
//
//  Expõe operações de algoritmos sobre autômatos e gramáticas, convertendo entidades para os modelos do núcleo antes de orquestrar transformações, análises e simulações complexas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../core/repositories/automaton_repository.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
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
import '../mappers/automaton_entity_mapper.dart';

/// Implementation of AlgorithmRepository
class AlgorithmRepositoryImpl implements AlgorithmRepository {
  @override
  Future<Result<AutomatonEntity>> nfaToDfa(AutomatonEntity nfaEntity) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity); // Converte para o modelo
      final result = algorithms.NFAToDFAConverter.convert(nfa);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!); // Converte de volta
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na conversão NFA → DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> removeLambdaTransitions(
    AutomatonEntity nfaEntity,
  ) async {
    try {
      final nfa = _entityToAutomaton(nfaEntity); // Converte para o modelo
      final result = algorithms.FSAOperations.removeLambdaTransitions(nfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na remoção de transições lambda: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> minimizeDfa(AutomatonEntity dfaEntity) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity); // Converte para o modelo
      final result = dfa_alg.DFAMinimizer.minimize(dfa);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!); // Converte de volta
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
      final dfa = _entityToAutomaton(dfaEntity); // Converte para o modelo
      final result = dfa_alg.DFACompleter.complete(dfa);
      final resultEntity = _automatonToEntity(result); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na completação do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> complementDfa(
    AutomatonEntity dfaEntity,
  ) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity); // Converte para o modelo
      final result = algorithms.DFAOperations.complement(dfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro no complemento do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> unionDfa(
    AutomatonEntity aEntity,
    AutomatonEntity bEntity,
  ) async {
    try {
      final a = _entityToAutomaton(aEntity); // Converte para o modelo
      final b = _entityToAutomaton(bEntity); // Converte para o modelo
      final result = algorithms.DFAOperations.union(a, b);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na união de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> intersectionDfa(
    AutomatonEntity aEntity,
    AutomatonEntity bEntity,
  ) async {
    try {
      final a = _entityToAutomaton(aEntity); // Converte para o modelo
      final b = _entityToAutomaton(bEntity); // Converte para o modelo
      final result = algorithms.DFAOperations.intersection(a, b);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na interseção de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> differenceDfa(
    AutomatonEntity aEntity,
    AutomatonEntity bEntity,
  ) async {
    try {
      final a = _entityToAutomaton(aEntity); // Converte para o modelo
      final b = _entityToAutomaton(bEntity); // Converte para o modelo
      final result = algorithms.DFAOperations.difference(a, b);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na diferença de DFAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> prefixClosureDfa(
    AutomatonEntity dfaEntity,
  ) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity); // Converte para o modelo
      final result = algorithms.DFAOperations.prefixClosure(dfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro no fecho por prefixos: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> suffixClosureDfa(
    AutomatonEntity dfaEntity,
  ) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity); // Converte para o modelo
      final result = algorithms.DFAOperations.suffixClosure(dfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro no fecho por sufixos: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> regexToNfa(String regex) async {
    try {
      final result = regex_alg.RegexToNFAConverter.convert(regex);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!); // Converte de volta
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na conversão ER → NFA: $e');
    }
  }

  @override
  Future<StringResult> dfaToRegex(
    AutomatonEntity dfaEntity, {
    bool allowLambda = false,
  }) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity);
      final result = regex_alg.FAToRegexConverter.convert(dfa);
      if (result.isSuccess) {
        return Success(result.data!);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na conversão DFA → ER: $e');
    }
  }

  @override
  Future<GrammarResult> fsaToGrammar(AutomatonEntity fsaEntity) async {
    try {
      final fsa = _entityToAutomaton(fsaEntity);
      final result = FSAToGrammarConverter.convert(fsa);
      final resultEntity = _grammarToEntity(result);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na conversão FSA → Gramática: $e');
    }
  }

  @override
  Future<BoolResult> areEquivalent(
    AutomatonEntity aEntity,
    AutomatonEntity bEntity,
  ) async {
    try {
      final a = _entityToAutomaton(aEntity);
      final b = _entityToAutomaton(bEntity);
      final result = EquivalenceChecker.areEquivalent(a, b);
      return Success(result);
    } catch (e) {
      return Failure('Erro na verificação de equivalência: $e');
    }
  }

  @override
  Future<Result<SimulationResult>> simulateWord(
    AutomatonEntity automatonEntity,
    String word,
  ) async {
    try {
      final automaton =
          _entityToAutomaton(automatonEntity); // Converte para o modelo
      final simResult = await algorithms.AutomatonSimulator.simulate(
        automaton,
        word,
        stepByStep: true,
      );

      if (simResult.isFailure) {
        return Failure(simResult.error!);
      }

      return Success(simResult.data!);
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
      final automaton =
          _entityToAutomaton(automatonEntity); // Converte para o modelo
      final simResult = await algorithms.AutomatonSimulator.simulate(
        automaton,
        word,
      );

      if (simResult.isFailure) {
        return Failure(simResult.error!);
      }

      return Success(simResult.data!.steps);
    } catch (e) {
      return Failure('Erro na simulação passo-a-passo: $e');
    }
  }

  // Helper methods for conversion between entities and FSA objects
  FSA _entityToAutomaton(AutomatonEntity entity) {
    return AutomatonEntityMapper.toFsa(entity);
  }

  AutomatonEntity _automatonToEntity(FSA automaton) {
    return AutomatonEntityMapper.fromFsa(
      automaton,
      deduplicateDestinations: true,
      sortDestinations: true,
    );
  }

  GrammarEntity _grammarToEntity(model_grammar.Grammar grammar) {
    final productions = grammar.productions
        .map(
          (p) => ProductionEntity(
            id: p.id,
            leftSide: p.leftSide,
            rightSide: p.rightSide,
          ),
        )
        .toList();

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
