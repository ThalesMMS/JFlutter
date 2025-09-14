import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/automaton_provider.dart';
import '../../core/entities/automaton_entity.dart';
import '../widgets/automaton_canvas.dart';
import '../widgets/automaton_controls.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/enhanced_algoview.dart';
import '../widgets/contextual_help.dart';
import '../widgets/mobile_navigation.dart';
import '../../injection/dependency_injection.dart';
import '../../core/algo_log.dart';
import 'cfg_page.dart';
import 'parsing_page.dart';
import 'mealy_moore_page.dart';

/// Main home page with clean architecture
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TabController _tabController;
  late final PageController _pageController;
  final Map<AutomatonType, AutomatonProvider> _providers = {};
  int _currentIndex = 0;

  // Navigation items for mobile
  final List<NavigationItem> _navigationItems = const [
    NavigationItem(label: 'AFD', icon: Icons.account_tree),
    NavigationItem(label: 'AFN', icon: Icons.account_tree_outlined),
    NavigationItem(label: 'GR', icon: Icons.text_fields),
    NavigationItem(label: 'GLC', icon: Icons.code),
    NavigationItem(label: 'LL/LR', icon: Icons.analytics),
    NavigationItem(label: 'Mealy', icon: Icons.input),
    NavigationItem(label: 'Moore', icon: Icons.output),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _pageController = PageController();
    _initializeProviders();
  }

  void _initializeProviders() {
    // Create separate providers for each automaton type
    for (final type in AutomatonType.values) {
      if (type != AutomatonType.regex) {
        _providers[type] = getIt<AutomatonProvider>();
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
    _tabController.animateTo(index);
  }

  String _getCurrentTabTitle() {
    switch (_currentIndex) {
      case 0:
        return 'AFD';
      case 1:
        return 'AFN';
      case 2:
        return 'Gramática Regular';
      case 3:
        return 'Gramáticas Livres de Contexto';
      case 4:
        return 'Parsing LL/LR';
      case 5:
        return 'Máquina Mealy';
      case 6:
        return 'Máquina Moore';
      default:
        return 'JFlutter';
    }
  }

  void _showHelpPanel() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpPanel(
          title: 'Ajuda do JFlutter',
          sections: const [
            HelpSection(
              title: 'Canvas e Interação',
              content: HelpContent.canvasBasics,
              icon: Icons.touch_app,
              subtitle: 'Como usar o canvas para criar e editar autômatos',
            ),
            HelpSection(
              title: 'Tipos de Autômatos',
              content: HelpContent.automatonTypes,
              icon: Icons.account_tree,
              subtitle: 'Diferenças entre AFD, AFN e Gramáticas',
            ),
            HelpSection(
              title: 'Algoritmos',
              content: HelpContent.algorithms,
              icon: Icons.settings,
              subtitle: 'Operações disponíveis para autômatos',
            ),
            HelpSection(
              title: 'Simulação',
              content: HelpContent.simulation,
              icon: Icons.play_arrow,
              subtitle: 'Como testar palavras nos autômatos',
            ),
            HelpSection(
              title: 'Layout e Posicionamento',
              content: HelpContent.layoutTools,
              icon: Icons.view_module,
              subtitle: 'Ferramentas para organizar estados',
            ),
            HelpSection(
              title: 'Atalhos de Teclado',
              content: HelpContent.keyboardShortcuts,
              icon: Icons.keyboard,
              subtitle: 'Comandos rápidos para produtividade',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: _getCurrentTabTitle(),
        actions: [
          IconButton(
            onPressed: _showHelpPanel,
            icon: const Icon(Icons.help),
            tooltip: 'Ajuda completa',
          ),
        ],
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      bottomNavigationBar: isMobile ? MobileNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavigationTap,
        items: _navigationItems,
      ) : null,
    );
  }

  Widget _buildMobileLayout() {
    return MobilePageView(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      children: [
        _buildModeView(AutomatonType.dfa, 'AFD (Determinístico)', true),
        _buildModeView(AutomatonType.nfa, 'AFN/AFNλ (Não‑Determinístico)', true),
        _buildModeView(AutomatonType.grammar, 'Gramática/Regex', true),
        const CFGPage(),
        const ParsingPage(),
        const MealyMoorePage(isMealy: true),
        const MealyMoorePage(isMealy: false),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildModeView(AutomatonType.dfa, 'AFD (Determinístico)', false),
        _buildModeView(AutomatonType.nfa, 'AFN/AFNλ (Não‑Determinístico)', false),
        _buildModeView(AutomatonType.grammar, 'Gramática/Regex', false),
        const CFGPage(),
        const ParsingPage(),
        const MealyMoorePage(isMealy: true),
        const MealyMoorePage(isMealy: false),
      ],
    );
  }

  Widget _buildModeView(AutomatonType type, String label, bool isMobile) {
    final provider = _providers[type];
    if (provider == null) {
      return Center(
        child: Text('Provider not found for $type'),
      );
    }

    return ChangeNotifierProvider.value(
      value: provider,
      child: _ModeView(
        modeLabel: label,
        type: type,
        isMobile: isMobile,
      ),
    );
  }
}

class _ModeView extends StatefulWidget {
  final String modeLabel;
  final AutomatonType type;
  final bool isMobile;

  const _ModeView({
    required this.modeLabel,
    required this.type,
    required this.isMobile,
  });

  @override
  State<_ModeView> createState() => _ModeViewState();
}

class _ModeViewState extends State<_ModeView> {
  bool _showControls = true;
  bool _showAlgoview = false;
  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // On mobile, start with controls hidden for AFD, AFN and GR as requested
    final isMobile = WidgetsBinding.instance.platformDispatcher.views.isNotEmpty
        ? (WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width /
                WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio) <
            768
        : false;
    if (isMobile && (widget.type == AutomatonType.dfa || widget.type == AutomatonType.nfa || widget.type == AutomatonType.grammar)) {
      _showControls = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AutomatonProvider>(
      builder: (context, provider, child) {
        if (widget.isMobile) {
          return _buildMobileLayout(provider);
        } else {
          return _buildDesktopLayout(provider);
        }
      },
    );
  }

  Widget _buildMobileLayout(AutomatonProvider provider) {
    return Column(
      children: [
        // Mobile controls toggle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showControls = !_showControls),
                  icon: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
                  label: Text(_showControls ? 'Ocultar Controles' : 'Mostrar Controles'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => setState(() => _showAlgoview = !_showAlgoview),
                  icon: Icon(_showAlgoview ? Icons.visibility_off : Icons.play_circle_outline),
                  label: Text(_showAlgoview ? 'Ocultar Algoritmo' : 'Mostrar Algoritmo'),
                ),
              ),
            ],
          ),
        ),
        
        // Controls panel (collapsible on mobile)
        if (_showControls) ...[
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AutomatonControls(
                    type: widget.type,
                    canvasKey: _canvasKey,
                    onAutomatonChanged: (automaton) {
                      // Handle automaton changes
                    },
                  ),
                  const SizedBox(height: 16),
                  AlgorithmPanel(type: widget.type),
                ],
              ),
            ),
          ),
        ],
        
        // Algorithm viewer panel (collapsible on mobile)
        if (_showAlgoview) ...[
          Expanded(
            flex: 1,
            child: ValueListenableBuilder<List<String>>(
              valueListenable: AlgoLog.lines,
              builder: (context, logLines, child) {
                return ValueListenableBuilder<Set<String>>(
                  valueListenable: AlgoLog.highlights,
                  builder: (context, highlightedStates, child) {
                    return EnhancedAlgoview(
                      logLines: logLines,
                      highlightedStates: highlightedStates,
                      isRunning: false, // TODO: Connect to algorithm execution state
                      onPlay: () {
                        // TODO: Implement play functionality
                      },
                      onPause: () {
                        // TODO: Implement pause functionality
                      },
                      onStep: () {
                        // TODO: Implement step functionality
                      },
                      onReset: () {
                        AlgoLog.clear();
                      },
                      onSpeedChanged: (speed) {
                        // TODO: Implement speed change functionality
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
        
        // Canvas (full width on mobile)
        Expanded(
          flex: _showControls ? 2 : 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: AutomatonCanvas(
              automaton: provider.currentAutomaton,
              canvasKey: _canvasKey,
              onAutomatonChanged: (automaton) {
                // Persist canvas-initiated changes in the provider so UI updates immediately
                provider.setAutomaton(automaton);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AutomatonProvider provider) {
    return Row(
      children: [
        // Left panel - Controls
        Expanded(
          flex: 2,
          child: Column(
            children: [
              AutomatonControls(
                type: widget.type,
                canvasKey: _canvasKey,
                onAutomatonChanged: (automaton) {
                  // Handle automaton changes
                },
              ),
              const SizedBox(height: 16),
              AlgorithmPanel(type: widget.type),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Canvas
        Expanded(
          flex: 3,
          child: AutomatonCanvas(
            automaton: provider.currentAutomaton,
            canvasKey: _canvasKey,
            onAutomatonChanged: (automaton) {
              provider.setAutomaton(automaton);
            },
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Algorithm Viewer
        Expanded(
          flex: 2,
          child: ValueListenableBuilder<List<String>>(
            valueListenable: AlgoLog.lines,
            builder: (context, logLines, child) {
              return ValueListenableBuilder<Set<String>>(
                valueListenable: AlgoLog.highlights,
                builder: (context, highlightedStates, child) {
                  return EnhancedAlgoview(
                    logLines: logLines,
                    highlightedStates: highlightedStates,
                    isRunning: false, // TODO: Connect to algorithm execution state
                    onPlay: () {
                      // TODO: Implement play functionality
                    },
                    onPause: () {
                      // TODO: Implement pause functionality
                    },
                    onStep: () {
                      // TODO: Implement step functionality
                    },
                    onReset: () {
                      AlgoLog.clear();
                    },
                    onSpeedChanged: (speed) {
                      // TODO: Implement speed change functionality
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
