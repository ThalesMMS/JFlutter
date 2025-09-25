import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/dfa.dart';
import '../providers/conversion_provider.dart';
import '../providers/nfa_provider.dart';
import '../utils/helpers.dart';
import '../models/nfa.dart';
import '../utils/constants.dart';
import '../utils/transition_helpers.dart';

class TransitionsTab extends StatefulWidget {
  const TransitionsTab({super.key});

  @override
  State<TransitionsTab> createState() => _TransitionsTabState();
}

class _TransitionsTabState extends State<TransitionsTab> with TickerProviderStateMixin {
  String? _fromState;
  String? _symbol;
  String? _toState;

  late final AnimationController _formController;
  late final AnimationController _listController;
  late final AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _formController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _formController.forward();
    _listController.forward();
    _fabController.forward();
  }

  @override
  void dispose() {
    _formController.dispose();
    _listController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _addTransition() async {
    if (_fromState == null || _symbol == null || _toState == null) {
      UIHelpers.showSnackBar(
          context,
          'لطفا تمام فیلدها را برای انتقال انتخاب کنید.',
          isError: true
      );
      return;
    }

    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
    if (nfaProvider.currentNFA.transitions[_fromState!]?[_symbol!]?.contains(_toState!) == true) {
      UIHelpers.showSnackBar(
          context,
          'این انتقال قبلاً وجود دارد.',
          isError: true
      );
      return;
    }

    _formController.reverse().then((_) {
      nfaProvider.addTransition(
        _fromState!,
        _symbol!,
        _toState!,
      );

      setState(() {
        _fromState = null;
        _symbol = null;
        _toState = null;
      });

      HapticFeedback.lightImpact();
      UIHelpers.hideKeyboard(context);
      UIHelpers.showSnackBar(
        context,
        'انتقال با موفقیت اضافه شد.',
        isError: false,
      );
      _formController.forward();
    });
  }

  void _clearForm() {
    setState(() {
      _fromState = null;
      _symbol = null;
      _toState = null;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NFAProvider>(
      builder: (context, nfa, child) {
        final states = nfa.currentNFA.states.toList()..sort();
        final alphabetWithEpsilon = ['ε', ...nfa.currentNFA.alphabet]..sort();
        final transitions = nfa.currentNFA.transitions;

        return Scaffold(
          body: Column(
            children: [
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _formController,
                  curve: Curves.easeOutBack,
                )),
                child: _buildTransitionForm(states, alphabetWithEpsilon),
              ),
              const Divider(height: 1),
              Expanded(
                child: transitions.isEmpty || transitions.values.every((map) => map.isEmpty)
                    ? _buildEmptyTransitions()
                    : _buildTransitionsList(transitions, nfa),
              ),
            ],
          ),
          floatingActionButton: transitions.isNotEmpty && transitions.values.any((map) => map.isNotEmpty)
              ? ScaleTransition(
            scale: _fabController,
            child: FloatingActionButton.extended(
              onPressed: () => _showBulkOperations(context, nfa),
              icon: const Icon(Icons.settings),
              label: const Text('عملیات گروهی'),
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
          )
              : null,
        );
      },
    );
  }

  Widget _buildTransitionForm(List<String> states, List<String> alphabetWithEpsilon) {
    final canAdd = states.isNotEmpty && alphabetWithEpsilon.length > 1;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.trending_flat,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'افزودن انتقال جدید',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'انتقال بین State ها را تعریف کنید',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canAdd && (_fromState != null || _symbol != null || _toState != null))
                    IconButton(
                      onPressed: _clearForm,
                      icon: const Icon(Icons.clear),
                      tooltip: 'پاک کردن فرم',
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (!canAdd)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.errorContainer,
                        Theme.of(context).colorScheme.errorContainer.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نیاز به تعریف اولیه',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ابتدا State ها و نمادهای الفبا را در تب‌های مربوطه تعریف کنید.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildAnimatedDropdown(
                        'از State',
                        states,
                        _fromState,
                            (val) => setState(() => _fromState = val),
                        Icons.radio_button_checked,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnimatedDropdown(
                        'با نماد',
                        alphabetWithEpsilon,
                        _symbol,
                            (val) => setState(() => _symbol = val),
                        Icons.text_fields,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAnimatedDropdown(
                        'به State',
                        states,
                        _toState,
                            (val) => setState(() => _toState = val),
                        Icons.flag,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        onPressed: (_fromState != null && _symbol != null && _toState != null)
                            ? _addTransition
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('افزودن انتقال'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: states.isNotEmpty && alphabetWithEpsilon.length > 1
                            ? () => _showQuickAdd(context)
                            : null,
                        icon: const Icon(Icons.flash_on),
                        label: const Text('سریع'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedDropdown(
      String label,
      List<String> items,
      String? value,
      ValueChanged<String?> onChanged,
      IconData icon,
      ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          prefixIcon: Icon(icon),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        )).toList(),
        onChanged: onChanged,
        isExpanded: true,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildEmptyTransitions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            ),
            child: Icon(
              Icons.trending_flat,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'هیچ انتقالی تعریف نشده',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'انتقال‌های بین State ها را در فرم بالا تعریف کنید',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'مثال: q0 با نماد \'a\' به q1',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransitionsList(Map<String, Map<String, Set<String>>> transitions, NFAProvider nfa) {
    return AnimatedBuilder(
      animation: _listController,
      builder: (context, child) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خلاصه انتقال‌ها',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_getTotalTransitions(transitions)} انتقال از ${transitions.keys.where((k) => transitions[k]!.isNotEmpty).length} State',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...transitions.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
              final fromState = entry.key;
              final symbolTransitions = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    leading: Hero(
                      tag: 'state_$fromState',
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          fromState.length > 2
                              ? fromState.substring(0, 2).toUpperCase()
                              : fromState.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      'از $fromState',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${_countTransitions(symbolTransitions)} انتقال'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _editStateTransitions(fromState, symbolTransitions),
                          tooltip: 'ویرایش انتقال‌ها',
                        ),
                        const Icon(
                          Icons.expand_more,
                        ),
                      ],
                    ),
                    children: symbolTransitions.entries.map((symbolEntry) {
                      final symbol = symbolEntry.key;
                      final toStates = symbolEntry.value;

                      return Column(
                        children: toStates.map((toState) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: symbol == 'ε'
                                        ? [
                                      Theme.of(context).colorScheme.secondaryContainer,
                                      Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                                    ]
                                        : [
                                      Theme.of(context).colorScheme.tertiaryContainer,
                                      Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  symbol,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: symbol == 'ε'
                                        ? Theme.of(context).colorScheme.onSecondaryContainer
                                        : Theme.of(context).colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ),
                              title: RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  children: [
                                    TextSpan(
                                      text: fromState,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    const TextSpan(text: ' → '),
                                    TextSpan(
                                      text: toState,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () => _confirmDeleteTransition(fromState, symbol, toState, nfa),
                                tooltip: 'حذف انتقال',
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  int _countTransitions(Map<String, Set<String>> symbolTransitions) {
    return symbolTransitions.values.fold(0, (sum, states) => sum + states.length);
  }

  int _getTotalTransitions(Map<String, Map<String, Set<String>>> transitions) {
    return transitions.values.fold(0, (sum, symbolTransitions) => sum + _countTransitions(symbolTransitions));
  }

  Future<void> _confirmDeleteTransition(String from, String symbol, String to, NFAProvider nfa) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('حذف انتقال'),
        content: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              const TextSpan(text: 'آیا مطمئن هستید که می‌خواهید انتقال '),
              TextSpan(
                text: from,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' → '),
              TextSpan(
                text: to,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' با نماد '),
              TextSpan(
                text: symbol,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const TextSpan(text: ' را حذف کنید؟'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      HapticFeedback.mediumImpact();
      nfa.removeTransition(from, symbol, to);
      UIHelpers.showSnackBar(
        context,
        'انتقال با موفقیت حذف شد.',
        isError: false,
      );
    }
  }

  void _showQuickAdd(BuildContext context) {
    TransitionHelpers.showQuickAdd(context);
  }

  void _showBulkOperations(BuildContext context, NFAProvider nfa) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'عملیات گروهی',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.clear_all),
              title: const Text('حذف همه انتقال‌ها'),
              onTap: () {
                Navigator.of(context).pop();
                _confirmClearAllTransitions(nfa);
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('صادرات انتقال‌ها'),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearAllTransitions(NFAProvider nfa) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف همه انتقال‌ها'),
        content: const Text('آیا مطمئن هستید که می‌خواهید همه انتقال‌ها را حذف کنید؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              nfa.clearTransitions(); // [MODIFIED] This line is now active
              UIHelpers.showSnackBar(
                context,
                'همه انتقال‌ها حذف شدند.',
                isError: false,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف همه'),
          ),
        ],
      ),
    );
  }

  void _editStateTransitions(String fromState, Map<String, Set<String>> symbolTransitions) {
    TransitionHelpers.showEditStateTransitions(context, fromState, symbolTransitions);
  }
}

// Enhanced Validation Tab
class ValidationTab extends StatefulWidget {
  const ValidationTab({super.key});

  @override
  State<ValidationTab> createState() => _ValidationTabState();
}

class _ValidationTabState extends State<ValidationTab> with TickerProviderStateMixin {
  late final AnimationController _headerController;
  late final AnimationController _contentController;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NFAProvider>(
      builder: (context, nfa, child) {
        final validationResult = nfa.currentNFA.validate();

        if (nfa.currentNFA.states.isEmpty) {
          return _buildGettingStarted();
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _headerController,
                  curve: Curves.easeOutBack,
                )),
                child: _buildStatusHeader(context, validationResult),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _contentController,
                child: _buildQuickStats(context, nfa, validationResult),
              ),
            ),
            if (validationResult.errors.isNotEmpty)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(-0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _contentController,
                    curve: Curves.easeOut,
                  )),
                  child: _buildValidationSection(
                    context,
                    'خطاها',
                    validationResult.errors,
                    Theme.of(context).colorScheme.error,
                    Icons.error_outline,
                  ),
                ),
              ),
            if (validationResult.warnings.isNotEmpty)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.3, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _contentController,
                    curve: Curves.easeOut,
                  )),
                  child: _buildValidationSection(
                    context,
                    'هشدارها',
                    validationResult.warnings,
                    Colors.orange,
                    Icons.warning_amber_rounded,
                  ),
                ),
              ),
            if (validationResult.isValid)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentController,
                  child: _buildSuccessAnalysis(context, nfa),
                ),
              ),
            if (validationResult.isValid)
              SliverToBoxAdapter(
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: _contentController,
                    curve: Curves.easeOut,
                  )),
                  child: _buildDetailedAnalysis(context, nfa),
                ),
              ),
            if (validationResult.isValid)
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _contentController,
                  child: _buildActionsSection(context, nfa),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGettingStarted() {
    final steps = [
      ('۱', 'State ها را تعریف کنید', Icons.radio_button_checked, Colors.blue),
      ('۲', 'الفبا را مشخص کنید', Icons.text_fields, Colors.green),
      ('۳', 'انتقال‌ها را اضافه کنید', Icons.trending_flat, Colors.orange),
      ('۴', 'اعتبارسنجی کنید', Icons.verified_outlined, Colors.purple),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.2),
                    Colors.purple.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rocket_launch_outlined,
                size: 80,
                color: Colors.blue.shade600,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'شروع کنید!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'برای ایجاد NFA خود این مراحل را طی کنید:',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final double start = (index * 0.15).clamp(0.0, 1.0);
              final double end = (start + 0.5).clamp(0.0, 1.0);

              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1.0, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _headerController,
                  curve: Interval(
                    start,
                    end,
                    curve: Curves.easeOut,
                  ),
                )),
                child: _buildStepCard(step.$1, step.$2, step.$3, step.$4),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(String number, String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.3)],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, ValidationResult validationResult) {
    final isValid = validationResult.isValid;
    final color = isValid
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.3),
                      color.withOpacity(0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  isValid ? Icons.verified : Icons.error_outline,
                  color: color,
                  size: 36,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isValid ? 'NFA آماده است!' : 'نیاز به بررسی دارد',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isValid
                          ? 'اتوماتای شما کامل است و می‌توانید به DFA تبدیل کنید'
                          : 'لطفاً ابتدا مشکلات زیر را برطرف کنید',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isValid) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatusCounter(
                    context,
                    'خطا',
                    validationResult.errors.length,
                    Icons.error_outline,
                    Theme.of(context).colorScheme.error,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                  _buildStatusCounter(
                    context,
                    'هشدار',
                    validationResult.warnings.length,
                    Icons.warning_amber_rounded,
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCounter(BuildContext context, String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(BuildContext context, NFAProvider nfa, ValidationResult validationResult) {
    final stats = [
      ('State ها', nfa.currentNFA.states.length, Icons.radio_button_checked, Colors.blue),
      ('الفبا', nfa.currentNFA.alphabet.length, Icons.text_fields, Colors.green),
      ('انتقال‌ها', _getTotalTransitionsCount(nfa.currentNFA.transitions), Icons.trending_flat, Colors.orange),
      ('State پایانی', nfa.currentNFA.finalStates.length, Icons.flag, Colors.purple),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'خلاصه آماری',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: stats.map((stat) {
                  final isLast = stat == stats.last;
                  return Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(context, stat.$1, stat.$2, stat.$3, stat.$4),
                        ),
                        if (!isLast)
                          Container(
                            width: 1,
                            height: 50,
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  int _getTotalTransitionsCount(Map<String, Map<String, Set<String>>> transitions) {
    return transitions.values.fold(0, (sum, symbolTransitions) {
      return sum + symbolTransitions.values.fold(0, (innerSum, states) => innerSum + states.length);
    });
  }

  Widget _buildValidationSection(
      BuildContext context,
      String title,
      List<String> items,
      Color color,
      IconData icon,
      ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color.withOpacity(0.2), color.withOpacity(0.3)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${items.length}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.05),
                          color.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [color.withOpacity(0.2), color.withOpacity(0.3)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(icon, color: color.withOpacity(0.7), size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnalysis(BuildContext context, NFAProvider nfa) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'تبریک! NFA شما آماده است',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...const [
                'می‌توانید چندین State پایانی داشته باشید',
                'انتقال‌های ε (اپسیلون) برای انتقال خودکار استفاده می‌شوند',
                'هر State می‌تواند با یک نماد به چندین State منتقل شود',
                'NFA شما می‌تواند به DFA تبدیل شود',
              ].map((tip) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.primary.withOpacity(0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis(BuildContext context, NFAProvider nfa) {
    final hasEpsilonTransitions = _hasEpsilonTransitions(nfa.currentNFA.transitions);
    final isNonDeterministic = _isNonDeterministic(nfa.currentNFA.transitions);
    final unreachableStates = _findUnreachableStates(nfa.currentNFA);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.science_outlined,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'تحلیل تفصیلی',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildAnalysisItem(
                context,
                'انتقال‌های اپسیلون',
                hasEpsilonTransitions ? 'دارد' : 'ندارد',
                hasEpsilonTransitions,
                hasEpsilonTransitions ? Icons.check_circle : Icons.cancel,
              ),
              _buildAnalysisItem(
                context,
                'غیرقطعیت (Non-determinism)',
                isNonDeterministic ? 'دارد' : 'ندارد',
                isNonDeterministic,
                isNonDeterministic ? Icons.check_circle : Icons.cancel,
              ),
              _buildAnalysisItem(
                context,
                'State های غیرقابل دسترس',
                unreachableStates.isEmpty ? 'ندارد' : '${unreachableStates.length} عدد',
                unreachableStates.isEmpty,
                unreachableStates.isEmpty ? Icons.check_circle : Icons.warning,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(BuildContext context, String label, String value, bool isGood, IconData icon) {
    final color = isGood ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context, NFAProvider nfa) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.rocket_launch,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'عملیات بعدی',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _convertToDFA(context, nfa),
                      icon: const Icon(Icons.transform),
                      label: const Text('تبدیل به DFA'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _testStrings(context, nfa),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('تست رشته‌ها'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasEpsilonTransitions(Map<String, Map<String, Set<String>>> transitions) {
    return transitions.values.any((symbolMap) => symbolMap.containsKey('ε'));
  }

  bool _isNonDeterministic(Map<String, Map<String, Set<String>>> transitions) {
    return transitions.values.any((symbolMap) =>
        symbolMap.values.any((states) => states.length > 1));
  }

  Set<String> _findUnreachableStates(NFA nfa) {
    if (nfa.startState.isEmpty) return nfa.states;

    Set<String> reachable = {};
    List<String> queue = [nfa.startState];
    reachable.add(nfa.startState);

    while (queue.isNotEmpty) {
      String currentState = queue.removeAt(0);
      nfa.transitions[currentState]?.forEach((symbol, toStates) {
        for (var toState in toStates) {
          if (!reachable.contains(toState)) {
            reachable.add(toState);
            queue.add(toState);
          }
        }
      });
    }
    return nfa.states.difference(reachable);
  }

  void _convertToDFA(BuildContext context, NFAProvider nfa) {
    // [MODIFIED]
    final conversionProvider = Provider.of<ConversionProvider>(context, listen: false);
    conversionProvider.startConversion(nfa.currentNFA);
    Navigator.pushNamed(context, AppRoutes.conversion);
  }

  void _testStrings(BuildContext context, NFAProvider nfa) {

    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تست رشته'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'رشته مورد نظر را وارد کنید',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = textController.text;
              Navigator.pop(context);
              final isAccepted = nfa.currentNFA.accepts(input);
              UIHelpers.showSnackBar(
                context,
                'رشته "$input" ${isAccepted ? "پذیرفته شد" : "رد شد"}',
                isError: !isAccepted,
                type: isAccepted ? SnackBarType.success : SnackBarType.error,
              );
            },
            child: const Text('تست'),
          ),
        ],
      ),
    );
  }
}