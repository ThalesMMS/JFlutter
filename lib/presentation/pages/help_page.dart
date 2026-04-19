//
//  help_page.dart
//  JFlutter
//
//  Reúne a documentação interativa com seções temáticas controladas por
//  PageView e filtros, oferecendo tutoriais guiados para cada módulo de
//  autômatos, gramáticas e ferramentas presentes no aplicativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../widgets/help_search_delegate.dart';

part 'help_page_content.dart';
part 'license_text_card.dart';
part 'licenses_help_content.dart';

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

  final List<HelpSection> _helpSections = const [
    HelpSection(
      title: 'Getting Started',
      icon: Icons.play_circle_outline,
      content: _GettingStartedContent(),
    ),
    HelpSection(
      title: 'FSA',
      icon: Icons.account_tree,
      content: _FSAHelpContent(),
    ),
    HelpSection(
      title: 'Grammar',
      icon: Icons.text_fields,
      content: _GrammarHelpContent(),
    ),
    HelpSection(title: 'PDA', icon: Icons.storage, content: _PDAHelpContent()),
    HelpSection(
      title: 'Turing Machine',
      icon: Icons.settings,
      content: _TMHelpContent(),
    ),
    HelpSection(
      title: 'Regular Expression',
      icon: Icons.pattern,
      content: _RegexHelpContent(),
    ),
    HelpSection(
      title: 'Pumping Lemma',
      icon: Icons.games,
      content: _PumpingLemmaHelpContent(),
    ),
    HelpSection(
      title: 'File Operations',
      icon: Icons.folder_open,
      content: _FileOperationsHelpContent(),
    ),
    HelpSection(
      title: 'Troubleshooting',
      icon: Icons.help_outline,
      content: _TroubleshootingContent(),
    ),
    HelpSection(
      title: 'Licenses',
      icon: Icons.policy_outlined,
      content: _LicensesHelpContent(),
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
            onPressed: () {
              showSearch(
                context: context,
                delegate: HelpSearchDelegate(ref: ref),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search Help',
          ),
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
              Text('1. Use the bottom navigation bar to choose a module'),
              Text('2. Create or load an automaton/grammar'),
              Text(
                '3. Use the editor to modify your structure (double-tap a state for quick actions)',
              ),
              Text('4. Run simulations to test your work'),
              Text('5. Use algorithms to transform structures'),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '• Use the bottom navigation to switch between modules quickly',
              ),
              Text('• Double-tap a state to open its quick action menu'),
              Text('• Pinch to zoom on canvas'),
              Text(
                '• Tap the Quick Start icon in the app bar whenever you need a refresher',
              ),
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
