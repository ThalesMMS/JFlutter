import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/tm.dart';
import 'tm_canvas.dart';

/// Legacy entry point that now proxies to the Flutter-based TM canvas.
class Draw2DTMCanvasView extends ConsumerStatefulWidget {
  const Draw2DTMCanvasView({
    super.key,
    required this.onTMModified,
  });

  final ValueChanged<TM> onTMModified;

  @override
  ConsumerState<Draw2DTMCanvasView> createState() => _Draw2DTMCanvasViewState();
}

class _Draw2DTMCanvasViewState extends ConsumerState<Draw2DTMCanvasView> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return TMCanvas(
      canvasKey: _canvasKey,
      onTMModified: widget.onTMModified,
    );
  }
}
