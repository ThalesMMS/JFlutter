//
//  grammar_editor.dart
//  JFlutter
//
//  Editor visual de gramáticas que combina campos reativos, lista de produções
//  e ações rápidas para criar, atualizar ou remover regras. Integra-se ao
//  GrammarProvider para sincronizar estado global, disponibilizando fluxos de
//  limpeza, importação e alteração do símbolo inicial com layout adaptável a
//  diferentes tamanhos de tela.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/production.dart';
import '../providers/grammar_provider.dart';

/// Comprehensive grammar editor widget
class GrammarEditor extends ConsumerStatefulWidget {
  const GrammarEditor({super.key});

  @override
  ConsumerState<GrammarEditor> createState() => _GrammarEditorState();
}

class _GrammarEditorState extends ConsumerState<GrammarEditor> {
  final TextEditingController _startSymbolController = TextEditingController(
    text: 'S',
  );
  final TextEditingController _leftSideController = TextEditingController();
  final TextEditingController _rightSideController = TextEditingController();
  final TextEditingController _grammarNameController = TextEditingController(
    text: 'My Grammar',
  );

  String? _selectedProductionId;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(grammarProvider);
    _startSymbolController.text = state.startSymbol;
    _grammarNameController.text = state.name;
  }

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
    final grammarState = ref.watch(grammarProvider);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildGrammarInfo(context),
            const SizedBox(height: 16),
            _buildProductionEditor(context),
            const SizedBox(height: 16),
            _buildProductionsList(context, grammarState.productions),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen =
        screenWidth < 600; // Increased breakpoint for better mobile support
    final theme = Theme.of(context);
    final clearButton = ElevatedButton.icon(
      onPressed: _clearGrammar,
      icon: const Icon(Icons.clear, size: 16),
      label: const Text('Clear'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );

    if (isSmallScreen) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.text_fields,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Grammar Editor',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              clearButton,
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.text_fields, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Grammar Editor',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        clearButton,
      ],
    );
  }

  Widget _buildGrammarInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grammar Information',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;

              if (isSmallScreen) {
                return Column(
                  children: [
                    TextField(
                      controller: _grammarNameController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateName(value.trim()),
                      decoration: const InputDecoration(
                        labelText: 'Grammar Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _startSymbolController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateStartSymbol(value.trim()),
                      decoration: const InputDecoration(
                        labelText: 'Start Symbol',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _grammarNameController,
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateName(value.trim()),
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
                      onChanged: (value) => ref
                          .read(grammarProvider.notifier)
                          .updateStartSymbol(value.trim()),
                      decoration: const InputDecoration(
                        labelText: 'Start Symbol',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductionEditor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEditing ? 'Edit Production Rule' : 'Add Production Rule',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 500;

              if (isSmallScreen) {
                return Column(
                  children: [
                    TextField(
                      controller: _leftSideController,
                      decoration: const InputDecoration(
                        labelText: 'Left Side (Variable)',
                        hintText: 'e.g., S, A, B',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.arrow_downward,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _rightSideController,
                      decoration: const InputDecoration(
                        labelText: 'Right Side (Production)',
                        hintText: 'e.g., aA, bB, ε',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ],
                );
              }

              return Row(
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
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;

              if (isSmallScreen) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isEditing
                          ? _updateProduction
                          : _addProduction,
                      icon: Icon(_isEditing ? Icons.save : Icons.add),
                      label: Text(_isEditing ? 'Update' : 'Add'),
                    ),
                    if (_isEditing) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _cancelEdit,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ],
                );
              }

              return Row(
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
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductionsList(
    BuildContext context,
    List<Production> productions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Production Rules (${productions.length})',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (productions.isEmpty)
          _buildEmptyState(context)
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            children: productions.asMap().entries.map((entry) {
              final index = entry.key;
              final production = entry.value;
              return _buildProductionItem(context, production, index);
            }).toList(),
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

  Widget _buildProductionItem(
    BuildContext context,
    Production production,
    int index,
  ) {
    final isSelected = _selectedProductionId == production.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
          '${_formatSymbols(production.leftSide)} → ${_formatRightSide(production)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Rule ${index + 1}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _editProduction(production);
            } else if (value == 'delete') {
              _deleteProduction(production);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
          child: const Icon(Icons.more_vert),
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

    final parsedLeft = _parseLeftSide(leftSide);
    if (parsedLeft.isEmpty) {
      _showError('Left side must contain a non-terminal symbol');
      return;
    }
    if (parsedLeft.length != 1) {
      _showError('Left side must contain exactly one non-terminal symbol');
      return;
    }

    final parsedRight = _parseRightSide(rightSide);
    final isLambda =
        parsedRight.length == 1 && _isLambdaSymbol(parsedRight.first);
    final normalizedRight = isLambda ? <String>[] : parsedRight;

    ref
        .read(grammarProvider.notifier)
        .addProduction(
          leftSide: parsedLeft,
          rightSide: normalizedRight,
          isLambda: isLambda,
        );
    _clearFields();
  }

  void _updateProduction() {
    if (_selectedProductionId == null) return;

    final leftSide = _leftSideController.text.trim();
    final rightSide = _rightSideController.text.trim();

    if (leftSide.isEmpty || rightSide.isEmpty) {
      _showError('Both left side and right side must be specified');
      return;
    }

    final parsedLeft = _parseLeftSide(leftSide);
    if (parsedLeft.isEmpty) {
      _showError('Left side must contain a non-terminal symbol');
      return;
    }
    if (parsedLeft.length != 1) {
      _showError('Left side must contain exactly one non-terminal symbol');
      return;
    }

    final parsedRight = _parseRightSide(rightSide);
    final isLambda =
        parsedRight.length == 1 && _isLambdaSymbol(parsedRight.first);
    final normalizedRight = isLambda ? <String>[] : parsedRight;

    ref
        .read(grammarProvider.notifier)
        .updateProduction(
          _selectedProductionId!,
          leftSide: parsedLeft,
          rightSide: normalizedRight,
          isLambda: isLambda,
        );
    setState(() {
      _isEditing = false;
      _selectedProductionId = null;
    });
    _clearFields();
  }

  void _editProduction(Production production) {
    setState(() {
      _selectedProductionId = production.id;
      _isEditing = true;
      _leftSideController.text = _formatSymbols(production.leftSide);
      _rightSideController.text = _formatRightSide(production);
    });
  }

  void _deleteProduction(Production production) {
    ref.read(grammarProvider.notifier).deleteProduction(production.id);
    if (_selectedProductionId == production.id) {
      setState(() {
        _selectedProductionId = null;
        _isEditing = false;
      });
      _clearFields();
    }
  }

  void _selectProduction(Production production) {
    setState(() {
      _selectedProductionId = production.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _selectedProductionId = null;
    });
    _clearFields();
  }

  void _clearGrammar() {
    ref.read(grammarProvider.notifier).clearProductions();
    setState(() {
      _selectedProductionId = null;
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

  List<String> _parseLeftSide(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    if (trimmed.contains(RegExp(r'\s+'))) {
      return trimmed
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
    }
    return [trimmed];
  }

  List<String> _parseRightSide(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    if (trimmed.contains(RegExp(r'\s+'))) {
      return trimmed
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
    }
    return trimmed.split('');
  }

  bool _isLambdaSymbol(String symbol) =>
      symbol == 'ε' || symbol == 'λ' || symbol.toLowerCase() == 'lambda';

  String _formatSymbols(List<String> symbols) {
    if (symbols.isEmpty) {
      return '';
    }
    return symbols.join();
  }

  String _formatRightSide(Production production) {
    if (production.isLambda || production.rightSide.isEmpty) {
      return 'ε';
    }
    return _formatSymbols(production.rightSide);
  }
}
