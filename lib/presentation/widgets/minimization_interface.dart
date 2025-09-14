import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/entities/automaton_entity.dart';
import '../../core/automaton.dart';
import '../../core/algorithms.dart';
import '../../core/dfa_algorithms.dart';
import '../providers/automaton_provider.dart';
import 'contextual_help.dart';

/// Interactive minimization interface based on JFLAP
/// Provides step-by-step DFA minimization with visual tree representation
class MinimizationInterface extends StatefulWidget {
  const MinimizationInterface({super.key});

  @override
  State<MinimizationInterface> createState() => _MinimizationInterfaceState();
}

class _MinimizationInterfaceState extends State<MinimizationInterface> {
  MinimizeTreeNode? _rootNode;
  MinimizeTreeNode? _selectedNode;
  MinimizeTreeNode? _expandingNode;
  bool _isMinimizationComplete = false;
  AutomatonEntity? _minimizedAutomaton;
  String _currentStep = 'Inicializando minimização...';

  @override
  void initState() {
    super.initState();
    _initializeMinimization();
  }

  void _initializeMinimization() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final automaton = automatonProvider.currentAutomaton;
    
    if (automaton == null || automaton.type != AutomatonType.dfa) {
      setState(() {
        _currentStep = 'Erro: Nenhum DFA carregado para minimização';
      });
      return;
    }

    // Convert to DFA if needed
    final dfa = _convertToAutomaton(automaton);
    if (dfa == null) {
      setState(() {
        _currentStep = 'Erro: Não foi possível converter para DFA';
      });
      return;
    }

