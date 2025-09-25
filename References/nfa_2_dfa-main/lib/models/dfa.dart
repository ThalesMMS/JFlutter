import 'state_model.dart';

class AutomatonMetrics {
  final int stateCount;
  final int alphabetSize;
  final int transitionCount;
  final double density;
  final double finalStateRatio;

  AutomatonMetrics({
    required this.stateCount,
    required this.alphabetSize,
    required this.transitionCount,
    required this.density,
    required this.finalStateRatio,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('Validation Result: ${isValid ? 'VALID' : 'INVALID'}');

    if (errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in errors) {
        buffer.writeln('  - $error');
      }
    }

    if (warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in warnings) {
        buffer.writeln('  - $warning');
      }
    }

    return buffer.toString();
  }
}

/// نتیجه پردازش رشته
class ProcessingResult {
  final bool accepted;
  final List<String> path;
  final String finalState;
  final String? errorMessage;

  const ProcessingResult({
    required this.accepted,
    required this.path,
    required this.finalState,
    this.errorMessage,
  });

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('String ${accepted ? 'ACCEPTED' : 'REJECTED'}');
    buffer.writeln('Path: ${path.join(' → ')}');
    buffer.writeln('Final State: $finalState');
    if (errorMessage != null) {
      buffer.writeln('Error: $errorMessage');
    }
    return buffer.toString();
  }
}

/// کلاس اصلی DFA
class DFA {
  Set<StateSet> _states;
  Set<String> _alphabet;
  Map<StateSet, Map<String, StateSet>> _transitions;
  StateSet? _startState;
  Set<StateSet> _finalStates;

  // نقشه برای تبدیل StateSet به نام نمایشی
  final Map<StateSet, String> _stateNames = {};
  int _nameCounter = 0;

  DFA({
    Set<StateSet>? states,
    Set<String>? alphabet,
    Map<StateSet, Map<String, StateSet>>? transitions,
    StateSet? startState,
    Set<StateSet>? finalStates,
  })  : _states = states ?? <StateSet>{},
        _alphabet = alphabet ?? <String>{},
        _transitions = transitions ?? <StateSet, Map<String, StateSet>>{},
        _startState = startState,
        _finalStates = finalStates ?? <StateSet>{};

  // Getters (readonly)
  Set<StateSet> get states => Set<StateSet>.unmodifiable(_states);
  Set<String> get alphabet => Set<String>.unmodifiable(_alphabet);
  Map<StateSet, Map<String, StateSet>> get transitions =>
      Map<StateSet, Map<String, StateSet>>.unmodifiable(_transitions);
  StateSet? get startState => _startState;
  Set<StateSet> get finalStates => Set<StateSet>.unmodifiable(_finalStates);

  /// ساخت DFA خالی
  factory DFA.empty() {
    return DFA();
  }

  /// ساخت DFA ساده (یک state)
  factory DFA.simple({
    required String stateName,
    required Set<String> alphabet,
    bool isFinalState = false,
  }) {
    final state = StateModel(name: stateName, isFinal: isFinalState);
    final stateSet = StateSet({state});

    final dfa = DFA(
      states: {stateSet},
      alphabet: Set<String>.from(alphabet),
      startState: stateSet,
      finalStates: isFinalState ? {stateSet} : <StateSet>{},
    );

    dfa._stateNames[stateSet] = stateName;

    // افزودن self-loops برای همه نمادها
    dfa._transitions[stateSet] = <String, StateSet>{};
    for (final symbol in alphabet) {
      dfa._transitions[stateSet]![symbol] = stateSet;
    }

    return dfa;
  }

