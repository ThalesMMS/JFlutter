import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/entities/automaton_entity.dart';
import '../providers/automaton_provider.dart';
import '../providers/algorithm_provider.dart';
import '../../injection/dependency_injection.dart';
import '../../core/grammar.dart';
import '../../core/algorithms.dart';
import '../../core/automaton.dart';
import '../../core/cfg.dart';
import '../../core/ll_parsing.dart';
import '../../core/lr_parsing.dart';
import 'minimization_interface.dart';
import 'pumping_lemma_interface.dart';
import 'examples_library.dart';

/// Panel for algorithm operations
class AlgorithmPanel extends StatelessWidget {
  final AutomatonType type;

  const AlgorithmPanel({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Algoritmos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ..._buildAlgorithmButtons(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAlgorithmButtons(BuildContext context) {
    switch (type) {
      case AutomatonType.dfa:
        return _buildDfaAlgorithms(context);
      case AutomatonType.nfa:
      case AutomatonType.nfaLambda:
        return _buildNfaAlgorithms(context);
      case AutomatonType.grammar:
      case AutomatonType.regex:
        return _buildGrammarAlgorithms(context);
    }
  }

  List<Widget> _buildDfaAlgorithms(BuildContext context) {
    return [
      _buildAlgorithmButton(
        context,
        'Biblioteca de Exemplos',
        Icons.library_books,
        () => _showExamplesLibrary(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'Completar AFD',
        Icons.check_circle,
        () => _completeDfa(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'Complemento',
        Icons.flip,
        () => _complementDfa(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'Minimizar AFD (Interativo)',
        Icons.compress,
        () => _showMinimizationInterface(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'Lema do Bombeamento',
        Icons.water_drop,
        () => _showPumpingLemmaInterface(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'Fecho por Prefixos',
        Icons.arrow_forward,
        () => _prefixClosure(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'Fecho por Sufixos',
        Icons.arrow_back,
        () => _suffixClosure(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'AFD → ER',
        Icons.text_fields,
        () => _dfaToRegex(context),
      ),
    ];
  }

  List<Widget> _buildNfaAlgorithms(BuildContext context) {
    return [
      _buildAlgorithmButton(
        context,
        'AFNλ → AFN',
        Icons.remove_circle,
        () => _removeLambdaTransitions(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'AFN → AFD',
        Icons.transform,
        () => _nfaToDfa(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'AFN → AFD e abrir',
        Icons.open_in_new,
        () => _nfaToDfaAndOpen(context),
      ),
    ];
  }

  List<Widget> _buildGrammarAlgorithms(BuildContext context) {
    return [
      _buildAlgorithmButton(
        context,
        'ER → AF',
        Icons.auto_awesome,
        () => _regexToNfa(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'GR → AF',
        Icons.account_tree,
        () => _grammarToNfa(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'GR → AFD',
        Icons.account_tree,
        () => _grammarToDfa(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'AF → GR',
        Icons.text_snippet,
        () => _automatonToGrammar(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'LL(1) Parsing',
        Icons.arrow_forward,
        () => _llParsing(context),
      ),
      const SizedBox(height: 8),
      _buildAlgorithmButton(
        context,
        'LR(1) Parsing',
        Icons.arrow_back,
        () => _lrParsing(context),
      ),
    ];
  }

  Widget _buildAlgorithmButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }

  // Algorithm handlers
  void _completeDfa(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.completeDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'AFD completado com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _complementDfa(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.complementDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'Complemento do AFD criado com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _minimizeDfa(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.minimizeDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'AFD minimizado com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _showMinimizationInterface(BuildContext context) {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    if (automatonProvider.currentAutomaton!.type != AutomatonType.dfa) {
      _showError(context, 'A interface de minimização só funciona com DFAs');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const MinimizationInterface(),
        ),
      ),
    );
  }

  void _showPumpingLemmaInterface(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const PumpingLemmaInterface(),
        ),
      ),
    );
  }

  void _showExamplesLibrary(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: const ExamplesLibrary(),
        ),
      ),
    );
  }

  void _prefixClosure(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.prefixClosureDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'Fecho por prefixos criado com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _suffixClosure(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.suffixClosureDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'Fecho por sufixos criado com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _dfaToRegex(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.dfaToRegex(automatonProvider.currentAutomaton!);
    if (result != null) {
      _showRegexResult(context, result);
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _removeLambdaTransitions(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.removeLambdaTransitions(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'Transições lambda removidas com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _nfaToDfa(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.nfaToDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'AFN convertido para AFD com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _nfaToDfaAndOpen(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    final result = await algorithmProvider.nfaToDfa(automatonProvider.currentAutomaton!);
    if (result != null) {
      // TODO: Open in new tab - for now, just replace current
      automatonProvider.setCurrentAutomaton(result);
      _showSuccess(context, 'AFN convertido para AFD e aberto com sucesso');
    } else {
      _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
    }
  }

  void _regexToNfa(BuildContext context) async {
    final algorithmProvider = getIt<AlgorithmProvider>();
    
    final regex = await _showRegexInputDialog(context);
    if (regex != null && regex.isNotEmpty) {
      final result = await algorithmProvider.regexToNfa(regex);
      if (result != null) {
        final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
        automatonProvider.setCurrentAutomaton(result);
        _showSuccess(context, 'Expressão regular convertida para AFN com sucesso');
      } else {
        _showError(context, algorithmProvider.error ?? 'Erro desconhecido');
      }
    }
  }

  void _grammarToNfa(BuildContext context) async {
    final grammar = await _showGrammarInputDialog(context);
    if (grammar != null && grammar.isNotEmpty) {
      try {
        // Import the grammar conversion function
        final automaton = automatonFromGrammar(grammar);
        final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
        
        // Convert to entity
        final entity = _convertAutomatonToEntity(automaton, 'Gramática Convertida');
        automatonProvider.setCurrentAutomaton(entity);
        
        _showSuccess(context, 'Gramática convertida para AFN com sucesso');
      } catch (e) {
        _showError(context, 'Erro ao converter gramática: $e');
      }
    }
  }

  void _grammarToDfa(BuildContext context) async {
    final grammar = await _showGrammarInputDialog(context);
    if (grammar != null && grammar.isNotEmpty) {
      try {
        // First convert to NFA, then to DFA
        final nfa = automatonFromGrammar(grammar);
        final dfa = nfaToDfa(nfa);
        final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
        
        // Convert to entity
        final entity = _convertAutomatonToEntity(dfa, 'Gramática Convertida');
        automatonProvider.setCurrentAutomaton(entity);
        
        _showSuccess(context, 'Gramática convertida para AFD com sucesso');
      } catch (e) {
        _showError(context, 'Erro ao converter gramática: $e');
      }
    }
  }

  void _automatonToGrammar(BuildContext context) async {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    
    if (automatonProvider.currentAutomaton == null) {
      _showError(context, 'Nenhum autômato carregado');
      return;
    }

    try {
      // Convert entity to automaton
      final automaton = _convertEntityToAutomaton(automatonProvider.currentAutomaton!);
      final grammar = exportGrammarFromAutomaton(automaton);
      
      _showGrammarResult(context, grammar);
    } catch (e) {
      _showError(context, 'Erro ao converter automaton para gramática: $e');
    }
  }

  // Helper methods
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRegexResult(BuildContext context, String regex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expressão Regular Resultante'),
        content: SelectableText(
          regex,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: regex));
              Navigator.pop(context);
              _showSuccess(context, 'Expressão regular copiada para a área de transferência');
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showRegexInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expressão Regular'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Digite a expressão regular',
            hintText: 'Ex: (a|b)*, a*b+, etc.',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Converter'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showGrammarInputDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gramática Regular'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digite a gramática regular no formato:\n'
              'S -> aA | bB\n'
              'A -> aA | λ\n'
              'B -> bB | λ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Gramática',
                hintText: 'S -> aA | bB\nA -> aA | λ',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Converter'),
          ),
        ],
      ),
    );
  }

  void _showGrammarResult(BuildContext context, String grammar) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gramática Regular Resultante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gramática gerada a partir do autômato:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SelectableText(
                grammar,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: grammar));
              Navigator.pop(context);
              _showSuccess(context, 'Gramática copiada para a área de transferência');
            },
            child: const Text('Copiar'),
          ),
        ],
      ),
    );
  }

