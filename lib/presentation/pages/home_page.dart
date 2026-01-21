//
//  home_page.dart
//  JFlutter
//
//  Orquestra a página inicial com navegação por PageView e bottom navigation
//  responsiva, integrando provedores de autômatos, gramáticas e destaques para
//  coordenar os módulos centrais do aplicativo em todas as plataformas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/automaton_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/mobile_navigation.dart';
import '../widgets/desktop_navigation.dart';
import '../../core/services/simulation_highlight_service.dart';
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
  final SimulationHighlightService _fallbackHighlightService =
      SimulationHighlightService();

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
    _fallbackHighlightService.clear();
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
    final hasCanvasHighlight =
        currentIndex == 0 || currentIndex == 2 || currentIndex == 3;

    // Handle navigation changes
    if (_lastNavigationIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) {
          return;
        }

        final currentPage =
            _pageController.page?.round() ?? _pageController.initialPage;
        if (currentPage == currentIndex) {
          return;
        }

        _pageController.jumpToPage(currentIndex);
      });
      _lastNavigationIndex = currentIndex;
    }

    final theme = Theme.of(context);
    final pageView = PageView(
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
    );

    final scaffold = Scaffold(
      appBar: AppBar(
        title: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getCurrentPageTitle(currentIndex)),
                  Text(
                    _getCurrentPageDescription(currentIndex),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getCurrentPageTitle(currentIndex)),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      _getCurrentPageDescription(currentIndex),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
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
      body: isMobile
          ? pageView
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: DesktopNavigation(
                    currentIndex: currentIndex,
                    onDestinationSelected: _onNavigationTap,
                    items: _navigationItems,
                    extended: screenSize.width >= 1440,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: pageView),
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

    if (hasCanvasHighlight) {
      return scaffold;
    }

    _fallbackHighlightService.clear();

    return ProviderScope(
      overrides: [
        canvasHighlightServiceProvider.overrideWithValue(
          _fallbackHighlightService,
        ),
      ],
      child: scaffold,
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context, int currentIndex) {
    // Show different FABs based on current page
    switch (currentIndex) {
      case 0: // FSA – redundant, handled via canvas toolbar
        return null;
      default:
        return null;
    }
  }

  Future<void> _createNewAutomaton(BuildContext context) async {
    final automatonNotifier = ref.read(automatonStateProvider.notifier);

    await automatonNotifier.createAutomaton(
      name: 'Untitled Automaton',
      alphabet: const ['0', '1'],
    );

    if (!mounted) return;

    final automatonState = ref.read(automatonStateProvider);
    if (automatonState.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(automatonState.error!)));
      return;
    }

    ref.read(homeNavigationProvider.notifier).goToFsa();
  }

  void _showHelpDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpPage()));
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => SettingsPage()));
  }
}
