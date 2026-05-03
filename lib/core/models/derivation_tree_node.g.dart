// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file

part of 'derivation_tree_node.dart';

DerivationTreeNode _$DerivationTreeNodeFromJson(Map<String, dynamic> json) =>
    _DerivationTreeNode(
      symbol: json['symbol'] as String,
      children: (json['children'] as List<dynamic>? ?? const <dynamic>[])
          .map((e) => DerivationTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      lexeme: json['lexeme'] as String?,
      start: json['start'] as int?,
      end: json['end'] as int?,
    );

Map<String, dynamic> _$DerivationTreeNodeToJson(
  _DerivationTreeNode instance,
) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'children': instance.children.map((e) => e.toJson()).toList(),
      'lexeme': instance.lexeme,
      'start': instance.start,
      'end': instance.end,
    };
