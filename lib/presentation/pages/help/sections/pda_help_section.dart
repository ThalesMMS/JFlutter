import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class PdaHelpSection extends StatelessWidget {
  const PdaHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Pushdown Automata'),
          SizedBox(height: 16),
          Text(
            'Pushdown Automata (PDA) are finite state machines with a stack. '
            'They can recognize context-free languages and are more powerful than FSAs.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('PDA Components'),
          SizedBox(height: 16),
          HelpComponentCard(
            title: 'States',
            description: 'Finite set of states',
          ),
          HelpComponentCard(
            title: 'Stack',
            description: 'LIFO data structure',
          ),
          HelpComponentCard(
            title: 'Transitions',
            description: 'Read input, pop/push stack, change state',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Transition Format'),
          SizedBox(height: 16),
          Text(
            'Transitions are of the form:\n'
            '(current_state, input_symbol, stack_top) → (new_state, stack_operation)\n\n'
            'Stack operations:\n'
            '• Pop: Remove top symbol\n'
            '• Push: Add symbol to top\n'
            '• Replace: Pop and push in one operation',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Simulation'),
          SizedBox(height: 16),
          Text(
            'During simulation:\n'
            '1. Read input symbol\n'
            '2. Check stack top\n'
            '3. Apply transition\n'
            '4. Update state and stack\n'
            '5. Continue until input is consumed',
          ),
        ],
      ),
    );
  }
}
