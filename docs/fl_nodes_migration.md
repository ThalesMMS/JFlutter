# FL Nodes Canvas Migration

Summary of Draw2D-specific behaviours and dependencies that the upcoming Flutter canvas must replicate to preserve feature parity.

## Behavioural Parity Requirements

### `lib/presentation/widgets/draw2d_canvas_view.dart`

* WebView setup injects two JavaScript channels (`JFlutterBridge`, `Alert`) and waits for the `editor_ready` message before syncing automata, using `Draw2DBridgeService` to toggle the toolbar status. The replacement canvas must surface an equivalent readiness signal so the UI can hide the “Canvas not connected” warning. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L52-L133】【F:lib/presentation/widgets/draw2d_canvas_toolbar.dart†L15-L95】
* Automaton updates are streamed through Riverpod and debounced move events (`state.move`) to avoid flooding state updates. The new implementation should preserve debouncing for drag gestures. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L84-L197】【F:lib/presentation/widgets/draw2d_canvas_view.dart†L279-L287】
* Incoming events must support adding/removing states and transitions, renaming, and flag toggles (`state.updateFlags`, `transition.remove`) as Draw2D currently normalises them into the shared `automatonProvider`. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L137-L277】
* ID generation for newly created entities mirrors Draw2D’s incremental scheme (`qN`, `tN`). The Flutter canvas should keep compatible heuristics to avoid collisions with persisted data. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L308-L338】

### `lib/presentation/widgets/automaton_canvas_web.dart`

* Flutter web uses an `<iframe>` bridge that mirrors the handshake (`editor_ready`) and posts `load_automaton` / `clear_automaton` messages with viewport and simulation trace metadata. The new canvas must continue exposing viewport pan/zoom and trace highlights through the same payload structure. 【F:lib/presentation/widgets/automaton_canvas_web.dart†L91-L235】【F:lib/presentation/widgets/automaton_canvas_web.dart†L251-L299】
* Web builds forward toolbar commands and simulator highlights via `postMessage` (`highlight`, `zoom_in`, `add_state_center`, etc.). Any replacement must keep accepting those message types to avoid breaking existing services (`Draw2DBridgeService`, `SimulationHighlightService`). 【F:lib/presentation/widgets/automaton_canvas_web.dart†L116-L180】【F:lib/core/services/draw2d_bridge_service.dart†L76-L123】
* Diff-based updates (`patch`, `viewport_patch`) are applied to the current automaton and can skip the next full sync to prevent feedback loops. The incoming canvas must either keep patch semantics or provide an alternative that preserves performance. 【F:lib/presentation/widgets/automaton_canvas_web.dart†L146-L235】

### `lib/presentation/widgets/draw2d_canvas_toolbar.dart`

* Toolbar buttons trigger `Draw2DBridgeService` helpers (zoom, fit, reset, add state) and expose a clear callback hook for bulk deletion. The new canvas should reuse the same command surface or provide backward-compatible callbacks. 【F:lib/presentation/widgets/draw2d_canvas_toolbar.dart†L20-L74】
* The toolbar reflects bridge readiness through an AnimatedBuilder. Maintain the notifier contract so the status label still reflects connectivity. 【F:lib/presentation/widgets/draw2d_canvas_toolbar.dart†L15-L95】【F:lib/core/services/draw2d_bridge_service.dart†L26-L131】

## Dependencies & Assets

* `Draw2DBridgeService` orchestrates JavaScript invocations and `postMessage` fallbacks; any migration must supply equivalent hooks for highlight control and viewport actions. 【F:lib/core/services/draw2d_bridge_service.dart†L66-L123】
* `Draw2dHtmlBuilder` inlines vendor assets (`jquery`, `draw2d.js`, `editor.js`) to work inside platform WebViews. If Draw2D is removed, ensure replacement assets (or compiled Flutter canvas code) are referenced through the same asset bundle plumbing. 【F:lib/presentation/widgets/draw2d_html_builder.dart†L1-L131】
* Embedded HTML currently loads `assets/draw2d/editor.html` / `editor.js`. Removing these without updating `pubspec.yaml` and the HTML builder will break the WebView bootstrap path. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L52-L104】【F:lib/presentation/widgets/automaton_canvas_web.dart†L91-L111】

## Risks & Open Questions

* WebView-only features such as the readiness handshake rely on JavaScript messaging; replacing Draw2D with a Flutter canvas must re-implement the handshake or adjust toolbar UX to avoid persistent “not connected” states. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L126-L133】【F:lib/presentation/widgets/draw2d_canvas_toolbar.dart†L15-L95】
* Highlight controls and viewport commands are broadcast to both WebView and web iframe targets; diverging message names would break simulator playback and toolbar actions. 【F:lib/core/services/draw2d_bridge_service.dart†L76-L123】【F:lib/presentation/widgets/automaton_canvas_web.dart†L116-L180】
* Current implementation lacks automated coverage for the WebView bridge, so regression risk is high without integration tests or golden scenarios for the new canvas. Plan manual verification scripts or new widget tests during migration.