  /// ساخت از JSON با error handling بهتر
  factory DFA.fromJson(Map<String, dynamic> json) {
    try {
      final dfa = DFA();

      if (json['alphabet'] != null) {
        final alphabetData = json['alphabet'];
        if (alphabetData is List) {
          dfa._alphabet = Set<String>.from(alphabetData.map((e) => e.toString()));
        }
      }

      // Parse states
      final stateMap = <String, StateSet>{};
      if (json['states'] != null) {
        final statesData = json['states'] as Map<String, dynamic>;

        for (final stateId in statesData.keys) {
          final stateInfo = statesData[stateId] as Map<String, dynamic>;
          final stateNames = Set<String>.from(stateInfo['stateNames'] ?? [stateId]);
          final isFinal = stateInfo['isFinal'] as bool? ?? false;

          // ساخت StateModel ها
          final stateModels = stateNames.map((name) =>
              StateModel(name: name, isFinal: isFinal)).toSet();
          final stateSet = StateSet(stateModels);

          dfa._states.add(stateSet);
          dfa._stateNames[stateSet] = stateInfo['displayName'] ?? stateId;
          stateMap[stateId] = stateSet;

          if (isFinal || stateSet.isFinal) {
            dfa._finalStates.add(stateSet);
          }
        }
      }

      // Parse start state
      if (json['startState'] != null) {
        final startStateData = json['startState'];
        if (startStateData is Map<String, dynamic>) {
          final startStateId = startStateData['displayName'] ??
              startStateData['stateNames']?.first;
          if (startStateId != null && stateMap.containsKey(startStateId)) {
            dfa._startState = stateMap[startStateId];
          }
        } else if (startStateData is String) {
          dfa._startState = stateMap[startStateData];
        }
      }

      // Parse transitions
      if (json['transitions'] != null) {
        final transitionsData = json['transitions'] as Map<String, dynamic>;

        for (final fromStateId in transitionsData.keys) {
          final fromState = stateMap[fromStateId];
          if (fromState != null) {
            final stateTransitions = transitionsData[fromStateId] as Map<String, dynamic>;
            dfa._transitions[fromState] = <String, StateSet>{};

            for (final symbol in stateTransitions.keys) {
              final toStateId = stateTransitions[symbol] as String;
              final toState = stateMap[toStateId];
              if (toState != null) {
                dfa._transitions[fromState]![symbol] = toState;
              }
            }
          }
        }
      }

      return dfa;
    } catch (e) {
      throw ArgumentError('Invalid JSON format for DFA: $e');
    }
  }

  /// تبدیل به JSON
  Map<String, dynamic> toJson() {
    final statesData = <String, dynamic>{};

    // تبدیل states
    for (final state in _states) {
      final stateId = getStateName(state);
      statesData[stateId] = {
        'displayName': stateId,
        'stateNames': state.stateNames,
        'isFinal': _finalStates.contains(state),
      };
    }

    // تبدیل transitions
    final transitionsData = <String, dynamic>{};
    for (final state in _transitions.keys) {
      final stateId = getStateName(state);
      transitionsData[stateId] = <String, dynamic>{};

      for (final symbol in _transitions[state]!.keys) {
        final toState = _transitions[state]![symbol]!;
        transitionsData[stateId][symbol] = getStateName(toState);
      }
    }

    return {
      'type': 'DFA',
      'version': '1.0',
      'states': statesData,
      'alphabet': _alphabet.toList()..sort(),
      'startState': _startState != null ? {
        'displayName': getStateName(_startState!),
        'stateNames': _startState!.stateNames,
      } : null,
      'finalStates': _finalStates.map(getStateName).toList()..sort(),
      'transitions': transitionsData,
      'metadata': {
        'stateCount': _states.length,
        'transitionCount': transitionCount,
        'isComplete': isComplete,
        'isMinimal': isMinimal(),
        'createdAt': DateTime.now().toIso8601String(),
      }
    };
  }

  /// کپی عمیق DFA
  DFA copyWith({
    Set<StateSet>? states,
    Set<String>? alphabet,
    Map<StateSet, Map<String, StateSet>>? transitions,
    StateSet? startState,
    Set<StateSet>? finalStates,
  }) {
    final copy = DFA(
      states: states ?? Set<StateSet>.from(_states),
      alphabet: alphabet ?? Set<String>.from(_alphabet),
      transitions: transitions ?? _copyTransitions(),
      startState: startState ?? _startState,
      finalStates: finalStates ?? Set<StateSet>.from(_finalStates),
    );

    copy._stateNames.addAll(_stateNames);
    copy._nameCounter = _nameCounter;

    return copy;
  }

  Map<StateSet, Map<String, StateSet>> _copyTransitions() {
    final copy = <StateSet, Map<String, StateSet>>{};
    for (final state in _transitions.keys) {
      copy[state] = Map<String, StateSet>.from(_transitions[state]!);
    }
    return copy;
  }

  String addState(StateSet stateSet, {String? customName, bool? isFinal}) {
    if (stateSet.states.isEmpty) {
      throw ArgumentError('StateSet cannot be empty');
    }

    // اگر state از قبل وجود داشت، فقط نام را برگردان
    if (_states.contains(stateSet)) {
      return getStateName(stateSet);
    }

    _states.add(stateSet);

    // تولید نام نمایشی
    String displayName;
    if (customName != null && customName.isNotEmpty) {
      // بررسی تکراری نبودن نام
      if (_stateNames.values.contains(customName)) {
        displayName = '${customName}_${_nameCounter++}';
      } else {
        displayName = customName;
      }
    } else {
      // تولید نام خودکار
      do {
        displayName = 'q$_nameCounter';
        _nameCounter++;
      } while (_stateNames.values.contains(displayName));
    }

    _stateNames[stateSet] = displayName;

    // تنظیم final state
    final shouldBeFinal = isFinal ?? stateSet.isFinal;
    if (shouldBeFinal) {
      _finalStates.add(stateSet);
    }

    // اگر هنوز start state نداریم، اولی رو start کن
    if (_startState == null) {
      _startState = stateSet;
    }

    // مطمئن شو که transitions map وجود داره
    _transitions[stateSet] ??= <String, StateSet>{};

    return displayName;
  }

