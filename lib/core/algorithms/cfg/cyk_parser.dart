//
//  cyk_parser.dart
//  JFlutter
//
//  Implementa o algoritmo CYK para gramáticas em Forma Normal de Chomsky,
//  incluindo a preparação da gramática em CNF, construção de tabela dinâmica e
//  reconstrução opcional da derivação. Trata o caso da palavra vazia, registra
//  apontadores de retrocesso e retorna resultados estruturados com árvore de
//  derivação quando a sentença é aceita.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../models/grammar.dart';
import '../../models/production.dart';
import '../../result.dart';

/// CYK parser for CFGs in CNF. Builds parse table and derivation tree.
class CYKParser {
  static Result<CYKResult> parse(Grammar g, String input) {
    try {
      // Handle empty string using nullable analysis (original grammar)
      if (input.isEmpty) {
        final acceptsEmpty = g.nullableNonterminals.contains(g.startSymbol);
        return ResultFactory.success(
          CYKResult(
            accepted: acceptsEmpty,
            table: const [],
            derivation: acceptsEmpty
                ? CYKDerivation.node(g.startSymbol, [])
                : null,
          ),
        );
      }

      // Convert to CNF for CYK (does not mutate original grammar)
      final cnf = _toCNF(g);
      final cnfG = cnf.grammar;

      final n = input.length;
      final table = List.generate(
        n,
        (i) => List.generate(n, (j) => <String>{}),
      );
      final back = List.generate(
        n,
        (i) => List.generate(n, (j) => <String, CYKBackptr>{}),
      );

      // Precompute productions A→a and A→BC
      final unary = <String, Set<String>>{}; // a -> {A}
      final binary = <(String, String), Set<String>>{}; // (B,C) -> {A}
      for (final p in cnfG.productions) {
        if (p.isLambda) continue;
        if (p.rightSide.length == 1 &&
            cnfG.terminals.contains(p.rightSide.first)) {
          final a = p.rightSide.first;
          (unary[a] ??= <String>{}).add(p.leftSide.first);
        } else if (p.rightSide.length == 2 &&
            cnfG.nonterminals.contains(p.rightSide[0]) &&
            cnfG.nonterminals.contains(p.rightSide[1])) {
          final key = (p.rightSide[0], p.rightSide[1]);
          (binary[key] ??= <String>{}).add(p.leftSide.first);
        }
      }

      // Fill length-1 substrings
      for (int i = 0; i < n; i++) {
        final a = input[i];
        for (final A in unary[a] ?? const <String>{}) {
          table[i][0].add(A);
          back[i][0][A] = CYKBackptr.leaf(a);
        }
      }

      // Fill longer substrings
      for (int len = 2; len <= n; len++) {
        for (int i = 0; i <= n - len; i++) {
          final j = len - 1; // column width
          for (int split = 1; split < len; split++) {
            final leftWidth = split - 1;
            final rightWidth = len - split - 1;
            for (final B in table[i][leftWidth]) {
              for (final C in table[i + split][rightWidth]) {
                final candidates = binary[(B, C)];
                if (candidates == null) continue;
                for (final A in candidates) {
                  if (table[i][j].add(A)) {
                    back[i][j][A] = CYKBackptr.internal(
                      left: (i, leftWidth, B),
                      right: (i + split, rightWidth, C),
                    );
                  }
                }
              }
            }
          }
        }
      }

      final accepted = table[0][n - 1].contains(cnfG.startSymbol);
      CYKDerivation? tree;
      if (accepted) {
        tree = _buildTree(back, 0, n - 1, cnfG.startSymbol);
      }
      return ResultFactory.success(
        CYKResult(accepted: accepted, table: table, derivation: tree),
      );
    } catch (e) {
      return ResultFactory.failure('CYK parse error: $e');
    }
  }

  static CYKDerivation _buildTree(
    List<List<Map<String, CYKBackptr>>> back,
    int i,
    int j,
    String A,
  ) {
    final bp = back[i][j][A];
    if (bp == null) return CYKDerivation.node(A, []);
    if (bp.isLeaf) {
      return CYKDerivation.node(A, [CYKDerivation.leaf(bp.leafSymbol!)]);
    }
    final (li, lj, B) = bp.left!;
    final (ri, rj, C) = bp.right!;
    return CYKDerivation.node(A, [
      _buildTree(back, li, lj, B),
      _buildTree(back, ri, rj, C),
    ]);
  }
}

/// CNF conversion output container
class _CNFGrammar {
  final Grammar grammar;
  const _CNFGrammar(this.grammar);
}

