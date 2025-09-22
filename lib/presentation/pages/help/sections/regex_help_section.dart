import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class RegexHelpSection extends StatelessWidget {
  const RegexHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Regular Expressions'),
          SizedBox(height: 16),
          Text(
            'Regular Expressions (regex) are patterns used to match character combinations in strings. '
            'They are fundamental to formal language theory and are equivalent to finite automata.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Basic Syntax'),
          SizedBox(height: 16),
          HelpSyntaxCard(
            pattern: 'a',
            description: 'Matches the literal character "a"',
          ),
          HelpSyntaxCard(
            pattern: 'a*',
            description: 'Zero or more occurrences of "a"',
          ),
          HelpSyntaxCard(
            pattern: 'a+',
            description: 'One or more occurrences of "a"',
          ),
          HelpSyntaxCard(
            pattern: 'a?',
            description: 'Zero or one occurrence of "a"',
          ),
          HelpSyntaxCard(
            pattern: 'a|b',
            description: 'Either "a" or "b"',
          ),
          HelpSyntaxCard(
            pattern: '(ab)*',
            description: 'Zero or more occurrences of "ab"',
          ),
          HelpSyntaxCard(
            pattern: '[abc]',
            description: 'Any character from the set {a, b, c}',
          ),
          HelpSyntaxCard(
            pattern: '[a-z]',
            description: 'Any lowercase letter',
          ),
          HelpSyntaxCard(
            pattern: '.',
            description: 'Any single character',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Common Patterns'),
          SizedBox(height: 16),
          HelpPatternCard(
            name: 'Email',
            pattern: r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}\$',
          ),
          HelpPatternCard(
            name: 'Phone Number',
            pattern: r'^\\+?[\\d\\s\\-\\(\\)]+\$',
          ),
          HelpPatternCard(
            name: 'Integer',
            pattern: r'^-?\\d+\$',
          ),
          HelpPatternCard(
            name: 'Decimal',
            pattern: r'^-?\\d+\\.?\\d*\$',
          ),
          HelpPatternCard(
            name: 'Identifier',
            pattern: r'^[a-zA-Z_][a-zA-Z0-9_]*\$',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Conversion to Automata'),
          SizedBox(height: 16),
          Text(
            'Regular expressions can be converted to equivalent finite automata:\n\n'
            '1. **Regex to NFA**: Thompson\'s construction algorithm\n'
            '2. **NFA to DFA**: Subset construction algorithm\n'
            '3. **DFA Minimization**: Hopcroft\'s algorithm\n'
            '4. **FA to Regex**: State elimination method\n\n'
            'These conversions preserve the language recognized by the expression.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Testing and Validation'),
          SizedBox(height: 16),
          HelpStepCard(
            stepNumber: '1',
            title: 'Enter Regex',
            description: 'Type your regular expression in the input field',
          ),
          HelpStepCard(
            stepNumber: '2',
            title: 'Validate',
            description: 'Check if the syntax is correct',
          ),
          HelpStepCard(
            stepNumber: '3',
            title: 'Test String',
            description: 'Enter a string to test against the regex',
          ),
          HelpStepCard(
            stepNumber: '4',
            title: 'View Results',
            description: 'See if the string matches the pattern',
          ),
          HelpStepCard(
            stepNumber: '5',
            title: 'Convert',
            description: 'Convert the regex to an equivalent automaton',
          ),
        ],
      ),
    );
  }
}
