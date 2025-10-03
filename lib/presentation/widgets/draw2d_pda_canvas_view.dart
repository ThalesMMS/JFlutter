import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import 'pda_canvas.dart';

/// Legacy entry point that now proxies to the Flutter-based PDA canvas.
class Draw2DPdaCanvasView extends ConsumerStatefulWidget {
  const Draw2DPdaCanvasView({
    super.key,
    required this.onPdaModified,
  });

  final ValueChanged<PDA> onPdaModified;

  @override
  ConsumerState<Draw2DPdaCanvasView> createState() => _Draw2DPdaCanvasViewState();
}

class _Draw2DPdaCanvasViewState extends ConsumerState<Draw2DPdaCanvasView> {
  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return PDACanvas(
      canvasKey: _canvasKey,
      onPDAModified: widget.onPdaModified,
    );
  }
}
