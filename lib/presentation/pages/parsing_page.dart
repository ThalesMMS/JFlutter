import 'package:flutter/material.dart';
import '../../core/cfg.dart';
import '../../core/ll_parsing.dart';
import '../../core/lr_parsing.dart';
import '../widgets/parsing_table_widget.dart';
import '../widgets/mobile_parsing_table_widget.dart';
import '../widgets/common_ui_components.dart';
import '../widgets/contextual_help.dart';

/// Page for LL and LR parsing
class ParsingPage extends StatefulWidget {
  const ParsingPage({super.key});

  @override
  State<ParsingPage> createState() => _ParsingPageState();
}

class _ParsingPageState extends State<ParsingPage> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Grammar input
  final TextEditingController _grammarController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();
  
  // Grammar state
  ContextFreeGrammar? _grammar;
  String _grammarError = '';
  
  // LL parsing state
  LLParseTable? _llTable;
  LLParsingResult? _llResult;
  bool _isLL1 = false;
  
  // LR parsing state
  LRParseTable? _lrTable;
  LRParsingResult? _lrResult;
  
  // UI state
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load example grammar
    _loadExampleGrammar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _grammarController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _loadExampleGrammar() {
    _grammarController.text = '''
S → aSb | λ
    ''';
    _parseGrammar();
  }

  void _parseGrammar() {
    setState(() {
      _isLoading = true;
      _grammarError = '';
      _grammar = null;
      _llTable = null;
      _llResult = null;
      _lrTable = null;
      _lrResult = null;
    });

    try {
      final grammar = ContextFreeGrammar.fromString(_grammarController.text);
      final errors = grammar.validate();
      
      if (errors.isNotEmpty) {
        setState(() {
          _grammarError = errors.join('\n');
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _grammar = grammar;
        _isLoading = false;
      });
      
      _generateParseTables();
    } catch (e) {
      setState(() {
        _grammarError = 'Erro ao analisar gramática: $e';
        _isLoading = false;
      });
    }
  }

  void _generateParseTables() {
    if (_grammar == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Generate LL parse table
      _llTable = LLParsing.generateParseTable(_grammar!);
      _isLL1 = LLParsing.isLL1(_grammar!);
      
      // Generate LR parse table
      _lrTable = LRParsing.generateParseTable(_grammar!);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _grammarError = 'Erro ao gerar tabelas de parsing: $e';
        _isLoading = false;
      });
    }
  }

  void _parseInput() {
    if (_grammar == null || _inputController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final input = _inputController.text;
      
      // LL parsing
      _llResult = LLParsing.parseString(_grammar!, input);
      
      // LR parsing
      _lrResult = LRParsing.parseString(_grammar!, input);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _grammarError = 'Erro ao fazer parsing: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      appBar: isMobile
          ? null
          : AppBar(
              title: const Text('Parsing LL/LR'),
              bottom: ResponsiveTabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Gramática', icon: Icon(Icons.edit)),
                  Tab(text: 'LL(1)', icon: Icon(Icons.table_chart)),
                  Tab(text: 'LR(1)', icon: Icon(Icons.account_tree)),
                  Tab(text: 'Parsing', icon: Icon(Icons.play_arrow)),
                ],
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGrammarTab(),
                _buildLLTab(),
                _buildLRTab(),
                _buildParsingTab(),
              ],
            ),
          ),
          _buildBottomShortcuts(),
        ],
      ),
    );
  }

  Widget _buildGrammarTab() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: CommonUIComponents.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
            title: 'Gramática Livre de Contexto',
            subtitle: 'Defina uma gramática e analise suas propriedades',
            icon: Icons.edit,
            actions: [
              StandardButton(
                text: 'Analisar',
                icon: Icons.refresh,
                onPressed: _parseGrammar,
                isLoading: _isLoading,
              ),
            ],
          ),
          Expanded(
            child: ResponsiveLayout(
              mobile: _buildMobileGrammarLayout(),
              desktop: _buildDesktopGrammarLayout(),
            ),
          ),
          if (_grammarError.isNotEmpty) ...[
            const SizedBox(height: CommonUIComponents.sectionSpacing),
            StatusIndicator(
              isSuccess: false,
              message: _grammarError,
            ),
          ],
          if (_grammar != null) ...[
            const SizedBox(height: CommonUIComponents.sectionSpacing),
            StatusIndicator(
              isSuccess: true,
              message: 'Gramática válida! Variáveis: ${_grammar!.variables.join(', ')}, '
                      'Terminais: ${_grammar!.terminals.join(', ')}, '
                      'Produções: ${_grammar!.productions.length}',
            ),
          ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileGrammarLayout() {
    return Column(
      children: [
        // Grammar input
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Definição da Gramática:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _grammarController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Digite a gramática...\nExemplo:\nS → aSb | λ',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Examples
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exemplos:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _buildExampleButton(
                      'Parênteses Balanceados',
                      'S → (S)S | λ',
                    ),
                    _buildExampleButton(
                      'Expressões Aritméticas',
                      '''E → TE'
E' → +TE' | λ
T → FT'
T' → *FT' | λ
F → (E) | id''',
                    ),
                    _buildExampleButton(
                      'Palavras a^n b^n',
                      'S → aSb | λ',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGrammarLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Definição da Gramática:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: TextField(
                  controller: _grammarController,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: 'Digite a gramática...\nExemplo:\nS → aSb | λ',
                    border: OutlineInputBorder(),
                  ),
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exemplos:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    _buildExampleButton(
                      'Parênteses Balanceados',
                      'S → (S)S | λ',
                    ),
                    _buildExampleButton(
                      'Expressões Aritméticas',
                      '''E → TE'
E' → +TE' | λ
T → FT'
T' → *FT' | λ
F → (E) | id''',
                    ),
                    _buildExampleButton(
                      'Palavras a^n b^n',
                      'S → aSb | λ',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExampleButton(String title, String grammar) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(title),
        subtitle: Text(
          grammar,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          _grammarController.text = grammar;
          _parseGrammar();
        },
      ),
    );
  }

  Widget _buildLLTab() {
    if (_isLoading) {
      return const StandardLoadingIndicator(message: 'Gerando tabela LL(1)...');
    }
    
    if (_grammar == null) {
      return EmptyState(
        title: 'Gramática não definida',
        subtitle: 'Defina uma gramática válida primeiro',
        icon: Icons.edit_off,
      );
    }
    
    return Padding(
      padding: CommonUIComponents.getResponsivePadding(context),
      child: Column(
        children: [
          SectionHeader(
            title: 'Análise LL(1)',
            subtitle: 'Tabela de parsing descendente',
            icon: Icons.table_chart,
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isLL1 ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLL1 ? Icons.check_circle : Icons.cancel,
                      color: _isLL1 ? Colors.green.shade700 : Colors.red.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isLL1 ? 'É LL(1)' : 'Não é LL(1)',
                      style: TextStyle(
                        color: _isLL1 ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: CommonUIComponents.getResponsiveFontSize(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              HelpButton(
                helpContent: HelpContent.llParsing,
                title: 'Parsing LL(1)',
                icon: Icons.help_outline,
                tooltip: 'Ajuda sobre LL(1)',
              ),
            ],
          ),
          if (_llTable != null)
            Expanded(child: MobileLLParseTableWidget(table: _llTable!))
          else
            Expanded(
              child: EmptyState(
                title: 'Tabela LL(1) não disponível',
                subtitle: 'Analise a gramática primeiro',
                icon: Icons.table_chart,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLRTab() {
    if (_isLoading) {
      return const StandardLoadingIndicator(message: 'Gerando tabela LR(1)...');
    }
    
    if (_grammar == null) {
      return EmptyState(
        title: 'Gramática não definida',
        subtitle: 'Defina uma gramática válida primeiro',
        icon: Icons.edit_off,
      );
    }
    
    return Padding(
      padding: CommonUIComponents.getResponsivePadding(context),
      child: Column(
        children: [
          SectionHeader(
            title: 'Análise LR(1)',
            subtitle: 'Tabela de parsing ascendente',
            icon: Icons.account_tree,
            actions: [
              HelpButton(
                helpContent: HelpContent.lrParsing,
                title: 'Parsing LR(1)',
                icon: Icons.help_outline,
                tooltip: 'Ajuda sobre LR(1)',
              ),
            ],
          ),
          if (_lrTable != null)
            Expanded(child: MobileLRParseTableWidget(table: _lrTable!))
          else
            Expanded(
              child: EmptyState(
                title: 'Tabela LR(1) não disponível',
                subtitle: 'Analise a gramática primeiro',
                icon: Icons.account_tree,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildParsingTab() {
    if (_isLoading) {
      return const StandardLoadingIndicator(message: 'Executando parsing...');
    }
    
    if (_grammar == null) {
      return EmptyState(
        title: 'Gramática não definida',
        subtitle: 'Defina uma gramática válida primeiro',
        icon: Icons.edit_off,
      );
    }
    
    return Padding(
      padding: CommonUIComponents.getResponsivePadding(context),
      child: Column(
        children: [
          SectionHeader(
            title: 'Parsing de Strings',
            subtitle: 'Teste strings com LL(1) e LR(1)',
            icon: Icons.play_arrow,
            actions: [
              HelpButton(
                helpContent: HelpContent.simulation,
                title: 'Simulação de Parsing',
                icon: Icons.help_outline,
                tooltip: 'Ajuda sobre parsing',
              ),
            ],
          ),
          const SizedBox(height: CommonUIComponents.sectionSpacing),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _inputController,
                  decoration: const InputDecoration(
                    labelText: 'String de entrada',
                    hintText: 'Ex: aabb',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: CommonUIComponents.sectionSpacing),
              StandardButton(
                text: 'Parsing',
                icon: Icons.play_arrow,
                onPressed: _parseInput,
                isLoading: _isLoading,
              ),
            ],
          ),
          const SizedBox(height: CommonUIComponents.sectionSpacing),
          if (_llResult != null || _lrResult != null)
            Expanded(
              child: ResponsiveLayout(
                mobile: _buildMobileParsingResults(),
                desktop: _buildDesktopParsingResults(),
              ),
            )
          else
            Expanded(
              child: EmptyState(
                title: 'Nenhum resultado de parsing',
                subtitle: 'Digite uma string e clique em "Parsing" para analisar',
                icon: Icons.play_circle_outline,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileParsingResults() {
    return Column(
      children: [
        if (_llResult != null) ...[
          Expanded(
            child: Column(
              children: [
                Text(
                  'LL(1) Parsing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MobileParsingStepsWidget(
                    steps: _llResult!.steps,
                    accepted: _llResult!.accepted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_lrResult != null) ...[
          Expanded(
            child: Column(
              children: [
                Text(
                  'LR(1) Parsing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MobileParsingStepsWidget(
                    steps: _lrResult!.steps,
                    accepted: _lrResult!.accepted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDesktopParsingResults() {
    return Row(
      children: [
        if (_llResult != null) ...[
          Expanded(
            child: Column(
              children: [
                Text(
                  'LL(1) Parsing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MobileParsingStepsWidget(
                    steps: _llResult!.steps,
                    accepted: _llResult!.accepted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (_lrResult != null) ...[
          Expanded(
            child: Column(
              children: [
                Text(
                  'LR(1) Parsing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: MobileParsingStepsWidget(
                    steps: _lrResult!.steps,
                    accepted: _lrResult!.accepted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Bottom shortcuts visible across tabs (mobile and desktop)
  Widget _buildBottomShortcuts() {
    final buttonStyle = OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8));
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(0),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Gramática'),
            style: buttonStyle,
          ),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(1),
            icon: const Icon(Icons.table_chart, size: 18),
            label: const Text('LL(1)'),
            style: buttonStyle,
          ),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(2),
            icon: const Icon(Icons.account_tree, size: 18),
            label: const Text('LR(1)'),
            style: buttonStyle,
          ),
          OutlinedButton.icon(
            onPressed: () => _tabController.animateTo(3),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: const Text('Parsing'),
            style: buttonStyle,
          ),
        ],
      ),
    );
  }

  void _showParsingHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuda - Parsing LL/LR'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Parsing LL/LR:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• LL(1): Parsing descendente com lookahead de 1 símbolo\n• LR(1): Parsing ascendente com lookahead de 1 símbolo\n• Análise de gramáticas livres de contexto\n• Geração de tabelas de parsing\n• Simulação de strings'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
