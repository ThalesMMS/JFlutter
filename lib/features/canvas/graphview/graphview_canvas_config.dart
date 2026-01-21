//
//  graphview_canvas_config.dart
//  JFlutter
//
//  Declara as configurações de customização do canvas GraphView, permitindo
//  diferentes tipos de autômatos (FSA, PDA, TM) especificarem como transições
//  devem ser editadas, renderizadas em overlays e persistidas no controlador.
//  Fornece factory methods para configurações comuns (FSA, PDA).
//
//  Thales Matheus Mendonça Santos - October 2025
//

import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../../features/canvas/graphview/graphview_label_field_editor.dart';
import '../../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../../../features/canvas/graphview/graphview_transition_models.dart';
import '../../../presentation/widgets/transition_editors/pda_transition_editor.dart';

/// Configuration describing how transitions are created, edited, and
/// persisted for a specific automaton type.
class AutomatonGraphViewTransitionConfig {
  const AutomatonGraphViewTransitionConfig({
    required this.initialPayloadBuilder,
    required this.overlayBuilder,
    required this.persistTransition,
  });

  final AutomatonTransitionPayload Function(GraphViewCanvasEdge? edge)
  initialPayloadBuilder;
  final AutomatonTransitionOverlayBuilder overlayBuilder;
  final void Function(AutomatonTransitionPersistRequest request)
  persistTransition;
}

/// Customisation options applied to the graph canvas behaviour.
class AutomatonGraphViewCanvasCustomization {
  const AutomatonGraphViewCanvasCustomization({
    required this.transitionConfigBuilder,
    this.enableStateDrag = true,
    this.enableToolSelection = true,
  });

  final AutomatonGraphViewTransitionConfig Function(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  )
  transitionConfigBuilder;

  final bool enableStateDrag;
  final bool enableToolSelection;

  factory AutomatonGraphViewCanvasCustomization.fsa() {
    return AutomatonGraphViewCanvasCustomization(
      transitionConfigBuilder: (controller) {
        return AutomatonGraphViewTransitionConfig(
          initialPayloadBuilder: (edge) =>
              AutomatonLabelTransitionPayload(edge?.label ?? ''),
          overlayBuilder: (context, data, overlayController) {
            final payload = data.payload as AutomatonLabelTransitionPayload;
            return GraphViewLabelFieldEditor(
              initialValue: payload.label,
              onSubmit: (value) => overlayController.submit(
                AutomatonLabelTransitionPayload(value),
              ),
              onCancel: overlayController.cancel,
            );
          },
          persistTransition: (request) {
            final payload = request.payload as AutomatonLabelTransitionPayload;
            final controller = request.controller as GraphViewCanvasController;
            controller.addOrUpdateTransition(
              fromStateId: request.fromStateId,
              toStateId: request.toStateId,
              label: payload.label,
              transitionId: request.transitionId,
              controlPointX: request.worldAnchor.dx,
              controlPointY: request.worldAnchor.dy,
            );
          },
        );
      },
    );
  }

  factory AutomatonGraphViewCanvasCustomization.pda() {
    return AutomatonGraphViewCanvasCustomization(
      enableToolSelection: true,
      transitionConfigBuilder: (controller) {
        return AutomatonGraphViewTransitionConfig(
          initialPayloadBuilder: (edge) {
            final read = edge?.readSymbol ?? '';
            final pop = edge?.popSymbol ?? '';
            final push = edge?.pushSymbol ?? '';
            return AutomatonPdaTransitionPayload(
              readSymbol: read,
              popSymbol: pop,
              pushSymbol: push,
              isLambdaInput: edge?.isLambdaInput ?? false,
              isLambdaPop: edge?.isLambdaPop ?? false,
              isLambdaPush: edge?.isLambdaPush ?? false,
            );
          },
          overlayBuilder: (context, data, overlayController) {
            final payload = data.payload as AutomatonPdaTransitionPayload;
            return PdaTransitionEditor(
              initialRead: payload.readSymbol,
              initialPop: payload.popSymbol,
              initialPush: payload.pushSymbol,
              isLambdaInput: payload.isLambdaInput,
              isLambdaPop: payload.isLambdaPop,
              isLambdaPush: payload.isLambdaPush,
              onSubmit:
                  ({
                    required String readSymbol,
                    required String popSymbol,
                    required String pushSymbol,
                    required bool lambdaInput,
                    required bool lambdaPop,
                    required bool lambdaPush,
                  }) {
                    overlayController.submit(
                      AutomatonPdaTransitionPayload(
                        readSymbol: readSymbol,
                        popSymbol: popSymbol,
                        pushSymbol: pushSymbol,
                        isLambdaInput: lambdaInput,
                        isLambdaPop: lambdaPop,
                        isLambdaPush: lambdaPush,
                      ),
                    );
                  },
              onCancel: overlayController.cancel,
            );
          },
          persistTransition: (request) {
            final payload = request.payload as AutomatonPdaTransitionPayload;
            final pdaController =
                request.controller as GraphViewPdaCanvasController;
            pdaController.addOrUpdateTransition(
              fromStateId: request.fromStateId,
              toStateId: request.toStateId,
              readSymbol: payload.readSymbol,
              popSymbol: payload.popSymbol,
              pushSymbol: payload.pushSymbol,
              isLambdaInput: payload.isLambdaInput,
              isLambdaPop: payload.isLambdaPop,
              isLambdaPush: payload.isLambdaPush,
              transitionId: request.transitionId,
              controlPointX: request.worldAnchor.dx,
              controlPointY: request.worldAnchor.dy,
            );
          },
        );
      },
    );
  }
}
