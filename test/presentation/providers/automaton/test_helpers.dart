import 'dart:convert';
import 'dart:math' as math;

import 'package:jflutter/core/entities/automaton_entity.dart';
import 'package:jflutter/core/entities/grammar_entity.dart';
import 'package:jflutter/core/models/simulation_result.dart';
import 'package:jflutter/core/models/simulation_step.dart';
import 'package:jflutter/core/repositories/automaton_repository.dart';
import 'package:jflutter/core/result.dart';

class FakeAutomatonRepository implements AutomatonRepository {
  FakeAutomatonRepository({
    Map<String, AutomatonEntity>? initialAutomatons,
    this.failureMessage = 'Automaton repository failure',
  }) : _storage = Map<String, AutomatonEntity>.fromEntries(
          (initialAutomatons ?? {}).entries.map(
            (entry) => MapEntry(entry.key, _cloneAutomaton(entry.value)),
          ),
        );

  final Map<String, AutomatonEntity> _storage;
  final String failureMessage;

  AutomatonResult Function(AutomatonEntity automaton)? saveAutomatonHandler;
  AutomatonResult Function(String id)? loadAutomatonHandler;
  ListResult<AutomatonEntity> Function()? loadAllAutomatonsHandler;
  BoolResult Function(String id)? deleteAutomatonHandler;
  StringResult Function(AutomatonEntity automaton)? exportAutomatonHandler;
  AutomatonResult Function(String jsonString)? importAutomatonHandler;
  BoolResult Function(AutomatonEntity automaton)? validateAutomatonHandler;

  Map<String, AutomatonEntity> get storedAutomatons =>
      _storage.map((key, value) => MapEntry(key, _cloneAutomaton(value)));

  void clear() => _storage.clear();

  @override
  Future<AutomatonResult> saveAutomaton(AutomatonEntity automaton) async {
    if (saveAutomatonHandler != null) {
      return saveAutomatonHandler!(automaton);
    }
    final clone = _cloneAutomaton(automaton);
    _storage[clone.id] = clone;
    return Success(_cloneAutomaton(clone));
  }

  @override
  Future<AutomatonResult> loadAutomaton(String id) async {
    if (loadAutomatonHandler != null) {
      return loadAutomatonHandler!(id);
    }
    final stored = _storage[id];
    if (stored == null) {
      return Failure('$failureMessage: automaton $id not found');
    }
    return Success(_cloneAutomaton(stored));
  }

  @override
  Future<ListResult<AutomatonEntity>> loadAllAutomatons() async {
    if (loadAllAutomatonsHandler != null) {
      return loadAllAutomatonsHandler!();
    }
    final automatons = _storage.values.map(_cloneAutomaton).toList();
    return Success(automatons);
  }

  @override
  Future<BoolResult> deleteAutomaton(String id) async {
    if (deleteAutomatonHandler != null) {
      return deleteAutomatonHandler!(id);
    }
    final removed = _storage.remove(id);
    if (removed == null) {
      return Failure('$failureMessage: automaton $id not found');
    }
    return const Success(true);
  }

  @override
  Future<StringResult> exportAutomaton(AutomatonEntity automaton) async {
    if (exportAutomatonHandler != null) {
      return exportAutomatonHandler!(automaton);
    }
    final stored = _storage[automaton.id] ?? automaton;
    try {
      final serialized = jsonEncode(_automatonToJson(stored));
      return Success(serialized);
    } catch (_) {
      return Failure('$failureMessage: unable to export automaton ${automaton.id}');
    }
  }