  List<String> addStates(Iterable<StateSet> stateSets) {
    return stateSets.map((stateSet) => addState(stateSet)).toList();
  }

  void addSymbol(String symbol) {
    if (symbol.isEmpty) {
      throw ArgumentError('Symbol cannot be empty');
    }
    _alphabet.add(symbol);
  }

  void addSymbols(Iterable<String> symbols) {
    for (final symbol in symbols) {
      addSymbol(symbol);
    }
  }

  void addTransition(StateSet fromState, String symbol, StateSet toState) {
    if (symbol.isEmpty) {
      throw ArgumentError('Transition symbol cannot be empty');
    }

    // مطمئن شو که state ها وجود دارند
    if (!_states.contains(fromState)) {
      addState(fromState);
    }
    if (!_states.contains(toState)) {
      addState(toState);
    }

    _alphabet.add(symbol);

    _transitions[fromState] ??= <String, StateSet>{};
    _transitions[fromState]![symbol] = toState;
  }

  /// حذف state با پاکسازی کامل
  bool removeState(StateSet stateSet) {
    if (!_states.contains(stateSet)) {
      return false;
    }

    _states.remove(stateSet);
    _finalStates.remove(stateSet);
    _stateNames.remove(stateSet);

    // اگر start state بود، reset کن
    if (_startState == stateSet) {
      _startState = _states.isNotEmpty ? _states.first : null;
    }

    // حذف transitions مربوط به این state
    _transitions.remove(stateSet);

    // حذف transitions که به این state می‌روند
    for (final state in _transitions.keys) {
      final toRemove = <String>[];
      for (final symbol in _transitions[state]!.keys) {
        if (_transitions[state]![symbol] == stateSet) {
          toRemove.add(symbol);
        }
      }
      for (final symbol in toRemove) {
        _transitions[state]!.remove(symbol);
      }
    }

    return true;
  }

  bool removeTransition(StateSet fromState, String symbol) {
    if (!_states.contains(fromState)) return false;

    final removed = _transitions[fromState]?.remove(symbol) != null;

    if (removed && !_isSymbolUsed(symbol)) {
      _alphabet.remove(symbol);
    }

    return removed;
  }

  /// بررسی استفاده از نماد
  bool _isSymbolUsed(String symbol) {
    for (final stateTransitions in _transitions.values) {
      if (stateTransitions.containsKey(symbol)) {
        return true;
      }
    }
    return false;
  }

  /// گرفتن نام نمایشی state
  String getStateName(StateSet stateSet) {
    return _stateNames[stateSet] ?? stateSet.displayName;
  }

  /// تنظیم نام سفارشی برای state
  bool setStateName(StateSet stateSet, String name) {
    if (!_states.contains(stateSet) || name.isEmpty) {
      return false;
    }

    // بررسی تکراری نبودن نام
    if (_stateNames.values.contains(name)) {
      return false;
    }

    _stateNames[stateSet] = name;
    return true;
  }

  /// گرفتن مقصد transition
  StateSet? getTransition(StateSet fromState, String symbol) {
    return _transitions[fromState]?[symbol];
  }

  /// تنظیم start state
  bool setStartState(StateSet stateSet) {
    if (!_states.contains(stateSet)) {
      return false;
    }
    _startState = stateSet;
    return true;
  }

  /// تنظیم final state
  bool setFinalState(StateSet stateSet, bool isFinal) {
    if (!_states.contains(stateSet)) {
      return false;
    }

    if (isFinal) {
      _finalStates.add(stateSet);
    } else {
      _finalStates.remove(stateSet);
    }
    return true;
  }

  /// پاک کردن همه چیز
  void clear() {
    _states.clear();
    _alphabet.clear();
    _transitions.clear();
    _startState = null;
    _finalStates.clear();
    _stateNames.clear();
    _nameCounter = 0;
  }

