import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/entities/automaton_entity.dart';
import '../providers/automaton_provider.dart';

/// Canvas widget for displaying and interacting with automatons
class AutomatonCanvas extends StatefulWidget {
  final AutomatonEntity? automaton;
  final void Function(AutomatonEntity)? onAutomatonChanged;
  final GlobalKey? canvasKey;

  const AutomatonCanvas({
    super.key,
    this.automaton,
    this.onAutomatonChanged,
    this.canvasKey,
  });

  @override
  State<AutomatonCanvas> createState() => _AutomatonCanvasState();
}

class _AutomatonCanvasState extends State<AutomatonCanvas> {
  final Set<String> _selectedTransitions = {};
  bool _isBoxSelecting = false;
  Offset? _boxSelectStart;
  Offset? _boxSelectEnd;
  bool _isDragging = false;
  Offset? _dragStart; // screen space (unused after canvas mapping)
  Offset? _dragStartCanvas; // canvas space
  bool _canDragStates = false; // only true when gesture started on a state
  Map<String, Offset> _dragOffsets = {};
  String? _editingTransition;
  final TextEditingController _transitionEditController =
      TextEditingController();
  final FocusNode _transitionEditFocus = FocusNode();

  // Mobile-specific gesture handling
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  Offset? _lastTapPosition; // canvas space
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();
    _transitionEditFocus.addListener(_onTransitionEditFocusChanged);
  }

  Set<String> get _selectedStates {
    final provider = Provider.of<AutomatonProvider>(context, listen: false);
    return provider.selectedStates;
  }

  void _updateSelectedStates(Set<String> states) {
    final provider = Provider.of<AutomatonProvider>(context, listen: false);
    provider.setSelectedStates(states);
  }

  void _clearSelectedStates() {
    final provider = Provider.of<AutomatonProvider>(context, listen: false);
    provider.clearSelectedStates();
  }

  @override
  void dispose() {
    _transitionEditController.dispose();
    _transitionEditFocus.dispose();
    super.dispose();
  }

  void _onTransitionEditFocusChanged() {
    if (!_transitionEditFocus.hasFocus && _editingTransition != null) {
      _finishTransitionEdit();
    }
  }

  // Removido: menu de contexto e criação de novo estado por duplo toque

  void _clearSelection() {
    setState(() {
      _clearSelectedStates();
      _selectedTransitions.clear();
    });
  }

  // Map a point from widget/screen local space to canvas drawing space
  Offset _toCanvasSpace(Offset p) {
    return Offset((p.dx - _offset.dx) / _scale, (p.dy - _offset.dy) / _scale);
  }

  // Removidos: barra de ações móvel e botão "..."

  Widget _buildMobileZoomControls() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildZoomButton(
              icon: Icons.zoom_in,
              onTap: () {
                setState(() {
                  _scale = (_scale * 1.2).clamp(0.5, 3.0);
                });
              },
            ),
            Container(height: 1, width: 40, color: Colors.grey.shade300),
            _buildZoomButton(
              icon: Icons.zoom_out,
              onTap: () {
                setState(() {
                  _scale = (_scale / 1.2).clamp(0.5, 3.0);
                });
              },
            ),
            Container(height: 1, width: 40, color: Colors.grey.shade300),
            _buildZoomButton(
              icon: Icons.center_focus_strong,
              onTap: () {
                setState(() {
                  _scale = 1.0;
                  _offset = Offset.zero;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 20),
      ),
    );
  }

  void _copySelected() {
    if (widget.automaton == null || _selectedStates.isEmpty) return;

    // Create a copy of selected states with their transitions
    final selectedStatesList = widget.automaton!.states
        .where((state) => _selectedStates.contains(state.id))
        .toList();

    final selectedTransitions = <String, List<String>>{};
    for (final entry in widget.automaton!.transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length == 2 && _selectedStates.contains(parts[0])) {
        // Only include transitions where destination is also selected
        final destinations = entry.value
            .where((dest) => _selectedStates.contains(dest))
            .toList();
        if (destinations.isNotEmpty) {
          selectedTransitions[entry.key] = destinations;
        }
      }
    }

    // Create a new automaton with selected states and transitions
    final copiedAutomaton = AutomatonEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Cópia',
      states: selectedStatesList,
      transitions: selectedTransitions,
      alphabet: widget.automaton!.alphabet,
      nextId: 0,
      type: widget.automaton!.type,
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedStates.length} estado(s) copiado(s)'),
        duration: const Duration(seconds: 2),
      ),
    );

    // TODO: Implement clipboard functionality for cross-app copying
  }

  void _editStateName(StateEntity state) {
    final controller = TextEditingController(text: state.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Nome do Estado'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nome do estado',
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
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != state.name) {
                _updateStateName(state, newName);
              }
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _updateStateName(StateEntity state, String newName) {
    if (widget.automaton == null || widget.onAutomatonChanged == null) return;

    // Check if name already exists
    final nameExists = widget.automaton!.states.any(
      (s) => s.id != state.id && s.name == newName,
    );

    if (nameExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome já existe. Escolha outro nome.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update state name
    final updatedStates = widget.automaton!.states.map((s) {
      if (s.id == state.id) {
        return s.copyWith(name: newName);
      }
      return s;
    }).toList();

    widget.onAutomatonChanged!(
      widget.automaton!.copyWith(states: updatedStates),
    );
  }

  void _addNewState() {
    if (widget.automaton == null || widget.onAutomatonChanged == null) return;

    // Generate unique state name
    int counter = 1;
    String newName = 'q$counter';
    while (widget.automaton!.states.any((s) => s.name == newName)) {
      counter++;
      newName = 'q$counter';
    }

    // Generate unique state ID
    String newId = 'state_$counter';
    while (widget.automaton!.states.any((s) => s.id == newId)) {
      counter++;
      newId = 'state_$counter';
    }

    // Add new state at center of canvas
    final newState = StateEntity(
      id: newId,
      name: newName,
      x: 200.0, // Center position
      y: 200.0,
      isInitial: widget.automaton!.states.isEmpty, // First state is initial
      isFinal: false,
    );

    final updatedStates = [...widget.automaton!.states, newState];
    widget.onAutomatonChanged!(
      widget.automaton!.copyWith(states: updatedStates),
    );

    // Select the new state
    setState(() {
      _clearSelectedStates();
      _selectedTransitions.clear();
      _updateSelectedStates({newState.id});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado $newName adicionado'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Connecting mode moved to AutomatonProvider

  void _startConnectStates() {
    final provider = Provider.of<AutomatonProvider>(context, listen: false);
    if (_selectedStates.isEmpty) {
      provider.startConnecting();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modo Transição: selecione origem e depois destino'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    if (_selectedStates.length > 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione no máximo 2 estados para conectar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    provider.startConnecting(fromStateId: _selectedStates.first);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modo Transição: selecione o estado de destino'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showTransitionSymbolDialog({
    required String fromStateId,
    required String toStateId,
  }) {
    final controller = TextEditingController();
    final isDfa = widget.automaton!.type == AutomatonType.dfa;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar Transição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('De: ${widget.automaton!.getState(fromStateId)?.name}'),
            Text('Para: ${widget.automaton!.getState(toStateId)?.name}'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: isDfa
                    ? 'Símbolo da transição'
                    : 'Símbolos (separados por vírgula)',
                border: const OutlineInputBorder(),
                hintText: isDfa ? 'Ex: a, b, 0, 1' : 'Ex: a,b,λ',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            if (!isDfa)
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final t = controller.text.trim();
                        controller.text = t.isEmpty ? 'λ' : '$t,λ';
                      },
                      child: const Text('λ'),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Provider.of<AutomatonProvider>(
                context,
                listen: false,
              ).finishConnecting();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              _addTransitionsFromText(fromStateId, toStateId, text);
              Provider.of<AutomatonProvider>(
                context,
                listen: false,
              ).finishConnecting();
              Navigator.pop(context);
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  void _addTransitionsFromText(
    String fromStateId,
    String toStateId,
    String symbolsText,
  ) {
    if (widget.automaton == null || widget.onAutomatonChanged == null) return;
    final isDfa = widget.automaton!.type == AutomatonType.dfa;
    final newTransitions = Map<String, List<String>>.from(
      widget.automaton!.transitions,
    );
    final symbols = symbolsText
        .split(RegExp(r'[;,]\s*|,\s*|\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (symbols.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe pelo menos um símbolo')),
      );
      return;
    }
    if (isDfa) {
      if (symbols.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AFDs não podem ter mais de um símbolo por transição',
            ),
          ),
        );
        return;
      }
      if (symbols.first == 'λ') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AFDs não permitem transições λ')),
        );
        return;
      }
    }

    for (final sym in symbols) {
      final key = '$fromStateId|$sym';
      if (newTransitions.containsKey(key)) {
        if (!newTransitions[key]!.contains(toStateId)) {
          newTransitions[key]!.add(toStateId);
        }
      } else {
        newTransitions[key] = [toStateId];
      }
    }

    widget.onAutomatonChanged!(
      widget.automaton!.copyWith(transitions: newTransitions),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          symbols.length == 1
              ? 'Transição ${symbols.first} adicionada'
              : 'Transições (${symbols.join(', ')}) adicionadas',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    Provider.of<AutomatonProvider>(context, listen: false).finishConnecting();
  }

  void _editTransition(String transitionKey) {
    final parts = transitionKey.split('|');
    if (parts.length == 2) {
      setState(() {
        _editingTransition = transitionKey;
        _transitionEditController.text = parts[1];
      });
      _transitionEditFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Consumer<AutomatonProvider>(
      builder: (context, provider, child) {
        // This will rebuild when the provider changes
        return _buildCanvasContent(isMobile);
      },
    );
  }

  Widget _buildCanvasContent(bool isMobile) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: widget.automaton == null
                    ? const Center(child: Text('Nenhum autômato carregado'))
                    : _buildInteractiveCanvas(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCanvas() {
    if (widget.automaton == null) return const SizedBox.shrink();

    final isMobile = MediaQuery.of(context).size.width < 768;

    return GestureDetector(
      onTapDown: _onTapDown,
      // Long press abre edição de estado/transição
      onLongPressStart: _onLongPressStart,
      onDoubleTap: null, // remover criação de novo estado por duplo toque
      onScaleStart: _onScaleStart,
      onScaleUpdate: _onScaleUpdate,
      onScaleEnd: _onScaleEnd,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: _onKeyPressed,
        child: Stack(
          children: [
            Transform(
              transform: Matrix4.identity()
                ..translate(_offset.dx, _offset.dy)
                ..scale(_scale),
              child: RepaintBoundary(
                key: widget.canvasKey,
                child: CustomPaint(
                  painter: AutomatonPainter(
                    widget.automaton!,
                    selectedStates: _selectedStates,
                    selectedTransitions: _selectedTransitions,
                    boxSelectStart: _boxSelectStart,
                    boxSelectEnd: _boxSelectEnd,
                    isBoxSelecting: _isBoxSelecting,
                  ),
                  child: Container(),
                ),
              ),
            ),
            if (_editingTransition != null) _buildTransitionEditOverlay(),
            if (isMobile) _buildMobileZoomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionEditOverlay() {
    if (_editingTransition == null) return const SizedBox.shrink();

    final parts = _editingTransition!.split('|');
    if (parts.length != 2) return const SizedBox.shrink();

    final fromStateId = parts[0];
    final symbol = parts[1];
    final fromState = widget.automaton!.getState(fromStateId);

    if (fromState == null) return const SizedBox.shrink();

    return Positioned(
      left: fromState.x - 50,
      top: fromState.y - 30,
      child: Container(
        width: 100,
        height: 30,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.blue),
          borderRadius: BorderRadius.circular(4),
        ),
        child: TextField(
          controller: _transitionEditController,
          focusNode: _transitionEditFocus,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          onSubmitted: (_) => _finishTransitionEdit(),
        ),
      ),
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousOffset = _offset;
    _isPanning = true;

    final localPosition = details.localFocalPoint;
    final canvasPos = _toCanvasSpace(localPosition);
    final hitState = _hitTestState(canvasPos);
    final hitTransition = _hitTestTransition(canvasPos);

    if (hitState != null) {
      if (!_selectedStates.contains(hitState.id)) {
        setState(() {
          _clearSelectedStates();
          _selectedTransitions.clear();
          _updateSelectedStates({hitState.id});
        });
      }
      _isDragging = false; // start drag only after threshold movement
      _canDragStates = true;
      _dragStart = localPosition;
      _dragStartCanvas = canvasPos;
      _dragOffsets = {};
      for (final stateId in _selectedStates) {
        final state = widget.automaton!.getState(stateId);
        if (state != null) {
          _dragOffsets[stateId] = Offset(
            canvasPos.dx - state.x,
            canvasPos.dy - state.y,
          );
        }
      }
    } else if (hitTransition != null) {
      setState(() {
        _clearSelectedStates();
        _selectedTransitions.clear();
        _selectedTransitions.add(hitTransition);
      });
      _canDragStates = false;
    } else {
      // Start canvas panning when clicking on empty area
      _isDragging = false;
      _canDragStates = false;
      _dragStart = localPosition;
      _dragStartCanvas = canvasPos;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      // Pinch to zoom
      _scale = (_previousScale * details.scale).clamp(0.5, 3.0);
    } else if (details.focalPointDelta != Offset.zero) {
      // Pan canvas or drag states
      // Activate dragging (for states) only after small movement
      if (_dragStart != null && !_isDragging && _canDragStates) {
        final moveDist = (details.localFocalPoint - _dragStart!).distance;
        if (moveDist > 4.0) {
          _isDragging = true;
        }
      }

      if (_isDragging && _dragStart != null) {
        // Move selected states
        final localPosition = details.localFocalPoint;
        final canvasPos = _toCanvasSpace(localPosition);

        if (widget.automaton != null && widget.onAutomatonChanged != null) {
          final newStates = widget.automaton!.states.map((state) {
            if (_selectedStates.contains(state.id)) {
              final off = _dragOffsets[state.id] ?? Offset.zero;
              return state.copyWith(
                x: canvasPos.dx - off.dx,
                y: canvasPos.dy - off.dy,
              );
            }
            return state;
          }).toList();

          widget.onAutomatonChanged!(
            widget.automaton!.copyWith(states: newStates),
          );
        }
      } else if (_isBoxSelecting) {
        // Update box selection
        setState(() {
          _boxSelectEnd = details.focalPoint;
        });
      } else if (_dragStart != null && !_isDragging) {
        // Pan canvas when dragging from empty area
        _offset = Offset(
          _offset.dx + details.focalPointDelta.dx,
          _offset.dy + details.focalPointDelta.dy,
        );
      }
    }
    setState(() {});
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _isPanning = false;

    if (_isBoxSelecting) {
      _finishBoxSelection();
    }

    setState(() {
      _isDragging = false;
      _dragStart = null;
      _dragOffsets = {};
      _canDragStates = false;
    });
  }

  void _onTapDown(TapDownDetails details) {
    final localPosition = details.localPosition;
    final canvasPos = _toCanvasSpace(localPosition);
    _lastTapPosition = canvasPos;
    final hitState = _hitTestState(canvasPos);
    final hitTransition = _hitTestTransition(canvasPos);

    if (hitState != null) {
      final provider = Provider.of<AutomatonProvider>(context, listen: false);
      if (provider.isConnectingStates) {
        if (provider.connectingFromState == null) {
          provider.setConnectingFromState(hitState.id);
          _updateSelectedStates({hitState.id});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agora selecione o estado de destino'),
            ),
          );
        } else {
          final fromId = provider.connectingFromState!;
          final toId = hitState.id;
          _updateSelectedStates({fromId, toId});
          _selectedTransitions.clear();
          _showTransitionSymbolDialog(fromStateId: fromId, toStateId: toId);
        }
      } else {
        setState(() {
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
          if (_selectedStates.contains(hitState.id)) {
            if (isShiftPressed) {
              _updateSelectedStates(
                _selectedStates.where((id) => id != hitState.id).toSet(),
              );
            }
          } else {
            if (isShiftPressed) {
              final newSelection = Set<String>.from(_selectedStates);
              newSelection.add(hitState.id);
              _updateSelectedStates(newSelection);
              _selectedTransitions.clear();
            } else {
              _clearSelectedStates();
              _selectedTransitions.clear();
              _updateSelectedStates({hitState.id});
            }
          }
        });
      }
    } else if (hitTransition != null) {
      setState(() {
        // Check if Shift key is pressed for multi-selection
        final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

        if (_selectedTransitions.contains(hitTransition)) {
          if (isShiftPressed) {
            // Remove from selection
            _selectedTransitions.remove(hitTransition);
          }
          // Don't edit transition on single click, only on double click
        } else {
          if (isShiftPressed) {
            // Add to selection
            _selectedTransitions.add(hitTransition);
            _clearSelectedStates();
          } else {
            // Single selection
            _clearSelectedStates();
            _selectedTransitions.clear();
            _selectedTransitions.add(hitTransition);
          }
        }
      });
    } else {
      // Tap on empty area clears selection
      setState(() {
        _clearSelectedStates();
        _selectedTransitions.clear();
      });
    }
  }

  void _onKeyPressed(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        _deleteSelected();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          _clearSelectedStates();
          _selectedTransitions.clear();
          _editingTransition = null;
        });
      }
    }
  }

  StateEntity? _hitTestState(Offset position) {
    if (widget.automaton == null) return null;

    for (final state in widget.automaton!.states) {
      final distance = (Offset(state.x, state.y) - position).distance;
      if (distance <= 30) {
        return state;
      }
    }
    return null;
  }

  String? _hitTestTransition(Offset position) {
    if (widget.automaton == null) return null;

    for (final entry in widget.automaton!.transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length == 2) {
        final fromStateId = parts[0];
        final symbol = parts[1];

        final fromState = widget.automaton!.getState(fromStateId);
        if (fromState != null) {
          for (final toStateId in entry.value) {
            final toState = widget.automaton!.getState(toStateId);
            if (toState != null) {
              if (_isPointNearLine(position, fromState, toState, symbol)) {
                return entry.key;
              }
            }
          }
        }
      }
    }
    return null;
  }

  void _onLongPress() {
    if (widget.automaton == null || _lastTapPosition == null) return;
    final p = _lastTapPosition!;
    final state = _hitTestState(p);
    if (state != null) {
      _editStateName(state);
      return;
    }
    final tKey = _hitTestTransition(p);
    if (tKey != null) {
      _showEditTransitionDialog(tKey);
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (widget.automaton == null) return;
    final local = details.localPosition;
    final canvasPoint = _toCanvasSpace(local);
    final state = _hitTestState(canvasPoint);
    if (state != null) {
      _editStateName(state);
      return;
    }
    final tKey = _hitTestTransition(canvasPoint);
    if (tKey != null) {
      _showEditTransitionDialog(tKey);
    }
  }

  void _showEditTransitionDialog(String transitionKey) {
    final parts = transitionKey.split('|');
    if (parts.length != 2 || widget.automaton == null) return;
    final fromId = parts[0];
    final oldSymbol = parts[1];
    final isDfa = widget.automaton!.type == AutomatonType.dfa;
    final controller = TextEditingController(text: oldSymbol);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Transição'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isDfa
                  ? 'AFD: apenas um símbolo por transição e sem λ'
                  : 'Vários símbolos separados por vírgula. Use λ para lambda',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: isDfa
                    ? 'Símbolo'
                    : 'Símbolos (separados por vírgula)',
                border: const OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            if (!isDfa) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        final t = controller.text.trim();
                        controller.text = t.isEmpty ? 'λ' : '$t,λ';
                      },
                      child: const Text('λ'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final text = controller.text.trim();
              _applyTransitionEdit(fromId, oldSymbol, text);
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void _applyTransitionEdit(
    String fromStateId,
    String oldSymbol,
    String symbolsText,
  ) {
    if (widget.automaton == null || widget.onAutomatonChanged == null) return;
    final isDfa = widget.automaton!.type == AutomatonType.dfa;
    final current = widget.automaton!;
    final oldKey = '$fromStateId|$oldSymbol';
    final destinations = List<String>.from(
      current.transitions[oldKey] ?? const [],
    );

    // Parse symbols
    final symList = symbolsText
        .split(RegExp(r'[;,]\s*|,\s*|\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (symList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe pelo menos um símbolo')),
      );
      return;
    }
    if (isDfa) {
      if (symList.length > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AFDs não podem ter mais de um símbolo por transição',
            ),
          ),
        );
        return;
      }
      if (symList.first == 'λ') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AFDs não permitem transições λ')),
        );
        return;
      }
    }

    final newTransitions = Map<String, List<String>>.from(current.transitions);
    // Remove old key
    newTransitions.remove(oldKey);
    // Add new keys (copy same destinations)
    for (final sym in symList) {
      final key = '$fromStateId|$sym';
      final list = List<String>.from(destinations);
      if (newTransitions.containsKey(key)) {
        final set = {...newTransitions[key]!, ...list};
        newTransitions[key] = set.toList();
      } else {
        newTransitions[key] = list;
      }
    }

    widget.onAutomatonChanged!(current.copyWith(transitions: newTransitions));
  }

  bool _isPointNearLine(
    Offset point,
    StateEntity from,
    StateEntity to,
    String symbol,
  ) {
    final fromCenter = Offset(from.x, from.y);
    final toCenter = Offset(to.x, to.y);

    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    // Handle self-loop selection: approximate by a ring around the state
    if (distance == 0) {
      const baseRadius = 40.0; // sync with _drawSelfLoop
      final d = (point - fromCenter).distance;
      return (d > baseRadius - 12 && d < baseRadius + 12);
    }

    final unitX = dx / distance;
    final unitY = dy / distance;

    final startX = fromCenter.dx + unitX * 30;
    final startY = fromCenter.dy + unitY * 30;
    final endX = toCenter.dx - unitX * 30;
    final endY = toCenter.dy - unitY * 30;

    final start = Offset(startX, startY);
    final end = Offset(endX, endY);

    // Calculate distance from point to line
    final lineLength = (end - start).distance;
    if (lineLength == 0) return false;

    final t =
        ((point.dx - start.dx) * (end.dx - start.dx) +
            (point.dy - start.dy) * (end.dy - start.dy)) /
        (lineLength * lineLength);

    final tClamped = t.clamp(0.0, 1.0);
    final closestPoint = Offset(
      start.dx + tClamped * (end.dx - start.dx),
      start.dy + tClamped * (end.dy - start.dy),
    );
    // Increase threshold for easier edge selection on touch
    const threshold = 16.0;
    return (point - closestPoint).distance <= threshold;
  }

  void _finishBoxSelection() {
    if (_boxSelectStart == null ||
        _boxSelectEnd == null ||
        widget.automaton == null)
      return;

    final rect = Rect.fromPoints(_boxSelectStart!, _boxSelectEnd!);
    final selectedStates = <String>{};

    for (final state in widget.automaton!.states) {
      if (rect.contains(Offset(state.x, state.y))) {
        selectedStates.add(state.id);
      }
    }

    setState(() {
      _clearSelectedStates();
      _selectedTransitions.clear();
      _updateSelectedStates(selectedStates);
    });
  }

  void _finishTransitionEdit() {
    if (_editingTransition == null ||
        widget.automaton == null ||
        widget.onAutomatonChanged == null)
      return;

    final parts = _editingTransition!.split('|');
    if (parts.length == 2) {
      final fromStateId = parts[0];
      final newSymbol = _transitionEditController.text.trim();

      if (newSymbol.isNotEmpty && newSymbol != parts[1]) {
        // Update transition symbol
        final newTransitions = Map<String, List<String>>.from(
          widget.automaton!.transitions,
        );
        final oldKey = _editingTransition!;
        final newKey = '$fromStateId|$newSymbol';

        if (newTransitions.containsKey(oldKey)) {
          final destinations = newTransitions[oldKey]!;
          newTransitions.remove(oldKey);
          newTransitions[newKey] = destinations;

          widget.onAutomatonChanged!(
            widget.automaton!.copyWith(transitions: newTransitions),
          );
        }
      }
    }

    setState(() {
      _editingTransition = null;
    });
  }

  void _deleteSelected() {
    if (widget.automaton == null || widget.onAutomatonChanged == null) return;

    if (_selectedStates.isNotEmpty) {
      // Delete selected states
      final newStates = widget.automaton!.states
          .where((state) => !_selectedStates.contains(state.id))
          .toList();

      final newTransitions = Map<String, List<String>>.from(
        widget.automaton!.transitions,
      );
      newTransitions.removeWhere((key, value) {
        final parts = key.split('|');
        return parts.length == 2 && _selectedStates.contains(parts[0]);
      });

      // Remove transitions to deleted states
      for (final key in newTransitions.keys.toList()) {
        newTransitions[key] = newTransitions[key]!
            .where((dest) => !_selectedStates.contains(dest))
            .toList();
        if (newTransitions[key]!.isEmpty) {
          newTransitions.remove(key);
        }
      }

      widget.onAutomatonChanged!(
        widget.automaton!.copyWith(
          states: newStates,
          transitions: newTransitions,
        ),
      );

      setState(() {
        _clearSelectedStates();
      });
    } else if (_selectedTransitions.isNotEmpty) {
      // Delete selected transitions
      final newTransitions = Map<String, List<String>>.from(
        widget.automaton!.transitions,
      );
      for (final transitionKey in _selectedTransitions) {
        newTransitions.remove(transitionKey);
      }

      widget.onAutomatonChanged!(
        widget.automaton!.copyWith(transitions: newTransitions),
      );

      setState(() {
        _selectedTransitions.clear();
      });
    }
  }
}

