import 'package:flutter/material.dart';
import 'package:jflutter/presentation/widgets/help/help_section_widgets.dart';

class FileOperationsHelpSection extends StatelessWidget {
  const FileOperationsHelpSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HelpSectionTitle('File Operations'),
          SizedBox(height: 16),
          Text(
            'JFlutter supports saving and loading automata, grammars, and other structures '
            'in JFLAP format for compatibility with the original JFLAP software.',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Supported Formats'),
          SizedBox(height: 16),
          HelpFormatCard(
            title: 'JFLAP XML',
            description: 'Native JFLAP format (.jff)',
          ),
          HelpFormatCard(
            title: 'SVG Export',
            description: 'Vector graphics for presentations',
          ),
          HelpFormatCard(
            title: 'Text Export',
            description: 'Plain text representation',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Saving Files'),
          SizedBox(height: 16),
          Text(
            'To save your work:\n'
            '1. Tap the save button in the file operations panel\n'
            '2. Choose a location and filename\n'
            '3. Select the format (JFLAP XML recommended)\n'
            '4. Confirm to save',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Loading Files'),
          SizedBox(height: 16),
          Text(
            'To load existing files:\n'
            '1. Tap the load button in the file operations panel\n'
            '2. Browse to your file location\n'
            '3. Select a .jff file\n'
            '4. The structure will be loaded into the editor',
          ),
          SizedBox(height: 24),
          HelpSectionTitle('Import/Export'),
          SizedBox(height: 16),
          HelpOperationCard(
            title: 'Import from JFLAP',
            description: 'Load files created in desktop JFLAP',
          ),
          HelpOperationCard(
            title: 'Export for Sharing',
            description: 'Save in formats others can use',
          ),
          HelpOperationCard(
            title: 'Backup Work',
            description: 'Create copies of your structures',
          ),
        ],
      ),
    );
  }
}
