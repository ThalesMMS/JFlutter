import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';

/// Comprehensive grammar editor widget
class GrammarEditor extends ConsumerStatefulWidget {
  const GrammarEditor({super.key});

  @override
  ConsumerState<GrammarEditor> createState() => _GrammarEditorState();
}

class _GrammarEditorState extends ConsumerState<GrammarEditor> {
  final List<Production> _productions = [];
  final TextEditingController _startSymbolController = TextEditingController(text: 'S');
  final TextEditingController _leftSideController = TextEditingController();
  final TextEditingController _rightSideController = TextEditingController();
  final TextEditingController _grammarNameController = TextEditingController(text: 'My Grammar');
  
  Production? _selectedProduction;
  bool _isEditing = false;

  @override
  void dispose() {
    _startSymbolController.dispose();
    _leftSideController.dispose();
    _rightSideController.dispose();
    _grammarNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildGrammarInfo(context),
            const SizedBox(height: 16),
            _buildProductionEditor(context),
            const SizedBox(height: 16),
            _buildProductionsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_fields,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grammar Editor',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _addProduction,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Rule'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _clearGrammar,
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(
          Icons.text_fields,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'Grammar Editor',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _addProduction,
          icon: const Icon(Icons.add),
          label: const Text('Add Rule'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _clearGrammar,
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
        ),
      ],
    );
  }

  Widget _buildGrammarInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grammar Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _grammarNameController,
                  decoration: const InputDecoration(
                    labelText: 'Grammar Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _startSymbolController,
                  decoration: const InputDecoration(
                    labelText: 'Start Symbol',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionEditor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Production Rule' : 'Add Production Rule',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _leftSideController,
                  decoration: const InputDecoration(
                    labelText: 'Left Side (Variable)',
                    hintText: 'e.g., S, A, B',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _rightSideController,
                  decoration: const InputDecoration(
                    labelText: 'Right Side (Production)',
                    hintText: 'e.g., aA, bB, ε',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isEditing ? _updateProduction : _addProduction,
                icon: Icon(_isEditing ? Icons.save : Icons.add),
                label: Text(_isEditing ? 'Update' : 'Add'),
              ),
              if (_isEditing) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _cancelEdit,
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductionsList(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production Rules (${_productions.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _productions.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: _productions.length,
                    itemBuilder: (context, index) {
                      final production = _productions[index];
                      return _buildProductionItem(context, production, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.text_fields_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No production rules yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first production rule above',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductionItem(BuildContext context, Production production, int index) {
    final isSelected = _selectedProduction == production;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected 
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${production.leftSide} → ${production.rightSide}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Rule ${index + 1}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editProduction(production),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _deleteProduction(production),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _selectProduction(production),
        selected: isSelected,
      ),
    );
  }

  void _addProduction() {
    final leftSide = _leftSideController.text.trim();
    final rightSide = _rightSideController.text.trim();
    
    if (leftSide.isEmpty || rightSide.isEmpty) {
      _showError('Both left side and right side must be specified');
      return;
    }
    
    final production = Production(
      id: 'p${_productions.length + 1}',
      leftSide: [leftSide],
      rightSide: [rightSide],
    );
    
    setState(() {
      _productions.add(production);
    });
    
    _clearFields();
  }

  void _updateProduction() {
    if (_selectedProduction == null) return;
    
    final leftSide = _leftSideController.text.trim();
    final rightSide = _rightSideController.text.trim();
    
    if (leftSide.isEmpty || rightSide.isEmpty) {
      _showError('Both left side and right side must be specified');
      return;
    }
    
    setState(() {
      final index = _productions.indexOf(_selectedProduction!);
      _productions[index] = _selectedProduction!.copyWith(
        leftSide: [leftSide],
        rightSide: [rightSide],
      );
      _selectedProduction = _productions[index];
      _isEditing = false;
    });
    
    _clearFields();
  }

  void _editProduction(Production production) {
    setState(() {
      _selectedProduction = production;
      _isEditing = true;
      _leftSideController.text = production.leftSide.join(' ');
      _rightSideController.text = production.rightSide.join(' ');
    });
  }

  void _deleteProduction(Production production) {
    setState(() {
      _productions.remove(production);
      if (_selectedProduction == production) {
        _selectedProduction = null;
        _isEditing = false;
        _clearFields();
      }
    });
  }

  void _selectProduction(Production production) {
    setState(() {
      _selectedProduction = production;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedProduction = null;
    });
    _clearFields();
  }

  void _clearGrammar() {
    setState(() {
      _productions.clear();
      _selectedProduction = null;
      _isEditing = false;
    });
    _clearFields();
  }

  void _clearFields() {
    _leftSideController.clear();
    _rightSideController.clear();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
