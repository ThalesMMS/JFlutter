// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'derivation_tree.dart';

DerivationTree _$DerivationTreeFromJson(Map<String, dynamic> json) =>
    _DerivationTree(
      root: DerivationTreeNode.fromJson(json['root'] as Map<String, dynamic>),
      isShallow: json['isShallow'] as bool? ?? false,
    );

Map<String, dynamic> _$DerivationTreeToJson(_DerivationTree instance) =>
    <String, dynamic>{
      'root': instance.root.toJson(),
      'isShallow': instance.isShallow,
    };
