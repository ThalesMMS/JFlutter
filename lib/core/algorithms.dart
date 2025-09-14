import 'dart:collection';

import 'automaton.dart';
import 'algo_log.dart';
import 'dfa_algorithms.dart';

// Utilities
String _k(String s, String sym) => '$s|$sym';

/// Helper function to auto-center automaton results
Automaton _autoCenter(Automaton automaton) {
  // Auto-centering is handled at the entity level, not the core level
  return automaton;
}

Set<String> _get(Automaton a, String s, String sym) => a.transitions[_k(s, sym)]?.toSet() ?? <String>{};

/// Checks if a transition is an epsilon/lambda transition
bool isEpsilonTransition(String transitionKey) {
  final parts = transitionKey.split('|');
  if (parts.length != 2) return false;
  final symbol = parts[1];
  return symbol == 'λ' || symbol == 'ε' || symbol == '';
}

/// Gets all epsilon transitions from a state
Set<String> getEpsilonTransitions(Automaton a, String state) {
  final epsilonStates = <String>{};
  for (final key in a.transitions.keys) {
    if (key.startsWith('$state|') && isEpsilonTransition(key)) {
      epsilonStates.addAll(a.transitions[key] ?? []);
    }
  }
  return epsilonStates;
}

// ε-closure for NFA-λ (improved version)
Set<String> epsilonClosure(Automaton a, Set<String> states) {
  final stack = List<String>.from(states);
  final seen = <String>{...states};
  while (stack.isNotEmpty) {
    final s = stack.removeLast();
    final epsilonStates = getEpsilonTransitions(a, s);
    for (final d in epsilonStates) {
      if (seen.add(d)) stack.add(d);
    }
  }
  return seen;
}

// NFA-λ -> NFA
Automaton nfaLambdaToNfa(Automaton a) {
  if (!a.hasLambda) return a.clone();
  AlgoLog.startAlgo('removeLambda', 'AFNλ → AFN');
  final out = a.clone();
  // For each state and symbol (excl. λ), connect via closure
  out.transitions.clear();
  for (final s in a.stateIds) {
    final closureS = epsilonClosure(a, {s});
    AlgoLog.add('ε-fecho($s) = {${closureS.join(', ')}}');
    AlgoLog.step('removeLambda', 'closure', data: {
      'state': s,
      'closure': closureS.toList(),
    }, highlight: {s, ...closureS});
    for (final sym in a.alphabet.where((e) => !isEpsilonTransition('dummy|$e'))) {
      final dests = <String>{};
      for (final q in closureS) {
        for (final d in _get(a, q, sym)) {
          dests.addAll(epsilonClosure(a, {d}));
        }
      }
      if (dests.isNotEmpty) {
        out.transitions[_k(s, sym)] = dests.toList();
        AlgoLog.add('($s, $sym) → {${dests.join(', ')}}');
        AlgoLog.step('removeLambda', 'transition', data: {
          'from': s,
          'sym': sym,
          'to': dests.toList(),
        }, highlight: {s, ...dests});
      }
    }
  }
  return _autoCenter(out);
}

// NFA -> DFA (subset construction)
Automaton nfaToDfa(Automaton nfa) {
  AlgoLog.startAlgo('nfaToDfa', 'AFN → AFD');
  
  // Validate input
  if (nfa.states.isEmpty) {
    throw ArgumentError('Cannot convert empty automaton to DFA');
  }
  if (nfa.initialId == null) {
    throw ArgumentError('NFA must have an initial state');
  }
  
  final a = nfa.hasLambda ? nfaLambdaToNfa(nfa) : nfa.clone();
  final sigma = a.alphabet.where((s) => !isEpsilonTransition('dummy|$s')).toSet();
  final startSet = a.initialId == null ? <String>{} : epsilonClosure(a, {a.initialId!});
  String nameOf(Set<String> set) {
    final sortedStates = set.toList()..sort();
    if (sortedStates.isEmpty) return '∅';
    if (sortedStates.length == 1) return sortedStates.first;
    if (sortedStates.length <= 3) return '{${sortedStates.join(',')}}';
    return '{${sortedStates.take(2).join(',')}...${sortedStates.last}}';
  }

  final newStates = <Set<String>>[];
  final queue = Queue<Set<String>>();
  final seen = <String, Set<String>>{}; // name -> set
  void enqueue(Set<String> s) {
    final key = nameOf(s);
    if (!seen.containsKey(key)) {
      seen[key] = s;
      newStates.add(s);
      queue.add(s);
      AlgoLog.step('nfaToDfa', 'newState', data: {
        'id': key,
        'subset': s.toList(),
      });
    }
  }

  enqueue(startSet);
  final transitions = <String, List<String>>{};

  while (queue.isNotEmpty) {
    final set = queue.removeFirst();
    for (final sym in sigma) {
      final move = <String>{};
      for (final q in set) {
        move.addAll(_get(a, q, sym));
      }
      if (move.isEmpty) continue;
      final dest = move;
      enqueue(dest);
      transitions[_k(nameOf(set), sym)] = [nameOf(dest)];
      AlgoLog.add('(${nameOf(set)}, $sym) → ${nameOf(dest)}');
      AlgoLog.step('nfaToDfa', 'transition', data: {
        'from': nameOf(set),
        'sym': sym,
        'to': nameOf(dest),
      }, highlight: {nameOf(set), nameOf(dest)});
    }
  }

  final states = newStates
      .map((set) => StateNode(
            id: nameOf(set),
            name: nameOf(set),
            x: 0,
            y: 0,
            isInitial: set.equals(startSet),
            isFinal: set.any((id) => a.getState(id)?.isFinal == true),
          ))
      .toList();

  final result = Automaton(
    alphabet: sigma,
    states: states,
    transitions: transitions,
    initialId: nameOf(startSet),
    nextId: states.length,
  );
  
  return _autoCenter(result);
}

extension _SetEq on Set<String> {
  bool equals(Set<String> other) => length == other.length && containsAll(other);
}

