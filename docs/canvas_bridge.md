# GraphView Canvas Architecture

JFlutter now renders automatons using a native GraphView-based canvas. The Flutter widget tree embeds `AutomatonGraphViewCanvas`, which wires provider state, highlight playback, and viewport controls without relying on any WebView or iframe bridge.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L26-L118】

> **Note:** The project depends on a fork of GraphView that adds deterministic loop-edge rendering and related fixes: https://github.com/ThalesMMS/graphview/tree/loop-edge-renderer. The fork is consumed via a path dependency in `pubspec.yaml`, so keep it in sync when updating the canvas plumbing.

## Rendering Pipeline

* `AutomatonGraphViewCanvas` owns a `GraphViewCanvasController` and synchronises it with the active automaton emitted by Riverpod. The controller creates the Graph/`GraphViewController` pair, attaches highlight channels, and performs an initial fit-to-content when data is available.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L52-L178】
* `GraphViewCanvasController` converts `AutomatonProvider` state into `GraphViewAutomatonSnapshot` instances and rebuilds the Graph when `synchronize` is invoked. Node and edge caches track layout information so diffing and undo/redo remain fast.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L13-L188】【F:lib/features/canvas/graphview/base_graphview_canvas_controller.dart†L17-L220】
* Snapshots merge back into domain models through `GraphViewAutomatonMapper`, ensuring IDs, labels, alphabet entries, and metadata such as bounds and zoom level stay in sync with Riverpod state.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L188-L219】【F:lib/features/canvas/graphview/graphview_automaton_mapper.dart†L7-L130】

## Editing Flow

`GraphViewCanvasController` exposes high-level mutation helpers that relay interactions back to `AutomatonProvider`:

* `addStateAt` assigns deterministic IDs and labels, marking the first node as initial when appropriate.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L106-L129】
* `moveState` normalises drag deltas, forwarding updated coordinates while preserving the undo history.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L130-L139】【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L304-L332】
* `addOrUpdateTransition` and `removeTransition` keep edge metadata aligned with the provider, including control points for curved links.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L160-L186】【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L333-L494】
* Node and edge selection state drives overlay editors rendered by the canvas itself, allowing inline label updates without leaving the widget tree.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L333-L626】

## Toolbar & Gestures

The `GraphViewCanvasToolbar` widget centralises viewport actions, undo/redo, and optional drawing tools. Desktop and mobile layouts reuse the same controller callbacks so gestures and button presses behave identically across platforms.【F:lib/presentation/widgets/graphview_canvas_toolbar.dart†L6-L138】 Touch-centric controls remain available through `MobileAutomatonControls`, which exposes simulator shortcuts and canvas commands in a bottom-aligned tray.【F:lib/presentation/widgets/mobile_automaton_controls.dart†L1-L132】

## Highlight Channel

`AutomatonGraphViewCanvas` installs a `GraphViewSimulationHighlightChannel` when it owns the controller, bridging `SimulationHighlightService` payloads to the canvas highlight notifier. Highlights update immediately during playback and are cleared when simulations finish.【F:lib/presentation/widgets/automaton_graphview_canvas.dart†L59-L118】【F:lib/features/canvas/graphview/graphview_highlight_channel.dart†L5-L19】【F:lib/core/services/simulation_highlight_service.dart†L8-L101】

## Data Round-Tripping

When the user edits the canvas, the controller merges the Graph snapshot into the existing automaton template and republishes it through `AutomatonProvider`. This keeps inspector panels, persistence layers, and simulators aligned with the visual representation while avoiding manual diff logic.【F:lib/features/canvas/graphview/graphview_canvas_controller.dart†L188-L219】【F:lib/presentation/providers/automaton_provider.dart†L25-L219】
