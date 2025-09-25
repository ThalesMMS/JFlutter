//TO-DO: Add exception handling for when a behaviour cannot be found for a certain key config,
//causing the machine to halt. This should be checked in the stepIntoConfiguration() function.
//Also implement a dialog box showing that the machine has halted.
// ignore_for_file: non_constant_identifier_names

import 'dart:collection';
import 'package:turing_machines/exceptions/action_exceptions.dart';
import 'package:turing_machines/models/Behaviour.dart';
import 'package:turing_machines/models/Configuration.dart';
import 'package:turing_machines/models/Tape.dart';

//An object of this class represents a hypothetical turing machine, complete with a tape, m-configs, scanned symbols,Actions adn a final m-config post-action execution
class TuringMachine {
  int iterations = 0;

  String initial_config;

  String current_config;

  Tape tape;

  String description;

  late LinkedHashMap<Configuration, Behaviour> machine;
  TuringMachine(List<Configuration> configurations, List<Behaviour> behaviours,
      {required this.tape, required this.initial_config})
      : machine = LinkedHashMap(),
        current_config = initial_config,
        description = "Enter a description for this turing machine here" {
    //Write code to convert ordered entires into hashmap key-pair values
    // ignore: unnecessary_this
    for (int i = 0; i < configurations.length; i++) {
      Behaviour behaviour = behaviours[i];
      Configuration configuration = configurations[i];
      machine[configuration] = behaviour;
    }
  }

  //Updates the state of the turing machine by exactly one Configuration-Behavior pair computation.
  //Returns true if the step was successful, false otherwise
  void stepIntoConfig() {
    Configuration key =
        Configuration(m_config: current_config, symbol: tape.symbol);
    //TO-DO:Override equals and hashcode functions for all composite data types to ensure proper key matching while referencing the hash map.
    //DONE: 3:51 AM 01-04-2024
    if (machine[key] == null) {
      //Code to check if (m_config,any) exists
      key = Configuration(m_config: current_config, symbol: "ANY");
      if (machine[key] == null || tape.symbol == "") {
        throw const InvalidLookupException();
      }
    }
    Behaviour value = machine[key]!;
    tape.process(value.actions);
    current_config = value.f_config;
    ++iterations;

    //machine has progressed and computed one <config,behaviour> pair
  }

  //resets the turing machine
  void reset() {
    //TO-DO:Implement reset() function for overall state of turing machine
    machine.clear();
    iterations = 0; //Reset iteration counter
    tape.reset(); //hard-reset the tape of the turing machine
    initial_config = "NONE";
    current_config = initial_config; //set back to initial configuration
  }

  //FIX-IT:Make sure there is a variable to reference original m-config for reset
  void softReset() {
    iterations = 0;
    tape.reset();
    current_config = initial_config;
  }

  //Add an entry to the turing machine
  void addEntry(Configuration config, Behaviour behave) {
    machine[config] = behave;
  }

  //delete an entry
  void deleteEntry(Configuration key) {
    machine.remove(key);
  }
}
