import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:turing_machines/main.dart';
import 'package:turing_machines/models/Targets.dart';
import 'package:turing_machines/models/TuringMachines.dart';
import 'package:turing_machines/screens/LoadMachineScreen.dart';
import 'package:turing_machines/screens/TableScreen.dart';
import 'package:turing_machines/testing.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    Targets platform = target;
    Size size = MediaQuery.of(context).size;
    if (size.width <= 480 && (platform == Targets.WEB)) {
      platform = Targets.ANDROID;
    }
    return SafeArea(
      child: Scaffold(
        // appBar: AppBar(
        //   title: Text("Welcome!"),
        // ),
        body: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Turing Machines",
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold),
              ),
              const Gap(100),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  TuringMachine machine = StandardMachines.emptyMachine();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return TableScreen(machine: machine);
                      },
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(17.0),
                  child: Text(
                    "Create Machine",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Gap((platform == Targets.ANDROID) ? 20 : 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  TuringMachine machine = StandardMachines.defaultMachine();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return TableScreen(machine: machine);
                      },
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(17.0),
                  child: Text(
                    "Default Machine",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Gap((platform == Targets.ANDROID) ? 20 : 35),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return LoadMachineScreen();
                      },
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(17.0),
                  child: Text(
                    "Load Machine",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              Gap((platform == Targets.ANDROID) ? 20 : 35),
            ],
          ),
        ),
      ),
    );
  }
}
