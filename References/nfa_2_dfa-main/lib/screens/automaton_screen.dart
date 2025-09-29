import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nfa_provider.dart';
import '../models/nfa.dart';
import '../models/dfa.dart';
import '../utils/constants.dart';
import 'dart:convert';

class CreateAutomatonScreen extends StatefulWidget {
  const CreateAutomatonScreen({super.key});

  @override
  State<CreateAutomatonScreen> createState() => _CreateAutomatonScreenState();
}

class _CreateAutomatonScreenState extends State<CreateAutomatonScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Text Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _symbolController = TextEditingController();

  // Data Lists
  List<String> _states = [];
  Set<String> _alphabet = {};
  Map<String, Map<String, Set<String>>> _transitions = {};
  String? _initialState;
  Set<String> _finalStates = {};

  // UI Control Variables
  bool _isNFA = true;
  bool _isCreating = false;
  int _currentStep = 0;

  // Stepper steps
  final List<StepInfo> _steps = [
    StepInfo(
      title: 'اطلاعات پایه',
      icon: Icons.info,
      description: 'نام و نوع اتوماتا را تعریف کنید',
    ),
    StepInfo(
      title: 'حالت‌ها',
      icon: Icons.circle,
      description: 'حالت‌های اتوماتا را اضافه کنید',
    ),
    StepInfo(
      title: 'الفبا',
      icon: Icons.abc,
      description: 'نمادهای ورودی را تعریف کنید',
    ),
    StepInfo(
      title: 'انتقال‌ها',
      icon: Icons.arrow_forward,
      description: 'قوانین انتقال را تنظیم کنید',
    ),
    StepInfo(
      title: 'حالت‌های پایانی',
      icon: Icons.flag,
      description: 'حالت‌های پذیرش را انتخاب کنید',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _stateController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _addState() {
    String state = _stateController.text.trim();
    if (state.isNotEmpty && !_states.contains(state)) {
      setState(() {
        _states.add(state);
        _transitions[state] = {};
        if (_initialState == null) {
          _initialState = state;
        }
      });
      _stateController.clear();
    }
  }

  void _removeState(String state) {
    setState(() {
      _states.remove(state);
      _transitions.remove(state);
      for (var from in _transitions.keys) {
        for (var symbol in _transitions[from]!.keys.toList()) {
          _transitions[from]![symbol]!.remove(state);
          if (_transitions[from]![symbol]!.isEmpty) {
            _transitions[from]!.remove(symbol);
          }
        }
      }
      if (_initialState == state) {
        _initialState = _states.isNotEmpty ? _states.first : null;
      }
      _finalStates.remove(state);
    });
  }

  void _addSymbol() {
    String symbol = _symbolController.text.trim();
    if (symbol.isNotEmpty && !_alphabet.contains(symbol)) {
      setState(() {
        _alphabet.add(symbol);
      });
      _symbolController.clear();
    }
  }

  void _removeSymbol(String symbol) {
    setState(() {
      _alphabet.remove(symbol);
      for (var state in _transitions.keys) {
        _transitions[state]!.remove(symbol);
      }
    });
  }

  void _addTransition(String fromState, String symbol, String toState) {
    setState(() {
      if (!_transitions[fromState]!.containsKey(symbol)) {
        _transitions[fromState]![symbol] = {};
      }
      _transitions[fromState]![symbol]!.add(toState);
    });
  }

  void _removeTransition(String fromState, String symbol, String toState) {
    setState(() {
      _transitions[fromState]![symbol]!.remove(toState);
      if (_transitions[fromState]![symbol]!.isEmpty) {
        _transitions[fromState]!.remove(symbol);
      }
    });
  }

  Future<void> _createAutomaton() async {
    if (_nameController.text.trim().isEmpty) {
      _showErrorSnackBar('لطفاً نام اتوماتا را وارد کنید');
      return;
    }
    if (_states.isEmpty) {
      _showErrorSnackBar('لطفاً حداقل یک حالت اضافه کنید');
      return;
    }
    if (_alphabet.isEmpty) {
      _showErrorSnackBar('لطفاً حداقل یک نماد اضافه کنید');
      return;
    }
    if (_initialState == null) {
      _showErrorSnackBar('لطفاً حالت اولیه را انتخاب کنید');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      Map<String, dynamic> automatonJson = {
        'name': _nameController.text.trim(),
        'type': _isNFA ? 'NFA' : 'DFA',
        'states': _states,
        'alphabet': _alphabet.toList(),
        'transitions': _transitions.map((from, transMap) => MapEntry(
              from,
              transMap.map((symbol, toStates) => MapEntry(
                    symbol,
                    _isNFA ? toStates.toList() : toStates.first,
                  )),
            )),
        'startState': _initialState,
        'finalStates': _finalStates.toList(),
      };

      NFA nfa = NFA.fromJson(automatonJson);

      final nfaProvider = Provider.of<NFAProvider>(context, listen: false);

      await nfaProvider.saveNewProject(
          _nameController.text.trim(), automatonJson);

      _showSuccessSnackBar('اتوماتا با موفقیت ایجاد شد');

      if (mounted) {
        Navigator.pop(context, nfa);
      }
    } catch (e) {
      _showErrorSnackBar('خطا در ایجاد اتوماتا: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'بستن',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'بستن',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ایجاد اتوماتای جدید'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_currentStep > 0)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousStep,
              tooltip: 'مرحله قبل',
            ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'راهنما',
          ),
        ],
      ),
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Column(
          children: [
            _buildProgressIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: _buildCurrentStepContent(),
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          Row(
            children: _steps.asMap().entries.map((entry) {
              int index = entry.key;
              StepInfo step = entry.value;
              bool isActive = index == _currentStep;
              bool isCompleted = index < _currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted
                            ? Colors.green
                            : isActive
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                      ),
                      child: Icon(
                        isCompleted ? Icons.check : step.icon,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    if (index < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color:
                              isCompleted ? Colors.green : Colors.grey.shade300,
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _steps[_currentStep].title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            _steps[_currentStep].description,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildStatesStep();
      case 2:
        return _buildAlphabetStep();
      case 3:
        return _buildTransitionsStep();
      case 4:
        return _buildFinalStatesStep();
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نام اتوماتا',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'نام اتوماتا را وارد کنید',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'نوع اتوماتا',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('NFA'),
                        subtitle: const Text('اتوماتای غیرقطعی'),
                        value: true,
                        groupValue: _isNFA,
                        onChanged: (value) => setState(() => _isNFA = value!),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text('DFA'),
                        subtitle: const Text('اتوماتای قطعی'),
                        value: false,
                        groupValue: _isNFA,
                        onChanged: (value) => setState(() => _isNFA = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'افزودن حالت جدید',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _stateController,
                        decoration: const InputDecoration(
                          hintText: 'نام حالت (مثال: q0)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.circle_outlined),
                        ),
                        onSubmitted: (_) => _addState(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addState,
                      child: const Text('افزودن'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_states.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'حالت‌های تعریف شده (${_states.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _states
                        .map((state) => Chip(
                              label: Text(state),
                              avatar: _initialState == state
                                  ? const Icon(Icons.start, size: 16)
                                  : null,
                              onDeleted: () => _removeState(state),
                              deleteIcon: const Icon(Icons.close, size: 16),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'حالت اولیه',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  DropdownButton<String>(
                    value: _initialState,
                    hint: const Text('انتخاب حالت اولیه'),
                    isExpanded: true,
                    items: _states
                        .map((state) => DropdownMenuItem(
                              value: state,
                              child: Text(state),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _initialState = value),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlphabetStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'افزودن نماد جدید',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _symbolController,
                        decoration: const InputDecoration(
                          hintText: 'نماد (مثال: a, b, 0, 1, ε)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.abc),
                        ),
                        onSubmitted: (_) => _addSymbol(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addSymbol,
                      child: const Text('افزودن'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_isNFA)
                      ActionChip(
                        label: const Text('ε (اپسیلون)'),
                        onPressed: () {
                          _symbolController.text = 'ε';
                          _addSymbol();
                        },
                      ),
                    ActionChip(
                      label: const Text('0,1 (باینری)'),
                      onPressed: () {
                        if (!_alphabet.contains('0')) {
                          setState(() => _alphabet.add('0'));
                        }
                        if (!_alphabet.contains('1')) {
                          setState(() => _alphabet.add('1'));
                        }
                      },
                    ),
                    ActionChip(
                      label: const Text('a,b (حروف)'),
                      onPressed: () {
                        if (!_alphabet.contains('a')) {
                          setState(() => _alphabet.add('a'));
                        }
                        if (!_alphabet.contains('b')) {
                          setState(() => _alphabet.add('b'));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_alphabet.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الفبای تعریف شده Σ = {${_alphabet.join(', ')}}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _alphabet
                        .map((symbol) => Chip(
                              label: Text(symbol),
                              backgroundColor:
                                  symbol == 'ε' ? Colors.orange.shade100 : null,
                              onDeleted: () => _removeSymbol(symbol),
                              deleteIcon: const Icon(Icons.close, size: 16),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransitionsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تنظیم انتقال‌ها',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ..._states
            .map((fromState) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'از حالت: $fromState',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        ..._alphabet.map(
                            (symbol) => _buildTransitionRow(fromState, symbol)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildTransitionRow(String fromState, String symbol) {
    Set<String> currentTransitions = _transitions[fromState]?[symbol] ?? {};

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text('$symbol →'),
          ),
          Expanded(
            child: Wrap(
              spacing: 4,
              children: [
                ...currentTransitions.map((toState) => Chip(
                      label: Text(toState),
                      onDeleted: () =>
                          _removeTransition(fromState, symbol, toState),
                      deleteIcon: const Icon(Icons.close, size: 16),
                    )),
                if (_isNFA || currentTransitions.isEmpty)
                  ActionChip(
                    label: const Icon(Icons.add, size: 16),
                    onPressed: () =>
                        _showAddTransitionDialog(fromState, symbol),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalStatesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'انتخاب حالت‌های پذیرش',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'حالت‌هایی که اتوماتا در آن‌ها کلمه ورودی را می‌پذیرد:',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ..._states.map((state) => CheckboxListTile(
                      title: Text(state),
                      value: _finalStates.contains(state),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _finalStates.add(state);
                          } else {
                            _finalStates.remove(state);
                          }
                        });
                      },
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'خلاصه اتوماتا',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('نام: ${_nameController.text.trim()}'),
                Text('نوع: ${_isNFA ? "NFA" : "DFA"}'),
                Text('حالت‌ها: ${_states.length}'),
                Text('الفبا: ${_alphabet.length}'),
                Text('حالت اولیه: $_initialState'),
                Text('حالت‌های پذیرش: ${_finalStates.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('قبلی'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isCreating
                  ? null
                  : _currentStep < _steps.length - 1
                      ? _nextStep
                      : _createAutomaton,
              child: _isCreating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_currentStep < _steps.length - 1
                      ? 'بعدی'
                      : 'ایجاد اتوماتا'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransitionDialog(String fromState, String symbol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('افزودن انتقال از $fromState با $symbol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _states
              .map((toState) => ListTile(
                    title: Text(toState),
                    onTap: () {
                      _addTransition(fromState, symbol, toState);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('راهنمای ایجاد اتوماتا'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('مراحل ایجاد اتوماتا:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('1. اطلاعات پایه: نام و نوع اتوماتا'),
              Text('2. حالت‌ها: تعریف حالت‌های اتوماتا'),
              Text('3. الفبا: تعریف نمادهای ورودی'),
              Text('4. انتقال‌ها: تنظیم قوانین انتقال'),
              Text('5. حالت‌های پذیرش: انتخاب حالت‌های پایانی'),
              SizedBox(height: 16),
              Text('تعاریف نظری:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  '• DFA: اتوماتای متناهی قطعی - هر حالت و نماد دقیقاً یک انتقال'),
              Text(
                  '• NFA: اتوماتای متناهی غیرقطعی - امکان چندین انتقال یا ε-انتقال'),
              SizedBox(height: 16),
              Text('نکات مهم:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• نام حالت‌ها باید منحصر به فرد باشد'),
            ],
          ),
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
}

class StepInfo {
  final String title;
  final IconData icon;
  final String description;

  StepInfo({
    required this.title,
    required this.icon,
    required this.description,
  });
}
