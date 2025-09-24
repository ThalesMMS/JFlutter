import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:turing_machines/models/Actions.dart';
import 'package:json_annotation/json_annotation.dart';
part 'Behaviour.g.dart';

@HiveType(typeId: 3)
@JsonSerializable()
class Behaviour {
  const Behaviour({required this.actions, required this.f_config});
  @HiveField(0)
  final List<Actions> actions;
  @HiveField(1)
  final String f_config;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Behaviour &&
          runtimeType == other.runtimeType &&
          listEquals(actions, other.actions) &&
          f_config == other.f_config;

  @override
  int get hashCode => actions.hashCode ^ f_config.hashCode;

  // Connect the generated function to the `fromJson`
  // factory.
  factory Behaviour.fromJson(Map<String, dynamic> json) =>
      _$BehaviourFromJson(json);

  // Connect the generated  function to the `toJson` method.
  Map<String, dynamic> toJson() => _$BehaviourToJson(this);
}
