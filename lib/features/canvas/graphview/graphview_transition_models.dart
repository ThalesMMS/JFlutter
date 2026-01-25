//
//  graphview_transition_models.dart
//  JFlutter
//
//  Declara os modelos imutáveis para payloads de transição, dados de overlay e
//  controladores utilizados durante o fluxo de edição de transições no canvas
//  GraphView. Estas estruturas permitem que diferentes tipos de autômatos (FSA,
//  PDA, TM) descrevam suas transições de forma type-safe e sejam renderizados
//  com overlays customizados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/widgets.dart';

import '../../../core/models/tm_transition.dart' show TapeDirection;
import '../../canvas/graphview/base_graphview_canvas_controller.dart';
import '../../canvas/graphview/graphview_canvas_models.dart';

typedef AutomatonTransitionOverlayBuilder =
    Widget Function(
      BuildContext context,
      AutomatonTransitionOverlayData data,
      AutomatonTransitionOverlayController controller,
    );

/// Payload used by the transition overlay to communicate user edits back to
/// the canvas.
sealed class AutomatonTransitionPayload {
  const AutomatonTransitionPayload();
}

/// Simple payload representing a raw transition label.
class AutomatonLabelTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonLabelTransitionPayload(this.label);

  final String label;
}

/// Payload describing TM tape operations (read/write/direction).
class AutomatonTmTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonTmTransitionPayload({
    required this.readSymbol,
    required this.writeSymbol,
    required this.direction,
  });

  final String readSymbol;
  final String writeSymbol;
  final TapeDirection direction;
}

/// Payload describing PDA stack operations (read/pop/push and λ flags).
class AutomatonPdaTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonPdaTransitionPayload({
    required this.readSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
  });

  final String readSymbol;
  final String popSymbol;
  final String pushSymbol;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;
}

/// Immutable description of the current transition overlay request.
class AutomatonTransitionOverlayData {
  const AutomatonTransitionOverlayData({
    required this.fromStateId,
    required this.toStateId,
    required this.worldAnchor,
    required this.payload,
    this.transitionId,
    this.edge,
  });

  final String fromStateId;
  final String toStateId;
  final Offset worldAnchor;
  final AutomatonTransitionPayload payload;
  final String? transitionId;
  final GraphViewCanvasEdge? edge;

  AutomatonTransitionOverlayData copyWith({
    AutomatonTransitionPayload? payload,
    Offset? worldAnchor,
    String? transitionId,
    GraphViewCanvasEdge? edge,
  }) {
    return AutomatonTransitionOverlayData(
      fromStateId: fromStateId,
      toStateId: toStateId,
      worldAnchor: worldAnchor ?? this.worldAnchor,
      payload: payload ?? this.payload,
      transitionId: transitionId ?? this.transitionId,
      edge: edge ?? this.edge,
    );
  }
}

/// Controller exposed to the overlay widget allowing it to submit or cancel
/// the edit flow.
class AutomatonTransitionOverlayController {
  AutomatonTransitionOverlayController({
    required this.onSubmit,
    required this.onCancel,
  });

  final void Function(AutomatonTransitionPayload payload) onSubmit;
  final VoidCallback onCancel;

  void submit(AutomatonTransitionPayload payload) => onSubmit(payload);
  void cancel() => onCancel();
}

/// Request emitted when the transition overlay is submitted.
class AutomatonTransitionPersistRequest {
  const AutomatonTransitionPersistRequest({
    required this.fromStateId,
    required this.toStateId,
    required this.payload,
    required this.worldAnchor,
    required this.controller,
    this.transitionId,
  });

  final String fromStateId;
  final String toStateId;
  final String? transitionId;
  final AutomatonTransitionPayload payload;
  final Offset worldAnchor;
  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
}
