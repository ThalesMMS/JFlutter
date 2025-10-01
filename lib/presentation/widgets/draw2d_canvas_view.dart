import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:jflutter/data/services/draw2d_bridge_service.dart';

/// Wraps the Draw2D editor inside a WebView and surfaces bridge callbacks.
class Draw2DCanvasView extends StatefulWidget {
  const Draw2DCanvasView({
    super.key,
    this.onNodeAdded,
    this.onNodeMoved,
    this.onEdgeAdded,
    this.onLabelEdited,
    this.onBridgeReady,
    this.onControllerReady,
    this.onBridgeError,
    this.onPageLoaded,
    BorderRadius? borderRadius,
    bool? enableDebugLogging,
  })  : borderRadius = borderRadius ?? BorderRadius.zero,
        enableDebugLogging = enableDebugLogging ?? kDebugMode;

  final Draw2DEventHandler? onNodeAdded;
  final Draw2DEventHandler? onNodeMoved;
  final Draw2DEventHandler? onEdgeAdded;
  final Draw2DEventHandler? onLabelEdited;
  final ValueChanged<Draw2DBridgeService>? onBridgeReady;
  final ValueChanged<WebViewController>? onControllerReady;
  final Draw2DBridgeErrorHandler? onBridgeError;
  final ValueChanged<String>? onPageLoaded;
  final BorderRadius borderRadius;
  final bool enableDebugLogging;

  @override
  State<Draw2DCanvasView> createState() => _Draw2DCanvasViewState();
}

class _Draw2DCanvasViewState extends State<Draw2DCanvasView> {
  late final WebViewController _controller;
  Draw2DBridgeService? _bridgeService;
  bool _pageLoaded = false;
  bool _debugTriggered = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: _handlePageFinished,
        ),
      )
      ..loadFlutterAsset('assets/draw2d/index.html');

    _bridgeService = Draw2DBridgeService(
      controller: _controller,
      onNodeAdded: widget.onNodeAdded,
      onNodeMoved: widget.onNodeMoved,
      onEdgeAdded: widget.onEdgeAdded,
      onLabelEdited: widget.onLabelEdited,
      onError: widget.onBridgeError,
    );

    widget.onBridgeReady?.call(_bridgeService!);
    widget.onControllerReady?.call(_controller);
  }

  @override
  void didUpdateWidget(covariant Draw2DCanvasView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _bridgeService?.updateHandlers(
      onNodeAdded: widget.onNodeAdded,
      onNodeMoved: widget.onNodeMoved,
      onEdgeAdded: widget.onEdgeAdded,
      onLabelEdited: widget.onLabelEdited,
    );

    if (widget.enableDebugLogging && !_debugTriggered && _pageLoaded) {
      _triggerDebug();
    }
  }

  Future<void> _handlePageFinished(String url) async {
    _pageLoaded = true;
    widget.onPageLoaded?.call(url);

    if (widget.enableDebugLogging && !_debugTriggered) {
      await _triggerDebug();
    }
  }

  Future<void> _triggerDebug() async {
    _debugTriggered = true;
    await _bridgeService?.sendDebugCommands();
    await _bridgeService?.triggerDebugEvents();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: WebViewWidget(controller: _controller),
    );
  }
}
