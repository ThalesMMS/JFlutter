# Draw2D Canvas Bridge

The Draw2D workspace is rendered inside a `WebView` (`Draw2DCanvasView`) that
loads `assets/draw2d/editor.html`. The HTML page bootstraps the Draw2D library
and exposes a very small messaging layer so Flutter can keep the canvas in sync
with the current automaton.

## Message Flow

Communication happens through the `JFlutterBridge` JavaScript channel. Each
message is a JSON object with two fields:

```json
{ "type": "state.add", "payload": { "id": "q0" } }
```

### Flutter → JavaScript

Flutter pushes the full automaton snapshot whenever the provider changes by
executing `window.draw2dBridge.loadModel(model)`. The payload matches the shape
produced by `Draw2DAutomatonMapper.toJson`:

| Field            | Description                                            |
| ---------------- | ------------------------------------------------------ |
| `id`             | Automaton identifier used to derive stable node IDs.   |
| `name`           | Human readable automaton name.                         |
| `alphabet`       | Sorted list of input symbols.                          |
| `states`         | Array of state objects (id, label, position, flags…).  |
| `transitions`    | Array of transition objects (from, to, label, control).|
| `initialStateId` | Draw2D identifier of the initial state (or `null`).    |

The JavaScript bridge clears the canvas and recreates all figures whenever a
new model arrives.

### JavaScript → Flutter

User interactions in Draw2D are forwarded back to Flutter through the
`JFlutterBridge` channel. The following event types are supported:

| `type`             | Payload fields                                                   | Effect                                             |
| ------------------ | ---------------------------------------------------------------- | -------------------------------------------------- |
| `state.add`        | `id`, `label`, `x`, `y`, `isInitial?`, `isAccepting?`            | Adds or replaces a state at the given coordinates. |
| `state.move`       | `id`, `x`, `y`                                                   | Updates a state's position (batched every 60 ms).  |
| `state.label`      | `id`, `label`                                                    | Renames a state.                                   |
| `transition.add`   | `id`, `fromStateId`, `toStateId`, `label`                        | Creates or updates a transition.                   |
| `transition.label` | `id`, `label`                                                    | Renames a transition and updates its symbols.      |

The provider normalises these events and merges them into the active `FSA`
instance, ensuring the rest of the UI reacts immediately.

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
