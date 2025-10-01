import 'package:flutter/material.dart';

/// Shared fallback UI displayed when Draw2D cannot be rendered in a WebView.
class Draw2dCanvasFallback extends StatelessWidget {
  const Draw2dCanvasFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Draw2dUnsupportedCanvasMessage(),
      ),
    );
  }
}

class Draw2dUnsupportedCanvasMessage extends StatelessWidget {
  const Draw2dUnsupportedCanvasMessage({super.key});

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
