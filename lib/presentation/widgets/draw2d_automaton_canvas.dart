import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/models/fsa.dart';
import '../../features/canvas_bridge/draw2d_canvas_bridge.dart';

/// WebView-backed Draw2D canvas that mirrors the Flutter automaton state.
class Draw2dAutomatonCanvas extends StatefulWidget {
  const Draw2dAutomatonCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    required this.onAutomatonChanged,
  });

  final FSA? automaton;
  final GlobalKey canvasKey;
  final ValueChanged<FSA> onAutomatonChanged;

  @override
  State<Draw2dAutomatonCanvas> createState() => _Draw2dAutomatonCanvasState();
}

class _Draw2dAutomatonCanvasState extends State<Draw2dAutomatonCanvas> {
  WebViewController? _controller;
  late final Draw2dCanvasBridge _bridge;
  bool _hasLoadedInitialState = false;

  @override
  void initState() {
    super.initState();
    _bridge = Draw2dCanvasBridge(
      messenger: const NoopBridgeMessenger(),
      onAutomatonChanged: widget.onAutomatonChanged,
    );
    _initializeWebView();
  }

  @override
  void didUpdateWidget(Draw2dAutomatonCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bridge.setOnAutomatonChanged(widget.onAutomatonChanged);
    if (oldWidget.automaton != widget.automaton || !_hasLoadedInitialState) {
      _bridge.synchronize(widget.automaton);
      _hasLoadedInitialState = true;
    }
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  void _initializeWebView() {
    if (!_isPlatformSupported) {
      return;
    }

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);

    final messenger = _WebViewBridgeMessenger(controller);
    _bridge.attachMessenger(messenger);

    controller.addJavaScriptChannel(
      'Draw2dBridge',
      onMessageReceived: (message) {
        _bridge.handleRawMessage(message.message);
      },
    );

    controller.loadHtmlString(_initialHtml);

    _controller = controller;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bridge.synchronize(widget.automaton);
        _hasLoadedInitialState = true;
      }
    });
  }

  bool get _isPlatformSupported {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isPlatformSupported || _controller == null) {
      return Container(
        key: widget.canvasKey,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: _UnsupportedCanvasMessage(),
        ),
      );
    }

    return KeyedSubtree(
      key: widget.canvasKey,
      child: WebViewWidget(controller: _controller!),
    );
  }
}

class _WebViewBridgeMessenger implements BridgeMessenger {
  _WebViewBridgeMessenger(this._controller);

  final WebViewController _controller;

  @override
  Future<void> postMessage(BridgeCommand command) {
    final json = command.toJson();
    final serialized = jsonEncode(json);
    return _controller.runJavaScript(
      'window.draw2dBridge?.receive($serialized);',
    );
  }
}

class _UnsupportedCanvasMessage extends StatelessWidget {
  const _UnsupportedCanvasMessage();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.web, size: 32),
        SizedBox(height: 12),
        Text(
          'Draw2D canvas requires a supported WebView platform.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

const _initialHtml = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <title>Draw2D Bridge</title>
    <style>
      html, body { height: 100%; margin: 0; background: #1e1e1e; }
      canvas { width: 100%; height: 100%; display: block; background: #272727; }
      .fallback { color: #f0f0f0; font-family: sans-serif; padding: 16px; }
    </style>
  </head>
  <body>
    <div class="fallback">Draw2D canvas connected. Waiting for Flutter events…</div>
    <script>
      window.draw2dBridge = {
        receive: function(message) {
          console.info('Received message from Flutter', message);
        }
      };
    </script>
  </body>
</html>
''';
