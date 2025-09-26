import '../../models/grammar.dart';
import '../../models/production.dart';
import '../../result.dart';

/// Toolkit for context-free grammars: CNF normalization and checks
class CFGToolkit {
  /// Remove ε-productions (except possibly S→ε), unit productions and useless symbols,
  /// returning an equivalent reduced grammar.
  static Result<Grammar> reduce(Grammar g) {
    try {
      final noLambda = _removeLambdaProductions(g);
      final noUnit = _removeUnitProductions(noLambda);
      final reduced = _removeUselessSymbols(noUnit);
      return ResultFactory.success(reduced);
    } catch (e) {
      return ResultFactory.failure('CFG reduce error: $e');
    }
  }

  /// Convert to Chomsky Normal Form (CNF).
  /// Assumes input is context-free.
  static Result<Grammar> toCNF(Grammar g) {
    try {
      // 1) Reduce grammar
      final reduced = (reduce(g).data)!;

      // 2) Ensure start symbol does not appear on right side by introducing S0 → S
      final needsAugment = reduced.productions.any((p) => p.rightSide.contains(reduced.startSymbol));
      final start = needsAugment ? '${reduced.startSymbol}0' : reduced.startSymbol;
      final nonterminals = {
        ...reduced.nonterminals,
        if (needsAugment) start,
      };
      final productions = <Production>{
        if (needsAugment) Production.unit(id: 'aug', leftSide: start, rightSide: reduced.startSymbol),
        ...reduced.productions,
      };
      var current = reduced.copyWith(
        nonterminals: nonterminals,
        startSymbol: start,
        productions: productions,
      );

      // 3) Break long RHS into binary chain
      current = _binarize(current);

      // 4) Replace terminals in binary rules by introducing new nonterminals
      current = _terminalizeBinary(current);

      return ResultFactory.success(current);
    } catch (e) {
      return ResultFactory.failure('CFG toCNF error: $e');
    }
  }

  /// Check if grammar is in CNF: A→BC or A→a, and S→ε optionally
  static bool isCNF(Grammar g) {
    for (final p in g.productions) {
      if (p.isLambda) {
        if (g.startSymbol != p.leftSide.first) return false;
        continue;
      }
      if (p.rightSide.length == 1) {
        // must be terminal
        final a = p.rightSide.first;
        if (!g.terminals.contains(a)) return false;
      } else if (p.rightSide.length == 2) {
        // both must be nonterminals
        final b = p.rightSide[0];
        final c = p.rightSide[1];
        if (!g.nonterminals.contains(b) || !g.nonterminals.contains(c)) return false;
      } else {
        return false;
      }
    }
    return true;
  }

  static Grammar _removeLambdaProductions(Grammar g) {
    final nullable = g.nullableNonterminals;
    final newProductions = <Production>{};
    for (final p in g.productions) {
      if (p.isLambda) continue;
      // generate all subsets of nullable occurrences in RHS
      final rhs = p.rightSide;
      final positions = <int>[];
      for (var i = 0; i < rhs.length; i++) {
        if (nullable.contains(rhs[i])) positions.add(i);
      }
      final total = 1 << positions.length;
      for (int mask = 0; mask < total; mask++) {
        final newRhs = <String>[];
        for (var i = 0; i < rhs.length; i++) {
          final idx = positions.indexOf(i);
          final drop = idx >= 0 && ((mask >> idx) & 1) == 1;
          if (!drop) newRhs.add(rhs[i]);
        }
        if (newRhs.isEmpty) {
          // Only keep S→ε
          if (p.leftSide.first == g.startSymbol) {
            newProductions.add(Production.lambda(id: '${p.id}_eps', leftSide: p.leftSide.first));
          }
        } else {
          newProductions.add(Production(
            id: '${p.id}_nl_${mask}',
            leftSide: p.leftSide,
            rightSide: newRhs,
          ));
        }
      }
    }
    return g.copyWith(productions: newProductions);
  }

  static Grammar _removeUnitProductions(Grammar g) {
    var prods = Set<Production>.from(g.productions);
    bool changed = true;
    while (changed) {
      changed = false;
      final toAdd = <Production>{};
      final toRemove = <Production>{};
      for (final p in prods) {
        if (p.rightSide.length == 1 && g.nonterminals.contains(p.rightSide.first) && !p.isLambda) {
          // unit A→B; replace by A→α for all B→α
          final a = p.leftSide.first;
          final b = p.rightSide.first;
          for (final q in prods.where((q) => q.leftSide.first == b)) {
            if (q.isLambda) {
              toAdd.add(Production.lambda(id: '${p.id}_${q.id}_lift', leftSide: a));
            } else {
              toAdd.add(Production(id: '${p.id}_${q.id}_lift', leftSide: [a], rightSide: q.rightSide));
            }
          }
          toRemove.add(p);
        }
      }
      if (toAdd.isNotEmpty || toRemove.isNotEmpty) {
        prods.removeAll(toRemove);
        prods.addAll(toAdd);
        changed = true;
      }
    }
    return g.copyWith(productions: prods);
  }

  static Grammar _removeUselessSymbols(Grammar g) {
    final useful = g.usefulNonterminals;
    final newProds = g.productions.where((p) => useful.contains(p.leftSide.first)).toSet();
    final newNon = g.nonterminals.intersection(useful);
    return g.copyWith(nonterminals: newNon, productions: newProds);
  }

  static Grammar _binarize(Grammar g) {
    final prods = <Production>{};
    int fresh = 0;
    for (final p in g.productions) {
      if (p.isLambda || p.rightSide.length <= 2) {
        prods.add(p);
        continue;
      }
      // A → X1 X2 X3 ... Xk  => A→X1 N0, N0→X2 N1, ..., Nk-3→X(k-1) Xk
      String left = p.leftSide.first;
      final rhs = List<String>.from(p.rightSide);
      while (rhs.length > 2) {
        final n = 'N${fresh++}';
        prods.add(Production(id: '${p.id}_b_${fresh}', leftSide: [left], rightSide: [rhs.removeAt(0), n]));
        left = n;
      }
      prods.add(Production(id: '${p.id}_b_end', leftSide: [left], rightSide: rhs));
    }
    final nonterminals = {...g.nonterminals, ...prods.map((p) => p.rightSide).expand((e) => e).where((s) => s.startsWith('N')).toSet()};
    return g.copyWith(nonterminals: nonterminals, productions: prods);
  }

  static Grammar _terminalizeBinary(Grammar g) {
    final prods = <Production>{};
    final mapping = <String, String>{};
    int k = 0;
    for (final p in g.productions) {
      if (p.rightSide.length == 2) {
        final rhs = <String>[];
        for (final sym in p.rightSide) {
          if (g.terminals.contains(sym)) {
            final t = mapping.putIfAbsent(sym, () => 'T${k++}');
            rhs.add(t);
          } else {
            rhs.add(sym);
          }
        }
        prods.add(Production(id: '${p.id}_tb', leftSide: p.leftSide, rightSide: rhs));
      } else {
        prods.add(p);
      }
    }
    final extraNon = mapping.values.toSet();
    final extraProds = mapping.entries
        .map((e) => Production.terminal(id: 'm_${e.key}', leftSide: e.value, terminal: e.key));
    prods.addAll(extraProds);
    return g.copyWith(nonterminals: {...g.nonterminals, ...extraNon}, productions: prods);
  }
}