  /// اعتبارسنجی کامل DFA
  ValidationResult validate() {
    final errors = <String>[];
    final warnings = <String>[];

    // بررسی اساسی
    if (_states.isEmpty) {
      errors.add('DFA باید حداقل یک state داشته باشد');
      return ValidationResult(isValid: false, errors: errors, warnings: warnings);
    }

    // بررسی start state
    if (_startState == null) {
      errors.add('Start state مشخص نشده است');
    } else if (!_states.contains(_startState)) {
      errors.add('Start state در مجموعه states موجود نیست');
    }

    // بررسی alphabet
    if (_alphabet.isEmpty) {
      warnings.add('Alphabet خالی است');
    }

    // بررسی نمادهای غیرمعتبر
    for (final symbol in _alphabet) {
      if (symbol.isEmpty) {
        errors.add('نماد خالی در alphabet موجود است');
      }
      if (symbol.contains(' ')) {
        warnings.add('نماد "$symbol" شامل فاصله است');
      }
    }

    // بررسی final states
    for (final finalState in _finalStates) {
      if (!_states.contains(finalState)) {
        errors.add('Final state "${getStateName(finalState)}" در مجموعه states موجود نیست');
      }
    }

    // بررسی کامل بودن transitions
    for (final state in _states) {
      final stateTransitions = _transitions[state] ?? <String, StateSet>{};

      for (final symbol in _alphabet) {
        if (!stateTransitions.containsKey(symbol)) {
          errors.add('Transition از state "${getStateName(state)}" با نماد "$symbol" موجود نیست');
        }
      }

      // بررسی transitions اضافی
      for (final symbol in stateTransitions.keys) {
        if (!_alphabet.contains(symbol)) {
          warnings.add('Transition با نماد "$symbol" در alphabet تعریف نشده');
        }

        final toState = stateTransitions[symbol]!;
        if (!_states.contains(toState)) {
          errors.add('مقصد transition "${getStateName(toState)}" در مجموعه states موجود نیست');
        }
      }
    }

    // بررسی unreachable states
    final reachableStates = _findReachableStates();
    final unreachableStates = _states.difference(reachableStates);
    for (final unreachable in unreachableStates) {
      warnings.add('State "${getStateName(unreachable)}" از start state قابل دسترسی نیست');
    }

    // بررسی dead states (states که هیچ final state ای قابل دسترسی نیست)
    final deadStates = _findDeadStates();
    for (final dead in deadStates) {
      warnings.add('State "${getStateName(dead)}" dead state است (هیچ final state ای از آن قابل دسترسی نیست)');
    }

    // بررسی نام‌های تکراری
    final nameSet = <String>{};
    for (final name in _stateNames.values) {
      if (!nameSet.add(name)) {
        warnings.add('نام state تکراری: "$name"');
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// پیدا کردن state های قابل دسترسی
  Set<StateSet> _findReachableStates() {
    if (_startState == null) return <StateSet>{};

    final reachable = <StateSet>{};
    final toVisit = <StateSet>[_startState!];

    while (toVisit.isNotEmpty) {
      final current = toVisit.removeLast();
      if (reachable.contains(current)) continue;

      reachable.add(current);

      final currentTransitions = _transitions[current];
      if (currentTransitions != null) {
        for (final destination in currentTransitions.values) {
          if (!reachable.contains(destination)) {
            toVisit.add(destination);
          }
        }
      }
    }

    return reachable;
  }

  /// پیدا کردن dead states
  Set<StateSet> _findDeadStates() {
    if (_finalStates.isEmpty) return Set<StateSet>.from(_states);

    final canReachFinal = <StateSet>{};
    final toVisit = <StateSet>[];

    // شروع از final states
    for (final finalState in _finalStates) {
      canReachFinal.add(finalState);
      toVisit.add(finalState);
    }

    // پیدا کردن states که می‌توانند به final برسند (reverse traversal)
    while (toVisit.isNotEmpty) {
      final current = toVisit.removeLast();

      for (final state in _states) {
        if (canReachFinal.contains(state)) continue;

        final stateTransitions = _transitions[state];
        if (stateTransitions != null) {
          for (final destination in stateTransitions.values) {
            if (destination == current) {
              canReachFinal.add(state);
              toVisit.add(state);
              break;
            }
          }
        }
      }
    }

    return _states.difference(canReachFinal);
  }

  /// تولید جدول انتقالات برای نمایش
  Map<String, Map<String, String>> getTransitionTable() {
    final table = <String, Map<String, String>>{};
    final sortedAlphabet = _alphabet.toList()..sort();

    for (final state in _states) {
      final stateName = getStateName(state);
      table[stateName] = <String, String>{};

      final stateTransitions = _transitions[state] ?? <String, StateSet>{};
      for (final symbol in sortedAlphabet) {
        final destination = stateTransitions[symbol];
        table[stateName]![symbol] = destination != null
            ? getStateName(destination)
            : '∅';
      }
    }

    return table;
  }

  /// بررسی پذیرش رشته با جزئیات کامل
  ProcessingResult processString(String input) {
    final path = <String>[];

    if (_startState == null) {
      return ProcessingResult(
        accepted: false,
        path: path,
        finalState: '∅',
        errorMessage: 'Start state تعریف نشده است',
      );
    }

    StateSet currentState = _startState!;
    path.add(getStateName(currentState));

    // پردازش هر نماد
    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];

      // بررسی وجود نماد در alphabet
      if (!_alphabet.contains(symbol)) {
        return ProcessingResult(
          accepted: false,
          path: path,
          finalState: getStateName(currentState),
          errorMessage: 'نماد "$symbol" در alphabet تعریف نشده است (موقعیت $i)',
        );
      }

      final nextState = getTransition(currentState, symbol);
      if (nextState == null) {
        return ProcessingResult(
          accepted: false,
          path: path,
          finalState: getStateName(currentState),
          errorMessage: 'Transition از "${getStateName(currentState)}" با نماد "$symbol" موجود نیست',
        );
      }

      currentState = nextState;
      path.add(getStateName(currentState));
    }

    final accepted = _finalStates.contains(currentState);
    return ProcessingResult(
      accepted: accepted,
      path: path,
      finalState: getStateName(currentState),
      errorMessage: accepted ? null : 'State نهایی "${getStateName(currentState)}" final state نیست',
    );
  }

  /// بررسی ساده پذیرش رشته
  bool acceptsString(String input) {
    return processString(input).accepted;
  }

  /// تولید رشته‌های پذیرفته شده تا طول مشخص
  List<String> generateAcceptedStrings(int maxLength) {
    final result = <String>[];
    final visited = <String, StateSet>{};

    void dfs(StateSet currentState, String currentString) {
      if (currentString.length > maxLength) return;

      // اگر قبلاً این رشته را بررسی کرده‌ایم
      if (visited.containsKey(currentString) && visited[currentString] == currentState) {
        return;
      }
      visited[currentString] = currentState;

      // اگر final state است، رشته را اضافه کن
      if (_finalStates.contains(currentState)) {
        result.add(currentString);
      }

      // ادامه DFS برای همه transitions
      final stateTransitions = _transitions[currentState];
      if (stateTransitions != null) {
        for (final symbol in stateTransitions.keys) {
          final nextState = stateTransitions[symbol]!;
          dfs(nextState, currentString + symbol);
        }
      }
    }

    if (_startState != null) {
      dfs(_startState!, '');
    }

    result.sort((a, b) => a.length != b.length ? a.length.compareTo(b.length) : a.compareTo(b));
    return result;
  }

  bool isMinimal() {

    final reachable = _findReachableStates();
    final dead = _findDeadStates();

    return reachable.length == _states.length && dead.isEmpty;
  }

  /// مینیمال کردن DFA (الگوریتم Table-Filling)
  DFA minimize() {
    if (_states.length <= 1) return copyWith();

    final stateList = _states.toList();
    final n = stateList.length;

    // جدول distinguishable pairs
    final distinguishable = List.generate(n, (i) => List.generate(n, (j) => false));

    // مرحله 1: مشخص کردن final و non-final states
    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        final state1 = stateList[i];
        final state2 = stateList[j];

        final isFinal1 = _finalStates.contains(state1);
        final isFinal2 = _finalStates.contains(state2);

        if (isFinal1 != isFinal2) {
          distinguishable[i][j] = true;
          distinguishable[j][i] = true;
        }
      }
    }

