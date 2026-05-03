// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'derivation_tree_node.dart';

mixin _$DerivationTreeNode {
  String get symbol;
  List<DerivationTreeNode> get children;
  String? get lexeme;
  int? get start;
  int? get end;

  Map<String, dynamic> toJson();
}

class _DerivationTreeNode extends DerivationTreeNode {
  const _DerivationTreeNode({
    required this.symbol,
    this.children = const <DerivationTreeNode>[],
    this.lexeme,
    this.start,
    this.end,
  }) : super._();

  @override
  final String symbol;
  @override
  final List<DerivationTreeNode> children;
  @override
  final String? lexeme;
  @override
  final int? start;
  @override
  final int? end;

  @override
  Map<String, dynamic> toJson() => _$DerivationTreeNodeToJson(this);

  @override
  String toString() {
    return 'DerivationTreeNode(symbol: $symbol, children: $children, lexeme: $lexeme, start: $start, end: $end)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DerivationTreeNode &&
            other.symbol == symbol &&
            _derivationTreeNodeListEquals(other.children, children) &&
            other.lexeme == lexeme &&
            other.start == start &&
            other.end == end;
  }

  @override
  int get hashCode => Object.hash(
        symbol,
        Object.hashAll(children),
        lexeme,
        start,
        end,
      );
}

bool _derivationTreeNodeListEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
