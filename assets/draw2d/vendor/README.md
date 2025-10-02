# Draw2D Vendor Bundle

This directory stores a vendored copy of the Draw2D JavaScript runtime and its
web dependencies so the embedded WebView can operate without relying on a CDN
(which WKWebView refuses when loading local assets).

- `draw2d.js` was retrieved from `https://github.com/freegroup/draw2d` (master
  branch snapshot fetched on 2025-10-02).
- `jquery-3.7.1.min.js` comes from `https://code.jquery.com/jquery-3.7.1.min.js`
  (downloaded on 2025-02-14).
- `jquery-ui-1.13.2.min.js` comes from
  `https://code.jquery.com/ui/1.13.2/jquery-ui.min.js` (downloaded on
  2025-10-02) and provides the draggable/droppable widgets required by the
  Draw2D editor when running offline inside a WebView.

Please review upstream licensing (MIT) before distributing.