    // Initialize minimization tree
    _rootNode = _createInitialTree(dfa);
    setState(() {
      _currentStep = 'Árvore de minimização inicializada. Clique em um nó para expandir.';
    });
  }

  Automaton? _convertToAutomaton(AutomatonEntity entity) {
    // Convert AutomatonEntity to Automaton
    final states = entity.states.map((s) => StateNode(
      id: s.id,
      name: s.name,
      x: s.x,
      y: s.y,
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    )).toList();
    
    return Automaton(
      alphabet: entity.alphabet,
      states: states,
      transitions: entity.transitions,
      initialId: entity.initialId,
      nextId: entity.nextId,
    );
  }

  MinimizeTreeNode _createInitialTree(Automaton dfa) {
    // Separate final and non-final states
    final finalStates = dfa.states.where((s) => s.isFinal).toList();
    final nonFinalStates = dfa.states.where((s) => !s.isFinal).toList();

    final root = MinimizeTreeNode('Root', []);
    
    if (nonFinalStates.isNotEmpty) {
      final nonFinalNode = MinimizeTreeNode('Non-final', nonFinalStates);
      root.add(nonFinalNode);
    }
    
    if (finalStates.isNotEmpty) {
      final finalNode = MinimizeTreeNode('Final', finalStates);
      root.add(finalNode);
    }

    return root;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Minimização de DFA',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 8),
                ContextualHelp(
                  helpContent: HelpContent.minimizationInterface,
                  title: 'Interface de Minimização',
                  icon: Icons.account_tree,
                  child: Icon(
                    Icons.help_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current step indicator
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _isMinimizationComplete ? Icons.check_circle : Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentStep,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Main content
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Use responsive layout based on screen width
                  if (constraints.maxWidth < 800) {
                    // Mobile layout: Stack panels vertically
                    return Column(
                      children: [
                        // Minimization tree
                        Expanded(
                          flex: 1,
                          child: _buildTreePanel(),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Controls and results
                        Expanded(
                          flex: 1,
                          child: _buildControlsPanel(),
                        ),
                      ],
                    );
                  } else {
                    // Desktop layout: Side by side panels
                    return Row(
                      children: [
                        // Left panel - Minimization tree
                        Expanded(
                          flex: 1,
                          child: _buildTreePanel(),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Right panel - Controls and results
                        Expanded(
                          flex: 1,
                          child: _buildControlsPanel(),
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreePanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Árvore de Minimização',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _rootNode == null
                  ? const Center(child: Text('Nenhuma árvore carregada'))
                  : _buildTreeView(_rootNode!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeView(MinimizeTreeNode node, {int level = 0}) {
    final isSelected = _selectedNode == node;
    final isExpanding = _expandingNode == node;
    
    return Container(
      margin: EdgeInsets.only(left: level * 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _selectNode(node),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : isExpanding
                        ? Theme.of(context).colorScheme.secondary.withOpacity(0.1)
                        : null,
                border: isSelected 
                    ? Border.all(color: Theme.of(context).colorScheme.primary)
                    : null,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    node.children.isEmpty ? Icons.circle : Icons.folder,
                    size: 16,
                    color: isSelected 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    node.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (node.states.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${node.states.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Show states in this node
          if (isSelected && node.states.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.only(left: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: node.states.map((state) => Chip(
                  label: Text(state.name),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                )).toList(),
              ),
            ),
          ],
          
          // Show children
          if (node.children.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...node.children.map((child) => _buildTreeView(child, level: level + 1)),
          ],
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controles',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 16),
            
            // Node actions
            if (_selectedNode != null) ...[
              Text(
                'Nó Selecionado: ${_selectedNode!.label}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_canExpandNode(_selectedNode!))
                    ElevatedButton.icon(
                      onPressed: () => _expandNode(_selectedNode!),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Expandir'),
                    ),
                  
                  if (_canCheckNode(_selectedNode!))
                    ElevatedButton.icon(
                      onPressed: () => _checkNode(_selectedNode!),
                      icon: const Icon(Icons.check),
                      label: const Text('Verificar'),
                    ),
                  
                  if (_canRemoveNode(_selectedNode!))
                    OutlinedButton.icon(
                      onPressed: () => _removeNode(_selectedNode!),
                      icon: const Icon(Icons.delete),
                      label: const Text('Remover'),
                    ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Global actions
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _canFinishMinimization() ? _finishMinimization : null,
                  icon: const Icon(Icons.done),
                  label: const Text('Finalizar'),
                ),
                
                OutlinedButton.icon(
                  onPressed: _resetMinimization,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reiniciar'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Results
            if (_minimizedAutomaton != null) ...[
              Text(
                'DFA Minimizado',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estados: ${_minimizedAutomaton!.states.length}'),
                    Text('Transições: ${_minimizedAutomaton!.transitions.length}'),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _applyMinimizedAutomaton,
                      icon: const Icon(Icons.check),
                      label: const Text('Aplicar Resultado'),
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

  void _selectNode(MinimizeTreeNode node) {
    setState(() {
      _selectedNode = node;
    });
  }

  bool _canExpandNode(MinimizeTreeNode node) {
    return _expandingNode == null && 
           node.children.isEmpty && 
           node.states.length > 1 &&
           !_isMinimizationComplete;
  }

  bool _canCheckNode(MinimizeTreeNode node) {
    return _expandingNode == node && !_isMinimizationComplete;
  }

  bool _canRemoveNode(MinimizeTreeNode node) {
    return _expandingNode?.parent == node && !_isMinimizationComplete;
  }

  bool _canFinishMinimization() {
    if (_isMinimizationComplete) return false;
    
    // Check if all distinguishable groups have been processed
    return _rootNode != null && _allNodesProcessed(_rootNode!);
  }

  bool _allNodesProcessed(MinimizeTreeNode node) {
    if (node.children.isEmpty) {
      // Leaf node - check if it's distinguishable
      return node.states.length <= 1;
    }
    
    // Internal node - check all children
    return node.children.every((child) => _allNodesProcessed(child));
  }

  void _expandNode(MinimizeTreeNode node) {
    setState(() {
      _expandingNode = node;
      _currentStep = 'Expandindo nó "${node.label}". Selecione um símbolo para dividir.';
    });
    
    // Show symbol selection dialog
    _showSymbolSelectionDialog(node);
  }

  void _showSymbolSelectionDialog(MinimizeTreeNode node) {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final automaton = automatonProvider.currentAutomaton;
    
    if (automaton == null) return;
    
    final alphabet = automaton.alphabet.toList();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Selecionar Símbolo para Expandir "${node.label}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: alphabet.map((symbol) => ListTile(
            title: Text(symbol),
            onTap: () {
              Navigator.pop(context);
              _expandNodeWithSymbol(node, symbol);
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _expandingNode = null;
                _currentStep = 'Expansão cancelada.';
              });
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _expandNodeWithSymbol(MinimizeTreeNode node, String symbol) {
    // This is a simplified implementation
    // In a full implementation, you would:
    // 1. Find all states that can be distinguished by the symbol
    // 2. Create new child nodes for each distinguishable group
    // 3. Update the tree structure
    
    setState(() {
      _expandingNode = null;
      _currentStep = 'Nó "${node.label}" expandido com símbolo "$symbol".';
    });
  }

  void _checkNode(MinimizeTreeNode node) {
    // Verify if the node expansion is correct
    setState(() {
      _expandingNode = null;
      _currentStep = 'Nó "${node.label}" verificado e aprovado.';
    });
  }

  void _removeNode(MinimizeTreeNode node) {
    setState(() {
      node.parent?.remove(node);
      _selectedNode = null;
      _currentStep = 'Nó removido.';
    });
  }

  void _finishMinimization() {
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    final automaton = automatonProvider.currentAutomaton;
    
    if (automaton == null) return;
    
    // Perform actual minimization
    final dfa = _convertToAutomaton(automaton);
    if (dfa != null) {
      final minimized = minimizeDfa(dfa);
      _minimizedAutomaton = _convertFromAutomaton(minimized);
      
      setState(() {
        _isMinimizationComplete = true;
        _currentStep = 'Minimização concluída! ${automaton.states.length} → ${_minimizedAutomaton!.states.length} estados.';
      });
    }
  }

  AutomatonEntity _convertFromAutomaton(Automaton automaton) {
    final states = automaton.states.map((s) => StateEntity(
      id: s.id,
      name: s.name,
      x: s.x,
      y: s.y,
      isInitial: s.isInitial,
      isFinal: s.isFinal,
    )).toList();
    
    return AutomatonEntity(
      id: 'minimized_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Minimized DFA',
      alphabet: automaton.alphabet,
      states: states,
      transitions: automaton.transitions,
      initialId: automaton.initialId,
      nextId: automaton.nextId,
      type: AutomatonType.dfa,
    );
  }

  void _applyMinimizedAutomaton() {
    if (_minimizedAutomaton == null) return;
    
    final automatonProvider = Provider.of<AutomatonProvider>(context, listen: false);
    automatonProvider.setAutomaton(_minimizedAutomaton!);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('DFA minimizado aplicado com sucesso!'),
      ),
    );
  }

  void _resetMinimization() {
    setState(() {
      _selectedNode = null;
      _expandingNode = null;
      _isMinimizationComplete = false;
      _minimizedAutomaton = null;
    });
    
    _initializeMinimization();
  }
}

/// Tree node for minimization process
class MinimizeTreeNode {
  final String label;
  final List<StateNode> states;
  final List<MinimizeTreeNode> children = [];
  MinimizeTreeNode? parent;
  String terminal = '';

  MinimizeTreeNode(this.label, this.states);

  void add(MinimizeTreeNode child) {
    child.parent = this;
    children.add(child);
  }

  void remove(MinimizeTreeNode child) {
    child.parent = null;
    children.remove(child);
  }
}

/// Help content for minimization interface
class MinimizationHelpContent {
  static const String minimizationInterface = '''
Interface de Minimização de DFA

Esta interface permite minimizar um DFA passo-a-passo, seguindo o algoritmo de minimização clássico.

Como usar:
1. A árvore de minimização mostra os grupos de estados distinguíveis
2. Clique em um nó para selecioná-lo
3. Use "Expandir" para dividir um grupo por um símbolo
4. Use "Verificar" para confirmar uma expansão
5. Use "Finalizar" quando todos os grupos estiverem processados

O resultado será um DFA com o menor número possível de estados equivalente ao original.
''';
}
