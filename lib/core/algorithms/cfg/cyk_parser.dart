import '../../models/grammar.dart';
import '../../result.dart';

/// CYK parser for CFGs in CNF. Builds parse table and derivation tree.
class CYKParser {
  static Result<CYKResult> parse(Grammar g, String input) {
    try {
      if (input.isEmpty) {
        final acceptsEmpty = g.productions
            .any((p) => p.isLambda && p.leftSide.first == g.startSymbol);
        return ResultFactory.success(CYKResult(
          accepted: acceptsEmpty,
          table: const [],
          derivation:
              acceptsEmpty ? CYKDerivation.node(g.startSymbol, []) : null,
        ));
      }
      final n = input.length;
      final table =
          List.generate(n, (i) => List.generate(n, (j) => <String>{}));
      final back = List.generate(
          n, (i) => List.generate(n, (j) => <String, CYKBackptr>{}));

      // Precompute productions A→a and A→BC
      final unary = <String, Set<String>>{}; // a -> {A}
      final binary = <(String, String), Set<String>>{}; // (B,C) -> {A}
      for (final p in g.productions) {
        if (p.isLambda) continue;
        if (p.rightSide.length == 1 &&
            g.terminals.contains(p.rightSide.first)) {
          final a = p.rightSide.first;
          (unary[a] ??= <String>{}).add(p.leftSide.first);
        } else if (p.rightSide.length == 2 &&
            g.nonterminals.contains(p.rightSide[0]) &&
            g.nonterminals.contains(p.rightSide[1])) {
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

      final accepted = table[0][n - 1].contains(g.startSymbol);
      CYKDerivation? tree;
      if (accepted) {
        tree = _buildTree(back, 0, n - 1, g.startSymbol);
      }
      return ResultFactory.success(
          CYKResult(accepted: accepted, table: table, derivation: tree));
    } catch (e) {
      return ResultFactory.failure('CYK parse error: $e');
    }
  }

  static CYKDerivation _buildTree(
      List<List<Map<String, CYKBackptr>>> back, int i, int j, String A) {
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

class CYKResult {
  final bool accepted;
  final List<List<Set<String>>>
      table; // upper triangular table; table[i][len-1]
  final CYKDerivation? derivation;
  const CYKResult(
      {required this.accepted, required this.table, required this.derivation});
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
  factory CYKBackptr.internal(
          {required (int, int, String) left,
          required (int, int, String) right}) =>
      CYKBackptr._(false, null, left, right);
}