// Ensure DFA completeness by adding a trap state where missing transitions.
Automaton completeDfa(Automaton dfa) {
  AlgoLog.startAlgo('completeDfa', 'Completar AFD');
  final a = dfa.clone();
  final sigma = a.alphabet.toList();
  bool missing(String s, String sym) => !a.transitions.containsKey(_k(s, sym));

  var needTrap = false;
  var missingCount = 0;
  for (final s in a.stateIds) {
    for (final sym in sigma) {
      if (missing(s, sym)) { needTrap = true; missingCount++; }
    }
  }
  if (!needTrap) {
    AlgoLog.step('completeDfa', 'final', data: {'completed': false});
    return a;
  }

  const trapId = '⊥';
  if (!a.stateIds.contains(trapId)) {
    a.states.add(StateNode(id: trapId, name: trapId, x: 0, y: 0, isInitial: false, isFinal: false));
    AlgoLog.step('completeDfa', 'addTrap', data: {'id': trapId});
  }
  for (final s in a.stateIds) {
    for (final sym in sigma) {
      if (missing(s, sym)) {
        a.transitions[_k(s, sym)] = [trapId];
      }
    }
  }
  for (final sym in sigma) {
    a.transitions[_k(trapId, sym)] = [trapId];
  }
  AlgoLog.step('completeDfa', 'addMissing', data: {'count': missingCount});
  AlgoLog.step('completeDfa', 'final', data: {'completed': true});
  return _autoCenter(a);
}

// Complement (assumes DFA). Completes before flipping finals.
Automaton complementDfa(Automaton dfa) {
  AlgoLog.startAlgo('complement', 'Complemento do AFD');
  final a = completeDfa(dfa);
  final states = a.states
      .map((s) => s.copyWith(isFinal: !s.isFinal))
      .toList();
  final flipped = states.where((s) => s.isFinal).map((s) => s.id).toList();
  AlgoLog.step('complement', 'flipFinals', data: {'finals': flipped});
  final result = Automaton(
    alphabet: a.alphabet,
    states: states,
    transitions: a.transitions,
    initialId: a.initialId,
    nextId: a.nextId,
  );
  
  return _autoCenter(result);
}

// Product of DFAs.
Automaton productDfa(Automaton a, Automaton b) {
  AlgoLog.startAlgo('productDfa', 'Produto de AFDs');
  final sigma = {...a.alphabet, ...b.alphabet};
  Automaton ad = completeDfa(a).clone();
  Automaton bd = completeDfa(b).clone();

  String pid(String x, String y) => '($x,$y)';

  final states = <StateNode>[];
  final trans = <String, List<String>>{};

  final queue = Queue<MapEntry<String, String>>();
  final seen = <String>{};
  final start = MapEntry(ad.initialId ?? '', bd.initialId ?? '');
  queue.add(start);
  seen.add(pid(start.key, start.value));
  AlgoLog.step('productDfa', 'newState', data: {'id': pid(start.key, start.value)});

  while (queue.isNotEmpty) {
    final pair = queue.removeFirst();
    final id = pid(pair.key, pair.value);
    final isInit = id == pid(start.key, start.value);
    final isFinal = (ad.getState(pair.key)?.isFinal ?? false) && (bd.getState(pair.value)?.isFinal ?? false);
    states.add(StateNode(id: id, name: id, x: 0, y: 0, isInitial: isInit, isFinal: isFinal));
    for (final sym in sigma) {
      final d1 = (ad.transitions[_k(pair.key, sym)] ?? const ['⊥']).first;
      final d2 = (bd.transitions[_k(pair.value, sym)] ?? const ['⊥']).first;
      final to = pid(d1, d2);
      trans[_k(id, sym)] = [to];
      AlgoLog.step('productDfa', 'transition', data: {
        'from': id,
        'sym': sym,
        'to': to,
      }, highlight: {id, to});
      if (seen.add(to)) {
        queue.add(MapEntry(d1, d2));
        AlgoLog.step('productDfa', 'newState', data: {'id': to});
      }
    }
  }
  return Automaton(
    alphabet: sigma,
    states: states,
    transitions: trans,
    initialId: pid(start.key, start.value),
    nextId: states.length,
  );
}

// Set-ops via product and final-state predicate
Automaton unionDfa(Automaton a, Automaton b) {
  final p = productDfa(a, b);
  final states = p.states
      .map((s) {
        final parts = s.id.substring(1, s.id.length - 1).split(',');
        final x = parts[0];
        final y = parts[1];
        final xf = completeDfa(a).getState(x)?.isFinal ?? false;
        final yf = completeDfa(b).getState(y)?.isFinal ?? false;
        return s.copyWith(isFinal: xf || yf);
      })
      .toList();
  final out = Automaton(
    alphabet: p.alphabet,
    states: states,
    transitions: p.transitions,
    initialId: p.initialId,
    nextId: p.nextId,
  );
  AlgoLog.step('union', 'final', data: {'states': out.states.length});
  return _autoCenter(out);
}

Automaton intersectionDfa(Automaton a, Automaton b) => productDfa(a, b);

Automaton differenceDfa(Automaton a, Automaton b) {
  // A \ B == A ∩ complement(B)
  final out = intersectionDfa(a, complementDfa(b));
  AlgoLog.step('difference', 'final', data: {'states': out.states.length});
  return _autoCenter(out);
}

