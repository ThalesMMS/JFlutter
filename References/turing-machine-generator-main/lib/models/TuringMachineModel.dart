import 'package:hive_flutter/adapters.dart';

import 'package:turing_machines/models/Behaviour.dart';
import 'package:turing_machines/models/Configuration.dart';
import 'package:turing_machines/models/Tape.dart';
import 'package:turing_machines/models/TuringMachines.dart';
import 'package:json_annotation/json_annotation.dart';
part "TuringMachineModel.g.dart";

@HiveType(typeId: 0)
@JsonSerializable()
class TuringMachineModel {
  @HiveField(0)
  String initial_config;
  @HiveField(1)
  List<Configuration> configs;
  @HiveField(2)
  List<Behaviour> behaviours;
  @HiveField(3)
  String description;
  TuringMachineModel(
      {required this.initial_config,
      required this.configs,
      required this.behaviours,
      required this.description});
  //Factory constructor for Model to save this machine object
  factory TuringMachineModel.fromMachine({required TuringMachine machine}) {
    //Construct object from machine object.
    return TuringMachineModel(
      initial_config: machine.initial_config,
      configs: machine.machine.keys.toList(),
      behaviours: machine.machine.values.toList(),
      description: machine.description,
    );
    //LinkedHashMap to List.
  }
  //Convert machine-model to machine.
  TuringMachine actuateMachine() {
    TuringMachine machine = TuringMachine(
      configs,
      behaviours,
      tape: Tape(tape: Tape.defaultTape(), pointer: 0),
      initial_config: initial_config,
    );
    machine.current_config = initial_config;
    machine.iterations = 0;
    machine.description = description;

    return machine;
  }

  // Connect the generated function to the `fromJson`
  // factory.
  factory TuringMachineModel.fromJson(Map<String, dynamic> json) =>
      _$TuringMachineModelFromJson(json);

  // Connect the generated  function to the `toJson` method.
  Map<String, dynamic> toJson() => _$TuringMachineModelToJson(this);
}
