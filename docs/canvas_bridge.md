# Draw2D Canvas Bridge

This document captures the contract between the Flutter `WebView` host and the Draw2D editor running inside the embedded WebView. The bridge is intentionally small and versioned so that the canvas implementation can evolve without breaking previously shipped clients.

## Message Envelope

All messages flowing across the bridge use the same JSON envelope.

```json
{
  "type": "node_added",
  "version": 1,
  "payload": { "id": "n1" },
  "id": "2dfe13b6-1fc3-4ff0-90c8-8d08d746213f",
  "timestamp": "2024-11-18T14:27:09.149Z"
}
```

| Field       | Direction | Required | Description |
|-------------|-----------|----------|-------------|
| `type`      | both      | ✅        | Machine readable event/command identifier. Lowercase with underscores (e.g. `node_added`). |
| `version`   | both      | ✅        | Semantic version of the payload schema. The Flutter bridge currently implements `1` and rejects anything newer. |
| `payload`   | both      | ✅        | Event/command specific data encoded as a JSON object. |
| `id`        | both      | ✅        | Unique identifier for the envelope. Flutter generates a `uuid.v4`, while the JavaScript runtime may reuse an incrementing counter. |
| `timestamp` | both      | ✅        | ISO-8601 timestamp generated at the point of emission. |

### Versioning Rules

* The bridge must ignore messages whose `version` is greater than the locally supported value.
* Future message revisions should increment the `version` when breaking changes are introduced. Non breaking additions can keep the same version.
* Flutter forwards the negotiated version back to JavaScript so both sides can adapt at runtime.

## Command Schemas (Flutter → JavaScript)

| `type`          | `payload` fields | Notes |
|-----------------|------------------|-------|
| `load_model`    | `model` – draw2d document structure. | Replaces the entire canvas state. |
| `highlight`     | `elementId`, `style` *(optional)*. | Applies visual emphasis to a node/edge. |
| `clear_highlight` | *(empty object)* | Removes any highlight styling. |
| `patch`         | `operations` – JSON Patch array. | Applies incremental updates to the existing model. |

The Flutter service serialises these commands and calls `window.Draw2DHost.receiveMessage(envelope)` inside the WebView. JavaScript logs the envelope and applies the requested change.

## Event Schemas (JavaScript → Flutter)

| `type`         | `payload` fields | Description |
|----------------|------------------|-------------|
| `node_added`   | `id`, `label`, `position { x, y }` | Raised when the user drops a new node. |
| `node_moved`   | `id`, `position { x, y }` | Node drag movement completed. |
| `edge_added`   | `id`, `from`, `to`, `label` | New edge created. |
| `label_edited` | `id`, `label`, `entityType` | Node/edge text edited in place. |

Each event is delivered through the `Draw2DBridge` JavaScript channel and dispatched by `Draw2DBridgeService`.

## Error Handling

* Malformed JSON triggers a `bridgeError` callback with the offending payload.
* Unsupported message versions are ignored after logging a warning. The offending envelope ID is included in the log for diagnostics.
* Missing required fields raise a soft error – the bridge logs the issue, notifies the callback, and prevents the application from crashing.
* Errors propagated from command execution (`loadModel`, `patch`, etc.) are caught and forwarded to the error callback so that providers can react (e.g. show a snackbar).

## Debug Triggers

`Draw2DCanvasView` exposes a debug flag. When enabled the widget:

1. Pushes example commands (`load_model`, `highlight`, `clear_highlight`, `patch`) once the page loads.
2. Executes `window.Draw2DTest.triggerSamples()` which emits one event for each supported message type.

Together these helpers allow developers to validate the bridge contract by inspecting the Flutter logs (`debugPrint`) and the WebView console (`console.log`) without touching production data.
