import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:turing_machines/main.dart';
import 'package:turing_machines/models/Targets.dart';
import 'package:turing_machines/models/TuringMachineModel.dart';
import 'package:turing_machines/models/TuringMachines.dart';
import 'package:turing_machines/screens/TableScreen.dart';

class LoadMachineScreen extends StatefulWidget {
  @override
  State<LoadMachineScreen> createState() => _LoadMachineScreenState();
}

class _LoadMachineScreenState extends State<LoadMachineScreen> {
  @override
  Widget build(BuildContext context) {
    Targets platform = target;
    Size size = MediaQuery.of(context).size;
    if (size.width <= 480 && (platform == Targets.WEB)) {
      platform = Targets.ANDROID;
    }
    Box machineBox = Hive.box<TuringMachineModel>("turing_machines");
    List<dynamic> names = machineBox.keys.toList();
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Load a saved machine"),
          actions: [
            IconButton(
              onPressed: () {
                _showJsonInput(context);
              },
              icon: const Icon(Icons.import_export_outlined),
            ),
            const Gap(5),
            IconButton(
                onPressed: () async {
                  await machineBox.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.restart_alt_rounded))
          ],
        ),
        body: Center(
          child: (names.isEmpty)
              ? const Text("No machines to view!")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: names.length,
                  itemBuilder: (context, index) {
                    return createTile(
                        context, names[index] as String, machineBox, platform);
                  }),
        ),
      ),
    );
  }

//Create tile to click to load a machine.
  // Widget createTile(BuildContext context, String name, Box machineBox) {
  //   return Padding(
  //     padding: EdgeInsets.only(
  //       bottom: 10.0,
  //       left: MediaQuery.of(context).size.width * 0.33,
  //       right: MediaQuery.of(context).size.width * 0.33,
  //     ),
  //     child: GestureDetector(
  //       onTap: () {
  //         Navigator.of(context)
  //             .pushReplacement(MaterialPageRoute(builder: (context) {
  //           return TableScreen(machine: machineBox.get(name).actuateMachine());
  //         }));
  //       },
  //       child: Container(
  //         decoration: BoxDecoration(
  //           color: Colors.blue,
  //           borderRadius: BorderRadius.circular(12.0),
  //         ),
  //         child: Padding(
  //           padding: const EdgeInsets.symmetric(
  //             vertical: 10.0,
  //             horizontal: 6.0,
  //           ),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             children: [
  //               Text(
  //                 name,
  //                 style: const TextStyle(
  //                     fontWeight: FontWeight.bold, fontSize: 22),
  //               ),
  //               const Gap(35.0),
  //               IconButton(
  //                   onPressed: () async {
  //                     await machineBox.delete(name);
  //                     setState(() {});
  //                   },
  //                   icon: const Icon(
  //                     Icons.delete_forever_rounded,
  //                     color: Colors.red,
  //                   ))
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget createTile(
      BuildContext context, String name, Box machineBox, Targets platform) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10.0,
        left: (platform == Targets.ANDROID)
            ? MediaQuery.of(context).size.width * 0.12
            : MediaQuery.of(context).size.width * 0.33,
        right: (platform == Targets.ANDROID)
            ? MediaQuery.of(context).size.width * 0.12
            : MediaQuery.of(context).size.width * 0.33,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12.0), // Adjust the border radius as needed
        ),
        trailing: IconButton(
          onPressed: () async {
            await machineBox.delete(name);
            setState(() {});
          },
          icon: const Icon(Icons.delete_forever),
        ),
        tileColor: Colors.blue,
        title: Center(
            child: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        )),
        onTap: () {
          Navigator.of(context)
              .pushReplacement(MaterialPageRoute(builder: (context) {
            return TableScreen(machine: machineBox.get(name).actuateMachine());
          }));
        },
      ),
    );
  }

  //move to table screen with the machine represented by the json string.
  void actuateJsonMachine(String json) {
    // ignore: non_constant_identifier_names
    TuringMachine target_machine =
        TuringMachineModel.fromJson(jsonDecode(json)).actuateMachine();
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
      return TableScreen(machine: target_machine);
    }));
  }

  //show input sheet for Json string
  void _showJsonInput(BuildContext context) {
    TextEditingController tc = TextEditingController();
    showModalBottomSheet(
        useSafeArea: true,
        isScrollControlled: true,
        context: context,
        isDismissible: false,
        enableDrag: false,
        builder: (context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: 300,
              padding: const EdgeInsets.only(
                  bottom: 8.0, top: 15, left: 15, right: 15),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                        "Enter the export string to construct the turing machine: "),
                    const Gap(15),
                    TextField(
                      controller: tc,
                      maxLines: 5,
                    ),
                    const Gap(15),
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
                              //Code to actuate and navigate to machine
                              try {
                                Navigator.pop(context);
                                actuateJsonMachine(tc.text);
                                // ignore: unused_catch_clause
                              } on FormatException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Invalid String format!'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text("Load machine"),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
  }
}