// Equivalence: check if symmetric difference is empty (via product search)
bool equivalentDfas(Automaton a, Automaton b) {
  AlgoLog.startAlgo('equivalence', 'Equivalência de AFDs');
  final ad = completeDfa(a);
  final bd = completeDfa(b);
  final sigma = {...ad.alphabet, ...bd.alphabet};
  final queue = Queue<MapEntry<String, String>>();
  final seen = <String>{};
  String pid(String x, String y) => '($x,$y)';
  bool isAccept(String x, String y) {
    final xf = ad.getState(x)?.isFinal ?? false;
    final yf = bd.getState(y)?.isFinal ?? false;
    return (xf && !yf) || (!xf && yf);
  }

  final start = MapEntry(ad.initialId ?? '', bd.initialId ?? '');
  queue.add(start);
  seen.add(pid(start.key, start.value));
  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    if (isAccept(cur.key, cur.value)) {
      AlgoLog.step('equivalence', 'diffFound', data: {'pair': pid(cur.key, cur.value)}, highlight: {pid(cur.key, cur.value)});
      return false; // found a counterexample
    }
    for (final sym in sigma) {
      final d1 = (ad.transitions[_k(cur.key, sym)] ?? const ['⊥']).first;
      final d2 = (bd.transitions[_k(cur.value, sym)] ?? const ['⊥']).first;
      final id = pid(d1, d2);
      if (seen.add(id)) queue.add(MapEntry(d1, d2));
    }
  }
  AlgoLog.step('equivalence', 'final', data: {'equal': true});
  return true;
}

/// Checks if an automaton is a valid DFA.
/// A valid DFA has exactly one transition for each symbol in the alphabet
/// from each state, and no lambda transitions.
bool isDfa(Automaton a) {
  if (a.hasLambda) return false;
  // Deterministic: for each (state, symbol) there is at most one destination
  for (final state in a.states) {
    for (final sym in a.alphabet) {
      final key = '${state.id}|$sym';
      final dests = a.transitions[key] ?? const <String>[];
      if (dests.length > 1) return false; // nondeterministic
    }
  }
  return true;
}

/// The result of DFA minimization, containing the minimized DFA and the log.
class MinimizationResult {
  final Automaton minimized;
  final List<String> log;

  MinimizationResult({required this.minimized, required this.log});
}

/// The result of NFA to DFA conversion, containing the converted DFA and the log.
class NfaToDfaResult {
  final Automaton dfa;
  final List<String> log;

  NfaToDfaResult({required this.dfa, required this.log});
}

/// Minimizes a DFA if it's a valid DFA, otherwise returns null.
/// Returns the minimized DFA and a log of the minimization process.
MinimizationResult? minimizeDfaIfValid(Automaton a) {
  if (!isDfa(a)) {
    return null;
  }
  
  AlgoLog.startAlgo('minimizeDfa', 'Minimização de AFD');
  
  // Create a copy to work with
  final dfa = a.clone();
  
  // Run the minimization algorithm
  final minimized = minimizeDfa(dfa);
  
  return MinimizationResult(
    minimized: minimized,
    log: List<String>.from(AlgoLog.lines.value),
  );
}

/// Converts an NFA to an equivalent DFA if the input is a valid NFA.
/// Returns null if the input is not a valid NFA.
NfaToDfaResult? nfaToDfaIfValid(Automaton a) {
  // Check if the automaton has any epsilon transitions or non-deterministic transitions
  bool hasEpsilonTransitions = a.transitions.keys.any((key) => key.endsWith('|ε'));
  
  // Check for non-deterministic transitions (multiple transitions for same state and symbol)
  bool isDeterministic = true;
  final transitionMap = <String, Set<String>>{};
  
  for (final entry in a.transitions.entries) {
    final parts = entry.key.split('|');
    if (parts.length != 2) continue;
    
    final stateSymbol = '${parts[0]}|${parts[1]}';
    if (transitionMap.containsKey(stateSymbol)) {
      isDeterministic = false;
      break;
    }
    transitionMap[stateSymbol] = entry.value.toSet();
  }
  
  // If it's already deterministic and has no epsilon transitions, no conversion needed
  if (isDeterministic && !hasEpsilonTransitions) {
    return null;
  }
  
  AlgoLog.startAlgo('nfaToDfa', 'Conversão de NFA para DFA');
  
  // Create a copy to work with
  final nfa = a.clone();
  
  // Run the conversion algorithm
  final dfa = nfaToDfa(nfa);
  
  return NfaToDfaResult(
    dfa: dfa,
    log: List<String>.from(AlgoLog.lines.value),
  );
}

// Run word
class RunResult {
  RunResult({required this.accepted, required this.visited});
  final bool accepted;
  final List<Set<String>> visited; // per step set of active states
}

