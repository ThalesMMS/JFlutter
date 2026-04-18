part of 'automaton_graphview_canvas.dart';

extension _AutomatonGraphViewCanvasInteractions
    on _AutomatonGraphViewCanvasState {
  Offset _screenToWorldExtracted(Offset localPosition) {
    final controller = _transformationController;
    if (controller == null) {
      return localPosition;
    }
    final matrix = Matrix4.copy(controller.value);
    final determinant = matrix.invert();
    if (determinant == 0) {
      return localPosition;
    }
    final vector = matrix.transform3(
      vmath.Vector3(localPosition.dx, localPosition.dy, 0),
    );
    return Offset(vector.x, vector.y);
  }

  GraphViewCanvasNode? _hitTestNodeExtracted(
    Offset localPosition, {
    bool logDetails = true,
  }) {
    final world = _screenToWorld(localPosition);
    GraphViewCanvasNode? closest;
    var closestDistance = double.infinity;
    for (final node in _controller.nodes) {
      final center = Offset(node.x + _kNodeRadius, node.y + _kNodeRadius);
      final dx = world.dx - center.dx;
      final dy = world.dy - center.dy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared <= _kNodeRadius * _kNodeRadius &&
          distanceSquared < closestDistance) {
        closest = node;
        closestDistance = distanceSquared;
      }
    }
    if (logDetails) {
      if (closest != null) {
        debugPrint(
          '[AutomatonGraphViewCanvas] Hit node ${closest.id} '
          '(tool=${_activeTool.name}) local=$localPosition world=$world',
        );
      } else if (_activeTool == AutomatonCanvasTool.transition) {
        debugPrint(
          '[AutomatonGraphViewCanvas] Transition tool miss '
          'local=$localPosition world=$world',
        );
      }
    }
    return closest;
  }

  Offset _globalToCanvasLocalExtracted(Offset globalPosition) {
    final renderBox =
        widget.canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return globalPosition;
    }
    return renderBox.globalToLocal(globalPosition);
  }

  void _logCanvasTapFromLocalExtracted({
    required String source,
    required Offset localPosition,
  }) {
    final node = _hitTestNode(localPosition, logDetails: false);
    final world = _screenToWorld(localPosition);
    final target = node?.id ?? 'canvas-background';
    debugPrint(
      '[AutomatonGraphViewCanvas] Tap source=$source target=$target '
      'tool=${_activeTool.name} local=$localPosition world=$world',
    );
  }

  void _logCanvasTapFromGlobalExtracted({
    required String source,
    required Offset globalPosition,
  }) {
    final local = _globalToCanvasLocal(globalPosition);
    _logCanvasTapFromLocal(source: source, localPosition: local);
  }

  void _handleCanvasTapDownExtracted(TapDownDetails details) {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    _logCanvasTapFromLocal(source: 'tap-down', localPosition: local);
  }

  void _beginNodeDragExtracted(GraphViewCanvasNode node, Offset localPosition) {
    debugPrint('[AutomatonGraphViewCanvas] Begin drag for ${node.id}');
    _hideTransitionOverlay();
    _draggingNodeId = node.id;
    _dragStartWorldPosition = _screenToWorld(localPosition);
    final current = _controller.nodeById(node.id) ?? node;
    _dragStartNodeCenter = Offset(current.x, current.y);
    _isDraggingNode = true;
    _didMoveDraggedNode = false;
  }

  void _updateNodeDragExtracted(Offset localPosition) {
    final nodeId = _draggingNodeId;
    final dragStartWorld = _dragStartWorldPosition;
    final dragStartNodeCenter = _dragStartNodeCenter;
    if (nodeId == null ||
        dragStartWorld == null ||
        dragStartNodeCenter == null) {
      return;
    }
    final currentWorld = _screenToWorld(localPosition);
    final delta = currentWorld - dragStartWorld;
    final nextPosition = dragStartNodeCenter + delta;
    _controller.moveState(nodeId, nextPosition);
    _didMoveDraggedNode = true;
  }

  void _endNodeDragExtracted() {
    _draggingNodeId = null;
    _dragStartWorldPosition = null;
    _dragStartNodeCenter = null;
    _setCanvasPanSuppressed(false, reason: 'drag ended');
    _isDraggingNode = false;
    _didMoveDraggedNode = false;
  }

  Future<void> _handleCanvasTapUpExtracted(TapUpDetails details) async {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    debugPrint(
      '[AutomatonGraphViewCanvas] Tap up with active tool ${_activeTool.name} '
      'local=$local',
    );
    final node = _hitTestNode(local, logDetails: false);

    if (_activeTool == AutomatonCanvasTool.addState) {
      if (_isDraggingNode || _didMoveDraggedNode || node != null) {
        return;
      }
      final world = _screenToWorld(local);
      _controller.addStateAt(world);
      return;
    }

    if (_activeTool == AutomatonCanvasTool.transition) {
      if (node != null) {
        _handleNodeTap(node.id);
      }
      return;
    }

    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }

    if (_isDraggingNode || _didMoveDraggedNode) {
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      return;
    }

    if (node == null) {
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      return;
    }

    _registerNodeTap(node.id);
  }

  void _handleNodePanStartExtracted(DragStartDetails details) {
    if (!_customization.enableStateDrag) {
      return;
    }
    final node = _hitTestNode(details.localPosition);
    if (node == null) {
      return;
    }
    debugPrint(
      '[AutomatonGraphViewCanvas] pan start gesture -> ${node.id} '
      'local=${details.localPosition}',
    );
    _setCanvasPanSuppressed(true, reason: 'node drag start ${node.id}');
    _beginNodeDrag(node, details.localPosition);
  }

  void _handleNodePanUpdateExtracted(DragUpdateDetails details) {
    debugPrint('[AutomatonGraphViewCanvas] pan update delta=${details.delta}');
    _updateNodeDrag(details.localPosition);
  }

  void _handleNodePanEndExtracted(DragEndDetails details) {
    final nodeId = _draggingNodeId;
    final didMove = _didMoveDraggedNode;
    debugPrint(
      '[AutomatonGraphViewCanvas] pan end velocity=${details.velocity}',
    );
    _endNodeDrag();
    if (!didMove &&
        nodeId != null &&
        _activeTool != AutomatonCanvasTool.transition) {
      _handleNodeTapFromPan(nodeId);
    }
  }

  void _handleNodePanCancelExtracted() {
    debugPrint('[AutomatonGraphViewCanvas] pan cancel');
    _endNodeDrag();
  }

  void _handleNodeTapExtracted(String nodeId) {
    debugPrint(
      '[AutomatonGraphViewCanvas] Node tapped $nodeId with '
      'active tool ${_activeTool.name}',
    );
    if (_activeTool != AutomatonCanvasTool.transition) {
      return;
    }

    if (_transitionSourceId == null) {
      debugPrint(
        '[AutomatonGraphViewCanvas] Transition source selected '
        '-> $nodeId',
      );
      setState(() {
        _transitionSourceId = nodeId;
      });
      return;
    }

    final sourceId = _transitionSourceId!;
    setState(() {
      _transitionSourceId = null;
    });
    debugPrint(
      '[AutomatonGraphViewCanvas] Transition target selected '
      '-> $nodeId (source: $sourceId)',
    );
    _showTransitionEditor(sourceId, nodeId);
  }

  void _handleNodeContextTapExtracted(String nodeId) {
    final node = _controller.nodeById(nodeId);
    if (node == null) {
      return;
    }
    debugPrint('[AutomatonGraphViewCanvas] opening state options for $nodeId');
    _showStateOptions(node);
  }

  void _handleNodeTapFromPanExtracted(String nodeId) {
    _registerNodeTap(nodeId);
  }

  void _registerNodeTapExtracted(String nodeId) {
    const doubleTapTimeout = Duration(milliseconds: 300);
    final now = _monotonicStopwatch.elapsed;
    if (_lastTapNodeId == nodeId &&
        _lastTapTimestamp != null &&
        now - _lastTapTimestamp! <= doubleTapTimeout) {
      debugPrint('[AutomatonGraphViewCanvas] Detected double tap on $nodeId');
      _handleNodeContextTap(nodeId);
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
    } else {
      _lastTapNodeId = nodeId;
      _lastTapTimestamp = now;
    }
  }

  Future<void> _showStateOptionsExtracted(GraphViewCanvasNode node) async {
    final labelController = TextEditingController(text: node.label);
    var isInitial = node.isInitial;
    var isAccepting = node.isAccepting;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    node.label.isEmpty ? node.id : node.label,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'State label'),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      final resolved = value.trim();
                      if (resolved != node.label) {
                        _controller.updateStateLabel(node.id, resolved);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: isInitial,
                    title: const Text('Initial state'),
                    onChanged: (value) {
                      setModalState(() => isInitial = value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    value: isAccepting,
                    title: const Text('Final state'),
                    onChanged: (value) {
                      setModalState(() => isAccepting = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      final resolved = labelController.text.trim();
                      if (resolved != node.label) {
                        _controller.updateStateLabel(node.id, resolved);
                      }
                      _controller.updateStateFlags(
                        node.id,
                        isInitial: isInitial,
                        isAccepting: isAccepting,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Save changes'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    labelController.dispose();
  }
}
