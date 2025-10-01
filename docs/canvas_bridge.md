# Draw2D Canvas Bridge

This document describes the Flutter ↔︎ Draw2D communication layer that powers the optional WebView canvas.

## Overview

The Draw2D canvas is a WebView-based renderer that mirrors the Finite State Automaton (FSA) state managed by Flutter. The bridge is responsible for:

- Serializing the current `FSA` into a Draw2D-friendly payload (`loadAutomaton`).
- Receiving user-driven events (`node:add`, `node:move`, `edge:link`) from the WebView and merging them back into the Flutter model.
- Persisting the "Use Draw2D Canvas" preference via `SettingsModel` and Riverpod's `settingsProvider`.

## Commands

### `loadAutomaton`

Sent whenever Flutter needs to hydrate Draw2D with the latest automaton snapshot.

```json
{
  "type": "loadAutomaton",
  "payload": {
    "nodes": [
      { "id": "q0", "label": "q0", "x": 0, "y": 0, "isInitial": true, "isAccepting": false }
    ],
    "edges": [
      { "id": "t0", "from": "q0", "to": "q1", "symbols": ["a"] }
    ],
    "metadata": { "id": "bridge-test", "name": "Bridge Test", "alphabet": ["a"] }
  }
}
```

The Draw2D host should clear its state and rehydrate from the payload.

## Events

Draw2D must emit JSON messages to the `Draw2dBridge` JavaScript channel. The bridge tolerates unknown fields and ignores malformed payloads.

| Type        | Payload fields                                                                 | Effect in Flutter                                                |
| ----------- | ------------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| `node:add`  | `id`, `label`, `x`, `y`, `isInitial`, `isAccepting`                              | Adds or replaces the state. If `isInitial` is `true` the previous initial state is cleared. |
| `node:move` | `id`, `label`, `x`, `y`, `isInitial`, `isAccepting`                              | Updates the state's position while keeping initial/accepting flags intact. |
| `edge:link` | `id`, `from`, `to`, `symbols` (string array or comma-delimited string)           | Creates or replaces an FSA transition and augments the alphabet. |

All payloads are merged into the current FSA in an immutable fashion using `Draw2dCanvasBridge`.

## Manual Verification

1. Enable **Use Draw2D Canvas** in *Settings → Canvas* and save.
2. Return to the FSA workspace; the WebView canvas should render (or show a platform warning on unsupported targets).
3. Trigger mock events via the integration test or by using the WebView console:
   - `window.Draw2dBridge.postMessage(JSON.stringify({ type: 'node:add', payload: { id: 'q1', label: 'q1', x: 160, y: 80, isInitial: false, isAccepting: true }}));`
   - `window.Draw2dBridge.postMessage(JSON.stringify({ type: 'node:move', payload: { id: 'q1', label: 'q1', x: 220, y: 120, isInitial: false, isAccepting: true }}));`
   - `window.Draw2dBridge.postMessage(JSON.stringify({ type: 'edge:link', payload: { id: 't1', from: 'q0', to: 'q1', symbols: ['a'] }}));`
4. Confirm that the automaton updates in Flutter (state list, transition list, alphabet badge).
5. Disable the toggle and verify that the legacy Flutter canvas returns.

## Troubleshooting

- **WebView not available**: Desktop platforms without a native WebView (e.g., Windows) fall back to a placeholder explaining the limitation.
- **No updates after saving settings**: Ensure `settingsProvider` is initialized; `SettingsPage` now synchronizes Riverpod state after load, save, and reset.
- **Malformed messages**: The bridge silently ignores decoding errors. Use the browser console to inspect the rejected payload.

Refer to the integration test `test/integration/draw2d_canvas_bridge_test.dart` for a complete example of the add → move → link flow.
