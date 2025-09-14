import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard shortcuts manager for JFlutter
class KeyboardShortcuts extends StatefulWidget {
  final Widget child;
  final KeyboardShortcutCallbacks callbacks;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.callbacks,
  });

  @override
  State<KeyboardShortcuts> createState() => _KeyboardShortcutsState();
}

class _KeyboardShortcutsState extends State<KeyboardShortcuts> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: widget.child,
    );
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    final isCtrlPressed = event.isControlPressed;
    final isShiftPressed = event.isShiftPressed;
    final isAltPressed = event.isAltPressed;
    final logicalKey = event.logicalKey;

    // Handle keyboard shortcuts
    if (isCtrlPressed) {
      switch (logicalKey) {
        case LogicalKeyboardKey.keyN:
          widget.callbacks.onNewAutomaton?.call();
          break;
        case LogicalKeyboardKey.keyO:
          widget.callbacks.onOpenAutomaton?.call();
          break;
        case LogicalKeyboardKey.keyS:
          if (isShiftPressed) {
            widget.callbacks.onSaveAsAutomaton?.call();
          } else {
            widget.callbacks.onSaveAutomaton?.call();
          }
          break;
        case LogicalKeyboardKey.keyE:
          widget.callbacks.onExportAutomaton?.call();
          break;
        case LogicalKeyboardKey.keyI:
          widget.callbacks.onImportAutomaton?.call();
          break;
        case LogicalKeyboardKey.keyZ:
          if (isShiftPressed) {
            widget.callbacks.onRedo?.call();
          } else {
            widget.callbacks.onUndo?.call();
          }
          break;
        case LogicalKeyboardKey.keyY:
          widget.callbacks.onRedo?.call();
          break;
        case LogicalKeyboardKey.keyA:
          widget.callbacks.onSelectAll?.call();
          break;
        case LogicalKeyboardKey.keyC:
          widget.callbacks.onCopy?.call();
          break;
        case LogicalKeyboardKey.keyV:
          widget.callbacks.onPaste?.call();
          break;
        case LogicalKeyboardKey.keyX:
          widget.callbacks.onCut?.call();
          break;
        case LogicalKeyboardKey.keyD:
          widget.callbacks.onDuplicate?.call();
          break;
        case LogicalKeyboardKey.keyR:
          widget.callbacks.onRunSimulation?.call();
          break;
        case LogicalKeyboardKey.keyT:
          widget.callbacks.onStepByStep?.call();
          break;
        case LogicalKeyboardKey.keyM:
          widget.callbacks.onMinimize?.call();
          break;
        case LogicalKeyboardKey.keyF:
          widget.callbacks.onConvertToDFA?.call();
          break;
        case LogicalKeyboardKey.keyG:
          widget.callbacks.onConvertToGrammar?.call();
          break;
        case LogicalKeyboardKey.keyH:
          widget.callbacks.onShowHelp?.call();
          break;
        case LogicalKeyboardKey.keyL:
          widget.callbacks.onLayout?.call();
          break;
        case LogicalKeyboardKey.keyP:
          widget.callbacks.onPrint?.call();
          break;
        case LogicalKeyboardKey.keyQ:
          widget.callbacks.onQuit?.call();
          break;
      }
    } else if (isAltPressed) {
      switch (logicalKey) {
        case LogicalKeyboardKey.key1:
          widget.callbacks.onSwitchToDFA?.call();
          break;
        case LogicalKeyboardKey.key2:
          widget.callbacks.onSwitchToNFA?.call();
          break;
        case LogicalKeyboardKey.key3:
          widget.callbacks.onSwitchToGrammar?.call();
          break;
      }
    } else {
      switch (logicalKey) {
        case LogicalKeyboardKey.delete:
        case LogicalKeyboardKey.backspace:
          widget.callbacks.onDelete?.call();
          break;
        case LogicalKeyboardKey.escape:
          widget.callbacks.onEscape?.call();
          break;
        case LogicalKeyboardKey.enter:
          widget.callbacks.onEnter?.call();
          break;
        case LogicalKeyboardKey.space:
          widget.callbacks.onSpace?.call();
          break;
        case LogicalKeyboardKey.arrowUp:
          widget.callbacks.onArrowUp?.call();
          break;
        case LogicalKeyboardKey.arrowDown:
          widget.callbacks.onArrowDown?.call();
          break;
        case LogicalKeyboardKey.arrowLeft:
          widget.callbacks.onArrowLeft?.call();
          break;
        case LogicalKeyboardKey.arrowRight:
          widget.callbacks.onArrowRight?.call();
          break;
        case LogicalKeyboardKey.f1:
          widget.callbacks.onShowHelp?.call();
          break;
        case LogicalKeyboardKey.f2:
          widget.callbacks.onRename?.call();
          break;
        case LogicalKeyboardKey.f5:
          widget.callbacks.onRefresh?.call();
          break;
        case LogicalKeyboardKey.f9:
          widget.callbacks.onRunSimulation?.call();
          break;
        case LogicalKeyboardKey.f10:
          widget.callbacks.onStepByStep?.call();
          break;
        case LogicalKeyboardKey.f11:
          widget.callbacks.onToggleFullscreen?.call();
          break;
        case LogicalKeyboardKey.f12:
          widget.callbacks.onToggleDebug?.call();
          break;
      }
    }
  }
}

