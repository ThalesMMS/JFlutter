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

import '../../core/config/v1_feature_flags.dart';
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
  final ScrollController _chipScrollController = ScrollController();
  late final List<GlobalKey> _chipKeys = List.generate(
    _helpSections.length,
    (_) => GlobalKey(),
  );

  List<HelpSection> get _helpSections => const [
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
        HelpSection(
            title: 'PDA', icon: Icons.storage, content: _PDAHelpContent()),
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
        if (V1FeatureFlags.showPumpingLemma)
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
    _chipScrollController.dispose();
    super.dispose();
  }

  void _onSectionSelected(int index) {
    _updateSelectedIndex(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _updateSelectedIndex(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
    _scrollSelectedChipIntoView();
  }

  void _scrollSelectedChipIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_chipScrollController.hasClients) {
        return;
      }

      final chipContext = _chipKeys[_selectedIndex].currentContext;
      if (chipContext == null) {
        return;
      }

      Scrollable.ensureVisible(
        chipContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    });
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
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 68,
            child: ListView.builder(
              controller: _chipScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _helpSections.length,
              itemBuilder: (context, index) {
                final section = _helpSections[index];
                final isSelected = index == _selectedIndex;

                return Padding(
                  key: _chipKeys[index],
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(
                      section.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: isSelected,
                    onSelected: (_) => _onSectionSelected(index),
                    avatar: Icon(section.icon, size: 16),
                  ),
                );
              },
            ),
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                _updateSelectedIndex(index);
              },
              children:
                  _helpSections.map((section) => section.content).toList(),
            ),
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
            onPageChanged: (index) => _updateSelectedIndex(index),
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
                'Welcome to JFlutter. Here\'s a quick way to get started:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                '1. Choose a workspace such as FSA, Grammar, PDA, TM, or Regex',
              ),
              Text(
                '2. Start with a blank workspace or open a supported example or file',
              ),
              Text(
                '3. Use the editor to build your machine or grammar (double-tap a state for quick actions)',
              ),
              Text('4. Run simulations to test your work'),
              Text('5. Use algorithms to transform structures'),
              SizedBox(height: 16),
              Text('Tips:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '• Use the navigation tabs or section chips to switch between workspaces quickly',
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
