import 'automaton.dart';

Automaton automatonFromGrammar(String raw) {
  final lines = raw
      .split(RegExp(r'\n+'))
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  if (lines.isEmpty) return Automaton.empty();

  final states = <StateNode>[];
  final transitions = <String, List<String>>{};
  final alphabet = <String>{};
  final ntMap = <String, String>{};
  int nextId = 0;
  String nid() => 'q${nextId++}';

  String ensureState(String nt) {
    return ntMap.putIfAbsent(nt, () {
      final id = nid();
      states.add(StateNode(id: id, name: nt, x: 120, y: 120, isInitial: false, isFinal: false));
      return id;
    });
  }

  String? startNt;
  final pending = <List<String>>[]; // [srcId, sym, destId|'FINAL']
  for (final line in lines) {
    final parts = line.split('->');
    if (parts.length != 2) continue;
    final lhs = parts[0].trim();
    final rhs = parts[1].trim();
    startNt ??= lhs;
    final fromId = ensureState(lhs);
    final prods = rhs.split('|').map((p) => p.trim()).where((p) => p.isNotEmpty);
    for (final prod in prods) {
      if (prod == 'λ' || prod == 'epsilon' || prod == 'ε') {
        final i = states.indexWhere((s) => s.id == fromId);
        states[i] = states[i].copyWith(isFinal: true);
        continue;
      }
      final sym = prod.substring(0, 1);
      alphabet.add(sym);
      final rest = prod.substring(1);
      if (rest.isEmpty) {
        pending.add([fromId, sym, 'FINAL']);
      } else {
        final toId = ensureState(rest);
        pending.add([fromId, sym, toId]);
      }
    }
  }

  final finalId = nid();
  states.add(StateNode(id: finalId, name: 'F', x: 160, y: 160, isInitial: false, isFinal: true));
  for (final tri in pending) {
    final src = tri[0];
    final sym = tri[1];
    final dest = tri[2] == 'FINAL' ? finalId : tri[2];
    final key = '$src|$sym';
    final arr = transitions[key] ??= <String>[];
    if (!arr.contains(dest)) arr.add(dest);
  }
  if (startNt != null) {
    final initId = ntMap[startNt];
    final idx = states.indexWhere((s) => s.id == initId);
    if (idx >= 0) states[idx] = states[idx].copyWith(isInitial: true);
  }
  final initId = startNt != null ? (ntMap[startNt] ?? states.first.id) : states.first.id;
  return Automaton(
    alphabet: alphabet,
    states: states,
    transitions: transitions,
    initialId: initId,
    nextId: states.length,
  );
}

String exportGrammarFromAutomaton(Automaton a) {
  // Disallow λ transitions
  if (a.transitions.keys.any((k) => k.endsWith('|λ'))) {
    throw StateError('Remova transições λ antes de exportar a gramática.');
  }
  String nameOf(String id) => a.states.firstWhere((s) => s.id == id).name;
  final used = <String>{};
  final ntName = <String, String>{};
  for (final s in a.states) {
    var n = nameOf(s.id);
    if (n.isEmpty || used.contains(n)) n = s.id;
    used.add(n);
    ntName[s.id] = n;
  }
  final prods = <String, List<String>>{};
  void addProd(String lhs, String rhs) => (prods[lhs] ??= []).add(rhs);
  for (final e in a.transitions.entries) {
    final parts = e.key.split('|');
    final src = parts[0];
    final sym = parts[1];
    if (sym == 'λ') continue;
    for (final to in e.value) {
      addProd(ntName[src]!, '$sym${ntName[to]!}');
      if (a.states.firstWhere((s) => s.id == to).isFinal) addProd(ntName[src]!, sym);
    }
  }
  for (final s in a.states) {
    if (s.isFinal) addProd(ntName[s.id]!, 'λ');
  }
  final start = a.initialId != null ? ntName[a.initialId!] : null;
  final keys = prods.keys.toList()..sort();
  if (start != null) {
    final i = keys.indexOf(start);
    if (i > 0) {
      keys.removeAt(i);
      keys.insert(0, start);
    }
  }
  final lines = keys.map((nt) => '$nt->${(prods[nt]!.toSet()).join('|')}').join('\n');
  return lines.isEmpty ? '// Sem produções' : lines;
}
