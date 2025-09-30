import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/nfa.dart';
import '../models/dfa.dart';
import '../providers/conversion_provider.dart';
import '../utils/constants.dart';
import '../widgets/enhanced_state_diagram.dart';
import '../widgets/transition_table.dart';

int _getConversionTimeMs(ConversionResult result) {
  try {
    final dynamic obj = result;

    // Check for conversionTime
    if (obj.runtimeType.toString().contains('conversionTime')) {
      final duration = (obj as dynamic).conversionTime as Duration?;
      return duration?.inMilliseconds ?? 0;
    }

    // Check for conversionDuration
    if (obj.runtimeType.toString().contains('conversionDuration')) {
      final duration = (obj as dynamic).conversionDuration as Duration?;
      return duration?.inMilliseconds ?? 0;
    }

    // Check for duration
    if (obj.runtimeType.toString().contains('duration')) {
      final duration = (obj as dynamic).duration as Duration?;
      return duration?.inMilliseconds ?? 0;
    }

    return 0;
  } catch (e) {
    return 0;
  }
}

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is! ConversionResult || !args.isSuccess) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('خطا'),
          backgroundColor: Colors.red.shade50,
          foregroundColor: Colors.red.shade800,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'نتیجه تبدیل معتبر نیست یا یافت نشد.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('بازگشت'),
              ),
            ],
          ),
        ),
      );
    }

    final ConversionResult result = args;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('نتیجه تبدیل DFA'),
            ],
          ),
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'اشتراک‌گذاری',
              onPressed: () => _shareResult(result),
            ),
            IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'بازگشت به صفحه اصلی',
              onPressed: () => Navigator.popUntil(
                context,
                ModalRoute.withName(AppRoutes.home),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.normal,
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.dashboard_outlined), text: 'خلاصه'),
                  Tab(
                    icon: Icon(Icons.table_chart_outlined),
                    text: 'جدول انتقال',
                  ),
                  Tab(
                    icon: Icon(Icons.play_circle_outline),
                    text: 'آزمایش رشته',
                  ),
                  Tab(icon: Icon(Icons.account_tree_outlined), text: 'نمودار'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _SummaryTab(result: result),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TransitionTable(
                dfa: result.dfa!,
                showHeaders: true,
                enableInteraction: true,
              ),
            ),
            _StringTesterTab(dfa: result.dfa!),
            _DiagramTab(dfa: result.dfa!),
          ],
        ),
      ),
    );
  }

  void _shareResult(ConversionResult result) {
    final conversionTimeMs = _getConversionTimeMs(result);

    final summary =
        '''
نتیجه تبدیل NFA به DFA:
• تعداد حالت‌های NFA: ${result.nfa!.states.length}
• تعداد حالت‌های DFA: ${result.dfa!.states.length}
• تعداد نمادهای الفبا: ${result.dfa!.alphabet.length}
• زمان تبدیل: $conversionTimeMs میلی‌ثانیه
''';

    Clipboard.setData(ClipboardData(text: summary));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check, color: Colors.white),
            SizedBox(width: 8),
            Text('خلاصه نتیجه کپی شد'),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _SummaryTab extends StatefulWidget {
  final ConversionResult result;
  const _SummaryTab({required this.result});

  @override
  State<_SummaryTab> createState() => _SummaryTabState();
}

