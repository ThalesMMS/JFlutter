import 'package:turing_machines/models/Actions.dart';
import 'package:turing_machines/models/Behaviour.dart';
import 'package:turing_machines/models/Configuration.dart';
import 'package:turing_machines/models/Tape.dart';
import 'package:turing_machines/models/TuringMachines.dart';

class StandardMachines {
  static TuringMachine defaultMachine() {
    //Create and test turing machine to print 0 continuously
    List<Configuration> configurations = [
      Configuration(m_config: "B", symbol: ""),
      Configuration(m_config: "Q", symbol: ""),
      Configuration(m_config: "Q", symbol: "0"),
    ];

    List<Behaviour> behaviours = [
      Behaviour(actions: Actions.parseActions("P0,R"), f_config: "Q"),
      Behaviour(actions: Actions.parseActions("L"), f_config: "Q"),
      Behaviour(actions: Actions.parseActions("R,P0"), f_config: "Q"),
    ];
    TuringMachine machine = TuringMachine(
      configurations,
      behaviours,
      tape: Tape(tape: Tape.defaultTape()),
      initial_config: "B",
    );
    return machine;
  }

  static TuringMachine emptyMachine() {
    List<Configuration> configurations = [];
    List<Behaviour> behaviours = [];
    TuringMachine machine = TuringMachine(
      configurations,
      behaviours,
      tape: Tape(tape: Tape.defaultTape()),
      initial_config: "",
    );
    return machine;
  }
}
