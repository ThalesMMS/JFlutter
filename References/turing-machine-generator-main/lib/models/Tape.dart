import 'package:turing_machines/exceptions/action_exceptions.dart';
import 'package:turing_machines/models/Actions.dart';

class Tape {
  //Initialize a Tape with a character String, and optionally, a head pointer.
  Tape({required this.tape, this.pointer = 0});
  //factory constructor to create custom tape for grammar parsing
  factory Tape.fromString({required String input}) {
    List<String> list = input.split('').map((charac) {
      if (charac == " ") {
        return "";
      }
      return charac;
    }).toList();
    return Tape(tape: list);
    //TO-DO
  }
  List<String> tape = ["", "", "", "", "", "", "", "", "", ""];
  int pointer = 0;
  //getter function for current symbol being scanned
  String get symbol => tape[pointer];
  //Processes a set of actions requested to be performed on the tape.
  void process(List<Actions> actions) {
    for (Actions action in actions) {
      switch (action.type) {
        case ActionType.L:
          if (pointer == 0) {
            throw const TapeOperationException("Cannot Move Left beyond 0");
          }
          --pointer;
          //Move Pointer left
          break;
        case ActionType.R:
          if (pointer == (tape.length - 1)) {
            tape.add("");
          }
          ++pointer;
          //Move pointer right
          break;
        //Erase pointer position symbol
        case ActionType.E:
          tape[pointer] = "";
          //Erase symbol at current pointer position
          break;
        case ActionType.P:
          //Print symbol specified in current Action object
          tape[pointer] = action.symbol;
          break;
        case ActionType.NONE:
          throw const TapeOperationException("NONE is not a valid operation");
      }
    }
  }

  void printTape() {
    String s = "";
    for (String symbol in tape) {
      if (symbol == "") {
        symbol = "e";
      }
      s += symbol + " ";
    }
    print(s);
  }

  //default tape for a turing machine at iteration 0
  static List<String> defaultTape() {
    return ["", "", "", "", "", "", "", "", "", ""];
  }

  //Hard reset for the tape of the turing machine
  void reset() {
    pointer = 0;
    tape = defaultTape();
  }

  //Reset data associated with Tape instead of constructing a new object
  void resetTo({required String input, required int pointer}) {
    if (input.isEmpty) {
      reset();
      return;
    }
    this.pointer = pointer;
    tape = input.split('').map((charac) {
      if (charac == " ") {
        return "";
      }
      return charac;
    }).toList();
  }

  @override
  String toString() {
    String output = "";
    for (String element in tape) {
      output += element;
    }
    return output;
  }

  //Clones the tape for saving purposes.
  Tape cloneTape() {
    return Tape(tape: tape.map((e) => e).toList(), pointer: pointer);
  }
}
