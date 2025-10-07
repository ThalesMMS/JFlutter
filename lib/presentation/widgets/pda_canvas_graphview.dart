//
//  pda_canvas_graphview.dart
//  JFlutter
//
//  Implementa o canvas especializado de PDA sobre a infraestrutura GraphView compartilhada, sincronizando provedores e destaques. Controla ciclo de vida do controlador, integra canal de highlight e emite callbacks sempre que o autômato é alterado.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../providers/pda_editor_provider.dart';
import 'automaton_canvas_tool.dart';
import 'automaton_graphview_canvas.dart';

class PDACanvasGraphView extends ConsumerStatefulWidget {
  const PDACanvasGraphView({
    super.key,
    required this.onPdaModified,
    this.controller,
    this.toolController,
  });

  final ValueChanged<PDA> onPdaModified;
  final GraphViewPdaCanvasController? controller;
  final AutomatonCanvasToolController? toolController;

  @override
  ConsumerState<PDACanvasGraphView> createState() => _PDACanvasGraphViewState();
}

class _PDACanvasGraphViewState extends ConsumerState<PDACanvasGraphView> {
  final GlobalKey _canvasKey = GlobalKey();
  late GraphViewPdaCanvasController _controller;
  late bool _ownsController;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  GraphViewSimulationHighlightChannel? _highlightChannel;
  ProviderSubscription<PDAEditorState>? _subscription;
  PDA? _lastDeliveredPda;

  AutomatonGraphViewCanvasCustomization get _customization =>
      AutomatonGraphViewCanvasCustomization.pda();

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
    } else {
      _controller = GraphViewPdaCanvasController(
        editorNotifier: ref.read(pdaEditorProvider.notifier),
      );
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(
        _controller,
      );
      _highlightChannel = highlightChannel;
      highlightService.channel = highlightChannel;
    }

    final initialState = ref.read(pdaEditorProvider);
    _controller.synchronize(initialState.pda);
    if (initialState.pda?.states.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.fitToContent();
      });
    }

    _lastDeliveredPda = initialState.pda;
    if (initialState.pda != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPdaModified(initialState.pda!);
      });
    }

    _subscription = ref.listenManual<PDAEditorState>(
      pdaEditorProvider,
      (previous, next) {
        if (!mounted) return;
        final pda = next.pda;
        if (pda != null && !identical(pda, _lastDeliveredPda)) {
          _lastDeliveredPda = pda;
          widget.onPdaModified(pda);
        } else if (pda == null) {
          _lastDeliveredPda = null;
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    if (_ownsController) {
      _controller.dispose();
    }
    if (_highlightService != null) {
      _highlightService!.channel = _previousHighlightChannel;
      _highlightChannel = null;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(pdaEditorProvider);
    return AutomatonGraphViewCanvas(
      automaton: editorState.pda,
      canvasKey: _canvasKey,
      controller: _controller,
      toolController: widget.toolController,
      customization: _customization,
    );
  }
}
