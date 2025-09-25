import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'state_model.dart';
import 'dfa.dart';

/// کلاس پایه برای انواع اتوماتا
abstract class Automaton {}

/// Result class for NFA operations
class NFAOperationResult {
  final bool success;
  final String message;
  final NFA? result;
  final Map<String, dynamic>? metadata;

  const NFAOperationResult({
    required this.success,
    required this.message,
    this.result,
    this.metadata,
  });

  factory NFAOperationResult.success(NFA result, {String? message, Map<String, dynamic>? metadata}) {
    return NFAOperationResult(
      success: true,
      message: message ?? 'Operation completed successfully',
      result: result,
      metadata: metadata,
    );
  }

  factory NFAOperationResult.failure(String message) {
    return NFAOperationResult(
      success: false,
      message: message,
    );
  }
}

/// Advanced trace information for string processing
class NFATraceStep {
  final Set<String> currentStates;
  final String consumedInput;
  final String remainingInput;
  final String? lastSymbol;
  final Set<String> epsilonClosure;
  final Map<String, Set<String>> transitions;

  const NFATraceStep({
    required this.currentStates,
    required this.consumedInput,
    required this.remainingInput,
    this.lastSymbol,
    required this.epsilonClosure,
    required this.transitions,
  });

  @override
  String toString() {
    return 'States: ${currentStates.join(',')} | '
        'Consumed: "$consumedInput" | '
        'Remaining: "$remainingInput" | '
        'Symbol: ${lastSymbol ?? 'ε'} | '
        'ε-closure: ${epsilonClosure.join(',')}';
  }
}

/// Comprehensive trace result
class NFATrace {
  final String input;
  final bool accepted;
  final List<NFATraceStep> steps;
  final Duration executionTime;
  final Map<String, dynamic> statistics;

  const NFATrace({
    required this.input,
    required this.accepted,
    required this.steps,
    required this.executionTime,
    required this.statistics,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('=== NFA Execution Trace ===');
    buffer.writeln('Input: "$input"');
    buffer.writeln('Result: ${accepted ? "ACCEPTED" : "REJECTED"}');
    buffer.writeln('Execution Time: ${executionTime.inMicroseconds}μs');
    buffer.writeln('Steps: ${steps.length}');
    buffer.writeln();

    for (int i = 0; i < steps.length; i++) {
      buffer.writeln('Step ${i + 1}: ${steps[i]}');
    }

    buffer.writeln('\nStatistics:');
    statistics.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });

    return buffer.toString();
  }
}

class NFA extends Automaton {
  // Core NFA components
  Set<String> _states;
  Set<String> _alphabet;
  Map<String, Map<String, Set<String>>> _transitions;
  String _startState;
  Set<String> _finalStates;

  // Advanced features
  Map<String, dynamic> _metadata;
  String _name;
  String _description;
  DateTime _createdAt;
  DateTime _modifiedAt;

  // Epsilon symbol constant
  static const String epsilon = 'ε';

  // Performance tracking
  int _operationCount = 0;
  Duration _totalExecutionTime = Duration.zero;

  // Constructors
  NFA({
    Set<String>? states,
    Set<String>? alphabet,
    Map<String, Map<String, Set<String>>>? transitions,
    String? startState,
    Set<String>? finalStates,
    String? name,
    String? description,
    Map<String, dynamic>? metadata,
  })  : _states = states ?? <String>{},
        _alphabet = alphabet ?? <String>{},
        _transitions = transitions ?? <String, Map<String, Set<String>>>{},
        _startState = startState ?? '',
        _finalStates = finalStates ?? <String>{},
        _name = name ?? 'Unnamed NFA',
        _description = description ?? '',
        _metadata = metadata ?? <String, dynamic>{},
        _createdAt = DateTime.now(),
        _modifiedAt = DateTime.now();

  // Enhanced getters
  Set<String> get states => UnmodifiableSetView(_states);
  Set<String> get alphabet => UnmodifiableSetView(_alphabet);
  Map<String, Map<String, Set<String>>> get transitions =>
      UnmodifiableMapView(_transitions);
  String get startState => _startState;
  Set<String> get finalStates => UnmodifiableSetView(_finalStates);
  String get name => _name;
  String get description => _description;
  DateTime get createdAt => _createdAt;
  DateTime get modifiedAt => _modifiedAt;
  Map<String, dynamic> get metadata => UnmodifiableMapView(_metadata);
  int get operationCount => _operationCount;
  Duration get totalExecutionTime => _totalExecutionTime;

