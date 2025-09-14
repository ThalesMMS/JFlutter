import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/cfg.dart';
import '../../core/cfg_algorithms.dart';
import '../../core/pumping_lemmas.dart';
import '../providers/automaton_provider.dart';
import '../widgets/cfg_canvas.dart';
import '../widgets/cfg_controls.dart';

class CFGPage extends StatefulWidget {
  const CFGPage({super.key});

  @override
  State<CFGPage> createState() => _CFGPageState();
}

class _CFGPageState extends State<CFGPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _grammarController;
  late TextEditingController _inputController;
  late TextEditingController _pumpingLengthController;
  
  ContextFreeGrammar? _currentGrammar;
  ParseResult? _parseResult;
  CNFConversionResult? _cnfResult;
  PumpingResult? _pumpingResult;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _grammarController = TextEditingController();
    _inputController = TextEditingController();
    _pumpingLengthController = TextEditingController(text: '3');
    
    // Load saved grammar
    _loadSavedGrammar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _grammarController.dispose();
    _inputController.dispose();
    _pumpingLengthController.dispose();
    super.dispose();
  }

  void _loadSavedGrammar() {
    // Load from shared preferences
    final prefs = Provider.of<AutomatonProvider>(context, listen: false);
    final savedGrammar = prefs.getSavedCFG();
    if (savedGrammar != null) {
      _grammarController.text = savedGrammar;
      _parseGrammar();
    }
  }

  void _saveGrammar() {
    final prefs = Provider.of<AutomatonProvider>(context, listen: false);
    prefs.saveCFG(_grammarController.text);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gramática salva com sucesso!')),
    );
  }

  void _parseGrammar() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final grammarText = _grammarController.text.trim();
      if (grammarText.isEmpty) {
        _currentGrammar = ContextFreeGrammar.empty();
      } else {
        _currentGrammar = ContextFreeGrammar.fromString(grammarText);
        final errors = _currentGrammar!.validate();
        if (errors.isNotEmpty) {
          _errorMessage = errors.join('\n');
        }
      }
    } catch (e) {
      _errorMessage = 'Erro ao analisar gramática: $e';
      _currentGrammar = null;
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _convertToCNF() {
    if (_currentGrammar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carregue uma gramática primeiro!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _cnfResult = CFGAlgorithms.convertToCNF(_currentGrammar!);
    } catch (e) {
      _errorMessage = 'Erro na conversão para CNF: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _parseInput() {
    if (_currentGrammar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carregue uma gramática primeiro!')),
      );
      return;
    }

    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma string para analisar!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _parseResult = CFGAlgorithms.cykParse(_currentGrammar!, input);
    } catch (e) {
      _errorMessage = 'Erro no parsing: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _checkPumpingLemma() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma string para verificar!')),
      );
      return;
    }

    final pumpingLength = int.tryParse(_pumpingLengthController.text) ?? 3;
    if (pumpingLength < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprimento de bombeamento deve ser ≥ 1!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use appropriate pumping lemma based on input
      if (input.contains('a') && input.contains('b') && 
          input.replaceAll('a', '').replaceAll('b', '').isEmpty) {
        final lemma = AnBnPumpingLemma();
        _pumpingResult = lemma.checkPumping(input, pumpingLength);
      } else if (input == input.split('').reversed.join('')) {
        final lemma = PalindromePumpingLemma();
        _pumpingResult = lemma.checkPumping(input, pumpingLength);
      } else {
        // Generic context-free pumping lemma
        final lemma = ContextFreePumpingLemma('Linguagem genérica');
        _pumpingResult = lemma.checkPumping(input, pumpingLength);
      }
    } catch (e) {
      _errorMessage = 'Erro no lema do bombeamento: $e';
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _clearAll() {
    setState(() {
      _grammarController.clear();
      _inputController.clear();
      _currentGrammar = null;
      _parseResult = null;
      _cnfResult = null;
      _pumpingResult = null;
      _errorMessage = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      appBar: isMobile
          ? null
          : AppBar(
              title: const Text(''),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(icon: Icon(Icons.edit), text: 'Editar'),
                  Tab(icon: Icon(Icons.play_arrow), text: 'Parsing'),
                  Tab(icon: Icon(Icons.transform), text: 'CNF'),
                  Tab(icon: Icon(Icons.water_drop), text: 'Bombeamento'),
                ],
              ),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEditTab(),
          _buildParsingTab(),
          _buildCNFTab(),
          _buildPumpingTab(),
        ],
      ),
    );
  }

  Widget _buildEditTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _grammarController,
            maxLines: null,
            decoration: const InputDecoration(
              labelText: 'Gramática (CFG)',
              hintText: 'S → aSb | λ\nA → aA | b',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: _parseGrammar,
                child: const Text('Analisar'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _saveGrammar,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
        if (_errorMessage.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ),
          ),
        // Canvas area takes remaining space; controls move to collapsible bottom panel
        Expanded(
          child: _currentGrammar != null
              ? CFGCanvas(grammar: _currentGrammar!)
              : const SizedBox.shrink(),
        ),
        // Bottom expandable controls, starting collapsed
        CFGControls(
          grammar: _currentGrammar,
          onGrammarChanged: _parseGrammar,
          onClear: _clearAll,
          onHelp: _showHelp,
          onNavigateTab: (index) => _tabController.animateTo(index),
          startCollapsed: false,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildParsingTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    labelText: 'String para analisar',
                    hintText: 'aabb',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _parseInput,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Analisar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _parseResult != null
              ? Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resultado do Parsing',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              _parseResult!.accepted
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _parseResult!.accepted
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _parseResult!.accepted
                                  ? 'String aceita'
                                  : 'String rejeitada',
                              style: TextStyle(
                                color: _parseResult!.accepted
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_parseResult!.explanation),
                        if (_parseResult!.derivation.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Derivação:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _parseResult!.derivation.length,
                              itemBuilder: (context, index) {
                                final prod = _parseResult!.derivation[index];
                                return ListTile(
                                  title: Text(prod.toString()),
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: Text('Execute o parsing para ver os resultados'),
                ),
        ),
      ],
    );
  }

  Widget _buildCNFTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Conversão para Forma Normal de Chomsky'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _convertToCNF,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Converter para CNF'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _cnfResult != null
              ? Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gramática em CNF',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (_cnfResult!.success) ...[
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Produções:',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(_cnfResult!.cnfGrammar.toString()),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Passos da conversão:',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  ..._cnfResult!.steps.map((step) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Text('• $step'),
                                  )),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Erro na conversão',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: Text('Execute a conversão para CNF para ver os resultados'),
                ),
        ),
      ],
    );
  }

  Widget _buildPumpingTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    labelText: 'String para verificar',
                    hintText: 'aabb',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _pumpingLengthController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'p',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _checkPumpingLemma,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Verificar'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _pumpingResult != null
              ? Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resultado do Lema do Bombeamento',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              _pumpingResult!.canPump
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _pumpingResult!.canPump
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _pumpingResult!.canPump
                                  ? 'Pode ser bombeada'
                                  : 'Não pode ser bombeada',
                              style: TextStyle(
                                color: _pumpingResult!.canPump
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(_pumpingResult!.explanation),
                        if (_pumpingResult!.decompositions.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Decomposições:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._pumpingResult!.decompositions.map((decomp) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• $decomp'),
                            ),
                          ),
                        ],
                        if (_pumpingResult!.pumpedStrings.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Strings bombeadas:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ..._pumpingResult!.pumpedStrings.map((str) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text('• "$str"'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : const Center(
                  child: Text('Execute a verificação do lema do bombeamento para ver os resultados'),
                ),
        ),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Gramáticas Livres de Contexto'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Formato da Gramática:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('S → aSb | λ\nA → aA | b'),
              SizedBox(height: 16),
              Text(
                'Funcionalidades:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Edição e visualização de gramáticas\n• Parsing CYK\n• Conversão para CNF\n• Lema do bombeamento'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