  @override
  Future<AutomatonResult> importAutomaton(String jsonString) async {
    if (importAutomatonHandler != null) {
      return importAutomatonHandler!(jsonString);
    }
    try {
      final data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) {
        return Failure('$failureMessage: invalid automaton payload');
      }
      final automaton = _automatonFromJson(data);
      _storage[automaton.id] = automaton;
      return Success(_cloneAutomaton(automaton));
    } catch (error) {
      return Failure('$failureMessage: unable to import automaton (${error.toString()})');
    }
  }

  @override
  Future<BoolResult> validateAutomaton(AutomatonEntity automaton) async {
    if (validateAutomatonHandler != null) {
      return validateAutomatonHandler!(automaton);
    }
    final states = automaton.states;
    if (states.isEmpty) {
      return Failure('$failureMessage: automaton must contain at least one state');
    }
    final initialId = automaton.initialId;
    if (initialId == null || states.every((state) => state.id != initialId)) {
      return Failure('$failureMessage: invalid initial state');
    }
    final stateIds = states.map((state) => state.id).toSet();
    final missing = automaton.transitions.values
        .expand((targets) => targets)
        .where((target) => !stateIds.contains(target))
        .toSet();
    if (missing.isNotEmpty) {
      return Failure(
          '$failureMessage: transition targets missing: ${missing.join(', ')}');
    }
    return const Success(true);
  }
}

class FakeAlgorithmRepository implements AlgorithmRepository {
  FakeAlgorithmRepository({this.failureMessage = 'Algorithm repository failure'});

  final String failureMessage;
  final Map<String, String> _operationFailures = {};

  final Map<String, AutomatonEntity> lastUnaryAutomatonInput = {};
  final Map<String, List<AutomatonEntity>> lastBinaryAutomatonInput = {};
  String? lastRegexInput;
  String? lastSimulatedWord;

  AutomatonResult Function(String operation, AutomatonEntity automaton)?
      unaryOperationHandler;
  AutomatonResult Function(
    String operation,
    AutomatonEntity first,
    AutomatonEntity second,
  )?
      binaryOperationHandler;
  AutomatonResult Function(String regex)? regexToNfaHandler;
  StringResult Function(AutomatonEntity dfa, bool allowLambda)? dfaToRegexHandler;
  GrammarResult Function(AutomatonEntity fsa)? fsaToGrammarHandler;
  BoolResult Function(AutomatonEntity a, AutomatonEntity b)? equivalenceHandler;
  Result<SimulationResult> Function(AutomatonEntity automaton, String word)?
      simulateWordHandler;
  Result<List<SimulationStep>> Function(
    AutomatonEntity automaton,
    String word,
  )?
      stepSimulationHandler;

  void failOperation(String operation, [String? message]) {
    _operationFailures[operation] = message ?? failureMessage;
  }