  factory NFA.empty({String? name}) {
    return NFA(name: name ?? 'Empty NFA');
  }

  factory NFA.singleChar(String symbol, {String? name}) {
    final nfa = NFA(name: name ?? 'Single Character NFA ($symbol)');
    nfa.addState('q0');
    nfa.addState('q1', isFinal: true);
    nfa.addTransition('q0', symbol, 'q1');
    nfa.setStartState('q0');
    return nfa;
  }

  factory NFA.epsilonNFA({String? name}) {
    final nfa = NFA(name: name ?? 'Epsilon NFA');
    nfa.addState('q0', isFinal: true);
    nfa.setStartState('q0');
    return nfa;
  }

  factory NFA.universal(Set<String> alphabet, {String? name}) {
    final nfa = NFA(name: name ?? 'Universal NFA');
    nfa.addState('q0', isFinal: true);
    nfa.setStartState('q0');

    for (final symbol in alphabet) {
      nfa.addTransition('q0', symbol, 'q0');
    }

    return nfa;
  }

  factory NFA.rejection({String? name, Set<String>? alphabet}) {
    // Creates an NFA that rejects all strings
    final nfa = NFA(name: name ?? 'Rejection NFA');
    nfa.addState('trap');
    nfa.setStartState('trap');

    if (alphabet != null) {
      for (final symbol in alphabet) {
        nfa.addTransition('trap', symbol, 'trap');
      }
    }

    return nfa;
  }

  factory NFA.fromRegex(String pattern, {String? name}) {

    final nfa = NFA(name: name ?? 'Regex NFA ($pattern)');

    nfa.addState('q0', isFinal: true);
    nfa.setStartState('q0');
    nfa._description = 'Generated from regex: $pattern (placeholder implementation)';
    return nfa;
  }

  factory NFA.fromJson(Map<String, dynamic> json) {
    final nfa = NFA();

    try {
      if (json['states'] != null) {
        final statesList = json['states'] as List;
        nfa._states = statesList.map((e) => e.toString()).toSet();
      }

      if (json['alphabet'] != null) {
        final alphabetList = json['alphabet'] as List;
        nfa._alphabet = alphabetList.map((e) => e.toString()).toSet();
      }

      nfa._startState = json['startState']?.toString() ?? '';

      if (json['finalStates'] != null) {
        final finalStatesList = json['finalStates'] as List;
        nfa._finalStates = finalStatesList.map((e) => e.toString()).toSet();
      }

      if (json['transitions'] != null) {
        final transitionsMap = json['transitions'] as Map<String, dynamic>;

        for (final state in transitionsMap.keys) {
          final stateTransitions = transitionsMap[state] as Map<String, dynamic>;
          nfa._transitions[state] = <String, Set<String>>{};

          for (final symbol in stateTransitions.keys) {
            final destinations = stateTransitions[symbol];
            if (destinations is List) {
              nfa._transitions[state]![symbol] =
                  destinations.map((e) => e.toString()).toSet();
            } else if (destinations != null) {
              nfa._transitions[state]![symbol] = {destinations.toString()};
            }
          }
        }
      }

      nfa._name = json['name']?.toString() ?? 'Unnamed NFA';
      nfa._description = json['description']?.toString() ?? '';

      if (json['metadata'] != null) {
        nfa._metadata = Map<String, dynamic>.from(json['metadata']);
      }

      if (json['createdAt'] != null) {
        nfa._createdAt = DateTime.parse(json['createdAt']);
      }

      if (json['modifiedAt'] != null) {
        nfa._modifiedAt = DateTime.parse(json['modifiedAt']);
      }

    } catch (e) {
      throw FormatException('Invalid JSON format for NFA: $e');
    }

    return nfa;
  }