RunResult runWord(Automaton a, String word) {
  if (a.isDfa && !a.hasLambda) {
    String? cur = a.initialId;
    final visited = <Set<String>>[{if (cur != null) cur}..removeWhere((e) => e.isEmpty)];
    for (final ch in word.split('')) {
      if (cur == null) break;
      cur = (a.transitions[_k(cur, ch)] ?? const <String>[])
          .cast<String?>()
          .firstOrNull;
      visited.add({if (cur != null) cur});
    }
    final acc = a.getState(cur ?? '')?.isFinal ?? false;
    return RunResult(accepted: acc, visited: visited);
  }
  // NFA/ε-NFA
  final nfa = a.hasLambda ? nfaLambdaToNfa(a) : a;
  var active = nfa.initialId == null ? <String>{} : {nfa.initialId!};
  final visited = <Set<String>>[active];
  for (final ch in word.split('')) {
    final next = <String>{};
    for (final s in active) {
      next.addAll(_get(nfa, s, ch));
    }
    active = next;
    visited.add(active);
  }
  final acc = active.any((s) => nfa.getState(s)?.isFinal == true);
  return RunResult(accepted: acc, visited: visited);
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// Prefix closure: accept all prefixes of accepted words.
// Mark as final any state that is reachable from initial AND can reach a final.
Automaton prefixClosureDfa(Automaton dfa) {
  AlgoLog.startAlgo('prefixClosure', 'Fecho por Prefixos');
  final a = completeDfa(dfa);
  // Reachable from initial
  final fromInit = <String>{};
  void dfsFrom(String s) {
    if (!fromInit.add(s)) return;
    for (final sym in a.alphabet) {
      final d = (a.transitions[_k(s, sym)] ?? const <String>[]).firstOrNull;
      if (d != null) dfsFrom(d);
    }
  }
  if (a.initialId != null) dfsFrom(a.initialId!);

  // Can reach a final (reverse graph)
  final toFinal = <String>{};
  final reverse = <String, List<String>>{};
  for (final e in a.transitions.entries) {
    final parts = e.key.split('|');
    final src = parts[0];
    for (final d in e.value) {
      (reverse[d] ??= []).add(src);
    }
  }
  final finals = a.states.where((s) => s.isFinal).map((s) => s.id).toList();
  final queue = List<String>.from(finals);
  while (queue.isNotEmpty) {
    final x = queue.removeLast();
    if (!toFinal.add(x)) continue;
    for (final p in reverse[x] ?? const <String>[]) {
      if (!toFinal.contains(p)) queue.add(p);
    }
  }

  final states = a.states
      .map((s) => s.copyWith(isFinal: fromInit.contains(s.id) && toFinal.contains(s.id)))
      .toList();

  final result = Automaton(
    alphabet: a.alphabet,
    states: states,
    transitions: a.transitions,
    initialId: a.initialId,
    nextId: a.nextId,
  );
  
  return _autoCenter(result);
}

// Suffix closure: union of languages starting from any state reachable from initial.
// Build an NFA with a new start that ε-transitions to all states reachable
// from the original initial; then determinize.
Automaton suffixClosureDfa(Automaton dfa) {
  AlgoLog.startAlgo('suffixClosure', 'Fecho por Sufixos');
  final a = completeDfa(dfa);
  // Compute set of states reachable from initial (ignoring symbols)
  final reachable = <String>{};
  void dfs(String s) {
    if (!reachable.add(s)) return;
    for (final sym in a.alphabet) {
      final d = (a.transitions[_k(s, sym)] ?? const <String>[]).firstOrNull;
      if (d != null) dfs(d);
    }
  }
  if (a.initialId != null) dfs(a.initialId!);

  // Build NFA with a fresh start S and λ to all reachable states
  const start = '__S';
  final states = [
    ...a.states,
    StateNode(id: start, name: start, x: 0, y: 0, isInitial: true, isFinal: false),
  ];
  final trans = Map<String, List<String>>.from(a.transitions);
  trans[_k(start, 'λ')] = reachable.toList();
  final nfa = Automaton(
    alphabet: {...a.alphabet, 'λ'},
    states: states,
    transitions: trans,
    initialId: start,
    nextId: a.nextId + 1,
  );
  final out = nfaToDfa(nfa);
  AlgoLog.step('suffixClosure', 'final', data: {'states': out.states.length});
  return _autoCenter(out);
}

// ============ DFA → Regex (state elimination) ============
String dfaToRegex(Automaton dfa, {bool allowLambda = false}) {
  if (dfa.initialId == null) return '';
  final finals = dfa.states.where((s) => s.isFinal).toList();
  if (finals.isEmpty) return '';
  AlgoLog.startAlgo('dfaToRegex', 'AFD → ER');
  final states = dfa.states.map((s) => s.id).toList();
  final idx = {for (var i = 0; i < states.length; i++) states[i]: i};
  final n = states.length;
  String? union(String? a, String? b) {
    if (a == null || a.isEmpty) return b;
    if (b == null || b.isEmpty) return a;
    if (a == b) return a;
    final parts = {...a.split(' ∪ '), ...b.split(' ∪ ')};
    return parts.join(' ∪ ');
  }
  String? concat(String? a, String? b) {
    if (a == null || a.isEmpty) return null;
    if (b == null || b.isEmpty) return null;
    if (a == 'λ') return b;
    if (b == 'λ') return a;
    String par(String x) {
      final simple = RegExp(r'^[A-Za-z0-9]$').hasMatch(x) || x == 'λ' || (x.endsWith('*'));
      return simple ? x : '($x)';
    }
    return '${par(a)}${par(b)}';
  }
String star(String? x) {
  if (x == null || x.isEmpty || x == 'λ') return 'λ';
  if (x.endsWith('*')) return x;
  String par(String t) => RegExp(r'^[A-Za-z0-9]$').hasMatch(t) ? t : '($t)';
  return '${par(x)}*';
}

  // Build adjacency regex matrix R
  final R = List.generate(n, (_) => List<String?>.filled(n, null));
  for (final e in dfa.transitions.entries) {
    final parts = e.key.split('|');
    final src = parts[0];
    final sym = parts[1];
    final to = e.value.firstOrNull;
    if (to == null) continue;
    final i = idx[src]!;
    final j = idx[to]!;
    R[i][j] = union(R[i][j], sym);
  }
  final init = idx[dfa.initialId]!;
  final finalsIdx = finals.map((s) => idx[s.id]!).toList();

  // Augment with super start/end
  final N = n + 2, Saux = n, Faux = n + 1;
  final G = List.generate(N, (_) => List<String?>.filled(N, null));
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < n; j++) {
      G[i][j] = R[i][j];
    }
  }
  G[Saux][init] = 'λ';
  for (final j in finalsIdx) {
    G[j][Faux] = union(G[j][Faux], 'λ');
  }

  // Eliminate states 0..n-1
  for (var k = 0; k < N; k++) {
    if (k == Saux || k == Faux) continue;
    final Rkk = G[k][k];
    final starK = star(Rkk);
    AlgoLog.add('Eliminando ${states[k]}');
    if (k < n) {
      AlgoLog.step('dfaToRegex', 'eliminate', data: {
        'state': states[k],
      }, highlight: {states[k]});
    }
    for (var i = 0; i < N; i++) {
      if (i == k) continue;
      final Rik = G[i][k];
      if (Rik == null) continue;
      for (var j = 0; j < N; j++) {
        if (j == k) continue;
        final Rkj = G[k][j];
        if (Rkj == null) continue;
        final via = concat(concat(Rik, starK), Rkj);
        G[i][j] = union(G[i][j], via);
        final fromName = i == Saux ? 'I' : (i < n ? states[i] : '');
        final toName = j == Faux ? 'F' : (j < n ? states[j] : '');
        AlgoLog.add('$fromName → $toName via ${states[k]}: ${via ?? ''}');
        final hl = <String>{};
        if (i < n) hl.add(states[i]);
        if (j < n) hl.add(states[j]);
        if (k < n) hl.add(states[k]);
        AlgoLog.step('dfaToRegex', 'transition', data: {
          'from': i < n ? states[i] : null,
          'fromName': fromName,
          'to': j < n ? states[j] : null,
          'toName': toName,
          'via': states[k],
          'regex': via ?? '',
        }, highlight: hl);
      }
    }
    for (var i = 0; i < N; i++) {
      G[i][k] = null;
      G[k][i] = null;
    }
  }

  var out = G[Saux][Faux] ?? '';
  AlgoLog.add('ER = $out');
  AlgoLog.step('dfaToRegex', 'final', data: {'regex': out});
  // Normalize and optionally drop λ when safe
  out = _simplifyRegex(out);
  if (!allowLambda) {
    final dropped = _dropEpsilonIfSafe(out);
    if (dropped == null) {
      AlgoLog.add('Aviso: A ER exige λ para representar exatamente a linguagem. Saída omitida.');
      return '';
    }
    out = dropped;
  }
  if (!_onlyAllowedTokens(out)) {
    AlgoLog.add('Aviso: tokens inesperados na ER; ver normalização.');
  }
  return out;
}

