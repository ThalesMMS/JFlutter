# fl_nodes Canvas Architecture

The Draw2D bridge has been removed in favour of a fully native canvas powered
by [`fl_nodes`](https://pub.dev/packages/fl_nodes). The Flutter widget tree
embeds a [`FlNodeEditorWidget`](https://pub.dev/documentation/fl_nodes/latest/fl_nodes/FlNodeEditorWidget-class.html)
managed by `FlNodesCanvasController`, which keeps the visual editor and the
Riverpod state (`AutomatonProvider`) perfectly aligned.

## Rendering Pipeline

* `AutomatonCanvas` owns a [`FlNodesCanvasController`](../lib/presentation/widgets/automaton_canvas_native.dart)
  and synchronises it with the active `FSA` whenever the provider emits a new
  automaton. The controller instantiates a `FlNodeEditorController`, registers
  the node prototype used to represent automaton states, and exposes a
  `ValueNotifier` with the current highlight payload.【F:lib/presentation/widgets/automaton_canvas_native.dart†L13-L92】【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L14-L88】
* The controller converts Riverpod data into `FlNodesAutomatonSnapshot`
  instances through `FlNodesAutomatonMapper.toSnapshot`. Each state becomes a
  `FlNodesCanvasNode` and each transition becomes a `FlNodesCanvasEdge`,
  preserving metadata such as control points and accepting flags.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L96-L166】【F:lib/features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart†L8-L59】
* Snapshot data is replayed into the editor by creating concrete `NodeInstance`
  and `Link` objects. During this phase the controller temporarily marks itself
  as synchronising so that the inbound event listener ignores the synthetic
  add/remove notifications fired by fl_nodes while the canvas is rebuilt.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L168-L234】

## Editing Flow

`FlNodesCanvasController` listens to the editor `eventBus` and forwards user
edits back to `AutomatonProvider`:

* `AddNodeEvent`, `RemoveNodeEvent`, and `DragSelectionEndEvent` translate into
  `addState`, `removeState`, and `moveState` calls, keeping coordinates and
  labels aligned with the automaton model.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L236-L302】【F:lib/presentation/providers/automaton_provider.dart†L83-L166】
* Node label edits invoke `updateStateLabel`, normalising blank labels to the
  node identifier so existing transitions remain consistent.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L304-L327】【F:lib/presentation/providers/automaton_provider.dart†L168-L214】
* Link creation and deletion map to `addOrUpdateTransition` and
  `removeTransition`, ensuring the Riverpod graph stays in sync with the visual
  wiring.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L329-L355】【F:lib/presentation/providers/automaton_provider.dart†L216-L260】

Toolbar buttons (zoom, fit, reset, add state) now call directly into the
controller instead of posting JavaScript messages. This keeps the ergonomics of
the previous bridge while avoiding WebView plumbing.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L48-L133】

## Highlight Channel

Simulation playback relies on `SimulationHighlightService`, which now dispatches
highlights through the `FlNodesHighlightController` interface implemented by the
canvas controller. The notifier exposed by the controller drives visual overlays
and remains compatible with existing Riverpod listeners.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L36-L45】【F:lib/core/services/simulation_highlight_service.dart†L6-L74】

## Data Round-Tripping

When the editor needs to persist changes (for example, after receiving a patch
from collaborative tooling) it converts the latest snapshot back into a new
`FSA` via `FlNodesAutomatonMapper.mergeIntoTemplate`. The mapper rebuilds
states, transitions, and alphabet entries using the template as a base, so
existing metadata such as simulation history remains intact.【F:lib/features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart†L61-L108】

By keeping all synchronisation logic inside `FlNodesCanvasController`, the app
no longer depends on HTML assets or platform-specific bridges, drastically
simplifying deployment and reducing the sources of runtime failure.
