# GraphView Canvas Migration Checklist

This checklist tracks the behaviours that replaced the legacy Draw2D and native node-editor bridges and should be preserved while iterating on the GraphView canvas.

## Behavioural Parity Requirements

### `lib/presentation/widgets/automaton_graphview_canvas.dart`

* The canvas embeds `GraphView.builder`, connects highlight channels, and mirrors Riverpod state through the shared controller. Theme updates must continue flowing through widget rebuilds so node and edge styles stay aligned with the active `ColorScheme`.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L26-L236】
* Simulation highlights flow through the controller notifier; new features must keep forwarding highlight payloads to avoid regressing playback or overlays.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L41-L84】

### `lib/features/canvas/graphview/graphview_canvas_controller.dart`

* The controller registers node/edge caches, exposes viewport helpers (`zoomIn`, `fitToContent`, etc.), and synchronises Riverpod models with the GraphView graph via snapshots. Changes to GraphView APIs should preserve these helpers so toolbars and gestures remain functional.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L38-L186】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L220】
* Event handlers convert canvas interactions into provider mutations. When adding new gestures ensure snapshot guards still prevent feedback loops and that every mutation mirrors `AutomatonProvider`.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L106-L214】【F:lib/presentation/providers/automaton_provider.dart†L25-L219】

### `lib/features/canvas/graphview/graphview_automaton_mapper.dart`

* The mapper remains the single source of truth for serialising and rebuilding automatons. Extending the automaton model (e.g., new metadata) requires updating `toSnapshot` and `mergeIntoTemplate` so persistent data and controller snapshots stay compatible.【F:lib/features/canvas/graphview/graphview_automaton_mapper.dart†L7-L130】

## Dependencies & Assets

* The Flutter canvas is now self-contained—keep `pubspec.yaml` aligned with GraphView and the bundled JSON examples only.【F:pubspec.yaml†L53-L98】
* Highlight integrations go through `GraphViewSimulationHighlightChannel`; when adding new highlight destinations update `SimulationHighlightService` rather than reintroducing global messengers.【F:lib/features/canvas/graphview/graphview_highlight_channel.dart†L5-L19】【F:lib/core/services/simulation_highlight_service.dart†L8-L101】

## Risks & Open Questions

* Lacking automated tests for the canvas controller leaves a gap compared with the deleted Draw2D/native node-editor suites—prioritise widget/controller tests covering node creation, link edits, undo/redo, and highlight propagation.
* GraphView exposes fewer built-in gestures than the previous node-editor; evaluate accessibility expectations on mobile versus desktop before enabling advanced shortcuts globally.
