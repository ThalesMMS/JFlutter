import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../providers/nfa_provider.dart';
import '../services/automaton_operations.dart';
import '../models/dfa.dart';
import '../models/nfa.dart';
import 'automaton_screen.dart';
import 'graph_visualization_screen.dart';

class OperationsScreen extends StatefulWidget {
  const OperationsScreen({super.key});

  @override
  State<OperationsScreen> createState() => _OperationsScreenState();
}

class _OperationsScreenState extends State<OperationsScreen>
    with TickerProviderStateMixin {
  final EnhancedAutomatonOperations _operations = EnhancedAutomatonOperations();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  NFA? _automaton1;
  NFA? _automaton2;

  bool _isOperationInProgress = false;
  String _operationStatus = '';

  final List<OperationInfo> _operationList = [
    OperationInfo(
      name: 'اجتماع (Union)',
      icon: Icons.merge_type,
      color: Colors.blue,
      description: 'ایجاد اتوماتای جدید که زبان هر دو اتوماتا را بپذیرد',
      operationType: OperationType.union,
    ),
    OperationInfo(
      name: 'اشتراک (Intersection)',
      icon: Icons.control_point_duplicate,
      color: Colors.green,
      description: 'ایجاد اتوماتای جدید که تنها کلمات مشترک را بپذیرد',
      operationType: OperationType.intersection,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _createNewAutomaton(BuildContext context, bool isFirst) async {
    final newAutomaton = await Navigator.push<NFA>(
      context,
      MaterialPageRoute(builder: (context) => const CreateAutomatonScreen()),
    );

    if (newAutomaton != null && mounted) {
      setState(() {
        if (isFirst) {
          _automaton1 = newAutomaton;
        } else {
          _automaton2 = newAutomaton;
        }
      });
      _showSuccessSnackBar('اتوماتای جدید با موفقیت انتخاب شد');
    }
  }

  Future<void> _performOperation(OperationInfo operationInfo) async {
    if (_automaton1 == null) {
      _showErrorSnackBar('لطفاً اتوماتای اول را انتخاب کنید');
      return;
    }

    if (operationInfo.requiresSecondAutomaton && _automaton2 == null) {
      _showErrorSnackBar('لطفاً اتوماتای دوم را انتخاب کنید');
      return;
    }

    setState(() {
      _isOperationInProgress = true;
      _operationStatus = 'در حال انجام ${operationInfo.name}...';
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProgressDialog(),
    );

    try {
      dynamic finalAutomaton;
      String resultInfo = '';

      switch (operationInfo.operationType) {
        case OperationType.union:
          final result = await _operations.unionWithOptimization(
            _automaton1!,
            _automaton2!,
          );
          finalAutomaton = result.resultDfa;
          resultInfo = 'DFA حاصل: ${result.resultDfa.stateCount} حالت';
          break;
        case OperationType.intersection:
          final result = await _operations.intersectionWithParallelProcessing(
            _automaton1!,
            _automaton2!,
          );
          finalAutomaton = result.resultDfa;
          resultInfo = 'DFA حاصل: ${result.resultDfa.stateCount} حالت';
          break;
        case OperationType.concatenation:
          final result = await _operations.concatenateWithOptimization(
            _automaton1!,
            _automaton2!,
          );
          finalAutomaton = result.resultNfa;
          resultInfo = 'NFA حاصل: ${result.resultNfa.stateCount} حالت';
          break;
        case OperationType.kleeneStar:
          final result = await _operations.kleeneStarWithCycleDetection(
            _automaton1!,
          );
          finalAutomaton = result.resultNfa;
          resultInfo = 'NFA حاصل: ${result.resultNfa.stateCount} حالت';
          break;
        case OperationType.complement:
          final result = await _operations.complementWithMetrics(_automaton1!);
          finalAutomaton = result.complementDfa;
          resultInfo = 'DFA مکمل: ${result.complementDfa.stateCount} حالت';
          break;
        case OperationType.difference:
          throw UnimplementedError('عمليات تفاضل هنوز پیاده‌سازی نشده است.');
      }

      if (mounted) Navigator.pop(context); // بستن دیالوگ "در حال انجام"
      await _showResultDialog(operationInfo, finalAutomaton, resultInfo);
    } catch (e) {
      if (mounted)
        Navigator.pop(context); // بستن دیالوگ "در حال انجام" در صورت خطا
      _showErrorSnackBar('خطا در انجام عملیات: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isOperationInProgress = false;
          _operationStatus = '';
        });
      }
    }
  }

  Widget _buildProgressDialog() {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_operationStatus),
            const SizedBox(height: 8),
            const Text(
              'لطفاً صبر کنید...',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResultDialog(
    OperationInfo operationInfo,
    dynamic finalAutomaton,
    String resultInfo,
  ) async {
    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(operationInfo.icon, color: operationInfo.color),
            const SizedBox(width: 8),
            Text('نتیجه ${operationInfo.name}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('عملیات با موفقیت انجام شد!'),
            const SizedBox(height: 8),
            Text(resultInfo),
            const SizedBox(height: 16),
            const Text('آیا می‌خواهید نتیجه را ذخیره کنید؟'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // [FIXED] پاس دادن Provider به جای جستجوی دوباره با context نامعتبر
              _saveResult(finalAutomaton, nfaProvider);
            },
            child: const Text('ذخیره'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _visualizeResult(finalAutomaton, operationInfo.name);
            },
            child: const Text('نمایش گرافیکی'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAutomatonFromFile(bool isFirst) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'nfa'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        Map<String, dynamic> jsonData = json.decode(content);
        NFA nfa = NFA.fromJson(jsonData);

        setState(() {
          if (isFirst) {
            _automaton1 = nfa;
          } else {
            _automaton2 = nfa;
          }
        });

        _showSuccessSnackBar('اتوماتا با موفقیت بارگذاری شد');
      }
    } catch (e) {
      _showErrorSnackBar('خطا در بارگذاری فایل: ${e.toString()}');
    }
  }

  Future<void> _selectFromRecentProjects(bool isFirst) async {
    final nfaProvider = Provider.of<NFAProvider>(context, listen: false);
    final recentProjects = nfaProvider.recentProjects;

    if (recentProjects.isEmpty) {
      _showErrorSnackBar('هیچ پروژه اخیری یافت نشد');
      return;
    }

    final selectedNFA = await showDialog<NFA>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('انتخاب از پروژه‌های اخیر'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: recentProjects.length,
            itemBuilder: (context, index) {
              final project = recentProjects[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(project.name),
                subtitle: Text(
                  '${(project.nfaJson['states'] as List).length} حالت',
                ),
                onTap: () =>
                    Navigator.pop(context, NFA.fromJson(project.nfaJson)),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
        ],
      ),
    );

    if (selectedNFA != null) {
      setState(() {
        if (isFirst) {
          _automaton1 = selectedNFA;
        } else {
          _automaton2 = selectedNFA;
        }
      });
    }
  }

  // [FIXED] دریافت NFAProvider به عنوان آرگومان
  void _saveResult(dynamic result, NFAProvider nfaProvider) {
    try {
      if (result is NFA) {
        nfaProvider.saveNewProject(result.name, result.toJson());
        _showSuccessSnackBar('نتیجه NFA با موفقیت در پروژه‌های اخیر ذخیره شد');
      } else if (result is DFA) {
        final nfa = _convertDFAToNFA(result);
        nfaProvider.saveNewProject(nfa.name, nfa.toJson());
        _showSuccessSnackBar('نتیجه DFA به عنوان یک پروژه جدید ذخیره شد');
      }
    } catch (e) {
      _showErrorSnackBar('خطا در ذخیره: ${e.toString()}');
    }
  }

  NFA _convertDFAToNFA(DFA dfa) {
    final nfa = NFA.empty();
    nfa.setName('DFA_to_NFA_${DateTime.now().millisecondsSinceEpoch}');

    for (final symbol in dfa.alphabet) {
      nfa.addSymbol(symbol);
    }

    for (final stateSet in dfa.states) {
      final stateName = dfa.getStateName(stateSet);
      nfa.addState(stateName);

      if (stateSet == dfa.startState) {
        nfa.setStartState(stateName);
      }

      if (dfa.finalStates.contains(stateSet)) {
        nfa.setFinalState(stateName, true);
      }
    }

    for (final fromStateSet in dfa.states) {
      final fromStateName = dfa.getStateName(fromStateSet);
      final transitions = dfa.transitions[fromStateSet] ?? {};
      for (final symbol in transitions.keys) {
        final toStateSet = transitions[symbol];
        if (toStateSet != null) {
          final toStateName = dfa.getStateName(toStateSet);
          nfa.addTransition(fromStateName, symbol, toStateName);
        }
      }
    }
    return nfa;
  }

  void _visualizeResult(dynamic result, String operationName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GraphVisualizationScreen(
          automaton: result,
          title: 'نتیجه $operationName',
        ),
      ),
    );
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
        title: const Text('عملیات روی اتوماتا'),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showHelpDialog(),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickGuide(),
              const SizedBox(height: 24),
              Text(
                'انتخاب اتوماتاها',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAutomatonSelector(
                title: 'اتوماتای اول (A)',
                automaton: _automaton1,
                onSelect: (nfa) => setState(() => _automaton1 = nfa),
                isFirst: true,
              ),
              const SizedBox(height: 16),
              _buildAutomatonSelector(
                title: 'اتوماتای دوم (B)',
                automaton: _automaton2,
                onSelect: (nfa) => setState(() => _automaton2 = nfa),
                isFirst: false,
              ),
              const Divider(height: 40, thickness: 2),
              Text(
                'عملیات‌های قابل انجام',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildOperationsGrid(),
              const SizedBox(height: 24),
              if (_isOperationInProgress) _buildOperationStatus(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickGuide() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'راهنما',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'ابتدا اتوماتاهای مورد نظر را انتخاب کنید، سپس عملیات دلخواه را اجرا کنید.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _operationList.length,
      itemBuilder: (context, index) {
        final operation = _operationList[index];
        final canPerform =
            _automaton1 != null &&
            (!operation.requiresSecondAutomaton || _automaton2 != null);

        return _buildOperationCard(operation, canPerform);
      },
    );
  }

  Widget _buildOperationCard(OperationInfo operation, bool canPerform) {
    return Card(
      elevation: canPerform ? 4 : 2,
      child: InkWell(
        onTap: canPerform && !_isOperationInProgress
            ? () => _performOperation(operation)
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                operation.icon,
                size: 32,
                color: canPerform ? operation.color : Colors.grey,
              ),
              const SizedBox(height: 8),
              Text(
                operation.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: canPerform ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                operation.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: canPerform ? Colors.grey.shade600 : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperationStatus() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(_operationStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomatonSelector({
    required String title,
    required NFA? automaton,
    required ValueChanged<NFA?> onSelect,
    required bool isFirst,
  }) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_tree,
                  color: isFirst ? Colors.blue : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (automaton != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            automaton.name.isNotEmpty
                                ? automaton.name
                                : 'اتوماتا انتخاب شده',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${automaton.stateCount} حالت، ${automaton.alphabet.length} نماد',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.red),
                      onPressed: () => onSelect(null),
                      tooltip: 'حذف انتخاب',
                    ),
                  ],
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open),
                          label: const Text('بارگذاری از فایل'),
                          onPressed: () => _loadAutomatonFromFile(isFirst),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.history),
                          label: const Text('انتخاب از اخیر'),
                          onPressed: () => _selectFromRecentProjects(isFirst),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.create),
                      label: const Text('ایجاد اتوماتای جدید'),
                      onPressed: () => _createNewAutomaton(context, isFirst),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('راهنمای عملیات'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _operationList
                .map(
                  (op) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(op.icon, size: 16, color: op.color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                op.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                op.description,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
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
}

// Helper Classes
class OperationInfo {
  final String name;
  final IconData icon;
  final Color color;
  final String description;
  final OperationType operationType;
  final bool requiresSecondAutomaton;

  OperationInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
    required this.operationType,
    this.requiresSecondAutomaton = true,
  });
}

enum OperationType {
  union,
  intersection,
  difference,
  concatenation,
  kleeneStar,
  complement,
}
