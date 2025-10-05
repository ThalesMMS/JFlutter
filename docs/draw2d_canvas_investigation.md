# GraphView Canvas Notes

## Summary of Findings

- The FSA, TM, and PDA screens now share the GraphView-based `AutomatonCanvas`, eliminating the legacy Draw2D and native node-editor bridges while keeping the entire workflow inside Flutter.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L26-L178】【F:lib/presentation/widgets/pda_canvas_graphview.dart†L5-L126】【F:lib/presentation/widgets/tm_canvas_graphview.dart†L5-L134】
- `GraphViewCanvasController` registers undo/redo checkpoints, manages node/edge caches, and forwards interactions to `AutomatonProvider`, keeping Riverpod as the authoritative source of truth.【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L220】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L106-L214】
- Toolbar actions and gestures now call controller methods directly (`zoomIn`, `fitToContent`, `addStateAt`), so viewport status updates synchronously without asynchronous bridge handshakes.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L33-L138】【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L106-L186】

## Expected Behaviour

- Synchronisation flows from Riverpod into GraphView through snapshot rebuilds guarded by the base controller, preventing feedback loops while nodes and edges are replayed.【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L57-L166】
- User gestures must keep dispatching `addState`, `moveState`, `removeState`, and `addOrUpdateTransition` so that simulations and persistence remain accurate across editors.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L106-L214】【F:lib/presentation/providers/automaton_provider.dart†L25-L219】

## Practical Usage Tips

- Remind testers that zooming works with the toolbar or platform shortcuts—the controller debounces both paths to avoid camera jitter while maintaining undo snapshots.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L33-L138】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L107-L220】
- Encourage authors to tap empty space while the Add State tool is active; the controller converts the tap into world coordinates and assigns deterministic IDs/labels automatically.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L254-L303】
- During simulation walkthroughs, watch the highlight overlay rather than status labels; the notifier updates instantly and clears when `SimulationHighlightService.clear()` runs.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L41-L84】【F:lib/core/services/simulation_highlight_service.dart†L57-L101】

## Suggested Follow-Up Tasks

1. **Web platform affordances** – audit browser-specific shortcuts (copy/paste, undo) exposed by GraphView or Flutter and decide whether they should surface in the toolbar or remain hidden power-user features.
2. **Snapshot diffing** – evaluate whether partial patching is needed for future collaborative editing. `GraphViewAutomatonMapper.mergeIntoTemplate` can be extended with diff helpers if required.【F:lib/features/canvas/graphview/graphview_automaton_mapper.dart†L7-L130】
3. **Extended testing** – replace the deleted Draw2D and native node-editor suites with focused widget/controller tests that validate node creation, link wiring, undo/redo, and highlight dispatch for the GraphView integration.