  Map<String, dynamic> toJson() {
    return {
      'states': _states.toList()..sort(),
      'alphabet': _alphabet.toList()..sort(),
      'startState': _startState,
      'finalStates': _finalStates.toList()..sort(),
      'transitions': _transitionsToJson(),
      'name': _name,
      'description': _description,
      'metadata': _metadata,
      'createdAt': _createdAt.toIso8601String(),
      'modifiedAt': _modifiedAt.toIso8601String(),
      'type': 'NFA',
      'version': '2.0',
    };
  }

  Map<String, dynamic> _transitionsToJson() {
    final result = <String, dynamic>{};

    final sortedStates = _transitions.keys.toList()..sort();
    for (final state in sortedStates) {
      result[state] = <String, dynamic>{};
      final sortedSymbols = _transitions[state]!.keys.toList()..sort();
      for (final symbol in sortedSymbols) {
        final destinations = _transitions[state]![symbol]!.toList()..sort();
        result[state][symbol] = destinations;
      }
    }

    return result;
  }

  NFA copyWith({
    Set<String>? states,
    Set<String>? alphabet,
    Map<String, Map<String, Set<String>>>? transitions,
    String? startState,
    Set<String>? finalStates,
    String? name,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    _updateModifiedTime();
    return NFA(
      states: states ?? Set<String>.from(_states),
      alphabet: alphabet ?? Set<String>.from(_alphabet),
      transitions: transitions ?? _deepCopyTransitions(),
      startState: startState ?? _startState,
      finalStates: finalStates ?? Set<String>.from(_finalStates),
      name: name ?? _name,
      description: description ?? _description,
      metadata: metadata ?? Map<String, dynamic>.from(_metadata),
    );
  }

  NFA clone() => copyWith();

  Map<String, Map<String, Set<String>>> _deepCopyTransitions() {
    final copy = <String, Map<String, Set<String>>>{};
    for (final state in _transitions.keys) {
      copy[state] = <String, Set<String>>{};
      for (final symbol in _transitions[state]!.keys) {
        copy[state]![symbol] = Set<String>.from(_transitions[state]![symbol]!);
      }
    }
    return copy;
  }

  bool addState(String stateName, {bool isFinal = false}) {
    if (stateName.isEmpty || stateName.trim() != stateName) {
      return false;
    }

    final wasNew = _states.add(stateName);

    if (isFinal) {
      _finalStates.add(stateName);
    }

    if (_startState.isEmpty && _states.isNotEmpty) {
      _startState = stateName;
    }

    _transitions[stateName] ??= <String, Set<String>>{};
    _updateModifiedTime();
    return wasNew;
  }

  bool removeState(String stateName) {
    if (!_states.contains(stateName)) return false;

    _states.remove(stateName);
    _finalStates.remove(stateName);

    if (_startState == stateName) {
      _startState = _states.isNotEmpty ? _states.first : '';
    }

    _transitions.remove(stateName);
    for (final state in _transitions.keys) {
      final stateTransitions = _transitions[state]!;
      for (final symbol in stateTransitions.keys.toList()) {
        stateTransitions[symbol]!.remove(stateName);
        if (stateTransitions[symbol]!.isEmpty) {
          stateTransitions.remove(symbol);
        }
      }
    }

    _updateModifiedTime();
    return true;
  }

  bool renameState(String oldName, String newName) {
    if (!_states.contains(oldName) ||
        newName.isEmpty ||
        newName.trim() != newName ||
        _states.contains(newName)) {
      return false;
    }

    _states.remove(oldName);
    _states.add(newName);

    if (_startState == oldName) {
      _startState = newName;
    }

    if (_finalStates.contains(oldName)) {
      _finalStates.remove(oldName);
      _finalStates.add(newName);
    }

    if (_transitions.containsKey(oldName)) {
      _transitions[newName] = _transitions[oldName]!;
      _transitions.remove(oldName);
    }

    for (final state in _transitions.keys) {
      for (final symbol in _transitions[state]!.keys) {
        if (_transitions[state]![symbol]!.contains(oldName)) {
          _transitions[state]![symbol]!.remove(oldName);
          _transitions[state]![symbol]!.add(newName);
        }
      }
    }

    _updateModifiedTime();
    return true;
  }

  // Batch operations
  bool addStates(List<String> stateNames, {Set<String>? finalStates}) {
    bool allAdded = true;
    for (final stateName in stateNames) {
      final isFinal = finalStates?.contains(stateName) ?? false;
      if (!addState(stateName, isFinal: isFinal)) {
        allAdded = false;
      }
    }
    return allAdded;
  }

  int removeStates(List<String> stateNames) {
    int removedCount = 0;
    for (final stateName in stateNames) {
      if (removeState(stateName)) {
        removedCount++;
      }
    }
    return removedCount;
  }

  // Enhanced alphabet management
  bool addSymbol(String symbol) {
    if (symbol.isEmpty) return false;
    final added = _alphabet.add(symbol);
    if (added) _updateModifiedTime();
    return added;
  }

  bool removeSymbol(String symbol) {
    if (!_alphabet.contains(symbol)) return false;

    _alphabet.remove(symbol);

    for (final state in _transitions.keys) {
      _transitions[state]!.remove(symbol);
    }

    _updateModifiedTime();
    return true;
  }

  void addSymbols(List<String> symbols) {
    for (final symbol in symbols) {
      addSymbol(symbol);
    }
  }

  bool addTransition(String fromState, String symbol, String toState) {
    if (fromState.isEmpty || toState.isEmpty) return false;

    addState(fromState);
    addState(toState);

    if (symbol != epsilon) {
      addSymbol(symbol);
    }

    _transitions[fromState] ??= <String, Set<String>>{};
    _transitions[fromState]![symbol] ??= <String>{};
    final added = _transitions[fromState]![symbol]!.add(toState);

    if (added) _updateModifiedTime();
    return added;
  }

  bool removeTransition(String fromState, String symbol, String toState) {
    if (_transitions[fromState]?[symbol] == null) return false;

    final removed = _transitions[fromState]![symbol]!.remove(toState);

    if (_transitions[fromState]![symbol]!.isEmpty) {
      _transitions[fromState]!.remove(symbol);
    }

    if (removed) _updateModifiedTime();
    return removed;
  }

  void clearTransitions() {
    _transitions.forEach((key, value) => value.clear());
    _updateModifiedTime();
  }

  void addTransitions(List<Map<String, String>> transitionList) {
    for (final transition in transitionList) {
      final from = transition['from'];
      final symbol = transition['symbol'];
      final to = transition['to'];
      if (from != null && symbol != null && to != null) {
        addTransition(from, symbol, to);
      }
    }
  }

  Set<String> getTransitions(String fromState, String symbol) {
    return Set<String>.from(_transitions[fromState]?[symbol] ?? <String>{});
  }

  Set<String> getAllTransitionsFrom(String state) {
    final result = <String>{};
    final stateTransitions = _transitions[state];
    if (stateTransitions != null) {
      for (final destinations in stateTransitions.values) {
        result.addAll(destinations);
      }
    }
    return result;
  }

  Map<String, Set<String>> getTransitionsWithSymbols(String state) {
    final result = <String, Set<String>>{};
    final stateTransitions = _transitions[state];
    if (stateTransitions != null) {
      for (final symbol in stateTransitions.keys) {
        result[symbol] = Set<String>.from(stateTransitions[symbol]!);
      }
    }
    return result;
  }

  // Enhanced start and final state management
  bool setStartState(String stateName) {
    if (!_states.contains(stateName)) return false;
    _startState = stateName;
    _updateModifiedTime();
    return true;
  }

  bool setFinalState(String stateName, bool isFinal) {
    if (!_states.contains(stateName)) return false;

    bool changed;
    if (isFinal) {
      changed = _finalStates.add(stateName);
    } else {
      changed = _finalStates.remove(stateName);
    }

    if (changed) _updateModifiedTime();
    return changed;
  }

  bool toggleFinalState(String stateName) {
    if (!_states.contains(stateName)) return false;

    bool isFinal;
    if (_finalStates.contains(stateName)) {
      _finalStates.remove(stateName);
      isFinal = false;
    } else {
      _finalStates.add(stateName);
      isFinal = true;
    }

    _updateModifiedTime();
    return isFinal;
  }

  void setFinalStates(Set<String> finalStates) {
    _finalStates.clear();
    for (final state in finalStates) {
      if (_states.contains(state)) {
        _finalStates.add(state);
      }
    }
    _updateModifiedTime();
  }

  // Enhanced epsilon closure operations
  Set<String> epsilonClosure(Set<String> states) {
    final closure = <String>{};
    final stack = <String>[];

    for (final state in states) {
      if (_states.contains(state)) {
        closure.add(state);
        stack.add(state);
      }
    }

    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      final epsilonTransitions = getTransitions(current, epsilon);

      for (final nextState in epsilonTransitions) {
        if (!closure.contains(nextState)) {
          closure.add(nextState);
          stack.add(nextState);
        }
      }
    }

    return closure;
  }