// ============ NFA helpers: union, concat, star (λ-NFA friendly) ============
Automaton nfaUnion(Automaton a, Automaton b) {
  final alpha = {...a.alphabet, ...b.alphabet, 'λ'};
  final states = <StateNode>[];
  final trans = <String, List<String>>{};
  final mapA = <String, String>{};
  final mapB = <String, String>{};
  int id = 0;
  String nid() => 'q${id++}';
  void clone(Automaton src, Map<String, String> map) {
    for (final s in src.states) {
      final nid0 = nid();
      states.add(StateNode(id: nid0, name: s.name, x: s.x, y: s.y, isInitial: false, isFinal: s.isFinal));
      map[s.id] = nid0;
    }
    src.transitions.forEach((k, v) {
      final parts = k.split('|');
      final srcId = map[parts[0]];
      final sym = parts[1];
      final arr = v.map((d) => map[d]!).toList();
      trans['$srcId|$sym'] = [...(trans['$srcId|$sym'] ?? const <String>[]), ...arr];
    });
  }
  clone(a, mapA);
  clone(b, mapB);
  final start = nid();
  states.add(StateNode(id: start, name: 'S', x: 60, y: 60, isInitial: true, isFinal: false));
  trans['$start|λ'] = [if (a.initialId != null) mapA[a.initialId!]!, if (b.initialId != null) mapB[b.initialId!]!];
  final result = Automaton(alphabet: alpha, states: states, transitions: trans, initialId: start, nextId: states.length);
  return _autoCenter(result);
}

Automaton nfaConcat(Automaton a, Automaton b) {
  final alpha = {...a.alphabet, ...b.alphabet, 'λ'};
  final states = <StateNode>[];
  final trans = <String, List<String>>{};
  final mapA = <String, String>{};
  final mapB = <String, String>{};
  int id = 0;
  String nid() => 'q${id++}';
  void clone(Automaton src, Map<String, String> map) {
    for (final s in src.states) {
      final nid0 = nid();
      states.add(StateNode(id: nid0, name: s.name, x: s.x, y: s.y, isInitial: false, isFinal: s.isFinal));
      map[s.id] = nid0;
    }
    src.transitions.forEach((k, v) {
      final parts = k.split('|');
      final srcId = map[parts[0]];
      final sym = parts[1];
      final arr = v.map((d) => map[d]!).toList();
      trans['$srcId|$sym'] = [...(trans['$srcId|$sym'] ?? const <String>[]), ...arr];
    });
  }
  clone(a, mapA);
  clone(b, mapB);
  final init = mapA[a.initialId ?? ''] ?? nid();
  if (!states.any((s) => s.id == init)) {
    states.add(StateNode(id: init, name: 'S', x: 60, y: 60, isInitial: true, isFinal: false));
  } else {
    final i = states.indexWhere((s) => s.id == init);
    states[i] = states[i].copyWith(isInitial: true);
  }
  final startB = b.initialId != null ? mapB[b.initialId!] : null;
  for (final s in a.states) {
    if (s.isFinal) {
      final from = mapA[s.id]!;
      final key = '$from|λ';
      trans[key] = [...(trans[key] ?? const <String>[]), if (startB != null) startB];
    }
  }
  for (var i = 0; i < states.length; i++) {
    if (mapA.values.contains(states[i].id)) {
      final orig = a.states.firstWhere((x) => mapA[x.id] == states[i].id);
      if (orig.isFinal) states[i] = states[i].copyWith(isFinal: false);
    }
  }
  final result = Automaton(alphabet: alpha, states: states, transitions: trans, initialId: init, nextId: states.length);
  return _autoCenter(result);
}

Automaton nfaStar(Automaton a) {
  final alpha = {...a.alphabet, 'λ'};
  final states = <StateNode>[];
  final trans = <String, List<String>>{};
  final map = <String, String>{};
  int id = 0;
  String nid() => 'q${id++}';
  for (final s in a.states) {
    final id0 = nid();
    states.add(StateNode(id: id0, name: s.name, x: s.x, y: s.y, isInitial: false, isFinal: s.isFinal));
    map[s.id] = id0;
  }
  a.transitions.forEach((k, v) {
    final parts = k.split('|');
    final srcId = map[parts[0]];
    final sym = parts[1];
    final arr = v.map((d) => map[d]!).toList();
    trans['$srcId|$sym'] = [...(trans['$srcId|$sym'] ?? const <String>[]), ...arr];
  });
  final newInit = nid();
  states.add(StateNode(id: newInit, name: 'S', x: 60, y: 60, isInitial: true, isFinal: true));
  final startOld = a.initialId != null ? map[a.initialId!] : null;
  trans['$newInit|λ'] = [if (startOld != null) startOld];
  for (final s in a.states) {
    if (s.isFinal) {
      final id0 = map[s.id]!;
      final key = '$id0|λ';
      trans[key] = [...(trans[key] ?? const <String>[]), if (startOld != null) startOld, newInit];
    }
  }
  final result = Automaton(alphabet: alpha, states: states, transitions: trans, initialId: newInit, nextId: states.length);
  return _autoCenter(result);
}

