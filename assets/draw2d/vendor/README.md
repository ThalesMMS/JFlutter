# Draw2D Vendor Bundle

This directory stores a vendored copy of the Draw2D JavaScript runtime so the
embedded WebView can operate without relying on a CDN (which WKWebView refuses
when loading local assets). The file `draw2d.js` was retrieved from
`https://github.com/freegroup/draw2d` (master branch snapshot fetched on
2025-10-02).

Please review upstream licensing (MIT) before distributing.
