import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Temporary Draw2D prototype embedded through a WebView.
class Draw2DCanvasView extends ConsumerStatefulWidget {
  const Draw2DCanvasView({super.key});

  @override
  ConsumerState<Draw2DCanvasView> createState() => _Draw2DCanvasViewState();
}

class _Draw2DCanvasViewState extends ConsumerState<Draw2DCanvasView> {
  late final WebViewController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            developer.log(
              'Draw2D asset finished loading: $url',
              name: 'Draw2DCanvasView',
            );
          },
          onWebResourceError: (error) {
            developer.log(
              'Draw2D asset failed to load',
              name: 'Draw2DCanvasView',
              error: error,
            );
          },
        ),
      )
      ..addJavaScriptChannel(
        'Draw2dReadyChannel',
        onMessageReceived: (message) {
          developer.log(
            'Draw2D ready message: ${message.message}',
            name: 'Draw2DCanvasView',
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _isReady = true;
          });
        },
      )
      ..loadFlutterAsset('assets/draw2d/index.html');
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      unawaited(_controller.clearCache());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outlineColor = theme.colorScheme.outlineVariant;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineColor.withOpacity(0.6)),
        color: theme.colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: _isReady ? 0 : 1,
              child: Container(
                color: theme.colorScheme.surface,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