// NFA Homomorphism: apply a symbol mapping to transform the automaton
// The homomorphism maps each symbol to a (possibly empty) string of symbols
Automaton nfaHomomorphism(Automaton a, Map<String, String> mapping) {
  AlgoLog.startAlgo('nfaHomomorphism', 'Homomorfismo do AFN');

  // Validate mapping
  for (final sym in a.alphabet) {
    if (sym == 'λ') continue;
    if (!mapping.containsKey(sym)) {
      AlgoLog.add('Aviso: símbolo $sym não tem mapeamento, usando identidade');
      mapping[sym] = sym;
    }
  }

  // Create the result automaton with updated alphabet
  final newAlphabet = <String>{};
  for (final target in mapping.values) {
    if (target.isNotEmpty && target != 'λ') {
      newAlphabet.addAll(target.split(''));
    }
  }
  newAlphabet.add('λ'); // Always include lambda for intermediate transitions

  final states = <StateNode>[];
  final transitions = <String, List<String>>{};
  int stateCounter = 0;

  // Copy all original states
  final stateMap = <String, String>{};
  for (final s in a.states) {
    final newId = s.id;
    stateMap[s.id] = newId;
    states.add(StateNode(
      id: newId,
      name: s.name,
      x: s.x,
      y: s.y,
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    ));
  }

  // Process transitions with homomorphism
  for (final entry in a.transitions.entries) {
    final parts = entry.key.split('|');
    final src = parts[0];
    final sym = parts[1];

    if (sym == 'λ') {
      // Lambda transitions remain unchanged
      transitions[entry.key] = entry.value.toList();
      AlgoLog.add('λ-transição preservada: $src → ${entry.value.join(', ')}');
    } else {
      final mappedString = mapping[sym] ?? sym;

      if (mappedString.isEmpty || mappedString == 'λ') {
        // Symbol maps to empty string - create direct lambda transition
        for (final dst in entry.value) {
          final key = '$src|λ';
          transitions[key] = [...(transitions[key] ?? []), dst];
          AlgoLog.add('$src --$sym→ $dst mapeado para $src --λ→ $dst');
        }
      } else if (mappedString.length == 1) {
        // Symbol maps to single symbol
        for (final dst in entry.value) {
          final key = '$src|$mappedString';
          transitions[key] = [...(transitions[key] ?? []), dst];
          AlgoLog.add('$src --$sym→ $dst mapeado para $src --$mappedString→ $dst');
        }
      } else {
        // Symbol maps to string - create intermediate states
        for (final dst in entry.value) {
          var current = src;
          final symbols = mappedString.split('');

          // Create chain of intermediate states
          for (int i = 0; i < symbols.length - 1; i++) {
            final intermediateId = '__h${stateCounter++}';
            states.add(StateNode(
              id: intermediateId,
              name: 'h$i',
              x: 0,
              y: 0,
              isInitial: false,
              isFinal: false,
            ));

            final key = '$current|${symbols[i]}';
            transitions[key] = [...(transitions[key] ?? []), intermediateId];
            current = intermediateId;
          }

          // Final transition to destination
          final key = '$current|${symbols.last}';
          transitions[key] = [...(transitions[key] ?? []), dst];

          AlgoLog.add('$src --$sym→ $dst mapeado para cadeia: $src --$mappedString→ $dst');
        }
      }
    }
  }

  AlgoLog.step('nfaHomomorphism', 'complete', data: {
    'mapping': mapping,
    'originalAlphabet': a.alphabet.toList(),
    'newAlphabet': newAlphabet.toList(),
    'statesAdded': states.length - a.states.length,
  });

  return Automaton(
    alphabet: newAlphabet,
    states: states,
    transitions: transitions,
    initialId: a.initialId,
    nextId: states.length,
  );
}

// NFA Right Quotient: L/w accepts strings x such that xw is in L
Automaton nfaRightQuotient(Automaton a, String word) {
  AlgoLog.startAlgo('nfaQuotient', 'Quociente à Direita do AFN');
  AlgoLog.add('Calculando L/$word onde L é a linguagem do autômato');

  // For right quotient L/w, we need to find states from which w leads to a final state
  // These become the new final states

  final result = a.clone();

  // Find all states that can reach a final state by reading word
  final newFinals = <String>{};

  for (final state in a.states) {
    // Simulate reading 'word' from this state
    var current = <String>{state.id};

    for (final sym in word.split('')) {
      final next = <String>{};
      for (final s in current) {
        final key = '$s|$sym';
        if (a.transitions.containsKey(key)) {
          next.addAll(a.transitions[key]!);
        }
      }
      current = next;
      if (current.isEmpty) break;
    }

    // Check if any of the reached states is final
    if (current.any((s) => a.getState(s)?.isFinal == true)) {
      newFinals.add(state.id);
      AlgoLog.add('Estado ${state.id} pode alcançar estado final lendo "$word"');
    }
  }

  // Update final states in result
  for (int i = 0; i < result.states.length; i++) {
    result.states[i] = result.states[i].copyWith(
      isFinal: newFinals.contains(result.states[i].id),
    );
  }

  AlgoLog.step('nfaQuotient', 'complete', data: {
    'word': word,
    'originalFinals': a.states.where((s) => s.isFinal).map((s) => s.id).toList(),
    'newFinals': newFinals.toList(),
  });

  return result;
}

