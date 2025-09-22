import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class PumpingLemmaHelpSection extends StatelessWidget {
  const PumpingLemmaHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Pumping Lemma Game'),
          SizedBox(height: 16),
          Text(
            'The Pumping Lemma Game is an interactive way to learn about the pumping '
            'lemma for regular languages. It helps you understand why certain languages '
            'are not regular.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('How to Play'),
          SizedBox(height: 16),
          HelpStepCard(
            stepNumber: '1',
            title: 'Choose Language',
            description: 'Select a language to analyze',
          ),
          HelpStepCard(
            stepNumber: '2',
            title: 'Find Pumping Length',
            description: 'Determine the pumping length p',
          ),
          HelpStepCard(
            stepNumber: '3',
            title: 'Choose String',
            description: 'Pick a string longer than p',
          ),
          HelpStepCard(
            stepNumber: '4',
            title: 'Decompose String',
            description: 'Split into xyz where |xy| ≤ p',
          ),
          HelpStepCard(
            stepNumber: '5',
            title: 'Pump String',
            description: 'Show that xyⁿz is not in the language',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Pumping Lemma Statement'),
          SizedBox(height: 16),
          Text(
            'For any regular language L, there exists a pumping length p such that '
            'for any string s in L with |s| ≥ p, s can be written as s = xyz where:\n\n'
            '1. |xy| ≤ p\n'
            '2. |y| > 0\n'
            '3. xyⁿz ∈ L for all n ≥ 0',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Tips'),
          SizedBox(height: 16),
          HelpTipCard(
            title: 'Start Simple',
            description: 'Begin with basic languages like aⁿbⁿ',
          ),
          HelpTipCard(
            title: 'Use Contradiction',
            description: 'Show pumping leads to strings not in L',
          ),
          HelpTipCard(
            title: 'Consider All Cases',
            description: 'Check different ways to split the string',
          ),
        ],
      ),
    );
  }
}
