import '../models/grammar.dart';
import '../models/production.dart';
import '../result.dart';

class GrammarAnalysisReport<T> {
  final T value;
  final List<String> notes;
  final List<String> derivations;
  final List<String> conflicts;

  const GrammarAnalysisReport({
    required this.value,
    this.notes = const [],
    this.derivations = const [],
    this.conflicts = const [],
  });
}

class LL1ParseTable {
  final Map<String, Map<String, List<List<String>>>> table;
  final Set<String> terminals;

  const LL1ParseTable({
    required this.table,
    required this.terminals,
  });

  Set<String> get nonTerminals => table.keys.toSet();
}

class GrammarAnalyzer {
  static Result<GrammarAnalysisReport<Grammar>> removeDirectLeftRecursion(
    Grammar grammar,
  ) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('The grammar has no productions.');
    }

    final productionsByNonTerminal = _groupProductions(grammar);
    final newProductions = <Production>[];
    final newNonTerminals = grammar.nonterminals.toSet();
    final notes = <String>[];
    final derivations = <String>[];
    var productionCounter = 0;

    bool changed = false;

    for (final entry in productionsByNonTerminal.entries) {
      final nonTerminal = entry.key;
      final alternatives = entry.value;
      final alpha = <List<String>>[];
      final beta = <List<String>>[];

      for (final alt in alternatives) {
        if (alt.isNotEmpty && alt.first == nonTerminal) {
          alpha.add(alt.sublist(1));
        } else {
          beta.add(alt);
        }
      }

      if (alpha.isEmpty) {
        for (final alt in alternatives) {
          newProductions.add(_productionFrom(nonTerminal, alt,
              productionCounter++, grammarId: grammar.id));
        }
        continue;
      }

      changed = true;
      final prime = _generatePrimeSymbol(nonTerminal, newNonTerminals);
      newNonTerminals.add(prime);
      notes.add('Introduced non-terminal $prime to remove left recursion from $nonTerminal.');

      if (beta.isEmpty) {
        beta.add(<String>[]);
        notes.add('Added implicit ε-production for $nonTerminal to preserve language.');
      }

      for (final betaAlt in beta) {
        final updated = [...betaAlt, prime];
        newProductions.add(_productionFrom(nonTerminal, updated,
            productionCounter++, grammarId: grammar.id));
        derivations.add(
            '$nonTerminal → ${_formatSymbols(betaAlt)}$prime (from β production)');
      }

      for (final alphaAlt in alpha) {
        final updated = [...alphaAlt, prime];
        newProductions.add(_productionFrom(prime, updated,
            productionCounter++, grammarId: grammar.id));
        derivations.add(
            '$prime → ${_formatSymbols(alphaAlt)}$prime (from α production)');
      }

      newProductions.add(Production(
        id: '${grammar.id}_rec_$productionCounter',
        leftSide: [prime],
        rightSide: const [],
        isLambda: true,
        order: productionCounter++,
      ));
      derivations.add('$prime → ε (allows termination of recursion)');
    }

    if (!changed) {
      notes.add('No direct left recursion detected.');
    }

    final transformed = grammar.copyWith(
      nonterminals: newNonTerminals,
      productions: newProductions.toSet(),
      modified: DateTime.now(),
    );

    return ResultFactory.success(
      GrammarAnalysisReport<Grammar>(
        value: transformed,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  static Result<GrammarAnalysisReport<Grammar>> leftFactor(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('The grammar has no productions.');
    }

    final grouped = _groupProductions(grammar);
    final newProductions = <Production>[];
    final newNonTerminals = grammar.nonterminals.toSet();
    final notes = <String>[];
    final derivations = <String>[];
    var productionCounter = 0;
    var factoringIndex = 1;

    bool changed = false;

    bool updated;
    do {
      updated = false;
      for (final nonTerminal in grouped.keys.toList()) {
        final alternatives = grouped[nonTerminal]!;
        final factoring = _findCommonPrefix(alternatives);
        if (factoring == null) {
          continue;
        }

        changed = true;
        updated = true;
        final prefix = factoring.prefix;
        final toFactor = factoring.alternatives;
        final newSymbol = _generateFactoredSymbol(
          nonTerminal,
          newNonTerminals,
          factoringIndex++,
        );
        newNonTerminals.add(newSymbol);
        notes.add(
            'Introduced non-terminal $newSymbol to factor prefix ${_formatSymbols(prefix)} from $nonTerminal.');

        grouped[nonTerminal] = [
          ...alternatives.where((alt) => !toFactor.contains(alt)),
          [...prefix, newSymbol],
        ];

        grouped[newSymbol] = toFactor
            .map((alt) =>
                alt.length == prefix.length ? <String>[] : alt.sublist(prefix.length))
            .toList();

        derivations.add(
            '$nonTerminal → ${_formatSymbols(prefix)}$newSymbol (factored ${toFactor.length} productions)');
        for (final alt in grouped[newSymbol]!) {
          derivations.add(
              '$newSymbol → ${alt.isEmpty ? 'ε' : alt.join(' ')} (remaining suffix)');
        }
        break;
      }
    } while (updated);

    if (!changed) {
      notes.add('No common prefixes requiring factoring were found.');
    }

    for (final entry in grouped.entries) {
      for (final alt in entry.value) {
        newProductions.add(_productionFrom(entry.key, alt,
            productionCounter++, grammarId: grammar.id));
      }
      if (entry.value.isEmpty) {
        newProductions.add(Production(
          id: '${grammar.id}_fact_${productionCounter}',
          leftSide: [entry.key],
          rightSide: const [],
          isLambda: true,
          order: productionCounter++,
        ));
      }
    }

    final transformed = grammar.copyWith(
      nonterminals: newNonTerminals,
      productions: newProductions.toSet(),
      modified: DateTime.now(),
    );

    return ResultFactory.success(
      GrammarAnalysisReport<Grammar>(
        value: transformed,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  static Result<GrammarAnalysisReport<Map<String, Set<String>>>> computeFirstSets(
    Grammar grammar,
  ) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('The grammar has no productions.');
    }

    final notes = <String>[];
    final derivations = <String>[];
    final first = <String, Set<String>>{};
    final productions = _groupProductions(grammar);

    for (final terminal in grammar.terminals) {
      first[terminal] = {terminal};
    }

    for (final nonTerminal in grammar.nonterminals) {
      first.putIfAbsent(nonTerminal, () => <String>{});
    }

    bool changed;
    do {
      changed = false;
      for (final entry in productions.entries) {
        final left = entry.key;
        for (final right in entry.value) {
          if (right.isEmpty) {
            if (first[left]!.add('ε')) {
              changed = true;
              derivations.add(
                  "FIRST($left) gains ε due to production $left → ε");
            }
            continue;
          }

          for (var i = 0; i < right.length; i++) {
            final symbol = right[i];
            if (_isEpsilon(symbol)) {
              if (first[left]!.add('ε')) {
                changed = true;
                derivations.add(
                    "FIRST($left) gains ε because production $left → ${_formatSymbols(right)} contains ε");
              }
              break;
            }

            if (!grammar.nonterminals.contains(symbol)) {
              if (first[left]!.add(symbol)) {
                changed = true;
                derivations.add(
                    "FIRST($left) gains terminal $symbol from production $left → ${_formatSymbols(right)}");
              }
              break;
            }

            final source = first[symbol]!;
            final withoutEpsilon = source.where((s) => s != 'ε').toSet();
            final targetFirst = first[left]!;
            final previousLength = targetFirst.length;
            targetFirst.addAll(withoutEpsilon);
            if (targetFirst.length != previousLength) {
              changed = true;
              derivations.add(
                  "FIRST($left) absorbs FIRST($symbol) − {ε} via production $left → ${_formatSymbols(right)}");
            }

            if (!source.contains('ε')) {
              break;
            }

            if (i == right.length - 1) {
              if (first[left]!.add('ε')) {
                changed = true;
                derivations.add(
                    "FIRST($left) gains ε because all symbols in $left → ${_formatSymbols(right)} can derive ε");
              }
            }
          }
        }
      }
    } while (changed);

    notes.add('Computed FIRST sets for ${grammar.nonterminals.length} non-terminals.');

    final resultMap = {
      for (final entry in first.entries)
        if (grammar.nonterminals.contains(entry.key)) entry.key: entry.value
    };

    return ResultFactory.success(
      GrammarAnalysisReport<Map<String, Set<String>>>(
        value: resultMap,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  static Result<GrammarAnalysisReport<Map<String, Set<String>>>> computeFollowSets(
    Grammar grammar,
  ) {
    final firstResult = computeFirstSets(grammar);
    if (firstResult.isFailure) {
      return ResultFactory.failure(firstResult.error!);
    }

    final first = firstResult.data!.value;
    final follow = {for (final nt in grammar.nonterminals) nt: <String>{}};
    final notes = <String>[];
    final derivations = List<String>.from(firstResult.data!.derivations);

    follow[grammar.startSymbol]!.add('\$');
    derivations.add('FOLLOW(${grammar.startSymbol}) includes \$ (start symbol).');

    final productions = _groupProductions(grammar);

    bool changed;
    do {
      changed = false;
      for (final entry in productions.entries) {
        final left = entry.key;
        for (final right in entry.value) {
          for (var i = 0; i < right.length; i++) {
            final symbol = right[i];
            if (!grammar.nonterminals.contains(symbol)) {
              continue;
            }

            final suffix = right.sublist(i + 1);
            final firstOfSuffix = _firstOfSequence(suffix, first);
            final withoutEpsilon = firstOfSuffix.where((s) => s != 'ε').toSet();
            final targetFollow = follow[symbol]!;
            final previousLength = targetFollow.length;
            targetFollow.addAll(withoutEpsilon);
            if (targetFollow.length != previousLength) {
              changed = true;
              derivations.add(
                  "FOLLOW($symbol) gains ${withoutEpsilon.join(', ')} from FIRST of suffix in $left → ${_formatSymbols(right)}");
            }

            if (suffix.isEmpty || firstOfSuffix.contains('ε')) {
              final previousFollowLength = targetFollow.length;
              targetFollow.addAll(follow[left]!);
              if (targetFollow.length != previousFollowLength) {
                changed = true;
                derivations.add(
                    "FOLLOW($symbol) absorbs FOLLOW($left) because suffix can derive ε in $left → ${_formatSymbols(right)}");
              }
            }
          }
        }
      }
    } while (changed);

    notes.add('Computed FOLLOW sets for ${grammar.nonterminals.length} non-terminals.');

    return ResultFactory.success(
      GrammarAnalysisReport<Map<String, Set<String>>>(
        value: follow,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  static Result<GrammarAnalysisReport<LL1ParseTable>> buildLL1ParseTable(
    Grammar grammar,
  ) {
    final firstResult = computeFirstSets(grammar);
    if (firstResult.isFailure) {
      return ResultFactory.failure(firstResult.error!);
    }

    final followResult = computeFollowSets(grammar);
    if (followResult.isFailure) {
      return ResultFactory.failure(followResult.error!);
    }

    final first = firstResult.data!.value;
    final follow = followResult.data!.value;
    final table = <String, Map<String, List<List<String>>>>{};
    final derivations = <String>[];
    final conflicts = <String>[];

    final productions = _groupProductions(grammar);
    for (final entry in productions.entries) {
      final left = entry.key;
      table.putIfAbsent(left, () => {});
      for (final right in entry.value) {
        final firstSet = _firstOfSequence(right, first);
        final targets = firstSet.where((symbol) => symbol != 'ε');
        for (final terminal in targets) {
          final cell = table[left]!.putIfAbsent(terminal, () => <List<String>>[]);
          cell.add(right);
          derivations.add(
              'Placed $left → ${_formatSymbols(right)} in table[$left, $terminal].');
          if (cell.length > 1) {
            final conflictDescription =
                'Conflict at [$left, $terminal]: ${cell.map(_formatSymbols).join(' vs ')}';
            if (!conflicts.contains(conflictDescription)) {
              conflicts.add(conflictDescription);
            }
          }
        }

        if (firstSet.contains('ε')) {
          for (final terminal in follow[left]!) {
            final cell = table[left]!.putIfAbsent(terminal, () => <List<String>>[]);
            cell.add(const []);
            derivations.add(
                'Placed $left → ε in table[$left, $terminal] using FOLLOW set.');
            if (cell.length > 1) {
              final conflictDescription =
                  'Conflict at [$left, $terminal]: ${cell.map(_formatSymbols).join(' vs ')}';
              if (!conflicts.contains(conflictDescription)) {
                conflicts.add(conflictDescription);
              }
            }
          }
        }
      }
    }

    final terminals = grammar.terminals.union({'\$'});
    return ResultFactory.success(
      GrammarAnalysisReport<LL1ParseTable>(
        value: LL1ParseTable(table: table, terminals: terminals),
        derivations: [
          ...firstResult.data!.derivations,
          ...followResult.data!.derivations,
          ...derivations,
        ],
        conflicts: conflicts,
        notes: [
          'Constructed LL(1) parse table with ${table.length} non-terminals.',
          if (conflicts.isEmpty)
            'No conflicts detected in parse table.'
          else
            '${conflicts.length} conflict(s) detected in parse table.',
        ],
      ),
    );
  }

  static Result<GrammarAnalysisReport<bool>> detectAmbiguity(Grammar grammar) {
    final tableResult = buildLL1ParseTable(grammar);
    if (tableResult.isFailure) {
      return ResultFactory.failure(tableResult.error!);
    }

    final conflicts = tableResult.data!.conflicts;
    final notes = <String>[];
    final derivations = List<String>.from(tableResult.data!.derivations);

    if (conflicts.isNotEmpty) {
      notes.add('Grammar is likely ambiguous due to parse table conflicts.');
    } else {
      notes.add('No LL(1) conflicts detected; grammar appears unambiguous.');
    }

    return ResultFactory.success(
      GrammarAnalysisReport<bool>(
        value: conflicts.isEmpty,
        notes: notes,
        conflicts: conflicts,
        derivations: derivations,
      ),
    );
  }

  static Map<String, List<List<String>>> _groupProductions(Grammar grammar) {
    final grouped = <String, List<List<String>>>{};
    for (final production in grammar.productions) {
      if (production.leftSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.first;
      grouped.putIfAbsent(left, () => <List<String>>[]);
      if (production.isLambda || production.rightSide.isEmpty) {
        grouped[left]!.add(<String>[]);
      } else {
        grouped[left]!.add(List<String>.from(production.rightSide));
      }
    }
    return grouped;
  }

  static Production _productionFrom(
    String left,
    List<String> right,
    int counter, {
    required String grammarId,
  }) {
    return Production(
      id: '${grammarId}_$counter',
      leftSide: [left],
      rightSide: right,
      isLambda: right.isEmpty,
      order: counter,
    );
  }

  static String _generatePrimeSymbol(String base, Set<String> existing) {
    var candidate = "${base}'";
    while (existing.contains(candidate)) {
      candidate = "${candidate}'";
    }
    return candidate;
  }

  static String _generateFactoredSymbol(
    String base,
    Set<String> existing,
    int index,
  ) {
    var candidate = '${base}_$index';
    while (existing.contains(candidate)) {
      index++;
      candidate = '${base}_$index';
    }
    return candidate;
  }

  static bool _isEpsilon(String symbol) => symbol == 'ε' || symbol == 'λ';

  static String _formatSymbols(List<String> symbols) {
    if (symbols.isEmpty) {
      return 'ε';
    }
    return symbols.join(' ');
  }

  static Set<String> _firstOfSequence(
    List<String> sequence,
    Map<String, Set<String>> first,
  ) {
    if (sequence.isEmpty) {
      return {'ε'};
    }

    final result = <String>{};
    for (var i = 0; i < sequence.length; i++) {
      final symbol = sequence[i];
      if (_isEpsilon(symbol)) {
        result.add('ε');
        break;
      }

      if (!first.containsKey(symbol)) {
        result.add(symbol);
        break;
      }

      final source = first[symbol]!;
      result.addAll(source.where((s) => s != 'ε'));
      if (!source.contains('ε')) {
        break;
      }

      if (i == sequence.length - 1) {
        result.add('ε');
      }
    }

    return result;
  }
}

class _FactoringResult {
  final List<String> prefix;
  final List<List<String>> alternatives;

  _FactoringResult({required this.prefix, required this.alternatives});
}

_FactoringResult? _findCommonPrefix(List<List<String>> alternatives) {
  if (alternatives.length < 2) {
    return null;
  }

  _FactoringResult? best;

  for (var i = 0; i < alternatives.length; i++) {
    final first = alternatives[i];
    for (var j = i + 1; j < alternatives.length; j++) {
      final second = alternatives[j];
      final prefix = <String>[];
      final length = first.length < second.length ? first.length : second.length;
      for (var k = 0; k < length; k++) {
        if (first[k] == second[k]) {
          prefix.add(first[k]);
        } else {
          break;
        }
      }
      if (prefix.isEmpty) {
        continue;
      }

      final group = alternatives
          .where((alt) =>
              alt.length >= prefix.length &&
              ListEquality().equals(alt.sublist(0, prefix.length), prefix))
          .toList();

      if (group.length < 2) {
        continue;
      }

      if (best == null || prefix.length > best!.prefix.length) {
        best = _FactoringResult(prefix: prefix, alternatives: group);
      }
    }
  }

  return best;
}

class ListEquality {
  const ListEquality();

  bool equals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

