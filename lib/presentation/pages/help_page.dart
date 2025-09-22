import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jflutter/presentation/pages/help/sections/file_operations_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/fsa_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/getting_started_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/grammar_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/pda_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/pumping_lemma_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/regex_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/tm_help_section.dart';
import 'package:jflutter/presentation/pages/help/sections/troubleshooting_help_section.dart';

/// Help page with interactive documentation and tutorials
/// Based on JFLAP's HelpAction.java and documentation structure
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<HelpSection> _helpSections = [
    HelpSection(
      title: 'Getting Started',
      icon: Icons.play_circle_outline,
      content: const GettingStartedHelpSection(),
    ),
    HelpSection(
      title: 'FSA',
      icon: Icons.account_tree,
      content: const FsaHelpSection(),
    ),
    HelpSection(
      title: 'Grammar',
      icon: Icons.text_fields,
      content: const GrammarHelpSection(),
    ),
    HelpSection(
      title: 'PDA',
      icon: Icons.storage,
      content: const PdaHelpSection(),
    ),
    HelpSection(
      title: 'Turing Machine',
      icon: Icons.settings,
      content: const TmHelpSection(),
    ),
    HelpSection(
      title: 'Regular Expression',
      icon: Icons.pattern,
      content: const RegexHelpSection(),
    ),
    HelpSection(
      title: 'Pumping Lemma',
      icon: Icons.games,
      content: const PumpingLemmaHelpSection(),
    ),
    HelpSection(
      title: 'File Operations',
      icon: Icons.folder_open,
      content: const FileOperationsHelpSection(),
    ),
    HelpSection(
      title: 'Troubleshooting',
      icon: Icons.help_outline,
      content: const TroubleshootingHelpSection(),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSectionSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Documentation'),
        actions: [
          IconButton(
            onPressed: _showQuickStart,
            icon: const Icon(Icons.rocket_launch),
            tooltip: 'Quick Start Guide',
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _helpSections.length,
            itemBuilder: (context, index) {
              final section = _helpSections[index];
              final isSelected = index == _selectedIndex;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilterChip(
                  label: Text(section.title),
                  selected: isSelected,
                  onSelected: (_) => _onSectionSelected(index),
                  avatar: Icon(section.icon, size: 16),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _helpSections.map((section) => section.content).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(
          width: 250,
          child: ListView.builder(
            itemCount: _helpSections.length,
            itemBuilder: (context, index) {
              final section = _helpSections[index];
              final isSelected = index == _selectedIndex;

              return ListTile(
                leading: Icon(section.icon),
                title: Text(section.title),
                selected: isSelected,
                onTap: () => _onSectionSelected(index),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: _helpSections.map((section) => section.content).toList(),
          ),
        ),
      ],
    );
  }

  void _showQuickStart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Start Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Welcome to JFlutter! Here\'s how to get started:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('1. Choose a topic from the navigation'),
              Text('2. Create or load an automaton/grammar'),
              Text('3. Use the editor to modify your structure'),
              Text('4. Run simulations to test your work'),
              Text('5. Use algorithms to transform structures'),
              SizedBox(height: 16),
              Text(
                'Tips:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Tap and hold for context menus'),
              Text('• Pinch to zoom on canvas'),
              Text('• Swipe between pages on mobile'),
              Text('• Use the help button (?) for specific help'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }
}

class HelpSection {
  final String title;
  final IconData icon;
  final Widget content;

  HelpSection({
    required this.title,
    required this.icon,
    required this.content,
  });
}