/// Callbacks for keyboard shortcuts
class KeyboardShortcutCallbacks {
  // File operations
  final VoidCallback? onNewAutomaton;
  final VoidCallback? onOpenAutomaton;
  final VoidCallback? onSaveAutomaton;
  final VoidCallback? onSaveAsAutomaton;
  final VoidCallback? onExportAutomaton;
  final VoidCallback? onImportAutomaton;
  final VoidCallback? onPrint;
  final VoidCallback? onQuit;

  // Edit operations
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onCut;
  final VoidCallback? onCopy;
  final VoidCallback? onPaste;
  final VoidCallback? onDuplicate;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onEscape;
  final VoidCallback? onEnter;
  final VoidCallback? onSpace;

  // Navigation
  final VoidCallback? onArrowUp;
  final VoidCallback? onArrowDown;
  final VoidCallback? onArrowLeft;
  final VoidCallback? onArrowRight;

  // Simulation
  final VoidCallback? onRunSimulation;
  final VoidCallback? onStepByStep;

  // Operations
  final VoidCallback? onMinimize;
  final VoidCallback? onConvertToDFA;
  final VoidCallback? onConvertToGrammar;
  final VoidCallback? onLayout;

  // UI
  final VoidCallback? onSwitchToDFA;
  final VoidCallback? onSwitchToNFA;
  final VoidCallback? onSwitchToGrammar;
  final VoidCallback? onShowHelp;
  final VoidCallback? onRename;
  final VoidCallback? onRefresh;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onToggleDebug;

  const KeyboardShortcutCallbacks({
    this.onNewAutomaton,
    this.onOpenAutomaton,
    this.onSaveAutomaton,
    this.onSaveAsAutomaton,
    this.onExportAutomaton,
    this.onImportAutomaton,
    this.onPrint,
    this.onQuit,
    this.onUndo,
    this.onRedo,
    this.onCut,
    this.onCopy,
    this.onPaste,
    this.onDuplicate,
    this.onSelectAll,
    this.onDelete,
    this.onEscape,
    this.onEnter,
    this.onSpace,
    this.onArrowUp,
    this.onArrowDown,
    this.onArrowLeft,
    this.onArrowRight,
    this.onRunSimulation,
    this.onStepByStep,
    this.onMinimize,
    this.onConvertToDFA,
    this.onConvertToGrammar,
    this.onLayout,
    this.onSwitchToDFA,
    this.onSwitchToNFA,
    this.onSwitchToGrammar,
    this.onShowHelp,
    this.onRename,
    this.onRefresh,
    this.onToggleFullscreen,
    this.onToggleDebug,
  });
}

