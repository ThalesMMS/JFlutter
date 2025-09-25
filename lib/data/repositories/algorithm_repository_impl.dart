import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../core/repositories/automaton_repository.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/result.dart';
import '../../core/models/automaton.dart' as model_automaton;
import '../../core/models/state.dart' as automaton_state;
import '../../core/models/transition.dart' as model_transition;
import '../../core/models/fsa_transition.dart' as fsa_transition;
import '../../core/models/fsa.dart';
import '../../core/algorithms.dart' as algorithms;
import '../../core/dfa_algorithms.dart' as dfa_alg;
import '../../core/regex.dart' as regex_alg;
import '../../core/grammar.dart' as grammar_core;
import '../../core/algorithms/fsa_language_operations.dart';
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
      final nfa =
          _entityToAutomaton(nfaEntity) as FSA; // Converte para o modelo
      final result = algorithms.NFAToDFAConverter.convert(nfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!,
            model_automaton.AutomatonType.fsa); // Converte de volta
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
      AutomatonEntity nfaEntity) async {
    try {
      final nfa =
          _entityToAutomaton(nfaEntity) as FSA; // Converte para o modelo
      final result = algorithms.FSAOperations.removeLambdaTransitions(nfa);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
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
      final dfa =
          _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = dfa_alg.DFAMinimizer.minimize(dfa);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!,
            model_automaton.AutomatonType.fsa); // Converte de volta
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
      final dfa =
          _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = dfa_alg.DFACompleter.complete(dfa);
      final resultEntity = _automatonToEntity(
          result, model_automaton.AutomatonType.fsa); // Converte de volta
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na completação do DFA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> complementDfa(
      AutomatonEntity dfaEntity) async {
    try {
      final dfa =
          _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = algorithms.DFAOperations.complement(dfa);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
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
      AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA; // Converte para o modelo
      final b = _entityToAutomaton(bEntity) as FSA; // Converte para o modelo
      final result = algorithms.DFAOperations.union(a, b);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
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
      AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA; // Converte para o modelo
      final b = _entityToAutomaton(bEntity) as FSA; // Converte para o modelo
      final result = algorithms.DFAOperations.intersection(a, b);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
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
      AutomatonEntity aEntity, AutomatonEntity bEntity) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA; // Converte para o modelo
      final b = _entityToAutomaton(bEntity) as FSA; // Converte para o modelo
      final result = algorithms.DFAOperations.difference(a, b);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
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
      AutomatonEntity dfaEntity) async {
    try {
      final dfa =
          _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = algorithms.DFAOperations.prefixClosure(dfa);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
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
      AutomatonEntity dfaEntity) async {
    try {
      final dfa =
          _entityToAutomaton(dfaEntity) as FSA; // Converte para o modelo
      final result = algorithms.DFAOperations.suffixClosure(dfa);
      if (result.isSuccess) {
        final resultEntity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro no fecho por sufixos: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> concatenateFsa(
    AutomatonEntity firstEntity,
    AutomatonEntity secondEntity,
  ) async {
    try {
      final first = _entityToAutomaton(firstEntity) as FSA;
      final second = _entityToAutomaton(secondEntity) as FSA;
      final result = FSALanguageOperations.concatenate(first, second);
      if (result.isSuccess) {
        final entity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
        return Success(entity);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro na concatenação de FSAs: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> kleeneStarFsa(
      AutomatonEntity automatonEntity) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA;
      final result = FSALanguageOperations.kleeneStar(automaton);
      if (result.isSuccess) {
        final entity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
        return Success(entity);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro na estrela de Kleene: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> reverseFsa(
      AutomatonEntity automatonEntity) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA;
      final result = FSALanguageOperations.reverse(automaton);
      if (result.isSuccess) {
        final entity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
        return Success(entity);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro na reversão do FSA: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> shuffleFsa(
    AutomatonEntity aEntity,
    AutomatonEntity bEntity,
  ) async {
    try {
      final a = _entityToAutomaton(aEntity) as FSA;
      final b = _entityToAutomaton(bEntity) as FSA;
      final result = FSALanguageOperations.shuffleProduct(a, b);
      if (result.isSuccess) {
        final entity =
            _automatonToEntity(result.data!, model_automaton.AutomatonType.fsa);
        return Success(entity);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro no shuffle de FSAs: $e');
    }
  }

  @override
  Future<BoolResult> isLanguageEmpty(AutomatonEntity automatonEntity) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA;
      final result = FSALanguageOperations.isLanguageEmpty(automaton);
      if (result.isSuccess) {
        return Success(result.data!);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro ao verificar linguagem vazia: $e');
    }
  }

  @override
  Future<BoolResult> isLanguageFinite(AutomatonEntity automatonEntity) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA;
      final result = FSALanguageOperations.isLanguageFinite(automaton);
      if (result.isSuccess) {
        return Success(result.data!);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro ao verificar finitude da linguagem: $e');
    }
  }

  @override
  Future<Result<Set<String>>> generateWords(
    AutomatonEntity automatonEntity, {
    int maxLength = 6,
    int maxWords = 32,
  }) async {
    try {
      final automaton = _entityToAutomaton(automatonEntity) as FSA;
      final result = FSALanguageOperations.generateWords(
        automaton,
        maxLength: maxLength,
        maxWords: maxWords,
      );
      if (result.isSuccess) {
        return Success(result.data!);
      }
      return Failure(result.error!);
    } catch (e) {
      return Failure('Erro ao gerar palavras: $e');
    }
  }

  @override
  Future<Result<AutomatonEntity>> regexToNfa(String regex) async {
    try {
      final result = regex_alg.RegexToNFAConverter.convert(regex);
      if (result.isSuccess) {
        final resultEntity = _automatonToEntity(result.data!,
            model_automaton.AutomatonType.fsa); // Converte de volta
        return Success(resultEntity);
      } else {
        return Failure(result.error!);
      }
    } catch (e) {
      return Failure('Erro na conversão ER → NFA: $e');
    }
  }

  @override
  Future<StringResult> dfaToRegex(AutomatonEntity dfaEntity,
      {bool allowLambda = false}) async {
    try {
      final dfa = _entityToAutomaton(dfaEntity) as FSA;
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
      final fsa = _entityToAutomaton(fsaEntity) as FSA;
      final result = FSAToGrammarConverter.convert(fsa);
      final resultEntity = _grammarToEntity(result);
      return Success(resultEntity);
    } catch (e) {
      return Failure('Erro na conversão FSA → Gramática: $e');
    }
  }

  @override
  Future<BoolResult> areEquivalent(
      AutomatonEntity aEntity, AutomatonEntity bEntity) async {
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
  Future<Result<SimulationResult>> simulateWord(
      AutomatonEntity automatonEntity, String word) async {
    try {
      final automaton =
          _entityToAutomaton(automatonEntity) as FSA; // Converte para o modelo
      final simResult = algorithms.AutomatonSimulator.simulate(
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
          _entityToAutomaton(automatonEntity) as FSA; // Converte para o modelo
      final simResult = algorithms.AutomatonSimulator.simulate(automaton, word);

      if (simResult.isFailure) {
        return Failure(simResult.error!);
      }

      return Success(simResult.data!.steps);
    } catch (e) {
      return Failure('Erro na simulação passo-a-passo: $e');
    }
  }

  @override
  Future<Result<regex_alg.RegexAst>> parseRegex(String pattern) async {
    return regex_alg.RegexExpressionParser.parse(pattern);
  }

  @override
  Future<Result<grammar_core.GrammarDefinitionAnalysis>> parseGrammarDefinition(
    String source,
  ) async {
    return grammar_core.GrammarDefinitionParser.parse(source);
  }

  // Helper methods for conversion between entities and core automaton objects
  model_automaton.Automaton _entityToAutomaton(AutomatonEntity entity) {
    final states = entity.states
        .map((s) => automaton_state.State(
              id: s.id,
              label: s.name,
              position: Vector2(s.x, s.y),
              isInitial: s.isInitial,
              isAccepting: s.isFinal,
            ))
        .toSet();

    final stateMap = {for (final state in states) state.id: state};

    final initialState = entity.initialId != null
        ? stateMap[entity.initialId]
        : states.firstWhereOrNull((s) => s.isInitial);

    final transitions = <model_transition.Transition>{};
    var transitionId = 1;

    entity.transitions.forEach((key, destinations) {
      final parts = key.split('|');
      if (parts.length != 2) {
        return;
      }

      final fromState = stateMap[parts[0]];
      if (fromState == null) {
        return;
      }

      final symbol = parts[1];
      final isLambda = _isLambdaSymbol(symbol);
      final transitionType = destinations.length > 1 || isLambda
          ? model_transition.TransitionType.nondeterministic
          : model_transition.TransitionType.deterministic;

      for (final destinationId in destinations) {
        final toState = stateMap[destinationId];
        if (toState == null) {
          continue;
        }

        transitions.add(fsa_transition.FSATransition(
          id: 't${transitionId++}',
          fromState: fromState,
          toState: toState,
          label: symbol,
          inputSymbols: isLambda ? const <String>{} : {symbol},
          lambdaSymbol: isLambda ? symbol : null,
          type: transitionType,
        ));
      }
    });

    final acceptingStates = states.where((state) => state.isAccepting).toSet();

    return FSA(
      id: entity.id,
      name: entity.name,
      states: states,
      transitions: transitions,
      alphabet: entity.alphabet,
      initialState: initialState,
      acceptingStates: acceptingStates,
      created: DateTime.now(),
      modified: DateTime.now(),
      bounds: const math.Rectangle(0, 0, 800, 600),
    );
  }

  AutomatonEntity _automatonToEntity(
      model_automaton.Automaton automaton, model_automaton.AutomatonType type) {
    final states = automaton.states.map((s) {
      final isInitial = automaton.initialState?.id == s.id;
      final isFinal = automaton.acceptingStates.any((acc) => acc.id == s.id);
      return StateEntity(
        id: s.id,
        name: s.label,
        x: s.position.x,
        y: s.position.y,
        isInitial: isInitial,
        isFinal: isFinal,
      );
    }).toList();

    final transitions = <String, Set<String>>{};
    for (final transition
        in automaton.transitions.whereType<fsa_transition.FSATransition>()) {
      final symbols = transition.isEpsilonTransition
          ? {transition.lambdaSymbol ?? 'ε'}
          : transition.inputSymbols;

      for (final symbol in symbols) {
        final key = '${transition.fromState.id}|$symbol';
        transitions.putIfAbsent(key, () => <String>{});
        transitions[key]!.add(transition.toState.id);
      }
    }

    final orderedTransitions = transitions.map(
      (key, value) {
        final destinations = value.toList()..sort();
        return MapEntry(key, destinations);
      },
    );

    return AutomatonEntity(
      id: automaton.id,
      name: automaton.name,
      type: AutomatonType.values.byName(type.name),
      states: states,
      transitions: orderedTransitions,
      alphabet: automaton.alphabet,
      initialId: automaton.initialState?.id,
      nextId: states.length,
    );
  }

  bool _isLambdaSymbol(String symbol) {
    final normalized = symbol.trim().toLowerCase();
    return normalized == 'ε' ||
        normalized == 'lambda' ||
        normalized == 'λ' ||
        normalized == '£' ||
        normalized == '€';
  }

  GrammarEntity _grammarToEntity(model_grammar.Grammar grammar) {
    final productions = grammar.productions
        .map((p) => ProductionEntity(
              id: p.id,
              leftSide: p.leftSide,
              rightSide: p.rightSide,
            ))
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
