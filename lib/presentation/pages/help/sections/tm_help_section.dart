import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class TmHelpSection extends StatelessWidget {
  const TmHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Turing Machines'),
          SizedBox(height: 16),
          Text(
            'Turing Machines (TM) are theoretical computational devices with an infinite '
            'tape and a read/write head. They can recognize recursively enumerable languages.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('TM Components'),
          SizedBox(height: 16),
          HelpComponentCard(
            title: 'Tape',
            description: 'Infinite sequence of cells',
          ),
          HelpComponentCard(
            title: 'Head',
            description: 'Read/write head that moves left/right',
          ),
          HelpComponentCard(
            title: 'States',
            description: 'Finite set of control states',
          ),
          HelpComponentCard(
            title: 'Transitions',
            description: 'Read symbol, write symbol, move head, change state',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Transition Format'),
          SizedBox(height: 16),
          Text(
            'Transitions are of the form:\n'
            '(current_state, read_symbol) → (new_state, write_symbol, direction)\n\n'
            'Directions:\n'
            '• L: Move left\n'
            '• R: Move right\n'
            '• S: Stay (if enabled in settings)',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Acceptance'),
          SizedBox(height: 16),
          Text(
            'A TM accepts a string if:\n'
            '• It reaches a final state (default)\n'
            '• It halts (if enabled in settings)\n\n'
            'Configure acceptance mode in Settings.',
          ),
        ],
      ),
    );
  }
}