    // مرحله 2: پیدا کردن distinguishable pairs
    bool changed = true;
    while (changed) {
      changed = false;

      for (int i = 0; i < n; i++) {
        for (int j = i + 1; j < n; j++) {
          if (distinguishable[i][j]) continue;

          final state1 = stateList[i];
          final state2 = stateList[j];

          for (final symbol in _alphabet) {
            final next1 = getTransition(state1, symbol);
            final next2 = getTransition(state2, symbol);

            if (next1 == null || next2 == null) {
              if (next1 != next2) {
                distinguishable[i][j] = true;
                distinguishable[j][i] = true;
                changed = true;
                break;
              }
            } else {
              final index1 = stateList.indexOf(next1);
              final index2 = stateList.indexOf(next2);

              if (index1 != -1 && index2 != -1 && distinguishable[index1][index2]) {
                distinguishable[i][j] = true;
                distinguishable[j][i] = true;
                changed = true;
                break;
              }
            }
          }
        }
      }
    }

    // مرحله 3: گروه‌بندی equivalent states
    final groups = <Set<int>>[];
    final visited = <bool>[for (int i = 0; i < n; i++) false];

    for (int i = 0; i < n; i++) {
      if (visited[i]) continue;

      final group = <int>{i};
      visited[i] = true;

      for (int j = i + 1; j < n; j++) {
        if (!visited[j] && !distinguishable[i][j]) {
          group.add(j);
          visited[j] = true;
        }
      }

      groups.add(group);
    }

    // اگر تعداد گروه‌ها برابر تعداد states است، DFA از قبل مینیمال است
    if (groups.length == n) {
      return copyWith();
    }

    // مرحله 4: ساخت DFA مینیمال
    final minimizedDFA = DFA();
    final groupToStateSet = <Set<int>, StateSet>{};

