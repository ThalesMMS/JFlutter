import 'package:flutter/material.dart';
import 'package:turing_machines/models/Tape.dart';

class TapeWidget extends StatelessWidget {
  //Tape to be passed to the Tape Widget

  const TapeWidget({
    super.key,
    required this.tape,
    required this.s_controller,
    required this.cell_width,
  });
  final Tape tape;
  final ScrollController s_controller;
  final double cell_width;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scrollbar(
        controller: s_controller,
        thumbVisibility: true,
        trackVisibility: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: SizedBox(
            height: 50,
            child: ListView.builder(
              controller: s_controller,
              shrinkWrap: true,
              padding: const EdgeInsets.all(0),
              scrollDirection: Axis.horizontal,
              itemCount: tape.tape.length,
              itemBuilder: (context, index) {
                //TO-DO: Build a horizontal list
                return buildTapeCell(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  //Builds the Tape cell
  Widget buildTapeCell(int index) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: (index == tape.pointer) ? Colors.green : Colors.black,
          width: (index == tape.pointer) ? 5 : 1,
        ),
        color: Colors.blue,
      ),
      margin: const EdgeInsets.all(0),
      width: cell_width,
      child: Center(child: Text(tape.tape[index])),
    );
  }
}