// NFA Left Quotient: w\L accepts strings x such that wx is in L
Automaton nfaLeftQuotient(Automaton a, String word) {
  AlgoLog.startAlgo('nfaLeftQuotient', 'Quociente à Esquerda do AFN');
  AlgoLog.add('Calculando $word\\L onde L é a linguagem do autômato');

  // For left quotient w\L, we need to find states reachable from initial by reading w
  // These become the new initial states (we create a new initial with λ-transitions)

  final result = a.clone();

  // Find states reachable from initial state by reading word
  if (a.initialId == null) {
    AlgoLog.add('Autômato sem estado inicial');
    return result;
  }

  var current = <String>{a.initialId!};

  for (final sym in word.split('')) {
    final next = <String>{};
    for (final s in current) {
      final key = '$s|$sym';
      if (a.transitions.containsKey(key)) {
        next.addAll(a.transitions[key]!);
      }
    }
    current = next;
    if (current.isEmpty) {
      AlgoLog.add('Palavra "$word" não pode ser lida a partir do estado inicial');
      // Return empty automaton
      return Automaton(
        alphabet: a.alphabet,
        states: [],
        transitions: {},
        initialId: null,
        nextId: 0,
      );
    }
  }

  AlgoLog.add('Estados alcançáveis após ler "$word": {${current.join(', ')}}');

  // Create new initial state with lambda transitions to reachable states
  const newInitialId = '__qInit';
  result.states.add(StateNode(
    id: newInitialId,
    name: 'qInit',
    x: 60,
    y: 60,
    isInitial: true,
    isFinal: false,
  ));

  // Remove initial flag from all other states
  for (int i = 0; i < result.states.length - 1; i++) {
    result.states[i] = result.states[i].copyWith(isInitial: false);
  }

  // Add lambda transitions from new initial to reachable states
  result.transitions['$newInitialId|λ'] = current.toList();
  result.initialId = newInitialId;

  // Add lambda to alphabet if not present
  result.alphabet.add('λ');

  AlgoLog.step('nfaLeftQuotient', 'complete', data: {
    'word': word,
    'newInitial': newInitialId,
    'reachableStates': current.toList(),
  });

  return result;
}

// NFA Reversal: reverse all transitions and swap initial/final states
Automaton nfaReverse(Automaton a) {
  AlgoLog.startAlgo('nfaReverse', 'Reverso do AFN');

  final alpha = {...a.alphabet, 'λ'};
  final states = <StateNode>[];
  final trans = <String, List<String>>{};

  // Get original final states
  final originalFinals = a.states.where((s) => s.isFinal).toList();

  // If no final states, return empty automaton
  if (originalFinals.isEmpty) {
    AlgoLog.add('Nenhum estado final no autômato original');
    return Automaton(alphabet: alpha, states: [], transitions: {}, initialId: null, nextId: 0);
  }

  // Create a new initial state that will have λ-transitions to all original final states
  final newInitialId = originalFinals.length == 1 ? originalFinals.first.id : '__init';

  // Copy all states, swapping initial/final properties
  for (final s in a.states) {
    states.add(StateNode(
      id: s.id,
      name: s.name,
      x: s.x,
      y: s.y,
      isInitial: false, // Will be set for new initial state
      isFinal: s.id == a.initialId, // Original initial becomes final
    ));
  }

  // If we need a new initial state (multiple original finals)
  if (originalFinals.length > 1) {
    states.add(StateNode(
      id: newInitialId,
      name: 'S',
      x: 60,
      y: 60,
      isInitial: true,
      isFinal: false,
    ));
    // Add λ-transitions from new initial to all original final states
    trans['$newInitialId|λ'] = originalFinals.map((s) => s.id).toList();
    AlgoLog.add('Novo estado inicial $newInitialId com λ-transições para {${originalFinals.map((s) => s.id).join(', ')}}');
  } else {
    // Single final state becomes the initial state
    final idx = states.indexWhere((s) => s.id == originalFinals.first.id);
    if (idx != -1) {
      states[idx] = states[idx].copyWith(isInitial: true);
    }
    AlgoLog.add('Estado final único ${originalFinals.first.id} torna-se inicial');
  }

  // Reverse all transitions
  for (final entry in a.transitions.entries) {
    final parts = entry.key.split('|');
    final src = parts[0];
    final sym = parts[1];
    for (final dst in entry.value) {
      final reverseKey = '$dst|$sym';
      trans[reverseKey] = [...(trans[reverseKey] ?? const <String>[]), src];
      AlgoLog.add('Transição reversa: $dst —$sym→ $src (original: $src —$sym→ $dst)');
    }
  }

  AlgoLog.step('nfaReverse', 'complete', data: {
    'originalInitial': a.initialId,
    'originalFinals': originalFinals.map((s) => s.id).toList(),
    'newInitial': newInitialId,
    'newFinals': a.initialId != null ? [a.initialId!] : [],
  });

  return Automaton(
    alphabet: alpha,
    states: states,
    transitions: trans,
    initialId: newInitialId,
    nextId: states.length,
  );
}

// ===================== Helpers para normalização de ER (paridade web) =====================
String _simplifyRegex(String? r) {
  if (r == null || r.isEmpty) return '';
  final parts = _splitTopUnion(r);
  final cleaned = parts.map(_cleanFactor).toSet().toList();
  final simplified = _applyAdvancedSimplifications(cleaned.join(' ∪ '));
  return simplified;
}

List<String> _splitTopUnion(String r) {
  final result = <String>[];
  var depth = 0;
  var cur = StringBuffer();
  for (var i = 0; i < r.length; i++) {
    final c = r[i];
    if (c == '(') depth++;
    if (c == ')') depth--;
    if (depth == 0 && i + 2 < r.length && r.substring(i, i + 3) == ' ∪ ') {
      result.add(cur.toString());
      cur = StringBuffer();
      i += 2; // skip ' ∪ '
      continue;
    }
    cur.write(c);
  }
  final last = cur.toString();
  if (last.isNotEmpty) result.add(last);
  return result;
}

