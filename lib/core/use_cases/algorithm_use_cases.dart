import '../entities/automaton_entity.dart';
import '../result.dart';
import '../repositories/automaton_repository.dart';
import '../models/simulation_result.dart';
import '../models/simulation_step.dart';

/// Use case for NFA to DFA conversion
class NfaToDfaUseCase {
  final AlgorithmRepository _repository;

  NfaToDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity nfa) async {
    return await _repository.nfaToDfa(nfa);
  }
}

/// Use case for removing lambda transitions
class RemoveLambdaTransitionsUseCase {
  final AlgorithmRepository _repository;

  RemoveLambdaTransitionsUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity nfa) async {
    return await _repository.removeLambdaTransitions(nfa);
  }
}

/// Use case for DFA minimization
class MinimizeDfaUseCase {
  final AlgorithmRepository _repository;

  MinimizeDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity dfa) async {
    return await _repository.minimizeDfa(dfa);
  }
}

/// Use case for completing a DFA
class CompleteDfaUseCase {
  final AlgorithmRepository _repository;

  CompleteDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity dfa) async {
    return await _repository.completeDfa(dfa);
  }
}

/// Use case for creating DFA complement
class ComplementDfaUseCase {
  final AlgorithmRepository _repository;

  ComplementDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity dfa) async {
    return await _repository.complementDfa(dfa);
  }
}

/// Use case for DFA union
class UnionDfaUseCase {
  final AlgorithmRepository _repository;

  UnionDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity a, AutomatonEntity b) async {
    return await _repository.unionDfa(a, b);
  }
}

/// Use case for DFA intersection
class IntersectionDfaUseCase {
  final AlgorithmRepository _repository;

  IntersectionDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity a, AutomatonEntity b) async {
    return await _repository.intersectionDfa(a, b);
  }
}

/// Use case for DFA difference
class DifferenceDfaUseCase {
  final AlgorithmRepository _repository;

  DifferenceDfaUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity a, AutomatonEntity b) async {
    return await _repository.differenceDfa(a, b);
  }
}

/// Use case for prefix closure
class PrefixClosureUseCase {
  final AlgorithmRepository _repository;

  PrefixClosureUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity dfa) async {
    return await _repository.prefixClosureDfa(dfa);
  }
}

/// Use case for suffix closure
class SuffixClosureUseCase {
  final AlgorithmRepository _repository;

  SuffixClosureUseCase(this._repository);

  Future<AutomatonResult> execute(AutomatonEntity dfa) async {
    return await _repository.suffixClosureDfa(dfa);
  }
}

/// Use case for regex to NFA conversion
class RegexToNfaUseCase {
  final AlgorithmRepository _repository;

  RegexToNfaUseCase(this._repository);

  Future<AutomatonResult> execute(String regex) async {
    return await _repository.regexToNfa(regex);
  }
}

/// Use case for DFA to regex conversion
class DfaToRegexUseCase {
  final AlgorithmRepository _repository;

  DfaToRegexUseCase(this._repository);

  Future<StringResult> execute(AutomatonEntity dfa, {bool allowLambda = false}) async {
    return await _repository.dfaToRegex(dfa, allowLambda: allowLambda);
  }
}

/// Use case for FSA to grammar conversion
class FsaToGrammarUseCase {
  final AlgorithmRepository _repository;

  FsaToGrammarUseCase(this._repository);

  Future<GrammarResult> execute(AutomatonEntity fsa) async {
    return await _repository.fsaToGrammar(fsa);
  }
}

/// Use case for checking DFA equivalence
class CheckEquivalenceUseCase {
  final AlgorithmRepository _repository;

  CheckEquivalenceUseCase(this._repository);

  Future<BoolResult> execute(AutomatonEntity a, AutomatonEntity b) async {
    return await _repository.areEquivalent(a, b);
  }
}

/// Use case for word simulation
class SimulateWordUseCase {
  final AlgorithmRepository _repository;

  SimulateWordUseCase(this._repository);

  Future<Result<SimulationResult>> execute(AutomatonEntity automaton, String word) async {
    return await _repository.simulateWord(automaton, word);
  }
}

/// Use case for step-by-step simulation
class CreateStepByStepSimulationUseCase {
  final AlgorithmRepository _repository;

  CreateStepByStepSimulationUseCase(this._repository);

  Future<Result<List<SimulationStep>>> execute(AutomatonEntity automaton, String word) async {
    return await _repository.createStepByStepSimulation(automaton, word);
  }
}
