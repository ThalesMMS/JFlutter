import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/dfa.dart' show ValidationResult;
import '../providers/nfa_provider.dart';
import '../providers/conversion_provider.dart';
import '../utils/constants.dart';
import '../models/nfa.dart';
import '../widgets/state_diagram.dart';
import 'input_tabs.dart';
import 'operational_tabs.dart';
import '../widgets/enhanced_state_diagram.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  int _currentTabIndex = 0;
  bool _isValidating = false;

  bool _showDiagramMinimap = true;
  bool _enableDiagramAnimations = true;
  bool _showDiagramAnalytics = false;
  LayoutAlgorithmType _selectedLayout = LayoutAlgorithmType.sugiyama;
  String? _selectedState;
  List<String> _selectedStates = [];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: 0,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    );

    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });

    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildProgressIndicator(),
          if (_currentTabIndex == 4) _buildDiagramControls(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const StatesTab(),
                const AlphabetTab(),
                const TransitionsTab(),
                const ValidationTab(),
                _buildEnhancedDiagramTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.account_tree_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'تعریف NFA',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        if (_currentTabIndex == 4) ...[
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            tooltip: 'تنظیمات دیاگرام',
            onSelected: _handleDiagramSettings,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'minimap',
                child: Row(
                  children: [
                    Icon(_showDiagramMinimap
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                    const SizedBox(width: 8),
                    const Text('نمایش Minimap'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'animations',
                child: Row(
                  children: [
                    Icon(_enableDiagramAnimations
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                    const SizedBox(width: 8),
                    const Text('انیمیشن‌ها'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'analytics',
                child: Row(
                  children: [
                    Icon(_showDiagramAnalytics
                        ? Icons.check_box
                        : Icons.check_box_outline_blank),
                    const SizedBox(width: 8),
                    const Text('پنل تجزیه و تحلیل'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.download),
                    const SizedBox(width: 8),
                    const Text('صادرات دیاگرام'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
        Consumer<NFAProvider>(
          builder: (context, nfa, child) {
            final hasData = nfa.currentNFA.states.isNotEmpty ||
                nfa.currentNFA.alphabet.isNotEmpty ||
                nfa.currentNFA.transitions.isNotEmpty;

            return AnimatedScale(
              scale: hasData ? 1.0 : 0.8,
              duration: const Duration(milliseconds: 200),
              child: IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'پاک کردن همه',
                onPressed: hasData ? _showClearDialog : null,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: Theme.of(context).colorScheme.primary,
        isScrollable: true,
        tabs: [
          _buildTab(Icons.radio_button_checked, 'States', 0),
          _buildTab(Icons.text_fields, 'Alphabet', 1),
          _buildTab(Icons.trending_flat, 'Transitions', 2),
          _buildTab(Icons.verified_outlined, 'Validate', 3),
          _buildTab(Icons.account_tree_outlined, 'دیاگرام', 4),
        ],
      ),
    );
  }

  Widget _buildDiagramControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Text('چیدمان: ', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: DropdownButton<LayoutAlgorithmType>(
                    value: _selectedLayout,
                    isExpanded: true,
                    underline: const SizedBox(),
                    style: Theme.of(context).textTheme.bodySmall,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLayout = value);
                      }
                    },
                    items: [
                      DropdownMenuItem(
                        value: LayoutAlgorithmType.sugiyama,
                        child: const Text('سلسله مراتبی'),
                      ),
                      DropdownMenuItem(
                        value: LayoutAlgorithmType.forceDirected,
                        child: const Text('نیرو محور'),
                      ),
                      DropdownMenuItem(
                        value: LayoutAlgorithmType.circular,
                        child: const Text('دایره‌ای'),
                      ),
                      DropdownMenuItem(
                        value: LayoutAlgorithmType.grid,
                        child: const Text('شبکه‌ای'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (_selectedState != null) ...[
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'انتخاب شده: $_selectedState',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () => setState(() => _selectedState = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (_selectedStates.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedStates.length} حالت',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDiagramTab() {
    return Consumer<NFAProvider>(
      builder: (context, nfaProvider, child) {
        final nfa = nfaProvider.currentNFA;

        if (nfa.states.isEmpty) {
          return _buildEmptyDiagramState();
        }

        return EnhancedStateDiagram(
          key: ValueKey(nfa.hashCode),
          automaton: nfa,
          title: 'نمودار NFA',
          description: 'نمایش تعاملی NFA با ${nfa.states.length} حالت',

          // تنظیمات فیچرها
          enablePerformanceOptimization: nfa.states.length > 20,
          enableAdvancedInteractions: true,
          enableCustomThemes: true,
          enableLayoutAlgorithms: true,
          enableMinimap: _showDiagramMinimap,
          enableAnimations: _enableDiagramAnimations,
          enableKeyboardShortcuts: true,
          enableContextMenu: true,
          enableMultiSelection: true,
          enableDragAndDrop: false,

          // تنظیمات نمایش
          showToolbar: false,
          showStatusBar: true,
          showAnalyticsPanel: _showDiagramAnalytics,

          // تنظیمات Layout
          layoutAlgorithm: _selectedLayout,

          // تنظیمات انیمیشن
          animationSettings: AnimationSettings(
            entranceAnimationDuration:
                Duration(milliseconds: _enableDiagramAnimations ? 1200 : 0),
            enablePathAnimation: _enableDiagramAnimations,
            enableRippleEffects: _enableDiagramAnimations,
          ),

          // تنظیمات عملکرد
          performanceSettings: PerformanceSettings(
            enableVirtualization: nfa.states.length > 50,
            enableCaching: true,
            maxVisibleNodes: 100,
          ),

          // تنظیمات پیشرفته
          config: EnhancedDiagramConfig(
            baseConfig: StateDiagramConfig(
              nodeSize: 60,
              fontSize: 14,
              nodeSeparation: 80,
              levelSeparation: 100,
              layoutDirection: LayoutDirection.leftToRight,
            ),
            showTransitionLabels: true,
            showGrid: false,
            enableZoom: true,
            enablePan: true,
            showTooltips: true,
          ),

          // Callbacks
          onStateSelected: _handleStateSelected,
          onMultiStateSelected: _handleMultiStateSelected,
          onTransitionSelected: _handleTransitionSelected,
          onKeyboardShortcut: _handleKeyboardShortcut,
          onContextMenuRequested: _handleContextMenuRequested,
          onAnalyticsUpdate: _handleAnalyticsUpdate,

          // UI سفارشی
          headerWidget: _buildDiagramHeader(nfa),
          footerWidget: _buildDiagramFooter(nfa),
        );
      },
    );
  }

  Widget _buildEmptyDiagramState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'دیاگرام خالی',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'ابتدا حالت‌ها و انتقالات را تعریف کنید',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('شروع تعریف NFA'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagramHeader(NFA nfa) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'NFA با ${nfa.states.length} حالت، ${nfa.alphabet.length} نماد و ${_getTotalTransitions(nfa)} انتقال',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          if (nfa.validate().isValid) ...[
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              'معتبر',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else ...[
            Icon(
              Icons.error,
              size: 16,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              'نامعتبر',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiagramFooter(NFA nfa) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (nfa.startState != null) ...[
            Icon(
              Icons.play_arrow,
              size: 14,
              color: Colors.green,
            ),
            const SizedBox(width: 4),
            Text(
              'شروع: ${nfa.startState}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 16),
          ],
          if (nfa.finalStates.isNotEmpty) ...[
            Icon(
              Icons.flag,
              size: 14,
              color: Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              'پایان: ${nfa.finalStates.join(", ")}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const Spacer(),
          Text(
            'کلیک کنید تا حالت انتخاب شود',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String text, int index) {
    final isSelected = _currentTabIndex == index;
    return Tab(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Consumer<NFAProvider>(
      builder: (context, nfa, child) {
        final hasStates = nfa.currentNFA.states.isNotEmpty;
        final hasAlphabet = nfa.currentNFA.alphabet.isNotEmpty;
        final hasTransitions = nfa.currentNFA.transitions.isNotEmpty;
        final isValid = nfa.currentNFA.validate().isValid;

        final progress = [hasStates, hasAlphabet, hasTransitions, isValid]
                .where((x) => x)
                .length /
            4.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'پیشرفت: ${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${[
                      hasStates,
                      hasAlphabet,
                      hasTransitions,
                      isValid
                    ].where((x) => x).length}/4 مرحله',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: double.infinity,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<NFAProvider>(
      builder: (context, nfa, child) {
        final validationResult = nfa.currentNFA.validate();
        final canConvert = validationResult.isValid;

        return ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton.extended(
            onPressed: _isValidating ? null : _startConversion,
            backgroundColor: canConvert
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
            foregroundColor: canConvert
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            icon: _isValidating
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_isValidating ? 'در حال بررسی...' : 'تبدیل به DFA'),
            heroTag: "convertFAB",
          ),
        );
      },
    );
  }

  void _handleStateSelected(String state) {
    setState(() {
      _selectedState = state;
    });

    // نمایش اطلاعات state در snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('حالت انتخاب شده: $state'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _handleMultiStateSelected(List<String> states) {
    setState(() {
      _selectedStates = states;
    });
  }

  void _handleTransitionSelected(String from, String to, String symbol) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('انتقال: $from --$symbol--> $to'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  void _handleKeyboardShortcut(String action) {
    print('Keyboard shortcut: $action');
  }

  void _handleContextMenuRequested(BuildContext context, String state) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('حالت $state'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اطلاعات حالت:'),
            const SizedBox(height: 8),
            Text('• نام: $state'),
            Consumer<NFAProvider>(
              builder: (context, nfa, child) {
                final isStart = nfa.currentNFA.startState == state;
                final isFinal = nfa.currentNFA.finalStates.contains(state);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '• نوع: ${isStart ? "شروع" : (isFinal ? "پایان" : "عادی")}'),
                    Text(
                        '• تعداد انتقالات: ${_getStateTransitionCount(nfa.currentNFA, state)}'),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  void _handleAnalyticsUpdate(Map<String, dynamic> analytics) {
    print('Analytics updated: $analytics');
  }

  void _handleDiagramSettings(String setting) {
    setState(() {
      switch (setting) {
        case 'minimap':
          _showDiagramMinimap = !_showDiagramMinimap;
          break;
        case 'animations':
          _enableDiagramAnimations = !_enableDiagramAnimations;
          break;
        case 'analytics':
          _showDiagramAnalytics = !_showDiagramAnalytics;
          break;
        case 'export':
          _exportDiagram();
          break;
      }
    });
  }

  void _exportDiagram() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('قابلیت صادرات به زودی اضافه خواهد شد'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper methods
  int _getTotalTransitions(NFA nfa) {
    int total = 0;
    nfa.transitions.forEach((from, symbols) {
      symbols.forEach((symbol, toStates) {
        total += toStates.length;
      });
    });
    return total;
  }

  int _getStateTransitionCount(NFA nfa, String state) {
    int count = 0;
    final stateTransitions = nfa.transitions[state];
    if (stateTransitions != null) {
      stateTransitions.forEach((symbol, toStates) {
        count += toStates.length;
      });
    }
    return count;
  }

  Future<void> _startConversion() async {
    if (!mounted) return;

    setState(() => _isValidating = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
    final validationResult = nfaProvider.currentNFA.validate();
    if (!mounted) return;

    setState(() => _isValidating = false);

    if (validationResult.isValid) {
      _fabAnimationController.reverse();
      HapticFeedback.lightImpact();

      final conversionProvider =
          Provider.of<ConversionProvider>(context, listen: false);
      conversionProvider.startConversion(nfaProvider.currentNFA);

      await Navigator.pushNamed(context, AppRoutes.conversion);

      if (mounted) {
        _tabController.animateTo(0);
        _fabAnimationController.forward();
      }
    } else {
      HapticFeedback.mediumImpact();
      _showValidationError(validationResult);
      _tabController.animateTo(3);
    }
  }

  void _showValidationError(ValidationResult result) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('خطاهای اعتبارسنجی'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('لطفاً ابتدا خطاهای زیر را برطرف کنید:'),
            const SizedBox(height: 12),
            ...result.errors.take(3).map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(error)),
                    ],
                  ),
                )),
            if (result.errors.length > 3)
              Text(
                '... و ${result.errors.length - 3} خطای دیگر',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('متوجه شدم'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDialog() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 8),
            const Text('پاک کردن NFA'),
          ],
        ),
        content: const Text(
          'آیا از پاک کردن تمام اطلاعات وارد شده مطمئن هستید؟\nاین عمل قابل بازگشت نیست.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('پاک کردن'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      Provider.of<NFAProvider>(context, listen: false).clear();

      setState(() {
        _selectedState = null;
        _selectedStates.clear();
      });
    }
  }
}
