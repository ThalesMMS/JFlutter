# Draw2D Canvas Investigation

## Summary of Findings

- The FSA page only embeds the Draw2D WebView on mobile/desktop targets. On web builds it still renders the legacy `AutomatonCanvas`, so the Draw2D toolbar cannot reach an active bridge instance. 【F:lib/presentation/pages/fsa_page.dart†L332-L379】
- The `Draw2DCanvasView` used by the FSA page loads `assets/draw2d/minimal_editor.html`, a diagnostic harness that never exposes the `window.draw2dBridge` API expected by `Draw2DBridgeService`. As a result, calls such as `addStateAtCenter` no-op because the bridge wrapper is missing. 【F:lib/presentation/widgets/draw2d_canvas_view.dart†L18-L109】【F:assets/draw2d/minimal_editor.html†L1-L200】
- The TM and PDA screens use `Draw2DTMCanvasView` / `Draw2DPdaCanvasView`, which rely on `editor.html` and `editor.js`. Those scripts do register `window.draw2dBridge.addStateAtCenter` and forward actions back to Flutter, so the tooling mismatch only affects the FSA screen. 【F:lib/presentation/widgets/draw2d_tm_canvas_view.dart†L1-L86】【F:lib/presentation/widgets/draw2d_pda_canvas_view.dart†L1-L78】【F:assets/draw2d/editor.js†L587-L1369】
- The "Add state" button invokes `Draw2DBridgeService.addStateAtCenter()`, which simply posts through the bridge. Because the FSA canvas never registers the bridge object, the command is dropped, explaining why none of the canvases respond when tested from that page. 【F:lib/presentation/widgets/draw2d_canvas_toolbar.dart†L23-L47】【F:lib/core/services/draw2d_bridge_service.dart†L41-L68】

## Suggested Follow-Up Tasks

1. **Align FSA canvas with TM/PDA implementation**  
   Replace the `minimal_editor.html` integration with the production `editor.html`/`editor.js` bundle and ensure the FSA view registers the same bridge contract as TM/PDA. This will restore the shared behaviour and allow `Draw2DBridgeService` commands to succeed.

2. **Enable Draw2D on the web FSA page**  
   Update `_buildCanvasArea` to render the Draw2D WebView (or a bridge-aware wrapper) instead of the legacy `AutomatonCanvas` when `kIsWeb` is true. Verify the toolbar buttons are conditionally hidden or fully functional in web builds.

3. **Add readiness diagnostics**  
   Extend the bridge service or toolbar to surface when no controller is registered so that pressing "Add state" gives immediate feedback. This will make future regressions easier to detect.

4. **Regression tests / smoke checks**  
   Introduce widget or integration tests that mock the `Draw2DBridgeService` and confirm toolbar actions dispatch the expected bridge calls, covering FSA, TM, and PDA pages.

5. **Clean up diagnostic HTML**  
   Either remove `minimal_editor.html` once the production bridge is stable or document its intended scope (e.g., internal debugging) to avoid accidental use in shipping views.
