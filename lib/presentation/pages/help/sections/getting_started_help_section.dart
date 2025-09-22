import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class GettingStartedHelpSection extends StatelessWidget {
  const GettingStartedHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Welcome to JFlutter'),
          SizedBox(height: 16),
          Text(
            'JFlutter is a mobile application for learning formal language theory. '
            'It provides interactive tools for working with automata, grammars, and other '
            'formal language concepts.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Navigation'),
          SizedBox(height: 16),
          HelpFeatureCard(
            title: 'FSA',
            icon: Icons.account_tree,
            description: 'Finite State Automata - Create and simulate finite state machines',
          ),
          HelpFeatureCard(
            title: 'Grammar',
            icon: Icons.text_fields,
            description: 'Context-Free Grammars - Work with production rules and parsing',
          ),
          HelpFeatureCard(
            title: 'PDA',
            icon: Icons.storage,
            description: 'Pushdown Automata - Explore stack-based computation',
          ),
          HelpFeatureCard(
            title: 'TM',
            icon: Icons.settings,
            description: 'Turing Machines - Learn about computational models',
          ),
          HelpFeatureCard(
            title: 'Regex',
            icon: Icons.pattern,
            description: 'Regular Expressions - Pattern matching and conversion',
          ),
          HelpFeatureCard(
            title: 'Pumping',
            icon: Icons.games,
            description: 'Pumping Lemma Game - Interactive learning tool',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Basic Operations'),
          SizedBox(height: 16),
          HelpOperationCard(
            title: 'Create',
            description: 'Add new states, transitions, or rules',
          ),
          HelpOperationCard(
            title: 'Edit',
            description: 'Modify existing elements',
          ),
          HelpOperationCard(
            title: 'Simulate',
            description: 'Test your automaton with input strings',
          ),
          HelpOperationCard(
            title: 'Convert',
            description: 'Transform between different representations',
          ),
          HelpOperationCard(
            title: 'Save/Load',
            description: 'Persist your work in JFLAP format',
          ),
        ],
      ),
    );
  }
}
