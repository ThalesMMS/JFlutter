// ignore: file_names

import 'package:hive_flutter/adapters.dart';
import 'package:turing_machines/exceptions/action_exceptions.dart';
import 'package:json_annotation/json_annotation.dart';
//Represents an Action which can be performed on the tape of a turing machine.
part 'Actions.g.dart';

@HiveType(typeId: 4)
@JsonSerializable()
class Actions {
  @HiveField(0)
  String symbol;
  @HiveField(1)
  ActionType type;
  Actions({required this.type, this.symbol = ""});
  //Parses a String containing actions, seperated by a ,(comma)
  static List<Actions> parseActions(String input) {
    input = input.replaceAll(" ", "");
    List<String> tokens = input.split(',');
    List<Actions> actions = [];
    for (String token in tokens) {
      ActionType type;
      String symbol = "";
      if (token == "L") {
        type = ActionType.L;
      } else if (token == "R") {
        type = ActionType.R;
      } else if (token == "E") {
        type = ActionType.E;
      } else if (token[0] == "P" && token.length == 2) {
        type = ActionType.P;
        symbol = token[1];
      } else {
        type = ActionType.NONE;
        throw ActionParserException("$token is not a valid action!");
      }
      Actions object = Actions(type: type, symbol: symbol);
      actions.add(object);
    }
    return actions;
  }

  static String printableListFrom(List<Actions> actionsList) {
    String output = "";
    for (Actions object in actionsList) {
      String action = object.type.name;
      if (object.type == ActionType.P) {
        action = action + object.symbol;
      }
      action = "$action,";
      output = output + action;
    }
    return output.substring(0, output.length - 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Actions &&
          runtimeType == other.runtimeType &&
          symbol == other.symbol &&
          type == other.type;

  @override
  int get hashCode => symbol.hashCode ^ type.hashCode;

  // Connect the generated function to the `fromJson`
  // factory.
  factory Actions.fromJson(Map<String, dynamic> json) =>
      _$ActionsFromJson(json);

  // Connect the generated  function to the `toJson` method.
  Map<String, dynamic> toJson() => _$ActionsToJson(this);
}

@HiveType(typeId: 5)
enum ActionType {
  @HiveField(0)
  P,
  @HiveField(1)
  R,
  @HiveField(2)
  L,
  @HiveField(3)
  E,
  // ignore: constant_identifier_names
  @HiveField(4)
  NONE,
}
