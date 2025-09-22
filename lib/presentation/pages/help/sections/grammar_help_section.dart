import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class GrammarHelpSection extends StatelessWidget {
  const GrammarHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Context-Free Grammars'),
          SizedBox(height: 16),
          Text(
            'Context-Free Grammars (CFG) are formal grammars where production rules '
            'have a single nonterminal on the left-hand side. They are used to describe '
            'context-free languages.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Grammar Components'),
          SizedBox(height: 16),
          HelpComponentCard(
            title: 'Variables',
            description: 'Nonterminal symbols (usually uppercase)',
          ),
          HelpComponentCard(
            title: 'Terminals',
            description: 'Terminal symbols (usually lowercase)',
          ),
          HelpComponentCard(
            title: 'Start Symbol',
            description: 'The initial nonterminal',
          ),
          HelpComponentCard(
            title: 'Productions',
            description: 'Rules of the form A → α',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Creating Productions'),
          SizedBox(height: 16),
          Text(
            'To add a production rule:\n'
            '1. Enter the left-hand side (nonterminal)\n'
            '2. Enter the right-hand side (string of terminals and nonterminals)\n'
            '3. Tap "Add" to include the rule\n'
            '4. Use λ or ε for empty string',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Parsing'),
          SizedBox(height: 16),
          HelpParseCard(
            title: 'LL Parsing',
            description: 'Left-to-right, Leftmost derivation',
          ),
          HelpParseCard(
            title: 'LR Parsing',
            description: 'Left-to-right, Rightmost derivation',
          ),
          HelpParseCard(
            title: 'CYK Algorithm',
            description: 'Cocke-Younger-Kasami algorithm',
          ),
        ],
      ),
    );
  }
}
