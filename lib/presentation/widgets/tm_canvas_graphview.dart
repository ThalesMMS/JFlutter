//
//  tm_canvas_graphview.dart
//  JFlutter
//
//  Widget que encapsula o canvas de Máquinas de Turing sobre a infraestrutura
//  compartilhada de automatos, delegando gestos, destaques e edições de
//  transições ao AutomatonGraphViewCanvas. A classe conecta o controlador
//  específico de TM aos provedores Riverpod, expõe ganchos para personalizar
//  ferramentas e habilita formulários inline para operações de fita.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_tm_canvas_controller.dart';
import '../providers/tm_editor_provider.dart';
import 'automaton_canvas_tool.dart';
import 'automaton_graphview_canvas.dart';
import 'transition_editors/tm_transition_operations_editor.dart';

class TMCanvasGraphView extends ConsumerStatefulWidget {
  const TMCanvasGraphView({
    super.key,
    required this.onTmModified,
    this.controller,
    this.toolController,
  });

  final ValueChanged<TM> onTmModified;
  final GraphViewTmCanvasController? controller;
  final AutomatonCanvasToolController? toolController;

  @override
  ConsumerState<TMCanvasGraphView> createState() => _TMCanvasGraphViewState();
}

class _TMCanvasGraphViewState extends ConsumerState<TMCanvasGraphView> {
  final GlobalKey _canvasKey = GlobalKey();
  late GraphViewTmCanvasController _controller;
  late bool _ownsController;
  SimulationHighlightService? _highlightService;
  SimulationHighlightChannel? _previousHighlightChannel;
  GraphViewSimulationHighlightChannel? _highlightChannel;
  ProviderSubscription<TMEditorState>? _subscription;
  TM? _lastDeliveredTm;

  AutomatonGraphViewCanvasCustomization get _customization =>
      AutomatonGraphViewCanvasCustomization(
        enableStateDrag: true,
        enableToolSelection: true,
        transitionConfigBuilder: (controller) {
          return AutomatonGraphViewTransitionConfig(
            initialPayloadBuilder: (edge) => AutomatonTmTransitionPayload(
              readSymbol: edge?.readSymbol ?? '',
              writeSymbol: edge?.writeSymbol ?? '',
              direction: edge?.direction ?? TapeDirection.right,
            ),
            overlayBuilder: (context, data, overlayController) {
              final payload =
                  data.payload as AutomatonTmTransitionPayload;
              return TmTransitionOperationsEditor(
                initialRead: payload.readSymbol,
                initialWrite: payload.writeSymbol,
                initialDirection: payload.direction,
                onSubmit: ({
                  required String readSymbol,
                  required String writeSymbol,
                  required TapeDirection direction,
                }) {
                  overlayController.submit(
                    AutomatonTmTransitionPayload(
                      readSymbol: readSymbol,
                      writeSymbol: writeSymbol,
                      direction: direction,
                    ),
                  );
                },
                onCancel: overlayController.cancel,
              );
            },
            persistTransition: (request) {
              final tmController =
                  request.controller as GraphViewTmCanvasController;
              final payload =
                  request.payload as AutomatonTmTransitionPayload;
              tmController.addOrUpdateTransition(
                fromStateId: request.fromStateId,
                toStateId: request.toStateId,
                readSymbol: payload.readSymbol,
                writeSymbol: payload.writeSymbol,
                direction: payload.direction,
                transitionId: request.transitionId,
                controlPointX: request.worldAnchor.dx,
                controlPointY: request.worldAnchor.dy,
              );
            },
          );
        },
      );

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
    } else {
      _controller = GraphViewTmCanvasController(
        editorNotifier: ref.read(tmEditorProvider.notifier),
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

    final initialState = ref.read(tmEditorProvider);
    _controller.synchronize(initialState.tm);
    if (initialState.tm?.states.isNotEmpty ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.fitToContent();
      });
    }

    _lastDeliveredTm = initialState.tm;
    if (initialState.tm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onTmModified(initialState.tm!);
      });
    }

    _subscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (previous, next) {
        if (!mounted) return;
        final tm = next.tm;
        if (tm != null && !identical(tm, _lastDeliveredTm)) {
          _lastDeliveredTm = tm;
          widget.onTmModified(tm);
        } else if (tm == null) {
          _lastDeliveredTm = null;
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
    final state = ref.watch(tmEditorProvider);
    return AutomatonGraphViewCanvas(
      automaton: state.tm,
      canvasKey: _canvasKey,
      controller: _controller,
      toolController: widget.toolController,
      customization: _customization,
    );
  }
}
