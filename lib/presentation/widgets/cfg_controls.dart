import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/cfg.dart';

class CFGControls extends StatefulWidget {
  final ContextFreeGrammar? grammar;
  final VoidCallback? onGrammarChanged;
  final VoidCallback? onClear;
  final VoidCallback? onHelp;
  final ValueChanged<int>? onNavigateTab; // 0: Editar, 1: Parsing, 2: CNF, 3: Bombeamento
  final bool startCollapsed;
  final bool fullWidth; // when true, expand to max width (bottom bar style)

  const CFGControls({
    super.key,
    this.grammar,
    this.onGrammarChanged,
    this.onClear,
    this.onHelp,
    this.onNavigateTab,
    this.startCollapsed = false,
    this.fullWidth = false,
  });

  @override
  State<CFGControls> createState() => _CFGControlsState();
}

class _CFGControlsState extends State<CFGControls> with TickerProviderStateMixin {
  final TextEditingController _variableController = TextEditingController();
  final TextEditingController _terminalController = TextEditingController();
  final TextEditingController _productionController = TextEditingController();
  final TextEditingController _startVariableController = TextEditingController();
  late bool _collapsed;

  @override
  void initState() {
    super.initState();
    _collapsed = widget.startCollapsed;
  }

  @override
  void dispose() {
    _variableController.dispose();
    _terminalController.dispose();
    _productionController.dispose();
    _startVariableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: widget.fullWidth ? double.infinity : (isMobile ? screenWidth * 0.9 : 300),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: widget.fullWidth
              ? BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                )
              : BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _collapsed
                ? const SizedBox.shrink()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickActions(),
                          const SizedBox(height: 16),
                          _buildVariablesSection(),
                          const SizedBox(height: 24),
                          _buildTerminalsSection(),
                          const SizedBox(height: 24),
                          _buildStartVariableSection(),
                          const SizedBox(height: 24),
                          _buildProductionsSection(),
                          const SizedBox(height: 24),
                          _buildExamplesSection(),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.settings,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Controles GLC',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Limpar tudo',
            icon: const Icon(Icons.clear_all),
            onPressed: widget.onClear,
          ),
          IconButton(
            tooltip: 'Ajuda',
            icon: const Icon(Icons.help_outline),
            onPressed: widget.onHelp,
          ),
          IconButton(
            tooltip: _collapsed ? 'Expandir' : 'Recolher',
            icon: Icon(_collapsed ? Icons.expand_more : Icons.expand_less),
            onPressed: () => setState(() => _collapsed = !_collapsed),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final buttonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(0),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Editar'),
          style: buttonStyle,
        ),
        OutlinedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(1),
          icon: const Icon(Icons.play_arrow, size: 18),
          label: const Text('Parsing'),
          style: buttonStyle,
        ),
        OutlinedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(2),
          icon: const Icon(Icons.transform, size: 18),
          label: const Text('CNF'),
          style: buttonStyle,
        ),
        OutlinedButton.icon(
          onPressed: () => widget.onNavigateTab?.call(3),
          icon: const Icon(Icons.water_drop, size: 18),
          label: const Text('Bombeamento'),
          style: buttonStyle,
        ),
      ],
    );
  }

  Widget _buildVariablesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variáveis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _variableController,
                    decoration: const InputDecoration(
                      labelText: 'Variável',
                      hintText: 'A, B, S',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addVariable,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar variável',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.grammar?.variables.isNotEmpty == true)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.grammar!.variables.map((variable) {
                  return Chip(
                    label: Text(variable),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeVariable(variable),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTerminalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terminais',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _terminalController,
                    decoration: const InputDecoration(
                      labelText: 'Terminal',
                      hintText: 'a, b, c',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-z]')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTerminal,
                  icon: const Icon(Icons.add),
                  tooltip: 'Adicionar terminal',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.grammar?.terminals.isNotEmpty == true)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: widget.grammar!.terminals.map((terminal) {
                  return Chip(
                    label: Text(terminal),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTerminal(terminal),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartVariableSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variável Inicial',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startVariableController,
                    decoration: const InputDecoration(
                      labelText: 'Variável inicial',
                      hintText: 'S',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Z]')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _setStartVariable,
                  icon: const Icon(Icons.flag),
                  tooltip: 'Definir variável inicial',
                ),
              ],
            ),
            if (widget.grammar?.startVariable.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Inicial: ${widget.grammar!.startVariable}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produções',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Produção',
                hintText: 'S → aSb | λ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _addProduction,
                    child: const Text('Adicionar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _clearProductions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade100,
                      foregroundColor: Colors.red.shade700,
                    ),
                    child: const Text('Limpar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.grammar?.productions.isNotEmpty == true)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.grammar!.productions.length,
                  itemBuilder: (context, index) {
                    final production = widget.grammar!.productions[index];
                    return ListTile(
                      dense: true,
                      title: Text(
                        production.toString(),
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 16),
                        onPressed: () => _removeProduction(production),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamplesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exemplos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildExampleButton(
              'L = {a^n b^n | n ≥ 0}',
              'S → aSb | λ',
            ),
            _buildExampleButton(
              'L = {palíndromos}',
              'S → aSa | bSb | a | b | λ',
            ),
            _buildExampleButton(
              'L = {a^n b^m | n, m ≥ 0}',
              'S → AB\nA → aA | λ\nB → bB | λ',
            ),
            _buildExampleButton(
              'L = {a^n b^n c^n | n ≥ 0}',
              'S → aSBC | λ\nCB → BC\nbB → bb\nbC → bc\ncC → cc',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExampleButton(String title, String grammar) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => _loadExample(grammar),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                grammar,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addVariable() {
    final variable = _variableController.text.trim().toUpperCase();
    if (variable.isNotEmpty && variable.length == 1) {
      // This would need to be implemented in the parent widget
      _variableController.clear();
    }
  }

  void _removeVariable(String variable) {
    // This would need to be implemented in the parent widget
  }

  void _addTerminal() {
    final terminal = _terminalController.text.trim().toLowerCase();
    if (terminal.isNotEmpty && terminal.length == 1) {
      // This would need to be implemented in the parent widget
      _terminalController.clear();
    }
  }

  void _removeTerminal(String terminal) {
    // This would need to be implemented in the parent widget
  }

  void _setStartVariable() {
    final startVar = _startVariableController.text.trim().toUpperCase();
    if (startVar.isNotEmpty && startVar.length == 1) {
      // This would need to be implemented in the parent widget
    }
  }

  void _addProduction() {
    final production = _productionController.text.trim();
    if (production.isNotEmpty) {
      // This would need to be implemented in the parent widget
      _productionController.clear();
    }
  }

  void _removeProduction(CFGProduction production) {
    // This would need to be implemented in the parent widget
  }

  void _clearProductions() {
    // This would need to be implemented in the parent widget
  }

  void _loadExample(String grammar) {
    _productionController.text = grammar;
    // This would need to be implemented in the parent widget
  }
}
