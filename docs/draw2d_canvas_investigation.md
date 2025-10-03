# fl_nodes Canvas Notes

## Summary of Findings

- The FSA, TM, and PDA screens now share the same Flutter-based canvas thanks to
  `AutomatonCanvas`, eliminating the WebView/iframe divergence that previously
  plagued the Draw2D integration.【F:lib/presentation/widgets/automaton_canvas_native.dart†L13-L156】
- `FlNodesCanvasController` registers the node prototype and listens to the
  editor `eventBus` so that additions, removals, drags, and label edits feed
  directly into `AutomatonProvider`. This keeps Riverpod state authoritative
  without relying on JavaScript bridges.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L20-L45】【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L236-L327】
- Toolbar actions now call the controller methods (`zoomIn`, `fitToContent`,
  `addStateAtCenter`, etc.), so the status label can always reflect the canvas
  readiness state—there is no asynchronous handshake to block the UI anymore.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L48-L133】

## Expected Behaviour

- Synchronisation flows from Riverpod into fl_nodes by converting the automaton
  into a snapshot before rebuilding the editor. The controller guards against
  feedback loops by setting `_isSynchronizing` while replaying nodes and edges.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L96-L234】
- User gestures must keep dispatching `addState`, `moveState`, `removeState`, and
  `addOrUpdateTransition` so that simulations and persistence remain accurate.【F:lib/features/canvas/fl_nodes/fl_nodes_canvas_controller.dart†L236-L355】【F:lib/presentation/providers/automaton_provider.dart†L83-L260】

## Suggested Follow-Up Tasks

1. **Web platform affordances** – audit browser-specific shortcuts (copy/paste,
   undo) exposed by fl_nodes and decide whether they should be mirrored in the
   toolbar or kept as hidden power-user features.
2. **Snapshot diffing** – evaluate whether we still need partial patching when
   collaborative editing lands. `FlNodesAutomatonMapper.mergeIntoTemplate` could
   be extended with diff helpers similar to the legacy bridge if needed.【F:lib/features/canvas/fl_nodes/fl_nodes_automaton_mapper.dart†L61-L108】
3. **Extended testing** – replace the deleted Draw2D bridge tests with focused
   widget and controller tests that validate node creation, link wiring, and
   highlight dispatch, ensuring the fl_nodes integration has automated coverage.
