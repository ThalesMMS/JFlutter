# fl_nodes Canvas Migration Checklist

This document tracks the behaviours that replaced the legacy Draw2D bridge and
should be preserved as we continue evolving the Flutter-native canvas.

## Behavioural Parity Requirements

### `lib/presentation/widgets/automaton_canvas_native.dart`

* The canvas embeds a `FlNodeEditorWidget` and wires it to the
  `FlNodesCanvasController`, keeping Riverpod state authoritative. Theme changes
  update the editor style dynamically, so the widget must continue applying the
  surface and grid colours derived from the current `ColorScheme`.【F:lib/presentation/widgets/automaton_canvas_native.dart†L13-L156】
* Simulation highlights flow through the controller notifier. Any new features
  must keep forwarding highlight changes to avoid regressing the playback UI.

### `lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart`

* The controller registers the automaton node prototype, exposes viewport
  helpers (`zoomIn`, `fitToContent`, etc.), and synchronises Riverpod models with
  the visual editor via snapshots. Changes to the editor API must retain these
  helpers so the toolbar keeps working.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L48-L133】【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L96-L166】
* Event handlers convert `fl_nodes` events into provider mutations. When adding
  new gestures ensure `_isSynchronizing` still prevents feedback loops and that
  every mutation is mirrored in `AutomatonProvider`.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L236-L355】

### `lib/features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart`

* The mapper remains the single source of truth for serialising and rebuilding
  automata. Extending the automaton model (e.g., new metadata) requires updating
  both `toSnapshot` and `mergeIntoTemplate` so persistent data and controller
  snapshots stay compatible.【F:lib/features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart†L12-L108】

## Dependencies & Assets

* The Flutter canvas no longer depends on HTML assets. Keep `pubspec.yaml`
  aligned with the remaining JSON examples and `fl_nodes` package updates only.
* Highlight integrations go through `FlNodesHighlightController`; when adding
  new highlight destinations update `SimulationHighlightService` rather than
  reintroducing global messengers.【F:lib/core/services/simulation_highlight_service.dart†L6-L74】

## Risks & Open Questions

* Lacking automated tests for the canvas controller leaves a gap compared with
  the deleted Draw2D bridge tests. Prioritise widget/controller suites to cover
  node creation, link edits, and highlight propagation.
* Clipboard and keyboard shortcuts differ per platform in fl_nodes; review
  accessibility expectations on mobile versus desktop before enabling advanced
  gestures globally.
