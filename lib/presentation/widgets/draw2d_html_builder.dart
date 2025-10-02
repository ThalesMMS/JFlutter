import 'package:flutter/services.dart' show rootBundle;

/// Builds the full HTML document used to bootstrap the Draw2D editor inside a
/// platform WebView. The document embeds the required JavaScript libraries so
/// the editor starts with all dependencies available, even when assets cannot
/// be fetched by relative path (e.g. iOS WebView sandbox restrictions).
class Draw2dHtmlBuilder {
  Draw2dHtmlBuilder._();

  static String? _cachedHtml;

  /// Returns the cached Draw2D HTML string, building it on first access.
  static Future<String> load() async {
    final cached = _cachedHtml;
    if (cached != null) {
      return cached;
    }
    final html = await _buildHtml();
    _cachedHtml = html;
    return html;
  }

  static Future<String> _buildHtml() async {
    final jquery = await rootBundle
        .loadString('assets/draw2d/vendor/jquery-3.7.1.min.js');
    final jqueryUi =
        await rootBundle.loadString('assets/draw2d/vendor/jquery-ui.min.js');
    final draw2d =
        await rootBundle.loadString('assets/draw2d/vendor/draw2d.js');
    final editorJs = await rootBundle.loadString('assets/draw2d/editor.js');

    const styles = '''
html,
body {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden;
  background: transparent;
}

#canvas {
  width: 100%;
  height: 100%;
  background-color: #f5f5f5;
  border: 1px solid #ddd;
}
''';

    const canvasMarkup = '''
<div id="canvas">
  <div id="loading-indicator" style="
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
    background: rgba(0, 0, 0, 0.8);
    color: white;
    padding: 20px;
    border-radius: 8px;
    font-family: Arial, sans-serif;
    text-align: center;
    z-index: 1000;
  ">
    Loading Draw2D Canvas...
  </div>
</div>
''';

    const alertBridge = '''
(function () {
  try {
    Alert.postMessage('HTML script is running!');
  } catch (error) {
    console.log('[Draw2D] Alert channel not available yet:', error);
  }

  const originalAlert = window.alert;
  window.alert = function (message) {
    try {
      Alert.postMessage(String(message));
    } catch (_) {
      if (typeof originalAlert === 'function') {
        originalAlert(message);
      }
    }
  };
})();
''';

    String wrapScript(String source) {
      final escaped = _escapeScriptContent(source);
      return '<script type="text/javascript">$escaped</script>';
    }

    /// Escapes script content to prevent breaking out of <script> tags and XSS.
    /// This replaces &, <, >, ", ', and </script> with safe equivalents.
    String _escapeScriptContent(String input) {
      return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('</script>', '<\\/script>');
    }
    final buffer = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="en">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8" />')
      ..writeln(
          '<meta name="viewport" content="width=device-width, initial-scale=1.0" />')
      ..writeln('<title>Draw2D Automaton Editor</title>')
      ..writeln('<style>')
      ..writeln(styles)
      ..writeln('</style>')
      ..writeln('</head>')
      ..writeln('<body>')
      ..writeln(canvasMarkup)
      ..writeln(wrapScript(alertBridge))
      ..writeln(wrapScript(jquery))
      ..writeln(wrapScript(jqueryUi))
      ..writeln(wrapScript(draw2d))
      ..writeln(wrapScript(editorJs))
      ..writeln('</body>')
      ..writeln('</html>');

    return buffer.toString();
  }
}