    // ساخت states جدید
    for (final group in groups) {
      final representativeIndex = group.first;
      final representativeState = stateList[representativeIndex];

      // ساخت نام ترکیبی برای گروه
      final groupNames = group.map((index) => getStateName(stateList[index])).toList()..sort();
      final groupName = groupNames.length == 1 ? groupNames.first : '{${groupNames.join(',')}}';

      // ساخت StateSet جدید
      final allStateModels = <StateModel>{};
      for (final index in group) {
        allStateModels.addAll(stateList[index].states);
      }
      final newStateSet = StateSet(allStateModels);

      groupToStateSet[group] = newStateSet;
      minimizedDFA.addState(newStateSet, customName: groupName);

      // اگر گروه شامل final state باشد
      if (group.any((index) => _finalStates.contains(stateList[index]))) {
        minimizedDFA.setFinalState(newStateSet, true);
      }

      // اگر گروه شامل start state باشد
      if (group.any((index) => stateList[index] == _startState)) {
        minimizedDFA.setStartState(newStateSet);
      }
    }

    // کپی alphabet
    minimizedDFA._alphabet = Set<String>.from(_alphabet);

    // ساخت transitions جدید
    for (final group in groups) {
      final representativeIndex = group.first;
      final representativeState = stateList[representativeIndex];
      final fromStateSet = groupToStateSet[group]!;

      final stateTransitions = _transitions[representativeState];
      if (stateTransitions != null) {
        for (final symbol in stateTransitions.keys) {
          final targetState = stateTransitions[symbol]!;
          final targetIndex = stateList.indexOf(targetState);

          // پیدا کردن گروه مقصد
          final targetGroup = groups.firstWhere((g) => g.contains(targetIndex));
          final toStateSet = groupToStateSet[targetGroup]!;

          minimizedDFA.addTransition(fromStateSet, symbol, toStateSet);
        }
      }
    }

