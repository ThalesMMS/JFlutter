import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/mobile_navigation.dart';
import 'fsa_page.dart';
import 'grammar_page.dart';
import 'pda_page.dart';
import 'tm_page.dart';
import 'regex_page.dart';
import 'pumping_lemma_page.dart';
import 'settings_page.dart';
import 'help_page.dart';

/// Main home page with modern design and mobile-first approach
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController;

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
      label: 'Regex',
      icon: Icons.pattern,
      description: 'Regular Expressions',
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
    final initialIndex = ref.read(homeNavigationProvider);
    _pageController = PageController(initialPage: initialIndex);

    ref.listen<int>(homeNavigationProvider, (previous, next) {
      if (previous == next) {
        return;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_pageController.hasClients) {
            return;
          }
          _pageController.jumpToPage(next);
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    ref.read(homeNavigationProvider.notifier).setIndex(index);
  }

  void _onPageChanged(int index) {
    ref.read(homeNavigationProvider.notifier).setIndex(index);
  }

  String _getCurrentPageTitle(int currentIndex) {
    return _navigationItems[currentIndex].label;
  }

  String _getCurrentPageDescription(int currentIndex) {
    return _navigationItems[currentIndex].description;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final currentIndex = ref.watch(homeNavigationProvider);
    final isMobile = screenSize.width < 1024; // Better breakpoint for modern devices

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getCurrentPageTitle(currentIndex)),
            if (isMobile)
              Text(
                _getCurrentPageDescription(currentIndex),
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
        physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
        children: const [
          FSAPage(),
          GrammarPage(),
          PDAPage(),
          TMPage(),
          RegexPage(),
          PumpingLemmaPage(),
        ],
      ),
      bottomNavigationBar: isMobile
          ? MobileNavigation(
              currentIndex: currentIndex,
              onTap: _onNavigationTap,
              items: _navigationItems,
            )
          : null,
      floatingActionButton: _buildFloatingActionButton(context, currentIndex),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, int currentIndex) {
    // Show different FABs based on current page
    switch (currentIndex) {
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HelpPage(),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SettingsPage(),
      ),
    );
  }
}