/// Custom painter for drawing automatons
class AutomatonPainter extends CustomPainter {
  final AutomatonEntity automaton;
  final Set<String> selectedStates;
  final Set<String> selectedTransitions;
  final Offset? boxSelectStart;
  final Offset? boxSelectEnd;
  final bool isBoxSelecting;

  AutomatonPainter(
    this.automaton, {
    this.selectedStates = const {},
    this.selectedTransitions = const {},
    this.boxSelectStart,
    this.boxSelectEnd,
    this.isBoxSelecting = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw box selection
    if (isBoxSelecting && boxSelectStart != null && boxSelectEnd != null) {
      final boxPaint = Paint()
        ..color = Colors.blue.withOpacity(0.2)
        ..style = PaintingStyle.fill;

      final boxStrokePaint = Paint()
        ..color = Colors.blue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final rect = Rect.fromPoints(boxSelectStart!, boxSelectEnd!);
      canvas.drawRect(rect, boxPaint);
      canvas.drawRect(rect, boxStrokePaint);
    }

    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = Colors.blue.shade100
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final selectedFillPaint = Paint()
      ..color = Colors.orange.shade100
      ..style = PaintingStyle.fill;

    // Draw states
    for (final state in automaton.states) {
      final center = Offset(state.x, state.y);
      final radius = 30.0;
      final isSelected = selectedStates.contains(state.id);

      // Draw state circle
      canvas.drawCircle(
        center,
        radius,
        isSelected ? selectedFillPaint : fillPaint,
      );
      canvas.drawCircle(center, radius, isSelected ? selectedPaint : paint);

      // Draw selection highlight
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.orange.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius + 5, highlightPaint);
      }

      // Draw state name
      final textPainter = TextPainter(
        text: TextSpan(
          text: state.name,
          style: TextStyle(
            color: isSelected ? Colors.orange.shade800 : Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );

      // Draw initial state arrow
      if (state.isInitial) {
        final arrowStart = Offset(center.dx - radius - 20, center.dy);
        final arrowEnd = Offset(center.dx - radius, center.dy);

        canvas.drawLine(
          arrowStart,
          arrowEnd,
          isSelected ? selectedPaint : paint,
        );

        // Draw arrowhead
        final arrowPath = Path();
        arrowPath.moveTo(arrowEnd.dx, arrowEnd.dy);
        arrowPath.lineTo(arrowEnd.dx - 8, arrowEnd.dy - 4);
        arrowPath.lineTo(arrowEnd.dx - 8, arrowEnd.dy + 4);
        arrowPath.close();

        canvas.drawPath(arrowPath, isSelected ? selectedFillPaint : fillPaint);
      }

      // Draw final state double circle
      if (state.isFinal) {
        canvas.drawCircle(
          center,
          radius - 5,
          isSelected ? selectedPaint : paint,
        );
      }
    }

    // Group transitions by state pairs for multiple edge support
    final transitionGroups = <String, List<MapEntry<String, List<String>>>>{};

    for (final entry in automaton.transitions.entries) {
      final parts = entry.key.split('|');
      if (parts.length == 2) {
        final fromStateId = parts[0];
        final symbol = parts[1];

        for (final toStateId in entry.value) {
          final groupKey = '$fromStateId->$toStateId';
          if (!transitionGroups.containsKey(groupKey)) {
            transitionGroups[groupKey] = [];
          }
          transitionGroups[groupKey]!.add(entry);
        }
      }
    }

    // Determine base offsets for bidirectional pairs (A->B vs B->A)
    final Map<String, double> baseOffsets = {};
    for (final key in transitionGroups.keys) {
      final parts = key.split('->');
      if (parts.length == 2) {
        final reverseKey = '${parts[1]}->${parts[0]}';
        if (transitionGroups.containsKey(reverseKey)) {
          // Assign opposite base offsets deterministically
          final sign = parts[0].compareTo(parts[1]) < 0 ? 1.0 : -1.0;
          baseOffsets[key] = 12.0 * sign; // half of edgeSpacing default
          // Use the SAME base offset sign for the reverse pair because
          // the perpendicular direction flips with reversed edge.
          baseOffsets[reverseKey] = 12.0 * sign;
        }
      }
    }

    // Draw transitions with support for multiple edges
    for (final groupEntry in transitionGroups.entries) {
      final groupKey = groupEntry.key;
      final transitions = groupEntry.value;

      final parts = groupKey.split('->');
      if (parts.length == 2) {
        final fromState = automaton.getState(parts[0]);
        final toState = automaton.getState(parts[1]);

        if (fromState != null && toState != null) {
          _drawMultipleTransitions(
            canvas,
            fromState,
            toState,
            transitions,
            selectedTransitions,
            paint,
            selectedPaint,
            baseOffsets[groupKey] ?? 0.0,
          );
        }
      }
    }
  }

  void _drawMultipleTransitions(
    Canvas canvas,
    StateEntity fromState,
    StateEntity toState,
    List<MapEntry<String, List<String>>> transitions,
    Set<String> selectedTransitions,
    Paint paint,
    Paint selectedPaint,
    double baseOffset,
  ) {
    final fromCenter = Offset(fromState.x, fromState.y);
    final toCenter = Offset(toState.x, toState.y);

    // Calculate base direction
    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance == 0) {
      // Self-loop case
      _drawSelfLoop(
        canvas,
        fromState,
        transitions,
        selectedTransitions,
        paint,
        selectedPaint,
      );
      return;
    }

    final unitX = dx / distance;
    final unitY = dy / distance;

    // Calculate perpendicular direction for multiple edges
    final perpX = -unitY;
    final perpY = unitX;

    final numEdges = transitions.length;
    final edgeSpacing = 24.0; // Distance between parallel edges
    final startOffset = -(numEdges - 1) * edgeSpacing / 2;

    for (int i = 0; i < transitions.length; i++) {
      final transition = transitions[i];
      final symbol = transition.key.split('|')[1];
      final isSelected = selectedTransitions.contains(transition.key);

      final offset = startOffset + i * edgeSpacing + baseOffset;
      final offsetX = offset * perpX;
      final offsetY = offset * perpY;

      _drawCurvedTransition(
        canvas,
        fromState,
        toState,
        symbol,
        isSelected ? selectedPaint : paint,
        isSelected,
        offsetX,
        offsetY,
      );
    }
  }