  @override
  Future<AutomatonResult> nfaToDfa(AutomatonEntity nfa) async {
    lastUnaryAutomatonInput['nfaToDfa'] = _cloneAutomaton(nfa);
    final failure = _maybeFailure<AutomatonEntity>('nfaToDfa');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!('nfaToDfa', _cloneAutomaton(nfa));
    }
    final clone = _cloneAutomaton(nfa).copyWith(
      type: AutomatonType.dfa,
      name: '${nfa.name} (DFA)',
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> removeLambdaTransitions(AutomatonEntity nfa) async {
    lastUnaryAutomatonInput['removeLambdaTransitions'] = _cloneAutomaton(nfa);
    final failure = _maybeFailure<AutomatonEntity>('removeLambdaTransitions');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!(
        'removeLambdaTransitions',
        _cloneAutomaton(nfa),
      );
    }
    final clone = _cloneAutomaton(nfa).copyWith(
      alphabet: {...nfa.alphabet}..remove('λ'),
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> minimizeDfa(AutomatonEntity dfa) async {
    lastUnaryAutomatonInput['minimizeDfa'] = _cloneAutomaton(dfa);
    final failure = _maybeFailure<AutomatonEntity>('minimizeDfa');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!('minimizeDfa', _cloneAutomaton(dfa));
    }
    final clone = _cloneAutomaton(dfa).copyWith(
      name: '${dfa.name} (minimized)',
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> completeDfa(AutomatonEntity dfa) async {
    lastUnaryAutomatonInput['completeDfa'] = _cloneAutomaton(dfa);
    final failure = _maybeFailure<AutomatonEntity>('completeDfa');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!('completeDfa', _cloneAutomaton(dfa));
    }
    final clone = _cloneAutomaton(dfa).copyWith(
      name: '${dfa.name} (complete)',
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> complementDfa(AutomatonEntity dfa) async {
    lastUnaryAutomatonInput['complementDfa'] = _cloneAutomaton(dfa);
    final failure = _maybeFailure<AutomatonEntity>('complementDfa');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!('complementDfa', _cloneAutomaton(dfa));
    }
    final clone = _cloneAutomaton(dfa).copyWith(
      name: '${dfa.name} (complement)',
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> unionDfa(AutomatonEntity a, AutomatonEntity b) async {
    lastBinaryAutomatonInput['unionDfa'] = [_cloneAutomaton(a), _cloneAutomaton(b)];
    final failure = _maybeFailure<AutomatonEntity>('unionDfa');
    if (failure != null) return failure;
    if (binaryOperationHandler != null) {
      return binaryOperationHandler!(
        'unionDfa',
        _cloneAutomaton(a),
        _cloneAutomaton(b),
      );
    }
    return Success(_combineAutomata(a, b, 'union'));
  }

  @override
  Future<AutomatonResult> intersectionDfa(AutomatonEntity a, AutomatonEntity b) async {
    lastBinaryAutomatonInput['intersectionDfa'] =
        [_cloneAutomaton(a), _cloneAutomaton(b)];
    final failure = _maybeFailure<AutomatonEntity>('intersectionDfa');
    if (failure != null) return failure;
    if (binaryOperationHandler != null) {
      return binaryOperationHandler!(
        'intersectionDfa',
        _cloneAutomaton(a),
        _cloneAutomaton(b),
      );
    }
    return Success(_combineAutomata(a, b, 'intersection'));
  }

  @override
  Future<AutomatonResult> differenceDfa(AutomatonEntity a, AutomatonEntity b) async {
    lastBinaryAutomatonInput['differenceDfa'] =
        [_cloneAutomaton(a), _cloneAutomaton(b)];
    final failure = _maybeFailure<AutomatonEntity>('differenceDfa');
    if (failure != null) return failure;
    if (binaryOperationHandler != null) {
      return binaryOperationHandler!(
        'differenceDfa',
        _cloneAutomaton(a),
        _cloneAutomaton(b),
      );
    }
    return Success(_combineAutomata(a, b, 'difference'));
  }

  @override
  Future<AutomatonResult> prefixClosureDfa(AutomatonEntity dfa) async {
    lastUnaryAutomatonInput['prefixClosureDfa'] = _cloneAutomaton(dfa);
    final failure = _maybeFailure<AutomatonEntity>('prefixClosureDfa');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!('prefixClosureDfa', _cloneAutomaton(dfa));
    }
    final clone = _cloneAutomaton(dfa).copyWith(
      name: '${dfa.name} (prefix closure)',
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> suffixClosureDfa(AutomatonEntity dfa) async {
    lastUnaryAutomatonInput['suffixClosureDfa'] = _cloneAutomaton(dfa);
    final failure = _maybeFailure<AutomatonEntity>('suffixClosureDfa');
    if (failure != null) return failure;
    if (unaryOperationHandler != null) {
      return unaryOperationHandler!('suffixClosureDfa', _cloneAutomaton(dfa));
    }
    final clone = _cloneAutomaton(dfa).copyWith(
      name: '${dfa.name} (suffix closure)',
    );
    return Success(clone);
  }

  @override
  Future<AutomatonResult> regexToNfa(String regex) async {
    lastRegexInput = regex;
    final failure = _maybeFailure<AutomatonEntity>('regexToNfa');
    if (failure != null) return failure;
    if (regexToNfaHandler != null) {
      return regexToNfaHandler!(regex);
    }
    final automaton = _automatonFromRegex(regex);
    return Success(automaton);
  }

  @override
  Future<StringResult> dfaToRegex(AutomatonEntity dfa, {bool allowLambda = false}) async {
    lastUnaryAutomatonInput['dfaToRegex'] = _cloneAutomaton(dfa);
    final failure = _maybeFailure<String>('dfaToRegex');
    if (failure != null) return failure;
    if (dfaToRegexHandler != null) {
      return dfaToRegexHandler!(_cloneAutomaton(dfa), allowLambda);
    }
    final suffix = allowLambda ? '_lambda' : '';
    return Success('regex_of_${dfa.id}$suffix');
  }

  @override
  Future<GrammarResult> fsaToGrammar(AutomatonEntity fsa) async {
    lastUnaryAutomatonInput['fsaToGrammar'] = _cloneAutomaton(fsa);
    final failure = _maybeFailure<GrammarEntity>('fsaToGrammar');
    if (failure != null) return failure;
    if (fsaToGrammarHandler != null) {
      return fsaToGrammarHandler!(_cloneAutomaton(fsa));
    }
    final productions = <ProductionEntity>[];
    for (final state in fsa.states) {
      final keyPrefix = '${state.id}|';
      final transitions = fsa.transitions.entries
          .where((entry) => entry.key.startsWith(keyPrefix));
      for (final entry in transitions) {
        final symbol = entry.key.split('|').last;
        for (final target in entry.value) {
          productions.add(
            ProductionEntity(
              id: '${state.id}_$symbol_$target',
              leftSide: [state.name],
              rightSide: [symbol, target],
            ),
          );
        }
      }
    }
    final grammar = GrammarEntity(
      id: 'grammar_${fsa.id}',
      name: 'Grammar of ${fsa.name}',
      terminals: Set<String>.from(fsa.alphabet),
      nonTerminals: fsa.states.map((state) => state.name).toSet(),
      startSymbol: fsa.initialId ?? (fsa.states.isEmpty ? 'S' : fsa.states.first.name),
      productions: productions,
    );
    return Success(grammar);
  }

  @override
  Future<BoolResult> areEquivalent(AutomatonEntity a, AutomatonEntity b) async {
    lastBinaryAutomatonInput['areEquivalent'] =
        [_cloneAutomaton(a), _cloneAutomaton(b)];
    final failure = _maybeFailure<bool>('areEquivalent');
    if (failure != null) return failure;
    if (equivalenceHandler != null) {
      return equivalenceHandler!(_cloneAutomaton(a), _cloneAutomaton(b));
    }
    final sameAlphabet = a.alphabet.length == b.alphabet.length &&
        a.alphabet.containsAll(b.alphabet);
    final sameStateCount = a.states.length == b.states.length;
    return Success(sameAlphabet && sameStateCount);
  }

  @override
  Future<Result<SimulationResult>> simulateWord(
    AutomatonEntity automaton,
    String word,
  ) async {
    lastUnaryAutomatonInput['simulateWord'] = _cloneAutomaton(automaton);
    lastSimulatedWord = word;
    final failure = _maybeFailure<SimulationResult>('simulateWord');
    if (failure != null) return failure;
    if (simulateWordHandler != null) {
      return simulateWordHandler!(_cloneAutomaton(automaton), word);
    }
    final steps = <SimulationStep>[
      SimulationStep(
        currentState: automaton.initialId ??
            (automaton.states.isEmpty ? '∅' : automaton.states.first.id),
        remainingInput: word,
        stepNumber: 0,
        description: 'Start simulation',
      ),
      SimulationStep(
        currentState:
            automaton.states.isEmpty ? '∅' : automaton.states.last.id,
        remainingInput: '',
        stepNumber: 1,
        description: 'Finish simulation',
        isAccepted: true,
      ),
    ];
    final result = SimulationResult.success(
      inputString: word,
      steps: steps,
      executionTime: const Duration(milliseconds: 1),
    );
    return Success(result);
  }

  @override
  Future<Result<List<SimulationStep>>> createStepByStepSimulation(
    AutomatonEntity automaton,
    String word,
  ) async {
    lastUnaryAutomatonInput['createStepByStepSimulation'] =
        _cloneAutomaton(automaton);
    lastSimulatedWord = word;
    final failure =
        _maybeFailure<List<SimulationStep>>('createStepByStepSimulation');
    if (failure != null) return failure;
    if (stepSimulationHandler != null) {
      return stepSimulationHandler!(_cloneAutomaton(automaton), word);
    }
    final steps = <SimulationStep>[
      SimulationStep(
        currentState: automaton.initialId ??
            (automaton.states.isEmpty ? '∅' : automaton.states.first.id),
        remainingInput: word,
        stepNumber: 0,
        description: 'Initialization',
      ),
    ];
    return Success(steps);
  }

  Result<T>? _maybeFailure<T>(String operation) {
    final message = _operationFailures[operation];
    if (message != null) {
      return Failure<T>(message);
    }
    return null;
  }
}

class FakeLayoutRepository implements LayoutRepository {
  FakeLayoutRepository({this.failureMessage = 'Layout repository failure'});

  final String failureMessage;
  final Map<String, String> _operationFailures = {};

  final Map<String, AutomatonEntity> lastAppliedLayouts = {};

  AutomatonEntity Function(String operation, AutomatonEntity automaton)?
      layoutTransformer;
  AutomatonEntity Function(AutomatonEntity automaton)? compactLayoutTransformer;
  AutomatonEntity Function(AutomatonEntity automaton)? balancedLayoutTransformer;
  AutomatonEntity Function(AutomatonEntity automaton)? spreadLayoutTransformer;
  AutomatonEntity Function(AutomatonEntity automaton)? hierarchicalLayoutTransformer;
  AutomatonEntity Function(AutomatonEntity automaton)? autoLayoutTransformer;
  AutomatonEntity Function(AutomatonEntity automaton)? centerLayoutTransformer;

  void failOperation(String operation, [String? message]) {
    _operationFailures[operation] = message ?? failureMessage;
  }

  @override
  Future<AutomatonResult> applyCompactLayout(AutomatonEntity automaton) async {
    return _performLayout(
      operation: 'applyCompactLayout',
      automaton: automaton,
      defaultTransformer: (clone) => _linearLayout(clone, spacingX: 60, spacingY: 0),
    );
  }

  @override
  Future<AutomatonResult> applyBalancedLayout(AutomatonEntity automaton) async {
    return _performLayout(
      operation: 'applyBalancedLayout',
      automaton: automaton,
      defaultTransformer: (clone) => _circularLayout(clone, radius: 120),
    );
  }

  @override
  Future<AutomatonResult> applySpreadLayout(AutomatonEntity automaton) async {
    return _performLayout(
      operation: 'applySpreadLayout',
      automaton: automaton,
      defaultTransformer: (clone) => _linearLayout(
        clone,
        spacingX: 140,
        spacingY: 80,
        alternate: true,
      ),
    );
  }

  @override
  Future<AutomatonResult> applyHierarchicalLayout(AutomatonEntity automaton) async {
    return _performLayout(
      operation: 'applyHierarchicalLayout',
      automaton: automaton,
      defaultTransformer: _hierarchicalLayout,
    );
  }

  @override
  Future<AutomatonResult> applyAutoLayout(AutomatonEntity automaton) async {
    return _performLayout(
      operation: 'applyAutoLayout',
      automaton: automaton,
      defaultTransformer: (clone) => _circularLayout(clone, radius: 150),
    );
  }

  @override
  Future<AutomatonResult> centerAutomaton(AutomatonEntity automaton) async {
    return _performLayout(
      operation: 'centerAutomaton',
      automaton: automaton,
      defaultTransformer: _centerLayout,
    );
  }

  Future<AutomatonResult> _performLayout({
    required String operation,
    required AutomatonEntity automaton,
    required AutomatonEntity Function(AutomatonEntity automaton) defaultTransformer,
  }) async {
    final failure = _maybeFailure<AutomatonEntity>(operation);
    if (failure != null) {
      return failure;
    }
    final AutomatonEntity clone = _cloneAutomaton(automaton);
    AutomatonEntity? result;
    final customTransformer = _operationTransformer(operation);
    if (customTransformer != null) {
      result = customTransformer(_cloneAutomaton(clone));
    } else if (layoutTransformer != null) {
      result = layoutTransformer!(operation, _cloneAutomaton(clone));
    } else {
      result = defaultTransformer(clone);
    }
    lastAppliedLayouts[operation] = _cloneAutomaton(result);
    return Success(_cloneAutomaton(result));
  }

  AutomatonEntity Function(AutomatonEntity automaton)? _operationTransformer(
    String operation,
  ) {
    switch (operation) {
      case 'applyCompactLayout':
        return compactLayoutTransformer;
      case 'applyBalancedLayout':
        return balancedLayoutTransformer;
      case 'applySpreadLayout':
        return spreadLayoutTransformer;
      case 'applyHierarchicalLayout':
        return hierarchicalLayoutTransformer;
      case 'applyAutoLayout':
        return autoLayoutTransformer;
      case 'centerAutomaton':
        return centerLayoutTransformer;
    }
    return null;
  }

  Result<T>? _maybeFailure<T>(String operation) {
    final message = _operationFailures[operation];
    if (message != null) {
      return Failure<T>(message);
    }
    return null;
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
    terminals: const {'a'},
    nonTerminals: const {'S'},
    productions: const [
      ProductionEntity(
        id: 'p1',
        leftSide: ['S'],
        rightSide: ['a'],
      ),
    ],
    startSymbol: 'S',
  );
}

AutomatonEntity _cloneAutomaton(AutomatonEntity automaton) {
  return automaton.copyWith(
    alphabet: Set<String>.from(automaton.alphabet),
    states: automaton.states.map((state) => state.copyWith()).toList(),
    transitions: automaton.transitions.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    ),
  );
}

Map<String, dynamic> _automatonToJson(AutomatonEntity automaton) {
  return {
    'id': automaton.id,
    'name': automaton.name,
    'alphabet': automaton.alphabet.toList(),
    'states': automaton.states
        .map(
          (state) => {
            'id': state.id,
            'name': state.name,
            'x': state.x,
            'y': state.y,
            'isInitial': state.isInitial,
            'isFinal': state.isFinal,
          },
        )
        .toList(),
    'transitions': automaton.transitions.map(
      (key, value) => MapEntry(key, List<String>.from(value)),
    ),
    'initialId': automaton.initialId,
    'nextId': automaton.nextId,
    'type': automaton.type.name,
  };
}

AutomatonEntity _automatonFromJson(Map<String, dynamic> json) {
  final rawStates = json['states'] as List<dynamic>? ?? const [];
  final states = rawStates
      .map((raw) => raw as Map<String, dynamic>)
      .map(
        (state) => StateEntity(
          id: state['id'] as String,
          name: state['name'] as String,
          x: (state['x'] as num?)?.toDouble() ?? 0,
          y: (state['y'] as num?)?.toDouble() ?? 0,
          isInitial: state['isInitial'] as bool? ?? false,
          isFinal: state['isFinal'] as bool? ?? false,
        ),
      )
      .toList();
  final transitions = <String, List<String>>{};
  final rawTransitions = json['transitions'] as Map<String, dynamic>? ?? {};
  for (final entry in rawTransitions.entries) {
    final values = entry.value as List<dynamic>? ?? const [];
    transitions[entry.key] = values.map((value) => value as String).toList();
  }
  final rawAlphabet = json['alphabet'] as List<dynamic>? ?? const [];
  final alphabet = rawAlphabet.map((symbol) => symbol as String).toSet();
  return AutomatonEntity(
    id: json['id'] as String,
    name: json['name'] as String,
    alphabet: alphabet,
    states: states,
    transitions: transitions,
    initialId: json['initialId'] as String?,
    nextId: (json['nextId'] as num?)?.toInt() ?? states.length,
    type: _parseAutomatonType(json['type'] as String?),
  );
}

AutomatonType _parseAutomatonType(String? rawType) {
  if (rawType == null) return AutomatonType.dfa;
  return AutomatonType.values.firstWhere(
    (type) => type.name == rawType || type.displayName == rawType,
    orElse: () => AutomatonType.dfa,
  );
}

AutomatonEntity _combineAutomata(
  AutomatonEntity a,
  AutomatonEntity b,
  String operation,
) {
  final clone = _cloneAutomaton(a);
  final combinedAlphabet = {...a.alphabet, ...b.alphabet};
  return clone.copyWith(
    id: '${a.id}_$operation_${b.id}',
    name: '${a.name} $operation ${b.name}',
    alphabet: combinedAlphabet,
  );
}

AutomatonEntity _automatonFromRegex(String regex) {
  final start = StateEntity(
    id: 'start',
    name: 'start',
    x: 0,
    y: 0,
    isInitial: true,
    isFinal: false,
  );
  final accept = StateEntity(
    id: 'accept',
    name: 'accept',
    x: 80,
    y: 0,
    isInitial: false,
    isFinal: true,
  );
  return AutomatonEntity(
    id: 'regex_${regex.hashCode}',
    name: 'NFA for $regex',
    alphabet: regex.split('').where((char) => char.trim().isNotEmpty).toSet(),
    states: [start, accept],
    transitions: {
      'start|${regex.isEmpty ? 'λ' : regex[0]}': [accept.id],
    },
    initialId: start.id,
    nextId: 2,
    type: AutomatonType.nfa,
  );
}

AutomatonEntity _linearLayout(
  AutomatonEntity automaton, {
  double spacingX = 80,
  double spacingY = 0,
  bool alternate = false,
}) {
  final states = <StateEntity>[];
  for (var i = 0; i < automaton.states.length; i++) {
    final state = automaton.states[i];
    final yPosition = alternate ? (i % 2) * spacingY : spacingY * i;
    states.add(
      state.copyWith(
        x: spacingX * i,
        y: yPosition,
      ),
    );
  }
  return automaton.copyWith(states: states);
}

AutomatonEntity _circularLayout(AutomatonEntity automaton, {double radius = 100}) {
  if (automaton.states.isEmpty) return automaton;
  final states = <StateEntity>[];
  for (var i = 0; i < automaton.states.length; i++) {
    final angle = (2 * math.pi * i) / automaton.states.length;
    final state = automaton.states[i];
    states.add(
      state.copyWith(
        x: radius * math.cos(angle),
        y: radius * math.sin(angle),
      ),
    );
  }
  return automaton.copyWith(states: states);
}

AutomatonEntity _hierarchicalLayout(AutomatonEntity automaton) {
  if (automaton.states.isEmpty) return automaton;
  final levels = <String, int>{};
  final queue = <String>[];
  final visited = <String>{};
  final initial = automaton.initialId ?? automaton.states.first.id;
  queue.add(initial);
  levels[initial] = 0;
  visited.add(initial);

  while (queue.isNotEmpty) {
    final current = queue.removeAt(0);
    final level = levels[current] ?? 0;
    final outgoing = automaton.transitions.entries
        .where((entry) => entry.key.startsWith('$current|'))
        .expand((entry) => entry.value);
    for (final target in outgoing) {
      if (visited.add(target)) {
        levels[target] = level + 1;
        queue.add(target);
      }
    }
  }

  for (final state in automaton.states) {
    levels.putIfAbsent(state.id, () => 0);
  }

  final grouped = <int, List<StateEntity>>{};
  for (final state in automaton.states) {
    final level = levels[state.id] ?? 0;
    grouped.putIfAbsent(level, () => []).add(state);
  }

  final states = <StateEntity>[];
  for (final state in automaton.states) {
    final level = levels[state.id] ?? 0;
    final siblings = grouped[level]!;
    final index = siblings.indexWhere((element) => element.id == state.id);
    states.add(
      state.copyWith(
        x: level * 140,
        y: index * 100,
      ),
    );
  }

  return automaton.copyWith(states: states);
}

AutomatonEntity _centerLayout(AutomatonEntity automaton) {
  if (automaton.states.isEmpty) return automaton;
  final xs = automaton.states.map((state) => state.x).toList();
  final ys = automaton.states.map((state) => state.y).toList();
  final minX = xs.reduce(math.min);
  final maxX = xs.reduce(math.max);
  final minY = ys.reduce(math.min);
  final maxY = ys.reduce(math.max);
  final offsetX = (minX + maxX) / 2;
  final offsetY = (minY + maxY) / 2;
  final states = automaton.states
      .map((state) =>
          state.copyWith(x: state.x - offsetX, y: state.y - offsetY))
      .toList();
  return automaton.copyWith(states: states);
}