  // Conversion helper methods
  AutomatonEntity _convertAutomatonToEntity(Automaton automaton, String name) {
    final states = automaton.states.map((state) => StateEntity(
      id: state.id,
      name: state.name,
      x: state.x,
      y: state.y,
      isInitial: state.isInitial,
      isFinal: state.isFinal,
    )).toList();

    return AutomatonEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      alphabet: automaton.alphabet,
      states: states,
      transitions: automaton.transitions,
      initialId: automaton.initialId,
      nextId: automaton.nextId,
      type: automaton.isDfa ? AutomatonType.dfa : AutomatonType.nfa,
    );
  }

  Automaton _convertEntityToAutomaton(AutomatonEntity entity) {
    final states = entity.states.map((state) => StateNode(
      id: state.id,
      name: state.name,
      x: state.x,
      y: state.y,
      isInitial: state.isInitial,
      isFinal: state.isFinal,
    )).toList();

    return Automaton(
      alphabet: entity.alphabet,
      states: states,
      transitions: entity.transitions,
      initialId: entity.initialId,
      nextId: entity.nextId,
    );
  }

  void _llParsing(BuildContext context) {
    // Show LL parsing dialog
    showDialog(
      context: context,
      builder: (context) => _LLParsingDialog(),
    );
  }

  void _lrParsing(BuildContext context) {
    // Show LR parsing dialog
    showDialog(
      context: context,
      builder: (context) => _LRParsingDialog(),
    );
  }
}

