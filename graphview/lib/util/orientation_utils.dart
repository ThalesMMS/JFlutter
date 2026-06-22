part of graphview;

class OrientationUtils {
  static const int ORIENTATION_TOP_BOTTOM = 1;
  static const int ORIENTATION_BOTTOM_TOP = 2;
  static const int ORIENTATION_LEFT_RIGHT = 3;
  static const int ORIENTATION_RIGHT_LEFT = 4;

  static bool isVertical(int orientation) {
    return orientation == ORIENTATION_TOP_BOTTOM ||
        orientation == ORIENTATION_BOTTOM_TOP;
  }

  static bool needReverseOrder(int orientation) {
    return orientation == ORIENTATION_BOTTOM_TOP ||
        orientation == ORIENTATION_RIGHT_LEFT;
  }

  static Offset getOffset(Graph graph, int orientation) {
    var offsetX = double.infinity;
    var offsetY = double.infinity;
    final doesNeedReverseOrder = needReverseOrder(orientation);

    if (doesNeedReverseOrder) {
      offsetY = double.minPositive;
    }

    graph.nodes.forEach((node) {
      if (doesNeedReverseOrder) {
        offsetX = min(offsetX, node.x);
        offsetY = max(offsetY, node.y);
      } else {
        offsetX = min(offsetX, node.x);
        offsetY = min(offsetY, node.y);
      }
    });

    return Offset(offsetX, offsetY);
  }

  static Offset getPosition(
    Node node,
    Offset offset,
    int orientation, {
    double padding = 0.0,
  }) {
    switch (orientation) {
      case ORIENTATION_TOP_BOTTOM:
        return Offset(node.x - offset.dx, node.y + padding);
      case ORIENTATION_BOTTOM_TOP:
        return Offset(node.x - offset.dx, offset.dy - node.y - padding);
      case ORIENTATION_LEFT_RIGHT:
        return Offset(node.y + padding, node.x - offset.dx);
      case ORIENTATION_RIGHT_LEFT:
        return Offset(offset.dy - node.y - padding, node.x - offset.dx);
      default:
        return Offset.zero;
    }
  }
}
