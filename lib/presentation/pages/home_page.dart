import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/automaton_provider.dart';
import '../widgets/automaton_canvas.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/mobile_navigation.dart';
import 'fsa_page.dart';
import 'grammar_page.dart';
import 'pda_page.dart';
import 'tm_page.dart';
import 'l_system_page.dart';
import 'pumping_lemma_page.dart';

/// Main home page with modern design and mobile-first approach
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      label: 'FSA',
      icon: Icons.account_tree,
      description: 'Finite State Automata',
    ),
    NavigationItem(
      label: 'Grammar',
      icon: Icons.text_fields,
      description: 'Context-Free Grammars',
    ),
    NavigationItem(
      label: 'PDA',
      icon: Icons.storage,
      description: 'Pushdown Automata',
    ),
    NavigationItem(
      label: 'TM',
      icon: Icons.settings,
      description: 'Turing Machines',
    ),
    NavigationItem(
      label: 'L-Systems',
      icon: Icons.auto_awesome,
      description: 'Lindenmayer Systems',
    ),
    NavigationItem(
      label: 'Pumping',
      icon: Icons.games,
      description: 'Pumping Lemma Game',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  String _getCurrentPageTitle() {
    return _navigationItems[_currentIndex].label;
  }

  String _getCurrentPageDescription() {
    return _navigationItems[_currentIndex].description;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getCurrentPageTitle()),
            if (isMobile)
              Text(
                _getCurrentPageDescription(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
          IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: const [
          FSAPage(),
          GrammarPage(),
          PDAPage(),
          TMPage(),
          LSystemPage(),
          PumpingLemmaPage(),
        ],
      ),
      bottomNavigationBar: isMobile
          ? MobileNavigation(
              currentIndex: _currentIndex,
              onTap: _onNavigationTap,
              items: _navigationItems,
            )
          : null,
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    // Show different FABs based on current page
    switch (_currentIndex) {
      case 0: // FSA
        return FloatingActionButton(
          onPressed: () => _createNewAutomaton(context),
          child: const Icon(Icons.add),
          tooltip: 'Create New Automaton',
        );
      case 1: // Grammar
        return FloatingActionButton(
          onPressed: () => _createNewGrammar(context),
          child: const Icon(Icons.add),
          tooltip: 'Create New Grammar',
        );
      default:
        return null;
    }
  }

  void _createNewAutomaton(BuildContext context) {
    // TODO: Implement new automaton creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new automaton - Coming soon!')),
    );
  }

  void _createNewGrammar(BuildContext context) {
    // TODO: Implement new grammar creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new grammar - Coming soon!')),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text(
          'JFlutter is a mobile app for learning formal language theory.\n\n'
          '• FSA: Create and simulate finite state automata\n'
          '• Grammar: Work with context-free grammars\n'
          '• PDA: Explore pushdown automata\n'
          '• TM: Learn about Turing machines\n'
          '• L-Systems: Generate fractal patterns\n'
          '• Pumping: Play the pumping lemma game',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings panel - Coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
