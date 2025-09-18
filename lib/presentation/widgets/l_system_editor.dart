import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/l_system.dart';
import '../../core/models/l_system_rule.dart';

/// Comprehensive L-System editor widget
class LSystemEditor extends ConsumerStatefulWidget {
  const LSystemEditor({super.key});

  @override
  ConsumerState<LSystemEditor> createState() => _LSystemEditorState();
}

class _LSystemEditorState extends ConsumerState<LSystemEditor> {
  final TextEditingController _axiomController = TextEditingController(text: 'F');
  final TextEditingController _ruleController = TextEditingController(text: 'F');
  final TextEditingController _replacementController = TextEditingController(text: 'F+F-F-F+F');
  final TextEditingController _angleController = TextEditingController(text: '90');
  final TextEditingController _iterationsController = TextEditingController(text: '3');
  final TextEditingController _nameController = TextEditingController(text: 'Dragon Curve');
  
  final List<LSystemRule> _rules = [];
  LSystemRule? _selectedRule;
  bool _isEditing = false;

  @override
  void dispose() {
    _axiomController.dispose();
    _ruleController.dispose();
    _replacementController.dispose();
    _angleController.dispose();
    _iterationsController.dispose();
    _nameController.dispose();
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
            _buildLSystemInfo(context),
            const SizedBox(height: 16),
            _buildRuleEditor(context),
            const SizedBox(height: 16),
            _buildRulesList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          'L-System Editor',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _addRule,
          icon: const Icon(Icons.add),
          label: const Text('Add Rule'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: _clearLSystem,
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

  Widget _buildLSystemInfo(BuildContext context) {
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
            'L-System Parameters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _axiomController,
                  decoration: const InputDecoration(
                    labelText: 'Axiom',
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
              Expanded(
                child: TextField(
                  controller: _angleController,
                  decoration: const InputDecoration(
                    labelText: 'Angle (degrees)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _iterationsController,
                  decoration: const InputDecoration(
                    labelText: 'Iterations',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRuleEditor(BuildContext context) {
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
            _isEditing ? 'Edit Rule' : 'Add Rule',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ruleController,
                  decoration: const InputDecoration(
                    labelText: 'Symbol',
                    hintText: 'e.g., F, +, -',
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
                  controller: _replacementController,
                  decoration: const InputDecoration(
                    labelText: 'Replacement',
                    hintText: 'e.g., F+F-F-F+F',
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
                onPressed: _isEditing ? _updateRule : _addRule,
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

  Widget _buildRulesList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Production Rules (${_rules.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: _rules.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  itemCount: _rules.length,
                  itemBuilder: (context, index) {
                    final rule = _rules[index];
                    return _buildRuleItem(context, rule, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No rules yet',
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

  Widget _buildRuleItem(BuildContext context, LSystemRule rule, int index) {
    final isSelected = _selectedRule == rule;
    
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
          '${rule.symbol} → ${rule.replacement}',
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
              onPressed: () => _editRule(rule),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
            IconButton(
              onPressed: () => _deleteRule(rule),
              icon: const Icon(Icons.delete),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _selectRule(rule),
        selected: isSelected,
      ),
    );
  }

  void _addRule() {
    final symbol = _ruleController.text.trim();
    final replacement = _replacementController.text.trim();
    
    if (symbol.isEmpty || replacement.isEmpty) {
      _showError('Both symbol and replacement must be specified');
      return;
    }
    
    final rule = LSystemRule(
      symbol: symbol,
      replacement: replacement,
    );
    
    setState(() {
      _rules.add(rule);
    });
    
    _clearFields();
  }

  void _updateRule() {
    if (_selectedRule == null) return;
    
    final symbol = _ruleController.text.trim();
    final replacement = _replacementController.text.trim();
    
    if (symbol.isEmpty || replacement.isEmpty) {
      _showError('Both symbol and replacement must be specified');
      return;
    }
    
    setState(() {
      final index = _rules.indexOf(_selectedRule!);
      _rules[index] = LSystemRule(
        symbol: symbol,
        replacement: replacement,
      );
      _selectedRule = _rules[index];
      _isEditing = false;
    });
    
    _clearFields();
  }

  void _editRule(LSystemRule rule) {
    setState(() {
      _selectedRule = rule;
      _isEditing = true;
      _ruleController.text = rule.symbol;
      _replacementController.text = rule.replacement;
    });
  }

  void _deleteRule(LSystemRule rule) {
    setState(() {
      _rules.remove(rule);
      if (_selectedRule == rule) {
        _selectedRule = null;
        _isEditing = false;
        _clearFields();
      }
    });
  }

  void _selectRule(LSystemRule rule) {
    setState(() {
      _selectedRule = rule;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedRule = null;
    });
    _clearFields();
  }

  void _clearLSystem() {
    setState(() {
      _rules.clear();
      _selectedRule = null;
      _isEditing = false;
    });
    _clearFields();
  }

  void _clearFields() {
    _ruleController.clear();
    _replacementController.clear();
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
