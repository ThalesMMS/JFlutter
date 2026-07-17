part of 'automaton_graphview_canvas.dart';

void _logAutomatonGraphViewCanvasInteraction(String message) {
  if (kDebugMode) {
    debugPrint('[AutomatonGraphViewCanvas] $message');
  }
}

extension _AutomatonGraphViewCanvasInteractions
    on _AutomatonGraphViewCanvasState {
  Offset _screenToWorldExtracted(Offset localPosition) {
    return _controller.toWorldOffset(localPosition);
  }

  GraphViewCanvasNode? _hitTestNodeExtracted(
    Offset localPosition, {
    bool logDetails = true,
  }) {
    // Keep hit testing in world coordinates so it remains stable under zoom.
    final world = _screenToWorld(localPosition);

    // A small hit slop keeps slow-start drags and near-edge touches anchored to
    // the intended node instead of falling through to the canvas pan gesture.
    const dragHitSlop = 8.0;
    const hitRadius = _kNodeRadius + dragHitSlop;
    const hitRadiusSquared = hitRadius * hitRadius;

    GraphViewCanvasNode? closest;
    var closestDistanceSquared = double.infinity;
    var candidateCount = 0;

    // PERF: avoid per-node sqrt by staying in squared distance space.
    // Timeline events are assert-only, so there is zero overhead in release.
    assert(() {
      Timeline.startSync('GraphViewCanvas.hitTestNode');
      return true;
    }());
    var iterations = 0;
    try {
      for (final node in _controller.nodes) {
        iterations++;

        // Coarse early-out: skip nodes whose bounding box cannot intersect the
        // circular hit area.
        final left = node.x;
        final top = node.y;
        final right = left + _kNodeRadius * 2;
        final bottom = top + _kNodeRadius * 2;
        if (world.dx < left - hitRadius ||
            world.dx > right + hitRadius ||
            world.dy < top - hitRadius ||
            world.dy > bottom + hitRadius) {
          continue;
        }

        candidateCount++;
        final center = Offset(left + _kNodeRadius, top + _kNodeRadius);
        final dx = world.dx - center.dx;
        final dy = world.dy - center.dy;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared <= hitRadiusSquared &&
            distanceSquared < closestDistanceSquared) {
          closest = node;
          closestDistanceSquared = distanceSquared;
        }
      }
    } finally {
      assert(() {
        Timeline.finishSync();
        return true;
      }());
    }

    assert(() {
      Timeline.instantSync(
        'GraphViewCanvas.hitTestNode.result',
        arguments: {
          'iterations': iterations,
          'candidates': candidateCount,
          'hit': closest != null,
          'tool': _activeTool.name,
        },
      );
      return true;
    }());

    if (logDetails) {
      if (closest != null) {
        _logAutomatonGraphViewCanvasInteraction(
          'Hit node ${closest.id} '
          '(tool=${_activeTool.name}) local=$localPosition world=$world '
          'candidates=$candidateCount',
        );
      } else if (_activeTool == AutomatonCanvasTool.transition) {
        _logAutomatonGraphViewCanvasInteraction(
          'Transition tool miss local=$localPosition world=$world '
          'candidates=$candidateCount',
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
    _logAutomatonGraphViewCanvasInteraction(
      'Tap source=$source target=$target '
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
    _logAutomatonGraphViewCanvasInteraction('Begin drag for ${node.id}');
    _hideTransitionOverlay();
    _draggingNodeId = node.id;
    _dragStartWorldPosition = _screenToWorld(localPosition);
    final current = _controller.nodeById(node.id) ?? node;
    _dragStartNodePosition = Offset(current.x, current.y);
    _dragCurrentNodePosition = _dragStartNodePosition;
    _isDraggingNode = true;
    _didMoveDraggedNode = false;
  }

  void _updateNodeDragExtracted(Offset localPosition) {
    final nodeId = _draggingNodeId;
    final dragStartWorld = _dragStartWorldPosition;
    final dragStartNodePosition = _dragStartNodePosition;
    if (nodeId == null ||
        dragStartWorld == null ||
        dragStartNodePosition == null) {
      return;
    }
    final currentWorld = _screenToWorld(localPosition);
    final delta = currentWorld - dragStartWorld;
    final nextPosition = dragStartNodePosition + delta;
    _controller.previewStatePosition(nodeId, nextPosition);
    _dragCurrentNodePosition = nextPosition;
    _didMoveDraggedNode = true;
  }

  void _endNodeDragExtracted() {
    _draggingNodeId = null;
    _dragStartWorldPosition = null;
    _dragStartNodePosition = null;
    _dragCurrentNodePosition = null;
    _setCanvasPanSuppressed(false, reason: 'drag ended');
    _isDraggingNode = false;
    _didMoveDraggedNode = false;
  }

  Future<void> _handleCanvasTapUpExtracted(TapUpDetails details) async {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    _logAutomatonGraphViewCanvasInteraction(
      'Tap up with active tool ${_activeTool.name} local=$local',
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
    _logAutomatonGraphViewCanvasInteraction(
      'pan start gesture -> ${node.id} '
      'local=${details.localPosition}',
    );
    _setCanvasPanSuppressed(true, reason: 'node drag start ${node.id}');
    _beginNodeDrag(node, details.localPosition);
  }

  void _handleNodePanUpdateExtracted(DragUpdateDetails details) {
    _logAutomatonGraphViewCanvasInteraction(
      'pan update delta=${details.delta}',
    );
    _updateNodeDrag(details.localPosition);
  }

  void _handleNodePanEndExtracted(DragEndDetails details) {
    final nodeId = _draggingNodeId;
    final didMove = _didMoveDraggedNode;
    final finalPosition = _dragCurrentNodePosition;
    _logAutomatonGraphViewCanvasInteraction(
      'pan end velocity=${details.velocity}',
    );
    _endNodeDrag();
    if (didMove && nodeId != null && finalPosition != null) {
      _controller.moveState(nodeId, finalPosition);
      return;
    }
    if (!didMove &&
        nodeId != null &&
        _activeTool != AutomatonCanvasTool.transition) {
      _handleNodeTapFromPan(nodeId);
    }
  }

  void _handleNodePanCancelExtracted() {
    _logAutomatonGraphViewCanvasInteraction('pan cancel');
    final nodeId = _draggingNodeId;
    final startPosition = _dragStartNodePosition;
    if (nodeId != null && startPosition != null) {
      _controller.previewStatePosition(nodeId, startPosition);
    }
    _endNodeDrag();
  }

  void _handleNodeTapExtracted(String nodeId) {
    _logAutomatonGraphViewCanvasInteraction(
      'Node tapped $nodeId with active tool ${_activeTool.name}',
    );
    if (_activeTool != AutomatonCanvasTool.transition) {
      return;
    }

    if (_transitionSourceId == null) {
      _logAutomatonGraphViewCanvasInteraction(
        'Transition source selected -> $nodeId',
      );
      _setTransitionSourceId(nodeId);
      return;
    }

    final sourceId = _transitionSourceId!;
    _setTransitionSourceId(null);
    _logAutomatonGraphViewCanvasInteraction(
      'Transition target selected -> $nodeId (source: $sourceId)',
    );
    _showTransitionEditor(sourceId, nodeId);
  }

  void _handleNodeContextTapExtracted(String nodeId) {
    final node = _controller.nodeById(nodeId);
    if (node == null) {
      return;
    }
    _logAutomatonGraphViewCanvasInteraction(
      'opening state options for $nodeId',
    );
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
      _logAutomatonGraphViewCanvasInteraction(
        'Detected double tap on $nodeId',
      );
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
