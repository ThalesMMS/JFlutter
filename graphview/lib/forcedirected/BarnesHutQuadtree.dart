part of graphview;

/// A Barnes-Hut quadtree node for spatial partitioning of graph nodes.
///
/// The quadtree recursively subdivides 2D space into quadrants to enable
/// O(n log n) force calculations by approximating distant node clusters
/// as single points with aggregated mass and center of mass.
class BarnesHutQuadtree {
  /// The spatial bounds of this quadtree node.
  ///
  /// Defines the rectangular region in 2D space that this node covers.
  final Rect bounds;

  /// Center of mass of all nodes contained in this quadtree node.
  ///
  /// For internal nodes, this is the weighted average position of all
  /// descendant nodes. For leaf nodes, this is the position of the single
  /// contained node.
  Offset centerOfMass;

  /// Total mass of all nodes contained in this quadtree node.
  ///
  /// Each graph node contributes a mass of 1.0. For internal nodes,
  /// this is the sum of all descendant nodes' masses.
  double totalMass;

  /// The four child quadrants (NW, NE, SW, SE).
  ///
  /// Null if this is a leaf node. When subdivided, the spatial bounds
  /// are divided equally into four quadrants.
  BarnesHutQuadtree? northWest;
  BarnesHutQuadtree? northEast;
  BarnesHutQuadtree? southWest;
  BarnesHutQuadtree? southEast;

  /// The graph node stored in this leaf node.
  ///
  /// Null if this is an internal node with children. A leaf node can
  /// contain at most one graph node before it must be subdivided.
  Node? node;
  bool _hasAggregatedLeafMass = false;

  /// Maximum number of nodes in a leaf before subdivision.
  ///
  /// Currently set to 1, meaning each leaf contains at most one node.
  /// This ensures the quadtree is as fine-grained as possible for
  /// optimal Barnes-Hut approximation accuracy.
  static const int capacity = 1;

  /// Maximum recursion depth to prevent infinite subdivision when
  /// nodes share identical positions.
  static const int _maxDepth = 30;

  /// Current depth in the quadtree hierarchy.
  final int _depth;

  BarnesHutQuadtree(this.bounds, {int depth = 0})
      : centerOfMass = Offset.zero,
        totalMass = 0.0,
        _depth = depth;

  /// Returns true if this is a leaf node (no children).
  ///
  /// A leaf node has no subdivisions and either contains a single graph node
  /// or is empty. Used to determine whether to recurse into children or
  /// treat this as a terminal node.
  bool get isLeaf =>
      northWest == null &&
      northEast == null &&
      southWest == null &&
      southEast == null;

  /// Returns true if this quadtree node is empty (no mass).
  ///
  /// An empty node contains no graph nodes and has zero total mass.
  /// Empty nodes are skipped during force calculations.
  bool get isEmpty => totalMass == 0.0;

  /// Inserts a graph node into the quadtree.
  ///
  /// The node is placed in the appropriate position in the quadtree hierarchy,
  /// subdividing nodes as necessary to maintain the capacity constraint.
  /// If the node's position falls outside the bounds of this quadtree node,
  /// it is ignored.
  ///
  /// Complexity: O(log n) average case, O(n) worst case for unbalanced trees.
  ///
  /// Returns true if the node was successfully inserted, false if the node
  /// is outside the bounds.
  bool insert(Node graphNode) {
    // Ignore nodes outside the bounds
    if (!bounds.contains(graphNode.position)) {
      return false;
    }

    // If this is an empty leaf, store the node here
    if (isEmpty && isLeaf) {
      node = graphNode;
      _hasAggregatedLeafMass = false;
      totalMass = 1.0;
      centerOfMass = graphNode.position;
      return true;
    }

    // If this is a non-empty leaf, subdivide and redistribute
    if (isLeaf) {
      // At max depth, just accumulate mass to avoid infinite recursion
      // when multiple nodes share the same position
      if (_depth >= _maxDepth) {
        _updateMassAndCenter(graphNode);
        _hasAggregatedLeafMass = true;
        return true;
      }

      final oldNode = node;
      node = null;
      _hasAggregatedLeafMass = false;

      // Create children
      _subdivide();

      // Reinsert the old node
      if (oldNode != null) {
        _insertIntoChild(oldNode);
      }

      // Insert the new node
      _insertIntoChild(graphNode);
    } else {
      // This is an internal node, insert into appropriate child
      _insertIntoChild(graphNode);
    }

    // Update center of mass and total mass
    _updateMassAndCenter(graphNode);

    return true;
  }