/// Help dialog showing available keyboard shortcuts
class KeyboardShortcutsHelp extends StatelessWidget {
  const KeyboardShortcutsHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atalhos de Teclado'),
      content: SizedBox(
        width: 600,
        height: 500,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShortcutSection(
                context,
                'Arquivo',
                [
                  _ShortcutItem('Ctrl+N', 'Novo automaton'),
                  _ShortcutItem('Ctrl+O', 'Abrir automaton'),
                  _ShortcutItem('Ctrl+S', 'Salvar automaton'),
                  _ShortcutItem('Ctrl+Shift+S', 'Salvar como'),
                  _ShortcutItem('Ctrl+E', 'Exportar'),
                  _ShortcutItem('Ctrl+I', 'Importar'),
                  _ShortcutItem('Ctrl+P', 'Imprimir'),
                  _ShortcutItem('Ctrl+Q', 'Sair'),
                ],
              ),
              const SizedBox(height: 16),
              _buildShortcutSection(
                context,
                'Edição',
                [
                  _ShortcutItem('Ctrl+Z', 'Desfazer'),
                  _ShortcutItem('Ctrl+Y', 'Refazer'),
                  _ShortcutItem('Ctrl+X', 'Cortar'),
                  _ShortcutItem('Ctrl+C', 'Copiar'),
                  _ShortcutItem('Ctrl+V', 'Colar'),
                  _ShortcutItem('Ctrl+D', 'Duplicar'),
                  _ShortcutItem('Ctrl+A', 'Selecionar tudo'),
                  _ShortcutItem('Delete', 'Excluir selecionado'),
                  _ShortcutItem('Escape', 'Cancelar seleção'),
                ],
              ),
              const SizedBox(height: 16),
              _buildShortcutSection(
                context,
                'Navegação',
                [
                  _ShortcutItem('↑↓←→', 'Mover seleção'),
                  _ShortcutItem('Alt+1', 'Aba AFD'),
                  _ShortcutItem('Alt+2', 'Aba AFN'),
                  _ShortcutItem('Alt+3', 'Aba Gramática'),
                ],
              ),
              const SizedBox(height: 16),
              _buildShortcutSection(
                context,
                'Simulação',
                [
                  _ShortcutItem('Ctrl+R', 'Executar simulação'),
                  _ShortcutItem('Ctrl+T', 'Passo a passo'),
                  _ShortcutItem('F9', 'Executar simulação'),
                  _ShortcutItem('F10', 'Passo a passo'),
                ],
              ),
              const SizedBox(height: 16),
              _buildShortcutSection(
                context,
                'Operações',
                [
                  _ShortcutItem('Ctrl+M', 'Minimizar AFD'),
                  _ShortcutItem('Ctrl+F', 'Converter para AFD'),
                  _ShortcutItem('Ctrl+G', 'Converter para Gramática'),
                  _ShortcutItem('Ctrl+L', 'Aplicar layout'),
                ],
              ),
              const SizedBox(height: 16),
              _buildShortcutSection(
                context,
                'Interface',
                [
                  _ShortcutItem('F1', 'Mostrar ajuda'),
                  _ShortcutItem('F2', 'Renomear'),
                  _ShortcutItem('F5', 'Atualizar'),
                  _ShortcutItem('F11', 'Tela cheia'),
                  _ShortcutItem('F12', 'Debug'),
                ],
              ),
            ],
          ),
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

  Widget _buildShortcutSection(BuildContext context, String title, List<_ShortcutItem> shortcuts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...shortcuts.map((shortcut) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    shortcut.key,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shortcut.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
}

class _ShortcutItem {
  final String key;
  final String description;

  _ShortcutItem(this.key, this.description);
}
