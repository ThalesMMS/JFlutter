part of graphview;

class OrientationUtils {
  // Orientation constants
  static const int ORIENTATION_TOP_BOTTOM = 1;
  static const int ORIENTATION_BOTTOM_TOP = 2;
  static const int ORIENTATION_LEFT_RIGHT = 3;
  static const int ORIENTATION_RIGHT_LEFT = 4;

  /// Returns true if the orientation is vertical (top-bottom or bottom-top)
  static bool isVertical(int orientation) {
    return orientation == ORIENTATION_TOP_BOTTOM ||
        orientation == ORIENTATION_BOTTOM_TOP;
  }

  /// Returns true if the orientation requires reverse order (bottom-top or right-left)
  static bool needReverseOrder(int orientation) {
    return orientation == ORIENTATION_BOTTOM_TOP ||
        orientation == ORIENTATION_RIGHT_LEFT;
  }

  /// Calculates the offset needed to position the graph based on orientation
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

  /// Calculates the final position of a node based on orientation
  static Offset getPosition(Node node, Offset offset, int orientation, {double padding = 0.0}) {
    Offset finalOffset;
    switch (orientation) {
      case ORIENTATION_TOP_BOTTOM:
        finalOffset = Offset(node.x - offset.dx, node.y + padding);
        break;
      case ORIENTATION_BOTTOM_TOP:
        finalOffset = Offset(node.x - offset.dx, offset.dy - node.y - padding);
        break;
      case ORIENTATION_LEFT_RIGHT:
        finalOffset = Offset(node.y + padding, node.x - offset.dx);
        break;
      case ORIENTATION_RIGHT_LEFT:
        finalOffset = Offset(offset.dy - node.y - padding, node.x - offset.dx);
        break;
      default:
        finalOffset = Offset(0, 0);
        break;
    }

    return finalOffset;
  }
}
