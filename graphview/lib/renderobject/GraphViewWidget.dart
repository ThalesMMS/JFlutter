part of graphview;

class GraphViewWidget extends RenderObjectWidget {
  final GraphChildDelegate delegate;
  final Paint? paint;
  final AnimationController nodeAnimationController;
  final bool enableAnimation;

  const GraphViewWidget({
    Key? key,
    required this.delegate,
    this.paint,
    required this.nodeAnimationController,
    required this.enableAnimation,
  }) : super(key: key);

  @override
  GraphViewElement createElement() => GraphViewElement(this);

  @override
  RenderCustomLayoutBox createRenderObject(BuildContext context) {
    return RenderCustomLayoutBox(
      delegate,
      paint,
      enableAnimation,
      nodeAnimationController: nodeAnimationController,
      childManager: context as GraphChildManager,
    )..nodeDraggingConfiguration = delegate.nodeDraggingConfig;
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderCustomLayoutBox renderObject) {
    renderObject
      ..delegate = delegate
      ..edgePaint = paint
      ..nodeAnimationController = nodeAnimationController
      ..enableAnimation = enableAnimation
      ..nodeDraggingConfiguration = delegate.nodeDraggingConfig;
  }
}