  /// Subdivides this node into four quadrants (NW, NE, SW, SE).
  ///
  /// Creates four child quadtree nodes, each representing one quadrant
  /// of this node's spatial bounds. Called automatically during insertion
  /// when a leaf node exceeds its capacity.
  void _subdivide() {
    final x = bounds.left;
    final y = bounds.top;
    final w = bounds.width / 2;
    final h = bounds.height / 2;
    final childDepth = _depth + 1;

    northWest = BarnesHutQuadtree(Rect.fromLTWH(x, y, w, h), depth: childDepth);
    northEast =
        BarnesHutQuadtree(Rect.fromLTWH(x + w, y, w, h), depth: childDepth);
    southWest =
        BarnesHutQuadtree(Rect.fromLTWH(x, y + h, w, h), depth: childDepth);
    southEast =
        BarnesHutQuadtree(Rect.fromLTWH(x + w, y + h, w, h), depth: childDepth);
  }

  /// Inserts a node into the appropriate child quadrant.
  ///
  /// Attempts to insert the node into each child quadrant in order (NW, NE, SW, SE)
  /// until one accepts it based on spatial bounds.
  void _insertIntoChild(Node graphNode) {
    if (northWest!.insert(graphNode)) return;
    if (northEast!.insert(graphNode)) return;
    if (southWest!.insert(graphNode)) return;
    if (southEast!.insert(graphNode)) return;

    _childForPosition(graphNode.position)._insertIgnoringBounds(graphNode);
  }

  BarnesHutQuadtree _childForPosition(Offset position) {
    final center = bounds.center;
    if (position.dy < center.dy) {
      return position.dx < center.dx ? northWest! : northEast!;
    }
    return position.dx < center.dx ? southWest! : southEast!;
  }

  bool _insertIgnoringBounds(Node graphNode) {
    if (isEmpty && isLeaf) {
      node = graphNode;
      _hasAggregatedLeafMass = false;
      totalMass = 1.0;
      centerOfMass = graphNode.position;
      return true;
    }

    if (isLeaf) {
      if (_depth >= _maxDepth) {
        _updateMassAndCenter(graphNode);
        _hasAggregatedLeafMass = true;
        return true;
      }

      final oldNode = node;
      node = null;
      _hasAggregatedLeafMass = false;
      _subdivide();
      if (oldNode != null) {
        _insertIntoChild(oldNode);
      }
      _insertIntoChild(graphNode);
    } else {
      _insertIntoChild(graphNode);
    }

    _updateMassAndCenter(graphNode);
    return true;
  }

  /// Updates the center of mass and total mass incrementally for this node.
  ///
  /// This is called during insertion to efficiently update the aggregated mass
  /// and center of mass using a weighted average as nodes are added.
  ///
  /// Complexity: O(1) per node insertion.
  void _updateMassAndCenter(Node graphNode) {
    final newMass = totalMass + 1.0;
    centerOfMass = Offset(
      (centerOfMass.dx * totalMass + graphNode.position.dx) / newMass,
      (centerOfMass.dy * totalMass + graphNode.position.dy) / newMass,
    );
    totalMass = newMass;
  }

  /// Recalculates center of mass and total mass from children (post-order traversal).
  ///
  /// This provides a robust way to compute the aggregated mass and center
  /// by traversing the tree bottom-up, ensuring numerical accuracy. Use this
  /// method after all insertions are complete or when numerical drift is a concern.
  ///
  /// Complexity: O(n) where n is the total number of nodes in the quadtree.
  void recalculateMassAndCenter() {
    if (isLeaf) {
      // Leaf node: mass and center come directly from the stored node
      if (node != null) {
        if (!_hasAggregatedLeafMass) {
          totalMass = 1.0;
          centerOfMass = node!.position;
        }
      } else {
        totalMass = 0.0;
        centerOfMass = Offset.zero;
        _hasAggregatedLeafMass = false;
      }
      return;
    }

    // Internal node: recursively recalculate children first
    northWest?.recalculateMassAndCenter();
    northEast?.recalculateMassAndCenter();
    southWest?.recalculateMassAndCenter();
    southEast?.recalculateMassAndCenter();

    // Calculate aggregated mass and center from children
    totalMass = 0.0;
    var weightedX = 0.0;
    var weightedY = 0.0;

    final children = [northWest, northEast, southWest, southEast];
    for (final child in children) {
      if (child != null && !child.isEmpty) {
        weightedX += child.centerOfMass.dx * child.totalMass;
        weightedY += child.centerOfMass.dy * child.totalMass;
        totalMass += child.totalMass;
      }
    }

    if (totalMass > 0) {
      centerOfMass = Offset(weightedX / totalMass, weightedY / totalMass);
    } else {
      centerOfMass = Offset.zero;
    }
  }
}