  void _drawCurvedTransition(
    Canvas canvas,
    StateEntity fromState,
    StateEntity toState,
    String symbol,
    Paint paint,
    bool isSelected,
    double offsetX,
    double offsetY,
  ) {
    final fromCenter = Offset(fromState.x, fromState.y);
    final toCenter = Offset(toState.x, toState.y);

    // Calculate transition line with offset
    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      final unitX = dx / distance;
      final unitY = dy / distance;

      final startX = fromCenter.dx + unitX * 30 + offsetX;
      final startY = fromCenter.dy + unitY * 30 + offsetY;
      final endX = toCenter.dx - unitX * 30 + offsetX;
      final endY = toCenter.dy - unitY * 30 + offsetY;

      final start = Offset(startX, startY);
      final end = Offset(endX, endY);

      // Create curved path for better visual separation
      final controlPoint1 = Offset(
        start.dx + (end.dx - start.dx) * 0.3 + offsetX * 0.5,
        start.dy + (end.dy - start.dy) * 0.3 + offsetY * 0.5,
      );
      final controlPoint2 = Offset(
        start.dx + (end.dx - start.dx) * 0.7 + offsetX * 0.5,
        start.dy + (end.dy - start.dy) * 0.7 + offsetY * 0.5,
      );

      final path = Path();
      path.moveTo(start.dx, start.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

      // Draw selection highlight for transition
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.orange.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;
        canvas.drawPath(path, highlightPaint);
      }

      // Draw transition curve
      canvas.drawPath(path, paint);

      // Draw arrowhead at the end
      final arrowDirection = math.atan2(
        end.dy - controlPoint2.dy,
        end.dx - controlPoint2.dx,
      );
      _drawArrowhead(canvas, end, arrowDirection, paint);

      // Draw symbol label
      final labelPoint = Offset(
        (start.dx + end.dx) / 2 + offsetX * 0.3,
        (start.dy + end.dy) / 2 + offsetY * 0.3,
      );
      _drawTransitionLabel(canvas, symbol, labelPoint, isSelected);
    }
  }

  void _drawSelfLoop(
    Canvas canvas,
    StateEntity state,
    List<MapEntry<String, List<String>>> transitions,
    Set<String> selectedTransitions,
    Paint paint,
    Paint selectedPaint,
  ) {
    final center = Offset(state.x, state.y);
    const stateRadius = 30.0; // must match node drawing
    const anchorAngleBase = -math.pi / 2; // top
    const anchorAngleStep = 0.20; // offset per loop
    const anchorSeparation = 0.55; // radians between start/end anchors
    const ctrlLenBase = 44.0; // how far the loop goes out
    const ctrlLenStep = 6.0; // extra per additional loop
    const lateralBase = 22.0; // how wide the loop arcs
    const lateralStep = 6.0;

    for (int i = 0; i < transitions.length; i++) {
      final transition = transitions[i];
      final symbol = transition.key.split('|')[1];
      final isSelected = selectedTransitions.contains(transition.key);

      final baseAngle = anchorAngleBase + (i - (transitions.length - 1) / 2) * anchorAngleStep;
      final startAnchorAngle = baseAngle - anchorSeparation / 2;
      final endAnchorAngle = baseAngle + anchorSeparation / 2;

      // Anchors on node border
      final anchorStart = Offset(
        center.dx + stateRadius * math.cos(startAnchorAngle),
        center.dy + stateRadius * math.sin(startAnchorAngle),
      );
      final anchorEnd = Offset(
        center.dx + stateRadius * math.cos(endAnchorAngle),
        center.dy + stateRadius * math.sin(endAnchorAngle),
      );

      // Outward and perpendicular vectors
      final outward = Offset(math.cos(baseAngle), math.sin(baseAngle));
      final perp = Offset(-outward.dy, outward.dx);

      // Control points tuned for a smooth, single-lobe loop
      final ctrlLen = ctrlLenBase + i * ctrlLenStep;
      final lateral = lateralBase + i * lateralStep;
      final c1 = anchorStart + outward * ctrlLen - perp * lateral;
      final c2 = anchorEnd + outward * ctrlLen + perp * lateral;

      final activePaint = isSelected ? selectedPaint : paint;

      final path = Path()
        ..moveTo(anchorStart.dx, anchorStart.dy)
        ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, anchorEnd.dx, anchorEnd.dy);

      // Highlight if selected
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.orange.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;
        canvas.drawPath(path, highlightPaint);
      }

      canvas.drawPath(path, activePaint);

      // Arrowhead aligned with end tangent
      final endDir = math.atan2(anchorEnd.dy - c2.dy, anchorEnd.dx - c2.dx);
      _drawArrowhead(canvas, anchorEnd, endDir, activePaint);

      // Label near the outer apex
      final apex = center + outward * (stateRadius + ctrlLen * 0.8);
      _drawTransitionLabel(canvas, symbol, apex - outward * 10, isSelected);
    }
  }

  void _drawArrowhead(Canvas canvas, Offset point, double angle, Paint paint) {
    final arrowPath = Path();
    final arrowSize = 8.0;

    arrowPath.moveTo(point.dx, point.dy);
    arrowPath.lineTo(
      point.dx - arrowSize * math.cos(angle - math.pi / 6),
      point.dy - arrowSize * math.sin(angle - math.pi / 6),
    );
    arrowPath.lineTo(
      point.dx - arrowSize * math.cos(angle + math.pi / 6),
      point.dy - arrowSize * math.sin(angle + math.pi / 6),
    );
    arrowPath.close();

    canvas.drawPath(arrowPath, paint);
  }

  void _drawTransitionLabel(
    Canvas canvas,
    String symbol,
    Offset point,
    bool isSelected,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol,
        style: TextStyle(
          color: isSelected ? Colors.orange.shade800 : Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background for better readability
    final backgroundPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final backgroundRect = Rect.fromCenter(
      center: point,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, const Radius.circular(4)),
      backgroundPaint,
    );

    textPainter.paint(
      canvas,
      Offset(
        point.dx - textPainter.width / 2,
        point.dy - textPainter.height / 2,
      ),
    );
  }

  void _drawTransition(
    Canvas canvas,
    StateEntity fromState,
    StateEntity toState,
    String symbol,
    Paint paint,
    bool isSelected,
  ) {
    final fromCenter = Offset(fromState.x, fromState.y);
    final toCenter = Offset(toState.x, toState.y);

    // Calculate transition line
    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    final distance = math.sqrt(dx * dx + dy * dy);

    if (distance > 0) {
      final unitX = dx / distance;
      final unitY = dy / distance;

      final startX = fromCenter.dx + unitX * 30;
      final startY = fromCenter.dy + unitY * 30;
      final endX = toCenter.dx - unitX * 30;
      final endY = toCenter.dy - unitY * 30;

      final start = Offset(startX, startY);
      final end = Offset(endX, endY);

      // Draw selection highlight for transition
      if (isSelected) {
        final highlightPaint = Paint()
          ..color = Colors.orange.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8;
        canvas.drawLine(start, end, highlightPaint);
      }

      // Draw transition line
      canvas.drawLine(start, end, paint);

      // Draw arrowhead
      final arrowPath = Path();
      arrowPath.moveTo(end.dx, end.dy);
      arrowPath.lineTo(
        end.dx - unitX * 10 + unitY * 5,
        end.dy - unitY * 10 - unitX * 5,
      );
      arrowPath.lineTo(
        end.dx - unitX * 10 - unitY * 5,
        end.dy - unitY * 10 + unitX * 5,
      );
      arrowPath.close();

      canvas.drawPath(
        arrowPath,
        Paint()
          ..style = PaintingStyle.fill
          ..color = paint.color,
      );

      // Draw symbol
      final midX = (startX + endX) / 2;
      final midY = (startY + endY) / 2;

      final textPainter = TextPainter(
        text: TextSpan(
          text: symbol,
          style: TextStyle(
            color: isSelected ? Colors.orange.shade800 : Colors.black,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(midX - textPainter.width / 2, midY - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // Repaint sempre que o automato, seleção ou caixa de seleção mudarem.
    // O operador == de AutomatonEntity compara apenas por id, então comparar
    // referencia/estado aqui pode falhar; preferimos garantir a atualização visual.
    return true;
  }
}
