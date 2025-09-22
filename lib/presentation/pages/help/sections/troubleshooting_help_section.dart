import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class TroubleshootingHelpSection extends StatelessWidget {
  const TroubleshootingHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('Troubleshooting'),
          SizedBox(height: 16),
          Text(
            'Common issues and solutions for using JFlutter.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Performance Issues'),
          SizedBox(height: 16),
          HelpIssueCard(
            title: 'App is slow with large automata',
            solution:
                'Try reducing the number of states or simplifying the structure. '
                'Large automata with many transitions can impact performance.',
          ),
          HelpIssueCard(
            title: 'Simulation takes too long',
            solution: 'Check for infinite loops in your automaton. Some inputs may cause '
                'the simulation to run indefinitely.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('File Issues'),
          SizedBox(height: 16),
          HelpIssueCard(
            title: 'Cannot load JFLAP file',
            solution:
                'Ensure the file is a valid JFLAP XML format (.jff). '
                'Corrupted files may not load properly.',
          ),
          HelpIssueCard(
            title: 'Save operation fails',
            solution:
                'Check that you have sufficient storage space and write permissions '
                'to the selected location.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('UI Issues'),
          SizedBox(height: 16),
          HelpIssueCard(
            title: 'Elements are too small to tap',
            solution:
                'Use pinch-to-zoom to enlarge the canvas, or adjust the zoom level '
                'in settings.',
          ),
          HelpIssueCard(
            title: 'Canvas is not responding',
            solution:
                'Try refreshing the page or restarting the app. '
                'Some touch gestures may conflict.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Getting Help'),
          SizedBox(height: 16),
          Text(
            'If you continue to experience issues:\n\n'
            '1. Check this help section for your specific problem\n'
            '2. Try restarting the application\n'
            '3. Clear app data and restart (will reset settings)\n'
            '4. Check for app updates\n'
            '5. Report bugs with detailed descriptions',
          ),
        ],
      ),
    );
  }
}