/// Dialog for LL(1) parsing
class _LLParsingDialog extends StatefulWidget {
  @override
  State<_LLParsingDialog> createState() => _LLParsingDialogState();
}

class _LLParsingDialogState extends State<_LLParsingDialog> {
  final TextEditingController _grammarController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  String _result = '';
  List<String> _steps = [];

  @override
  void dispose() {
    _grammarController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _parse() {
    try {
      final grammar = ContextFreeGrammar.fromString(_grammarController.text);
      final result = LLParsing.parseString(grammar, _inputController.text);
      
      setState(() {
        _result = result.accepted ? 'Aceita' : 'Rejeitada';
        _steps = result.steps;
      });
    } catch (e) {
      setState(() {
        _result = 'Erro: $e';
        _steps = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('LL(1) Parsing'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _grammarController,
              decoration: const InputDecoration(
                labelText: 'Gramática (ex: S → aSb | λ)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'String de entrada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _parse,
              child: const Text('Parsear'),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Resultado: $_result'),
              if (_steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(_steps[index]),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

/// Dialog for LR(1) parsing
class _LRParsingDialog extends StatefulWidget {
  @override
  State<_LRParsingDialog> createState() => _LRParsingDialogState();
}

class _LRParsingDialogState extends State<_LRParsingDialog> {
  final TextEditingController _grammarController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  String _result = '';
  List<String> _steps = [];

  @override
  void dispose() {
    _grammarController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _parse() {
    try {
      final grammar = ContextFreeGrammar.fromString(_grammarController.text);
      final result = LRParsing.parseString(grammar, _inputController.text);
      
      setState(() {
        _result = result.accepted ? 'Aceita' : 'Rejeitada';
        _steps = result.steps;
      });
    } catch (e) {
      setState(() {
        _result = 'Erro: $e';
        _steps = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('LR(1) Parsing'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _grammarController,
              decoration: const InputDecoration(
                labelText: 'Gramática (ex: S → aSb | λ)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: 'String de entrada',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _parse,
              child: const Text('Parsear'),
            ),
            if (_result.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Resultado: $_result'),
              if (_steps.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    itemCount: _steps.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 12,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(_steps[index]),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
