import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class FsaHelpSection extends StatelessWidget {
  const FsaHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Finite State Automata'),
          SizedBox(height: 16),
          Text(
            'Finite State Automata (FSA) are computational models that can be in one of '
            'a finite number of states at any given time. They are used to recognize '
            'regular languages.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Creating an FSA'),
          SizedBox(height: 16),
          HelpStepCard(
            stepNumber: '1',
            title: 'Add States',
            description: 'Tap the canvas to add states',
          ),
          HelpStepCard(
            stepNumber: '2',
            title: 'Set Initial State',
            description: 'Double-tap a state to make it initial',
          ),
          HelpStepCard(
            stepNumber: '3',
            title: 'Set Final States',
            description: 'Long-press states to mark as final',
          ),
          HelpStepCard(
            stepNumber: '4',
            title: 'Add Transitions',
            description: 'Drag between states to create transitions',
          ),
          HelpStepCard(
            stepNumber: '5',
            title: 'Label Transitions',
            description: 'Tap transitions to add input symbols',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Simulation'),
          SizedBox(height: 16),
          Text(
            'To test your FSA:\n'
            '1. Enter an input string in the simulation panel\n'
            '2. Tap "Step" to see each transition\n'
            '3. Tap "Run" to see the complete simulation\n'
            '4. Check if the string is accepted or rejected',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Algorithms'),
          SizedBox(height: 16),
          HelpAlgorithmCard(
            title: 'NFA to DFA',
            description: 'Convert non-deterministic to deterministic',
          ),
          HelpAlgorithmCard(
            title: 'DFA Minimization',
            description: 'Reduce the number of states',
          ),
          HelpAlgorithmCard(
            title: 'Equality Test',
            description: 'Check if two FSAs are equivalent',
          ),
        ],
      ),
    );
  }
}
