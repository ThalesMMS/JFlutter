# Draw2D Canvas Bridge

The Draw2D workspace is rendered inside a `WebView` (`Draw2DCanvasView`) that
loads `assets/draw2d/editor.html`. The HTML page bootstraps the Draw2D library
and exposes a messaging layer so Flutter can keep the canvas in sync with the
current automaton.

## Message Flow

Communication happens through the `JFlutterBridge` JavaScript channel. Each
message is a JSON envelope with a `type` string and an optional `payload`
object. The bridge performs a handshake (`editor_ready`) before Flutter starts
sending data so the toolbar can surface the “Canvas not connected” hint until
Draw2D is ready.

### Flutter → JavaScript

Flutter keeps the WebView copy of the automaton in sync by executing
`window.draw2dBridge.loadModel(model)` whenever the provider emits a new
snapshot. The payload matches the structure returned by
`Draw2DAutomatonMapper.toJson`:

| Field            | Description                                            |
| ---------------- | ------------------------------------------------------ |
| `id`             | Automaton identifier used to derive stable node IDs.   |
| `name`           | Human readable automaton name.                         |
| `alphabet`       | Sorted list of input symbols.                          |
| `states`         | Array of state objects (id, label, position, flags…).  |
| `transitions`    | Array of transition objects (from, to, label, control).|
| `initialStateId` | Draw2D identifier of the initial state (or `null`).    |

Additional bridge commands mirror toolbar actions and simulator needs. All
payloads are JSON-serialised before being injected:

| Command                | Transport                          | Payload shape                         | Purpose |
| ---------------------- | ---------------------------------- | ------------------------------------- | ------- |
| `highlight`            | JS bridge method + `postMessage`   | `{ states: string[], transitions: string[] }` | Highlight states/transitions during simulations. |
| `clear_highlight`      | JS bridge method + `postMessage`   | `{}`                                  | Remove active highlights. |
| `zoom_in` / `zoom_out` | JS bridge method + `postMessage`   | `{}`                                  | Adjust canvas zoom level. |
| `reset_view`           | JS bridge method + `postMessage`   | `{}`                                  | Restore the default pan/zoom. |
| `fit_content`          | JS bridge method + `postMessage`   | `{}`                                  | Auto-frame the automaton. |
| `add_state_center`     | JS bridge method + `postMessage`   | `{}`                                  | Insert a new state at the viewport centre. |
| `load_automaton`       | `postMessage` (Flutter web builds) | Automaton snapshot + viewport & trace metadata | Initialise Draw2D in web builds. |
| `clear_automaton`      | `postMessage` (Flutter web builds) | `{}`                                  | Remove the rendered automaton. |

### JavaScript → Flutter

User interactions in Draw2D are forwarded back to Flutter through
`JFlutterBridge`. The mobile WebView emits the following events:

| `type`                 | Payload fields                                                   | Effect |
| ---------------------- | ---------------------------------------------------------------- | ------ |
| `editor_ready`         | `{}`                                                             | Marks the bridge as ready and triggers the first sync. |
| `log`                  | `level`, `message`, `details?`                                   | Surfaces runtime diagnostics in Flutter logs. |
| `state.add`            | `id?`, `label?`, `x`, `y`, `isInitial?`, `isAccepting?`          | Adds or replaces a state at the requested coordinates. |
| `state.move`           | `id`, `x`, `y`                                                   | Updates a state's position (debounced every 60 ms). |
| `state.label`          | `id`, `label`                                                    | Renames a state. |
| `state.updateFlags`    | `id`, `isInitial?`, `isAccepting?`                               | Toggles initial/accepting flags. |
| `state.remove`         | `id`                                                             | Deletes a state. |
| `transition.add`       | `id?`, `fromStateId`, `toStateId`, `label?`                      | Creates or updates a transition. |
| `transition.label`     | `id`, `label`                                                    | Updates transition symbols. |
| `transition.remove`    | `id`                                                             | Deletes a transition. |

Flutter web builds reuse the same event names via `postMessage` and add
request/patch helpers (`request_automaton`, `patch`, `viewport_patch`) so the
HTML editor can ask for the latest snapshot or send diff updates.

## Debugging Tips

* Enable the "Use Draw2D Canvas" toggle in Settings to render the WebView
  instead of the legacy Flutter canvas.
* Open the WebView's developer tools (when available) to inspect console logs.
  Every inbound/outbound message is printed with a `[Draw2D]` prefix.
* The toolbar now shows "Canvas not connected" until the Draw2D bridge reports
  readiness. If the message persists, inspect the console for bridge errors.

## Web Highlight Bridge

For Flutter Web builds a lightweight bridge lives in
`web/assets/draw2d/editor.js`. It listens for `postMessage` calls with the
`type` values `highlight` and `clear_highlight` so the simulation view can
highlight states and transitions during playback.