    return minimizedDFA;
  }

  /// تکمیل DFA (افزودن dead state در صورت نیاز)
  DFA complete() {
    if (isComplete) return copyWith();

    final completeDFA = copyWith();
    StateSet? deadState;

    // بررسی نیاز به dead state
    bool needsDeadState = false;
    for (final state in _states) {
      final stateTransitions = _transitions[state] ?? <String, StateSet>{};
      for (final symbol in _alphabet) {
        if (!stateTransitions.containsKey(symbol)) {
          needsDeadState = true;
          break;
        }
      }
      if (needsDeadState) break;
    }

    if (!needsDeadState) return completeDFA;

    // ساخت dead state
    final deadStateModel = StateModel(name: 'dead', isFinal: false);
    deadState = StateSet({deadStateModel});
    completeDFA.addState(deadState, customName: 'dead');

    // افزودن transitions مفقود
    for (final state in completeDFA._states) {
      final stateTransitions = completeDFA._transitions[state] ?? <String, StateSet>{};
      for (final symbol in completeDFA._alphabet) {
        if (!stateTransitions.containsKey(symbol)) {
          completeDFA.addTransition(state, symbol, deadState);
        }
      }
    }

    if (deadState != null) {
      for (final symbol in completeDFA._alphabet) {
        completeDFA.addTransition(deadState, symbol, deadState);
      }
    }

    return completeDFA;
  }

  /// تبدیل به complement DFA
  DFA complement() {
    final completeDFA = complete();
    final complementDFA = completeDFA.copyWith();

    // تغییر final states
    final newFinalStates = <StateSet>{};
    for (final state in completeDFA._states) {
      if (!completeDFA._finalStates.contains(state)) {
        newFinalStates.add(state);
      }
    }

    complementDFA._finalStates.clear();
    complementDFA._finalStates.addAll(newFinalStates);

    return complementDFA;
  }

  /// اتحاد دو DFA (Union)
  static DFA union(DFA dfa1, DFA dfa2) {
    // ساخت alphabet مشترک
    final unionAlphabet = <String>{}
      ..addAll(dfa1._alphabet)
      ..addAll(dfa2._alphabet);

    final unionDFA = DFA();
    unionDFA._alphabet = unionAlphabet;

    // نقشه state های ترکیبی
    final combinedStates = <String, StateSet>{};

    // ساخت همه ترکیبات ممکن states
    for (final state1 in dfa1._states) {
      for (final state2 in dfa2._states) {
        final combinedStateModels = <StateModel>{}
          ..addAll(state1.states)
          ..addAll(state2.states);
        final combinedStateSet = StateSet(combinedStateModels);

        final name1 = dfa1.getStateName(state1);
        final name2 = dfa2.getStateName(state2);
        final combinedName = '($name1,$name2)';

        combinedStates[combinedName] = combinedStateSet;
        unionDFA.addState(combinedStateSet, customName: combinedName);

        // اگر یکی از states final باشد، combined state هم final است
        if (dfa1._finalStates.contains(state1) || dfa2._finalStates.contains(state2)) {
          unionDFA.setFinalState(combinedStateSet, true);
        }

        // اگر هر دو start state باشند، combined state هم start است
        if (state1 == dfa1._startState && state2 == dfa2._startState) {
          unionDFA.setStartState(combinedStateSet);
        }
      }
    }

    // ساخت transitions
    for (final name in combinedStates.keys) {
      final combinedState = combinedStates[name]!;
      final nameParts = name.substring(1, name.length - 1).split(',');
      final name1 = nameParts[0];
      final name2 = nameParts[1];

      final state1 = dfa1._states.firstWhere((s) => dfa1.getStateName(s) == name1);
      final state2 = dfa2._states.firstWhere((s) => dfa2.getStateName(s) == name2);

      for (final symbol in unionAlphabet) {
        final next1 = dfa1.getTransition(state1, symbol);
        final next2 = dfa2.getTransition(state2, symbol);

        if (next1 != null && next2 != null) {
          final nextName1 = dfa1.getStateName(next1);
          final nextName2 = dfa2.getStateName(next2);
          final nextCombinedName = '($nextName1,$nextName2)';
          final nextCombinedState = combinedStates[nextCombinedName]!;

          unionDFA.addTransition(combinedState, symbol, nextCombinedState);
        }
      }
    }

    return unionDFA;
  }

  /// اشتراک دو DFA (Intersection)
  static DFA intersection(DFA dfa1, DFA dfa2) {
    final intersectionAlphabet = <String>{}
      ..addAll(dfa1._alphabet)
      ..addAll(dfa2._alphabet);

    final intersectionDFA = DFA();
    intersectionDFA._alphabet = intersectionAlphabet;

    final combinedStates = <String, StateSet>{};

    for (final state1 in dfa1._states) {
      for (final state2 in dfa2._states) {
        final combinedStateModels = <StateModel>{}
          ..addAll(state1.states)
          ..addAll(state2.states);
        final combinedStateSet = StateSet(combinedStateModels);

        final name1 = dfa1.getStateName(state1);
        final name2 = dfa2.getStateName(state2);
        final combinedName = '($name1,$name2)';

        combinedStates[combinedName] = combinedStateSet;
        intersectionDFA.addState(combinedStateSet, customName: combinedName);

        if (dfa1._finalStates.contains(state1) && dfa2._finalStates.contains(state2)) {
          intersectionDFA.setFinalState(combinedStateSet, true);
        }

        if (state1 == dfa1._startState && state2 == dfa2._startState) {
          intersectionDFA.setStartState(combinedStateSet);
        }
      }
    }

    for (final name in combinedStates.keys) {
      final combinedState = combinedStates[name]!;
      final nameParts = name.substring(1, name.length - 1).split(',');
      final name1 = nameParts[0];
      final name2 = nameParts[1];

      final state1 = dfa1._states.firstWhere((s) => dfa1.getStateName(s) == name1);
      final state2 = dfa2._states.firstWhere((s) => dfa2.getStateName(s) == name2);

      for (final symbol in intersectionAlphabet) {
        final next1 = dfa1.getTransition(state1, symbol);
        final next2 = dfa2.getTransition(state2, symbol);

        if (next1 != null && next2 != null) {
          final nextName1 = dfa1.getStateName(next1);
          final nextName2 = dfa2.getStateName(next2);
          final nextCombinedName = '($nextName1,$nextName2)';
          final nextCombinedState = combinedStates[nextCombinedName]!;

          intersectionDFA.addTransition(combinedState, symbol, nextCombinedState);
        }
      }
    }

    return intersectionDFA;
  }

  /// بررسی تساوی دو DFA
  static bool areEquivalent(DFA dfa1, DFA dfa2) {

    final diff1 = intersection(dfa1, dfa2.complement());
    final diff2 = intersection(dfa1.complement(), dfa2);

    return diff1.isEmpty && diff2.isEmpty;
  }

  bool get isEmpty {
    if (_startState == null || _finalStates.isEmpty) return true;

    final visited = <StateSet>{};
    final queue = <StateSet>[_startState!];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (_finalStates.contains(current)) return false;

      if (visited.contains(current)) continue;
      visited.add(current);

      final currentTransitions = _transitions[current];
      if (currentTransitions != null) {
        for (final nextState in currentTransitions.values) {
          if (!visited.contains(nextState)) {
            queue.add(nextState);
          }
        }
      }
    }

    return true;
  }

  /// تعداد states
  int get stateCount => _states.length;

  /// تعداد transitions
  int get transitionCount {
    int count = 0;
    for (final stateTransitions in _transitions.values) {
      count += stateTransitions.length;
    }
    return count;
  }

  bool get isComplete {
    for (final state in _states) {
      final stateTransitions = _transitions[state] ?? <String, StateSet>{};
      for (final symbol in _alphabet) {
        if (!stateTransitions.containsKey(symbol)) {
          return false;
        }
      }
    }
    return true;
  }

  bool get isConnected {
    return _findReachableStates().length == _states.length;
  }

  /// تولید گزارش کامل
  String generateReport() {
    final buffer = StringBuffer();
    final validation = validate();

    buffer.writeln('========== DFA Analysis Report ==========');
    buffer.writeln('Generated at: ${DateTime.now()}');
    buffer.writeln();

    // اطلاعات کلی
    buffer.writeln('=== General Information ===');
    buffer.writeln('States: ${_states.length}');
    buffer.writeln('Alphabet: $_alphabet (${_alphabet.length} symbols)');
    buffer.writeln('Transitions: $transitionCount');
    buffer.writeln('Start State: ${_startState != null ? getStateName(_startState!) : 'None'}');
    buffer.writeln('Final States: ${_finalStates.map(getStateName).toList()} (${_finalStates.length})');
    buffer.writeln();

    // خصوصیات
    buffer.writeln('=== Properties ===');
    buffer.writeln('Complete: ${isComplete ? 'Yes' : 'No'}');
    buffer.writeln('Connected: ${isConnected ? 'Yes' : 'No'}');
    buffer.writeln('Minimal: ${isMinimal() ? 'Yes' : 'No'}');
    buffer.writeln('Empty Language: ${isEmpty ? 'Yes' : 'No'}');
    buffer.writeln();

    // اعتبارسنجی
    buffer.writeln('=== Validation ===');
    buffer.writeln('Status: ${validation.isValid ? 'VALID' : 'INVALID'}');

    if (validation.errors.isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in validation.errors) {
        buffer.writeln('  • $error');
      }
    }

    if (validation.warnings.isNotEmpty) {
      buffer.writeln('Warnings:');
      for (final warning in validation.warnings) {
        buffer.writeln('  • $warning');
      }
    }
    buffer.writeln();

    // جدول انتقالات
    if (_states.isNotEmpty && _alphabet.isNotEmpty) {
      buffer.writeln('=== Transition Table ===');
      final table = getTransitionTable();
      final sortedStates = _states.map(getStateName).toList()..sort();
      final sortedAlphabet = _alphabet.toList()..sort();

      // هدر جدول
      buffer.write('State\\Symbol\t');
      for (final symbol in sortedAlphabet) {
        buffer.write('$symbol\t');
      }
      buffer.writeln();

      for (final stateName in sortedStates) {
        final isStart = _startState != null && getStateName(_startState!) == stateName;
        final isFinal = _finalStates.any((s) => getStateName(s) == stateName);

        String stateDisplay = stateName;
        if (isStart && isFinal) {
          stateDisplay = '→*$stateName';
        } else if (isStart) {
          stateDisplay = '→$stateName';
        } else if (isFinal) {
          stateDisplay = '*$stateName';
        }

        buffer.write('$stateDisplay\t');
        for (final symbol in sortedAlphabet) {
          final destination = table[stateName]?[symbol] ?? '∅';
          buffer.write('$destination\t');
        }
        buffer.writeln();
      }
      buffer.writeln();
    }

    if (!isEmpty) {
      buffer.writeln('=== Sample Accepted Strings ===');
      final samples = generateAcceptedStrings(3);
      if (samples.isEmpty) {
        buffer.writeln('No accepted strings found (up to length 3)');
      } else {
        for (int i = 0; i < samples.length && i < 10; i++) {
          final str = samples[i];
          buffer.writeln('  "${str.isEmpty ? 'ε' : str}"');
        }
        if (samples.length > 10) {
          buffer.writeln('  ... and ${samples.length - 10} more');
        }
      }
    }

    buffer.writeln('==========================================');
    return buffer.toString();
  }

  @override
  String toString() {
    return 'DFA(states: ${_states.length}, alphabet: $_alphabet, complete: $isComplete, valid: ${validate().isValid})';
  }

  String toDetailedString() {
    return generateReport();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DFA) return false;

    return _states.length == other._states.length &&
        _alphabet.length == other._alphabet.length &&
        _transitions.length == other._transitions.length &&
        _finalStates.length == other._finalStates.length &&
        areEquivalent(this, other);
  }

  @override
  int get hashCode {
    return Object.hash(
      _states.length,
      _alphabet.length,
      _transitions.length,
      _finalStates.length,
    );
  }

  AutomatonMetrics getMetrics() {
    return AutomatonMetrics(
      stateCount: stateCount,
      alphabetSize: alphabet.length,
      transitionCount: transitionCount,
      density: stateCount > 0 && alphabet.isNotEmpty ? transitionCount / (stateCount * alphabet.length) : 0.0,
      finalStateRatio: stateCount > 0 ? finalStates.length / stateCount : 0.0,
    );
  }
}