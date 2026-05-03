// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'derivation_tree.dart';

mixin _$DerivationTree {
  DerivationTreeNode get root;
  bool get isShallow;

  Map<String, dynamic> toJson();
}

class _DerivationTree extends DerivationTree {
  const _DerivationTree({
    required this.root,
    this.isShallow = false,
  }) : super._();

  @override
  final DerivationTreeNode root;
  @override
  final bool isShallow;

  @override
  Map<String, dynamic> toJson() => _$DerivationTreeToJson(this);

  @override
  String toString() {
    return 'DerivationTree(root: $root, isShallow: $isShallow)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DerivationTree &&
            other.root == root &&
            other.isShallow == isShallow;
  }

  @override
  int get hashCode => Object.hash(root, isShallow);
}