  Set<String> epsilonClosureOfState(String state) {
    return epsilonClosure({state});
  }

  Map<String, Set<String>> getAllEpsilonClosures() {
    final result = <String, Set<String>>{};
    for (final state in _states) {
      result[state] = epsilonClosureOfState(state);
    }
    return result;
  }

  // Enhanced string acceptance with tracing
  bool accepts(String input) {
    if (_startState.isEmpty) return false;

    Set<String> currentStates = epsilonClosureOfState(_startState);

    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      final nextStates = <String>{};

      for (final state in currentStates) {
        nextStates.addAll(getTransitions(state, symbol));
      }

      if (nextStates.isEmpty) return false;

      currentStates = epsilonClosure(nextStates);
    }

    return currentStates.any((state) => _finalStates.contains(state));
  }

  // Advanced tracing functionality
  NFATrace traceExecution(String input) {
    final startTime = DateTime.now();
    final steps = <NFATraceStep>[];
    final statistics = <String, dynamic>{};

    int stateVisits = 0;
    int transitionsTaken = 0;
    final visitedStates = <String>{};

    if (_startState.isEmpty) {
      final endTime = DateTime.now();
      return NFATrace(
        input: input,
        accepted: false,
        steps: steps,
        executionTime: endTime.difference(startTime),
        statistics: {'error': 'No start state defined'},
      );
    }

    var currentStates = epsilonClosureOfState(_startState);
    visitedStates.addAll(currentStates);
    stateVisits += currentStates.length;

    steps.add(NFATraceStep(
      currentStates: currentStates,
      consumedInput: '',
      remainingInput: input,
      epsilonClosure: currentStates,
      transitions: {},
    ));

    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      final nextStates = <String>{};
      final transitionMap = <String, Set<String>>{};

      for (final state in currentStates) {
        final transitions = getTransitions(state, symbol);
        if (transitions.isNotEmpty) {
          transitionMap[state] = transitions;
          nextStates.addAll(transitions);
          transitionsTaken += transitions.length;
        }
      }

      if (nextStates.isEmpty) {
        steps.add(NFATraceStep(
          currentStates: <String>{},
          consumedInput: input.substring(0, i + 1),
          remainingInput: input.substring(i + 1),
          lastSymbol: symbol,
          epsilonClosure: <String>{},
          transitions: transitionMap,
        ));
        break;
      }

      currentStates = epsilonClosure(nextStates);
      visitedStates.addAll(currentStates);
      stateVisits += currentStates.length;

      steps.add(NFATraceStep(
        currentStates: nextStates,
        consumedInput: input.substring(0, i + 1),
        remainingInput: input.substring(i + 1),
        lastSymbol: symbol,
        epsilonClosure: currentStates,
        transitions: transitionMap,
      ));
    }

    final accepted = currentStates.any((state) => _finalStates.contains(state));
    final endTime = DateTime.now();
    final executionTime = endTime.difference(startTime);

    statistics.addAll({
      'input_length': input.length,
      'steps_taken': steps.length,
      'states_visited': visitedStates.length,
      'total_state_visits': stateVisits,
      'transitions_taken': transitionsTaken,
      'final_states_reached': currentStates.where((s) => _finalStates.contains(s)).toSet(),
    });

    _operationCount++;
    _totalExecutionTime += executionTime;

    return NFATrace(
      input: input,
      accepted: accepted,
      steps: steps,
      executionTime: executionTime,
      statistics: statistics,
    );
  }

  // Batch string testing
  Map<String, bool> acceptsAll(List<String> inputs) {
    final results = <String, bool>{};
    for (final input in inputs) {
      results[input] = accepts(input);
    }
    return results;
  }

  List<String> findAcceptedStrings(List<String> inputs) {
    return inputs.where((input) => accepts(input)).toList();
  }

  List<String> findRejectedStrings(List<String> inputs) {
    return inputs.where((input) => !accepts(input)).toList();
  }

  // Advanced NFA operations with validation
  NFAOperationResult union(NFA other) {
    final thisValidation = validate();
    final otherValidation = other.validate();

    if (!thisValidation.isValid) {
      return NFAOperationResult.failure('NFA اول نامعتبر است: ${thisValidation.errors.join(', ')}');
    }

    if (!otherValidation.isValid) {
      return NFAOperationResult.failure('NFA دوم نامعتبر است: ${otherValidation.errors.join(', ')}');
    }

    try {
      final result = NFA(name: '${_name} ∪ ${other.name}');
      final newStart = 'q_start';
      result.addState(newStart);
      result.setStartState(newStart);

      final thisStart = 'this_${_startState}';
      final otherStart = 'other_${other._startState}';

      for (final state in _states) {
        result.addState('this_$state', isFinal: _finalStates.contains(state));
      }
      for (final state in other._states) {
        result.addState('other_$state', isFinal: other._finalStates.contains(state));
      }

      for (final fromState in _transitions.keys) {
        for (final symbol in _transitions[fromState]!.keys) {
          for (final toState in _transitions[fromState]![symbol]!) {
            result.addTransition('this_$fromState', symbol, 'this_$toState');
          }
        }
      }

      for (final fromState in other._transitions.keys) {
        for (final symbol in other._transitions[fromState]!.keys) {
          for (final toState in other._transitions[fromState]![symbol]!) {
            result.addTransition('other_$fromState', symbol, 'other_$toState');
          }
        }
      }

      result.addTransition(newStart, epsilon, thisStart);
      result.addTransition(newStart, epsilon, otherStart);

      return NFAOperationResult.success(result);
    } catch (e) {
      return NFAOperationResult.failure('Union operation failed: $e');
    }
  }

  NFAOperationResult concatenation(NFA other) {
    final thisValidation = validate();
    final otherValidation = other.validate();

    if (!thisValidation.isValid) {
      return NFAOperationResult.failure('NFA اول نامعتبر است: ${thisValidation.errors.join(', ')}');
    }

    if (!otherValidation.isValid) {
      return NFAOperationResult.failure('NFA دوم نامعتبر است: ${otherValidation.errors.join(', ')}');
    }

    try {
      final result = NFA(name: '${_name} · ${other.name}');

      for (final state in _states) {
        result.addState(state, isFinal: false);
      }
      for (final state in other._states) {
        result.addState('next_$state', isFinal: other._finalStates.contains(state));
      }

      result.setStartState(_startState);

      for (final fromState in _transitions.keys) {
        for (final symbol in _transitions[fromState]!.keys) {
          for (final toState in _transitions[fromState]![symbol]!) {
            result.addTransition(fromState, symbol, toState);
          }
        }
      }

      for (final fromState in other._transitions.keys) {
        for (final symbol in other._transitions[fromState]!.keys) {
          for (final toState in other._transitions[fromState]![symbol]!) {
            result.addTransition('next_$fromState', symbol, 'next_$toState');
          }
        }
      }

      for (final finalState in _finalStates) {
        result.addTransition(finalState, epsilon, 'next_${other._startState}');
      }

      return NFAOperationResult.success(result);
    } catch (e) {
      return NFAOperationResult.failure('Concatenation operation failed: $e');
    }
  }

  NFAOperationResult kleeneStar() {
    final validation = validate();
    if (!validation.isValid) {
      return NFAOperationResult.failure('NFA نامعتبر است: ${validation.errors.join(', ')}');
    }

    try {
      final result = NFA(name: '${_name}*');
      final newStart = 'q_star_start';
      result.addState(newStart, isFinal: true);
      result.setStartState(newStart);

      for (final state in _states) {
        result.addState('star_$state', isFinal: _finalStates.contains(state));
      }

      for (final fromState in _transitions.keys) {
        for (final symbol in _transitions[fromState]!.keys) {
          for (final toState in _transitions[fromState]![symbol]!) {
            result.addTransition('star_$fromState', symbol, 'star_$toState');
          }
        }
      }

      result.addTransition(newStart, epsilon, 'star_${_startState}');

      for (final finalState in _finalStates) {
        result.addTransition('star_$finalState', epsilon, 'star_${_startState}');
      }

      return NFAOperationResult.success(result);
    } catch (e) {
      return NFAOperationResult.failure('Kleene star operation failed: $e');
    }
  }

  // Utility methods
  void clear() {
    _states.clear();
    _alphabet.clear();
    _transitions.clear();
    _startState = '';
    _finalStates.clear();
    _metadata.clear();
    _updateModifiedTime();
  }

  bool get isEmpty => _states.isEmpty;

  bool get isComplete {
    for (final state in _states) {
      for (final symbol in _alphabet) {
        if (!_transitions.containsKey(state) || !_transitions[state]!.containsKey(symbol)) {
          return false;
        }
      }
    }
    return true;
  }

  int get stateCount => _states.length;
  int get transitionCount {
    int count = 0;
    for (final stateTransitions in _transitions.values) {
      for (final destinations in stateTransitions.values) {
        count += destinations.length;
      }
    }
    return count;
  }
  int getTransitionCount() => transitionCount;
  int getEpsilonTransitionCount() {
    int count = 0;
    for (final stateTransitions in _transitions.values) {
      if (stateTransitions.containsKey(epsilon)) {
        count += stateTransitions[epsilon]!.length;
      }
    }
    return count;
  }
  double getTransitionDensity() {
    if (stateCount == 0 || alphabet.isEmpty) return 0.0;
    return transitionCount / (stateCount * alphabet.length);
  }
  bool get hasEpsilonTransitions {
    for (final stateTransitions in _transitions.values) {
      if (stateTransitions.containsKey(epsilon)) {
        return true;
      }
    }
    return false;
  }

  // Metadata management
  void setMetadata(String key, dynamic value) {
    _metadata[key] = value;
    _updateModifiedTime();
  }
  dynamic getMetadata(String key) => _metadata[key];
  void removeMetadata(String key) {
    _metadata.remove(key);
    _updateModifiedTime();
  }
  void setName(String name) {
    _name = name;
    _updateModifiedTime();
  }
  void setDescription(String description) {
    _description = description;
    _updateModifiedTime();
  }
  void _updateModifiedTime() {
    _modifiedAt = DateTime.now();
  }

  // Enhanced validation
  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    if (_states.isEmpty) {
      errors.add('NFA باید حداقل یک حالت داشته باشد');
    }
    if (_startState.isEmpty && _states.isNotEmpty) {
      errors.add('حالت شروع باید مشخص شود');
    } else if (_startState.isNotEmpty && !_states.contains(_startState)) {
      errors.add('حالت شروع "$_startState" در مجموعه حالات وجود ندارد');
    }
    if (_finalStates.isEmpty && _states.isNotEmpty) {
      warnings.add('NFA بدون حالت پایانی، هیچ رشته‌ای را قبول نخواهد کرد');
    }
    for (final finalState in _finalStates) {
      if (!_states.contains(finalState)) {
        errors.add('حالت پایانی "$finalState" در مجموعه حالات وجود ندارد');
      }
    }
    for (final fromState in _transitions.keys) {
      if (!_states.contains(fromState)) {
        errors.add('حالت مبدأ "$fromState" در انتقال‌ها وجود دارد ولی در مجموعه حالات نیست');
      }
      final stateTransitions = _transitions[fromState]!;
      for (final symbol in stateTransitions.keys) {
        if (symbol != epsilon && !_alphabet.contains(symbol)) {
          warnings.add('نماد "$symbol" در انتقال‌ها استفاده شده ولی در الفبا نیست');
        }
        for (final toState in stateTransitions[symbol]!) {
          if (!_states.contains(toState)) {
            errors.add('حالت مقصد "$toState" در مجموعه حالات وجود ندارد');
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  // String representations
  @override
  String toString() {
    return 'NFA(name: "$_name", states: ${_states.length}, alphabet: $_alphabet, '
        'start: $_startState, final: $_finalStates, transitions: ${transitionCount})';
  }
}