/// Converts an arbitrary CFG to (weak) Chomsky Normal Form suitable for CYK.
/// - Eliminates terminals in binary+ productions by introducing X_a → a
/// - Eliminates unit productions
/// - Binarizes long right-sides
/// - Preserves start symbol and terminal set
_CNFGrammar _toCNF(Grammar g) {
  final now = DateTime.now();

  // Working sets (mutable during construction)
  final Set<String> terminals = {...g.terminals};
  final Set<String> nonterminals = {...g.nonterminals};
  final List<Production> newProds = [];

  // Map each terminal to a dedicated nonterminal if needed in binary rules
  final Map<String, String> termNt = {};

  String fresh0(String base) {
    var idx = 0;
    String cand;
    do {
      cand = '${base}_${idx++}';
    } while (nonterminals.contains(cand));
    nonterminals.add(cand);
    return cand;
  }

  String ensureTerminalNt(String t) {
    return termNt.putIfAbsent(t, () {
      final nt = 'T_${t.hashCode.abs()}';
      if (!nonterminals.contains(nt)) nonterminals.add(nt);
      newProds.add(
        Production(
          id: 'cnf_t_${newProds.length}',
          leftSide: [nt],
          rightSide: [t],
          isLambda: false,
          order: newProds.length,
        ),
      );
      return nt;
    });
  }

  // 1) Start from original productions; expand into CNF-friendly ones
  final List<Production> work = [];
  for (final p in g.productions) {
    // Keep epsilon only if left is start symbol; others handled via CYK empty case
    if (p.isLambda) {
      if (p.leftSide.isNotEmpty && p.leftSide.first == g.startSymbol) {
        work.add(p);
      }
      continue;
    }

    // Replace terminals in RHS positions of length > 1 with their NT wrappers
    final rhs = <String>[];
    for (final s in p.rightSide) {
      if (terminals.contains(s) && p.rightSide.length > 1) {
        rhs.add(ensureTerminalNt(s));
      } else {
        rhs.add(s);
      }
    }

    // Binarize if needed
    if (rhs.length <= 2) {
      work.add(
        Production(
          id: 'cnf_keep_${newProds.length}',
          leftSide: p.leftSide,
          rightSide: rhs,
          isLambda: false,
          order: newProds.length,
        ),
      );
    } else {
      // Chain of new nonterminals: A -> X1 X2 X3 ... -> ... in binary form
      var left = p.leftSide.first;
      for (int i = 0; i < rhs.length - 2; i++) {
        final fresh = fresh0('X');
        work.add(
          Production(
            id: 'cnf_bin_${newProds.length}',
            leftSide: [left],
            rightSide: [rhs[i], fresh],
            isLambda: false,
            order: newProds.length,
          ),
        );
        left = fresh;
      }
      work.add(
        Production(
          id: 'cnf_bin_last_${newProds.length}',
          leftSide: [left],
          rightSide: [rhs[rhs.length - 2], rhs[rhs.length - 1]],
          isLambda: false,
          order: newProds.length,
        ),
      );
    }
  }

  // 2) Eliminate unit productions A -> B
  final List<Production> withoutUnits = [];
  final Map<String, Set<String>> unitReach = {};
  for (final A in nonterminals) {
    unitReach[A] = {A};
  }
  bool changed = true;
  while (changed) {
    changed = false;
    for (final p in work) {
      final A = p.leftSide.first;
      if (p.rightSide.length == 1 && nonterminals.contains(p.rightSide.first)) {
        final B = p.rightSide.first;
        if (unitReach[A]!.add(B)) changed = true;
      }
    }
  }
  for (final A in nonterminals) {
    for (final p in work) {
      final B = p.leftSide.first;
      if (!unitReach[A]!.contains(B)) continue;
      // Keep only non-unit productions
      if (p.rightSide.length == 1 && nonterminals.contains(p.rightSide.first)) {
        continue;
      }
      withoutUnits.add(
        Production(
          id: 'cnf_unitfree_${withoutUnits.length}',
          leftSide: [A],
          rightSide: p.rightSide,
          isLambda: false,
          order: withoutUnits.length,
        ),
      );
    }
  }

  final cnfGrammar = Grammar(
    id: 'cnf_${g.id}',
    name: '${g.name} (CNF)',
    terminals: terminals,
    nonterminals: nonterminals,
    startSymbol: g.startSymbol,
    productions: {...newProds, ...withoutUnits}.toSet(),
    type: g.type,
    created: now,
    modified: now,
  );

  return _CNFGrammar(cnfGrammar);
}

class CYKResult {
  final bool accepted;
  final List<List<Set<String>>>
  table; // upper triangular table; table[i][len-1]
  final CYKDerivation? derivation;
  const CYKResult({
    required this.accepted,
    required this.table,
    required this.derivation,
  });
}

class CYKDerivation {
  final String label; // nonterminal or terminal
  final List<CYKDerivation> children;
  const CYKDerivation._(this.label, this.children);
  factory CYKDerivation.node(String nt, List<CYKDerivation> children) =>
      CYKDerivation._(nt, children);
  factory CYKDerivation.leaf(String t) => CYKDerivation._(t, const []);
  bool get isLeaf => children.isEmpty;
}

class CYKBackptr {
  final bool isLeaf;
  final String? leafSymbol; // terminal
  final (int, int, String)? left; // (i, j, B)
  final (int, int, String)? right; // (i, j, C)
  const CYKBackptr._(this.isLeaf, this.leafSymbol, this.left, this.right);
  factory CYKBackptr.leaf(String a) => CYKBackptr._(true, a, null, null);
  factory CYKBackptr.internal({
    required (int, int, String) left,
    required (int, int, String) right,
  }) => CYKBackptr._(false, null, left, right);
}
