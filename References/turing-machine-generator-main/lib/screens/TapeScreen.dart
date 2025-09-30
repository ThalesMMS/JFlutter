// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:turing_machines/exceptions/action_exceptions.dart';
import 'package:turing_machines/main.dart';
import 'package:turing_machines/models/Configuration.dart';
import 'package:turing_machines/models/Targets.dart';
import 'package:turing_machines/models/TuringMachines.dart';
import 'package:turing_machines/widgets/TapeWidget.dart';
import 'package:gap/gap.dart';
import 'package:turing_machines/models/Actions.dart' as actions1;

int timeGap = 1000;

class TapeScreen extends StatefulWidget {
  bool _followHead = true;
  bool automate = false;

  final TuringMachine machine;
  TapeScreen({super.key, required this.machine});
  final double tape_cell_width = 50.0;
  @override
  State<TapeScreen> createState() => _TapeScreenState();
}

class _TapeScreenState extends State<TapeScreen> {
  final TextEditingController _timeController = TextEditingController(
    text: "$timeGap",
  );
  final ScrollController _sc = ScrollController();
  final ScrollController _tableScroll = ScrollController();
  @override
  Widget build(BuildContext context) {
    Targets platform = target;
    Size size = MediaQuery.of(context).size;
    if (size.width <= 480 && (platform == Targets.WEB)) {
      platform = Targets.ANDROID;
    }
    return SafeArea(
      child: PopScope(
        canPop: !widget.automate,
        onPopInvoked: (didPop) {
          if (!didPop) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Disable automatic progression to navigate back!',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Tape Screen"),
            actions: <Widget>[
              IconButton(
                onPressed: (widget.automate)
                    ? null
                    : () {
                        _showTimeInputSheet(context);
                      },
                icon: Icon(
                  Icons.schedule_outlined,
                  color: (widget.automate) ? Colors.grey : Colors.blue,
                ),
              ),
              const Gap(5),
              IconButton(
                onPressed: (widget.automate)
                    ? null
                    : () {
                        setState(() {
                          widget.machine
                              .softReset(); //hard-reset on tape,soft-reset on machine state.
                        });
                      },
                icon: Icon(
                  Icons.restart_alt_rounded,
                  color: (widget.automate) ? Colors.grey : Colors.blue,
                ),
              ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            //MainAxisAlignment should be start for smaller screens,
            //smaller screens should also increase gap between table and tape.
            children: [
              buildTable(platform: platform),
              Gap((platform == Targets.ANDROID) ? 45 : 22),
              //Padding on the left and right of the tape widget prevents the tape from touching the ends of the window
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: TapeWidget(
                  cell_width: widget.tape_cell_width,
                  tape: widget.machine.tape,
                  s_controller: _sc,
                ),
              ),
              const Gap(20),
              Text(
                "Current pointer: ${widget.machine.tape.pointer}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(2),
              Text(
                "Current m-config: ${widget.machine.current_config}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(2),
              Text(
                "Scanned Symbol: ${scannedSymbol(widget.machine.tape.tape[widget.machine.tape.pointer])}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(2),
              Text(
                "Iteration number: ${widget.machine.iterations}",
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(5),
              SizedBox(
                width: 220,
                child: CheckboxListTile(
                  title: Text(
                    "Follow Head Pointer",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (widget._followHead) ? Colors.blue : Colors.black,
                    ),
                  ),
                  value: widget._followHead,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(
                    Icons.follow_the_signs,
                    color: (widget._followHead) ? Colors.blue : Colors.black,
                  ),
                  activeColor: Colors.blue,
                  onChanged: (bool? val) {
                    if (val == null) {
                      return;
                    }
                    setState(() {
                      widget._followHead = val;
                    });
                  },
                ),
              ),
              const Gap(5),

              //Put the automate checkbox here, maybe.
              SizedBox(
                width: 220,
                child: CheckboxListTile(
                  title: Text(
                    "Automate Progression",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: (widget.automate) ? Colors.blue : Colors.black,
                    ),
                  ),
                  value: widget.automate,
                  controlAffinity: ListTileControlAffinity.leading,
                  secondary: Icon(
                    Icons.auto_mode_outlined,
                    color: (widget.automate) ? Colors.blue : Colors.black,
                  ),
                  activeColor: Colors.blue,
                  onChanged: (bool? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      widget.automate = value;
                    });
                    if (widget.automate) {
                      automateProgression();
                    }
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: (widget.automate)
                ? null
                : () {
                    bool result = true;
                    try {
                      widget.machine.stepIntoConfig();
                    } on InvalidLookupException {
                      result = false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Turing Machine has Halted!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } on TapeOperationException catch (e) {
                      result = false;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    if (result) {
                      setState(() {});
                      if (widget._followHead) {
                        _sc.animateTo(
                          (widget.tape_cell_width *
                              widget.machine.tape.pointer),
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.ease,
                        );
                      }
                    }
                  },
            backgroundColor: (widget.automate) ? Colors.grey : Colors.blue,
            child: const Icon(Icons.play_arrow_outlined),
          ),
        ),
      ),
    );
  }

  static String scannedSymbol(String symbol) {
    if (symbol == "") {
      return "NONE";
    }
    return symbol;
  }

  //Build sample table
  Widget buildTable({required Targets platform}) {
    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      controller: _tableScroll,
      child: SizedBox(
        height: (platform == Targets.ANDROID) ? 200 : 400,
        child: SingleChildScrollView(
          controller: _tableScroll,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: DataTable(
              columnSpacing: (platform == Targets.ANDROID) ? 18 : 56,
              decoration: const BoxDecoration(
                color: Colors.blue, // Set the background color here
              ),
              columns: const <DataColumn>[
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'M-config',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Symbol',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'Actions',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      'New m-config',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows: buildEntries(),
            ),
          ),
        ),
      ),
    );
  }

  // Builds rows for tables
  List<DataRow> buildEntries() {
    int green_index = findMatch(
      Configuration(
        m_config: widget.machine.current_config,
        symbol: widget.machine.tape.tape[widget.machine.tape.pointer],
      ),
    );
    int index = 0;
    List<DataRow> dataRows = <DataRow>[];
    widget.machine.machine.forEach((config, behaviour) {
      bool green = (green_index == index);
      List<DataCell> dataCells = <DataCell>[];
      dataCells.add(DataCell(Text(config.m_config)));
      dataCells.add(DataCell(Text(parseSymbolOutput(config.symbol))));
      dataCells.add(
        DataCell(Text(actions1.Actions.printableListFrom(behaviour.actions))),
      );
      dataCells.add(DataCell(Text(behaviour.f_config)));
      dataRows.add(
        DataRow(
          cells: dataCells,
          color: MaterialStateProperty.all(green ? Colors.green : Colors.blue),
        ),
      );
      ++index;
    });
    return dataRows;
  }

  //This function finds the index of the config matching the parameter, preferring
  //a specific symbol over the "any" symbol
  //IMP: Handle case where return result is -1(No match-machine will halt on next operation).
  int findMatch(Configuration configuration) {
    int index = 0;
    List<int> configs = [];
    widget.machine.machine.forEach((config, behaviour) {
      if (config == configuration) {
        configs.add(index);
      }
      ++index;
    });
    if (configs.length == 1) {
      return configs[0];
    }
    List<Configuration> keys = widget.machine.machine.keys.toList();
    for (int i = 0; i < configs.length; i++) {
      Configuration current = keys[configs[i]];
      if (current.symbol.toLowerCase() != "any") {
        return configs[i];
      }
    }
    return -1;
  }

  Future automateProgression() async {
    while (widget.automate) {
      await Future.delayed(Duration(milliseconds: timeGap), () async {
        if (widget.automate) {
          bool result = true;
          try {
            widget.machine.stepIntoConfig();
          } on InvalidLookupException {
            result = false;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Turing Machine has Halted!'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() {
              widget.automate = false;
            });
          } on TapeOperationException catch (e) {
            result = false;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: Colors.red),
            );
            setState(() {
              widget.automate = false;
            });
          }
          if (result) {
            setState(() {});
            if (widget._followHead) {
              _sc.animateTo(
                (widget.tape_cell_width * widget.machine.tape.pointer),
                duration: const Duration(milliseconds: 200),
                curve: Curves.ease,
              );
            }
          }
        }
      });
    }
  }

  void _showTimeInputSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      enableDrag: false,
      isDismissible: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: 230,
            padding: const EdgeInsets.only(
              bottom: 8.0,
              top: 15,
              left: 15,
              right: 15,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Time gap between each automatic iteration: (ms)"),
                  const Gap(15),
                  TextField(
                    controller: _timeController,
                    maxLength: 6,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    ],
                  ),
                  const Gap(15.0),
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        const Gap(7.0),
                        ElevatedButton(
                          onPressed: () {
                            timeGap = int.parse(_timeController.text);

                            Navigator.pop(context);
                          },
                          child: const Text("Ok"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
