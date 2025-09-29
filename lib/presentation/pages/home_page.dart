import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/automaton_provider.dart';
import '../providers/grammar_provider.dart';
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
  int? _lastNavigationIndex;

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
      description: 'Pumping Lemma',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final initialIndex = ref.read(homeNavigationProvider);
    _pageController = PageController(initialPage: initialIndex);
    _lastNavigationIndex = initialIndex;
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
    final isMobile =
        screenSize.width < 1024; // Better breakpoint for modern devices

    // Handle navigation changes
    if (_lastNavigationIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.animateToPage(
            currentIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
      _lastNavigationIndex = currentIndex;
    }

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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
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

  Future<void> _createNewAutomaton(BuildContext context) async {
    final automatonNotifier = ref.read(automatonProvider.notifier);

    await automatonNotifier.createAutomaton(
      name: 'Untitled Automaton',
      alphabet: const ['0', '1'],
    );

    if (!mounted) return;

    final automatonState = ref.read(automatonProvider);
    if (automatonState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(automatonState.error!)),
      );
      return;
    }

    ref.read(homeNavigationProvider.notifier).goToFsa();
  }

  void _createNewGrammar(BuildContext context) {
    ref.read(grammarProvider.notifier).createNewGrammar();
    ref
        .read(homeNavigationProvider.notifier)
        .setIndex(HomeNavigationNotifier.grammarIndex);
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
        builder: (context) => SettingsPage(),
      ),
    );
  }
}