String _cleanFactor(String f) {
  String out = f;
  bool balanced(String s) {
    var d = 0;
    for (final ch in s.split('')) {
      if (ch == '(') {
        d++;
      } else if (ch == ')') {
        d--;
      }
      if (d < 0) return false;
    }
    return d == 0;
  }
  while (out.startsWith('(') && out.endsWith(')') && balanced(out.substring(1, out.length - 1))) {
    out = out.substring(1, out.length - 1);
  }
  return out;
}

String? _dropEpsilonIfSafe(String r) {
  if (!r.contains('λ')) return r;
  final parts = _splitTopUnion(r);
  if (parts.contains('λ')) {
    final others = parts.where((p) => p != 'λ').toList();
    if (others.isEmpty) return null; // only λ
    final someStar = others.any((p) => p.trim().endsWith('*'));
    return someStar ? _simplifyRegex(others.join(' ∪ ')) : null;
  }
  // Fallback: remove explicit λ occurrences inside factors (very conservative)
  return r.replaceAll('λ', '');
}

bool _onlyAllowedTokens(String r) {
  return RegExp(r'^[A-Za-z0-9 ()∪*]+$').hasMatch(r);
}

String _applyAdvancedSimplifications(String regex) {
  if (regex.isEmpty) return regex;
  
  var result = regex;
  
  // Apply multiple rounds of simplification
  for (var round = 0; round < 3; round++) {
    final before = result;
    
    // 1. Remove redundant parentheses
    result = _removeRedundantParentheses(result);
    
    // 2. Simplify star operations
    result = _simplifyStarOperations(result);
    
    // 3. Simplify union operations
    result = _simplifyUnionOperations(result);
    
    // 4. Simplify concatenation
    result = _simplifyConcatenation(result);
    
    // 5. Apply algebraic identities
    result = _applyAlgebraicIdentities(result);
    
    // Stop if no changes were made
    if (result == before) break;
  }
  
  return result;
}

String _removeRedundantParentheses(String regex) {
  // Remove unnecessary parentheses around single characters or simple expressions
  var result = regex;
  
  // Remove parentheses around single characters: (a) -> a
  result = result.replaceAll(RegExp(r'\(([A-Za-z0-9])\)'), r'$1');
  
  // Remove parentheses around starred expressions: (a*) -> a*
  result = result.replaceAll(RegExp(r'\(([A-Za-z0-9]\*)\)'), r'$1');
  
  // Remove nested parentheses: ((a)) -> (a)
  while (result.contains('((')) {
    result = result.replaceAll(RegExp(r'\(\(([^()]+)\)\)'), r'($1)');
  }
  
  return result;
}

String _simplifyStarOperations(String regex) {
  var result = regex;
  
  // λ* = λ (empty string star is empty string)
  result = result.replaceAll('λ*', 'λ');
  
  // (a*)* = a* (double star)
  result = result.replaceAll(RegExp(r'\(([A-Za-z0-9]+)\*\)\*'), r'$1*');
  
  // a*a* = a* (repeated star)
  result = result.replaceAll(RegExp(r'([A-Za-z0-9]+)\*\1\*'), r'$1*');
  
  return result;
}

String _simplifyUnionOperations(String regex) {
  var result = regex;
  
  // Remove empty unions: a ∪ λ ∪ b -> a ∪ b (if λ can be safely removed)
  final parts = _splitTopUnion(result);
  final nonEmptyParts = parts.where((p) => p.trim() != 'λ').toList();
  if (nonEmptyParts.length != parts.length && nonEmptyParts.isNotEmpty) {
    result = nonEmptyParts.join(' ∪ ');
  }
  
  // Remove duplicate terms: a ∪ b ∪ a -> a ∪ b
  final uniqueParts = parts.toSet().toList();
  if (uniqueParts.length != parts.length) {
    result = uniqueParts.join(' ∪ ');
  }
  
  // Simplify single-term unions: (a) -> a
  if (result.startsWith('(') && result.endsWith(')') && !result.contains(' ∪ ')) {
    final inner = result.substring(1, result.length - 1);
    if (!inner.contains('(') || _isProperlyParenthesized(inner)) {
      result = inner;
    }
  }
  
  return result;
}

String _simplifyConcatenation(String regex) {
  var result = regex;
  
  // Remove λ from concatenation: aλb -> ab, λa -> a, aλ -> a
  result = result.replaceAll(RegExp(r'λ([A-Za-z0-9])'), r'$1');
  result = result.replaceAll(RegExp(r'([A-Za-z0-9])λ'), r'$1');
  
  // Simplify concatenation with empty string: λa -> a, aλ -> a
  result = result.replaceAll(RegExp(r'λ([A-Za-z0-9])'), r'$1');
  result = result.replaceAll(RegExp(r'([A-Za-z0-9])λ'), r'$1');
  
  return result;
}

String _applyAlgebraicIdentities(String regex) {
  var result = regex;
  
  // a ∪ a = a (idempotent union)
  final parts = _splitTopUnion(result);
  final uniqueParts = parts.toSet().toList();
  if (uniqueParts.length != parts.length) {
    result = uniqueParts.join(' ∪ ');
  }
  
  // a ∪ ∅ = a (union with empty set)
  result = result.replaceAll(RegExp(r'([A-Za-z0-9]+) ∪ ∅'), r'$1');
  result = result.replaceAll(RegExp(r'∅ ∪ ([A-Za-z0-9]+)'), r'$1');
  
  // a∅ = ∅ (concatenation with empty set)
  result = result.replaceAll(RegExp(r'([A-Za-z0-9]+)∅'), '∅');
  result = result.replaceAll(RegExp(r'∅([A-Za-z0-9]+)'), '∅');
  
  // ∅* = λ (empty set star is empty string)
  result = result.replaceAll('∅*', 'λ');
  
  return result;
}

bool _isProperlyParenthesized(String expr) {
  var depth = 0;
  for (final char in expr.split('')) {
    if (char == '(') depth++;
    if (char == ')') depth--;
    if (depth < 0) return false;
  }
  return depth == 0;
}