class _SummaryTabState extends State<_SummaryTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animations = List.generate(4, (index) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _animController,
          curve: Interval(index * 0.2, 1.0, curve: Curves.elasticOut),
        ),
      );
    });

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnimatedBuilder(
          animation: _animations[0],
          builder: (context, child) => Transform.scale(
            scale: _animations[0].value,
            child: _buildStatsCard(context),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _animations[1],
          builder: (context, child) => Transform.translate(
            offset: Offset((1 - _animations[1].value) * 200, 0),
            child: Opacity(
              opacity: _animations[1].value,
              child: _buildComparisonCard(context),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (widget.result.warnings.isNotEmpty)
          AnimatedBuilder(
            animation: _animations[2],
            builder: (context, child) => Transform.translate(
              offset: Offset((1 - _animations[2].value) * -200, 0),
              child: Opacity(
                opacity: _animations[2].value,
                child: _buildWarningsCard(context),
              ),
            ),
          ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _animations[3],
          builder: (context, child) => Transform.scale(
            scale: _animations[3].value,
            child: _buildExportCard(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    final conversionTimeMs = _getConversionTimeMs(widget.result);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'آمار کلی',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _EnhancedStatItem(
                    label: 'States NFA',
                    value: widget.result.nfa!.states.length.toString(),
                    icon: Icons.radio_button_unchecked,
                    color: Colors.blue,
                  ),
                  _EnhancedStatItem(
                    label: 'States DFA',
                    value: widget.result.dfa!.states.length.toString(),
                    icon: Icons.radio_button_checked,
                    color: Colors.green,
                  ),
                  _EnhancedStatItem(
                    label: 'نمادهای الفبا',
                    value: widget.result.dfa!.alphabet.length.toString(),
                    icon: Icons.abc,
                    color: Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.timer, size: 20, color: Colors.purple),
                        Text(
                          '${conversionTimeMs}ms',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const Text(
                          'زمان تبدیل',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 20,
                          color: Colors.teal,
                        ),
                        Text(
                          '${((widget.result.dfa!.states.length / widget.result.nfa!.states.length) * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const Text(
                          'نسبت حالت‌ها',
                          style: TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.compare_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'مقایسه تفصیلی',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _EnhancedComparisonRow(
              title: 'حالت شروع',
              nfaValue:
                  widget.result.nfa!.startState?.toString() ?? 'تعریف نشده',
              dfaValue:
                  widget.result.dfa!.startState?.toString() ?? 'تعریف نشده',
              icon: Icons.play_arrow,
            ),
            const Divider(height: 32),
            _EnhancedComparisonRow(
              title: 'حالت‌های پایانی',
              nfaValue:
                  '{${widget.result.nfa!.finalStates.map((e) => e.toString()).join(', ')}}',
              dfaValue:
                  '{${widget.result.dfa!.finalStates.map((e) => e.toString()).join(', ')}}',
              icon: Icons.flag,
            ),
            const Divider(height: 32),
            _EnhancedComparisonRow(
              title: 'تعداد انتقالات',
              nfaValue: _getTotalTransitions(widget.result.nfa!).toString(),
              dfaValue: _getTotalTransitions(widget.result.dfa!).toString(),
              icon: Icons.arrow_forward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade50,
              Colors.orange.shade100.withOpacity(0.5),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'هشدارها',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...widget.result.warnings.asMap().entries.map((entry) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.orange.shade200,
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(entry.value)),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.file_download_outlined,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Text(
                  'خروجی و ذخیره‌سازی',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _exportAsJson(),
                    icon: const Icon(Icons.code),
                    label: const Text('ذخیره JSON'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _exportAsText(),
                    icon: const Icon(Icons.text_snippet),
                    label: const Text('ذخیره متنی'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsJson() {
    final conversionTimeMs = _getConversionTimeMs(widget.result);

    final jsonData = {
      'nfa': _automatonToJson(widget.result.nfa!),
      'dfa': _automatonToJson(widget.result.dfa!),
      'conversionTime': conversionTimeMs,
      'warnings': widget.result.warnings,
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
    Clipboard.setData(ClipboardData(text: jsonString));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('داده‌ها به صورت JSON کپی شد')),
    );
  }

  void _exportAsText() {
    final conversionTimeMs = _getConversionTimeMs(widget.result);

    final textData =
        '''
=== نتیجه تبدیل NFA به DFA ===

NFA:
- حالت‌ها: ${widget.result.nfa!.states.map((e) => e.toString()).join(', ')}
- حالت شروع: ${widget.result.nfa!.startState?.toString() ?? 'تعریف نشده'}
- حالت‌های پایانی: ${widget.result.nfa!.finalStates.map((e) => e.toString()).join(', ')}
- الفبا: ${widget.result.nfa!.alphabet.map((e) => e.toString()).join(', ')}

DFA:
- حالت‌ها: ${widget.result.dfa!.states.map((e) => e.toString()).join(', ')}
- حالت شروع: ${widget.result.dfa!.startState?.toString() ?? 'تعریف نشده'}
- حالت‌های پایانی: ${widget.result.dfa!.finalStates.map((e) => e.toString()).join(', ')}
- الفبا: ${widget.result.dfa!.alphabet.map((e) => e.toString()).join(', ')}

آمار:
- زمان تبدیل: $conversionTimeMs میلی‌ثانیه
- تعداد حالت‌های NFA: ${widget.result.nfa!.states.length}
- تعداد حالت‌های DFA: ${widget.result.dfa!.states.length}
''';

    Clipboard.setData(ClipboardData(text: textData));

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('داده‌ها به صورت متن کپی شد')));
  }

  Map<String, dynamic> _automatonToJson(dynamic automaton) {
    return {
      'states': automaton.states?.map((e) => e.toString()).toList() ?? [],
      'alphabet': automaton.alphabet?.map((e) => e.toString()).toList() ?? [],
      'startState': automaton.startState?.toString(),
      'finalStates':
          automaton.finalStates?.map((e) => e.toString()).toList() ?? [],
      'transitions': automaton.transitions,
    };
  }

  int _getTotalTransitions(dynamic automaton) {
    int total = 0;
    try {
      if (automaton?.transitions != null) {
        final transitions = automaton.transitions;
        if (transitions is Map) {
          transitions.forEach((dynamic from, dynamic symbols) {
            if (symbols is Map) {
              symbols.forEach((dynamic symbol, dynamic destinations) {
                if (destinations is List) {
                  total += destinations.length;
                } else {
                  total += 1;
                }
              });
            }
          });
        }
      }
    } catch (e) {
      total = 0;
    }
    return total;
  }
}

class _StringTesterTab extends StatefulWidget {
  final DFA dfa;
  const _StringTesterTab({required this.dfa});

  @override
  State<_StringTesterTab> createState() => _StringTesterTabState();
}

class _StringTesterTabState extends State<_StringTesterTab>
    with TickerProviderStateMixin {
  final _controller = TextEditingController();
  final List<TestResult> _testHistory = [];
  bool? _lastResult;
  String _lastTestString = '';
  late AnimationController _resultAnimController;
  late Animation<double> _resultScaleAnimation;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _resultScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnimController, curve: Curves.elasticOut),
    );
  }

  void _testString() {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لطفاً رشته‌ای وارد کنید')));
      return;
    }

    // بررسی اینکه تمام کاراکترهای رشته در الفبای DFA باشند
    for (int i = 0; i < input.length; i++) {
      if (!widget.dfa.alphabet.contains(input[i])) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('کاراکتر "${input[i]}" در الفبای DFA وجود ندارد'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final result = widget.dfa.acceptsString(input);
    setState(() {
      _lastTestString = input;
      _lastResult = result;
      _testHistory.insert(0, TestResult(input, result, DateTime.now()));
      if (_testHistory.length > 10) {
        _testHistory.removeLast();
      }
    });

    _resultAnimController.reset();
    _resultAnimController.forward();

    // پاک کردن فیلد ورودی بعد از تست
    _controller.clear();
  }

  void _clearHistory() {
    setState(() {
      _testHistory.clear();
      _lastResult = null;
      _lastTestString = '';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // بخش ورودی
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'آزمایش رشته',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'الفبای DFA: {${widget.dfa.alphabet.map((e) => e.toString()).join(', ')}}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            labelText: 'رشته ورودی',
                            hintText: 'رشته‌ای از نمادهای الفبا وارد کنید',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.text_fields),
                          ),
                          style: const TextStyle(fontFamily: 'monospace'),
                          onSubmitted: (_) => _testString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _testString,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Icon(Icons.play_arrow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // نتیجه آخرین تست
          if (_lastResult != null)
            ScaleTransition(
              scale: _resultScaleAnimation,
              child: Card(
                elevation: 4,
                color: _lastResult! ? Colors.green.shade50 : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _lastResult! ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _lastResult! ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'رشته: "$_lastTestString"',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _lastResult! ? 'پذیرفته شد' : 'رد شد',
                              style: TextStyle(
                                color: _lastResult!
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // تاریخچه تست‌ها
          if (_testHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تاریخچه تست‌ها',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('پاک کردن'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Card(
                elevation: 2,
                child: ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _testHistory.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final test = _testHistory[index];
                    return ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: test.result ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          test.result ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        '"${test.input}"',
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      subtitle: Text(
                        _formatTimestamp(test.timestamp),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      trailing: Chip(
                        label: Text(
                          test.result ? 'پذیرفته' : 'رد شده',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: test.result
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        side: BorderSide(
                          color: test.result ? Colors.green : Colors.red,
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else ...[
            // حالت خالی
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'هنوز رشته‌ای تست نشده',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'رشته‌ای وارد کنید و دکمه تست را فشار دهید',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'همین الان';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} دقیقه پیش';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} ساعت پیش';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

// TestResult class
class TestResult {
  final String input;
  final bool result;
  final DateTime timestamp;

  TestResult(this.input, this.result, this.timestamp);
}

class _DiagramTab extends StatefulWidget {
  final DFA dfa;
  const _DiagramTab({required this.dfa});

  @override
  State<_DiagramTab> createState() => _DiagramTabState();
}

class _DiagramTabState extends State<_DiagramTab> {
  bool _showMinimap = true;
  bool _enableAnimations = true;
  LayoutAlgorithmType _selectedLayout = LayoutAlgorithmType.sugiyama;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // نوار کنترل
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text('چیدمان: '),
                    DropdownButton<LayoutAlgorithmType>(
                      value: _selectedLayout,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLayout = value);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: LayoutAlgorithmType.sugiyama,
                          child: Text('سلسله مراتبی'),
                        ),
                        DropdownMenuItem(
                          value: LayoutAlgorithmType.forceDirected,
                          child: Text('نیرو محور'),
                        ),
                        DropdownMenuItem(
                          value: LayoutAlgorithmType.circular,
                          child: Text('دایره‌ای'),
                        ),
                        DropdownMenuItem(
                          value: LayoutAlgorithmType.grid,
                          child: Text('شبکه‌ای'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_showMinimap ? Icons.map : Icons.map_outlined),
                    tooltip: 'تغییر وضعیت Minimap',
                    onPressed: () =>
                        setState(() => _showMinimap = !_showMinimap),
                  ),
                  IconButton(
                    icon: Icon(
                      _enableAnimations
                          ? Icons.animation
                          : Icons.stop_circle_outlined,
                    ),
                    tooltip: 'تغییر وضعیت انیمیشن‌ها',
                    onPressed: () =>
                        setState(() => _enableAnimations = !_enableAnimations),
                  ),
                ],
              ),
            ],
          ),
        ),
        // دیاگرام
        Expanded(
          child: EnhancedStateDiagram(
            key: ValueKey(
              '${_selectedLayout}_${_showMinimap}_${_enableAnimations}',
            ),
            automaton: widget.dfa,
            title: 'نمودار DFA نهایی',
            description: 'نتیجه تبدیل NFA به DFA',
            enableMinimap: _showMinimap,
            enableAnimations: _enableAnimations,
            layoutAlgorithm: _selectedLayout,
            enablePerformanceOptimization: widget.dfa.states.length > 20,
          ),
        ),
      ],
    );
  }
}

// Widget classes for UI components
class _EnhancedStatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _EnhancedStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EnhancedComparisonRow extends StatelessWidget {
  final String title;
  final String nfaValue;
  final String dfaValue;
  final IconData icon;

  const _EnhancedComparisonRow({
    required this.title,
    required this.nfaValue,
    required this.dfaValue,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NFA: $nfaValue',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 4),
              Text(
                'DFA: $dfaValue',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
