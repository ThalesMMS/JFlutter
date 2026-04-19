part of graphview;

/// Configuration class for edge routing behavior in GraphView.
///
/// This class controls how edges connect to nodes (anchor modes),
/// how edge paths are generated (routing modes), and whether edge-to-edge
/// repulsion is applied to prevent visual conflicts.
class EdgeRoutingConfig {
  /// The anchor mode determining how edges connect to node boundaries.
  AnchorMode anchorMode = DEFAULT_ANCHOR_MODE;

  /// The routing mode determining how edge paths are generated.
  RoutingMode routingMode = DEFAULT_ROUTING_MODE;

  /// Whether to enable edge-to-edge repulsion forces.
  bool enableRepulsion = DEFAULT_ENABLE_REPULSION;

  /// Strength of repulsion forces (0.0 = disabled, 1.0 = maximum).
  double repulsionStrength = DEFAULT_REPULSION_STRENGTH;

  /// Minimum distance to maintain between edges (in pixels).
  double minEdgeDistance = DEFAULT_MIN_EDGE_DISTANCE;

  /// Maximum iterations for repulsion force convergence.
  int maxRepulsionIterations = DEFAULT_MAX_REPULSION_ITERATIONS;

  /// Distance threshold for dirty tracking (movements smaller than this are ignored).
  double movementThreshold = DEFAULT_MOVEMENT_THRESHOLD;

  static const AnchorMode DEFAULT_ANCHOR_MODE = AnchorMode.center;
  static const RoutingMode DEFAULT_ROUTING_MODE = RoutingMode.direct;
  static const bool DEFAULT_ENABLE_REPULSION = false;
  static const double DEFAULT_REPULSION_STRENGTH = 0.5;
  static const double DEFAULT_MIN_EDGE_DISTANCE = 10.0;
  static const int DEFAULT_MAX_REPULSION_ITERATIONS = 10;
  static const double DEFAULT_MOVEMENT_THRESHOLD = 1.0;

  EdgeRoutingConfig({
    this.anchorMode = DEFAULT_ANCHOR_MODE,
    this.routingMode = DEFAULT_ROUTING_MODE,
    this.enableRepulsion = DEFAULT_ENABLE_REPULSION,
    this.repulsionStrength = DEFAULT_REPULSION_STRENGTH,
    this.minEdgeDistance = DEFAULT_MIN_EDGE_DISTANCE,
    this.maxRepulsionIterations = DEFAULT_MAX_REPULSION_ITERATIONS,
    this.movementThreshold = DEFAULT_MOVEMENT_THRESHOLD,
  });

  AnchorMode getAnchorMode() {
    return anchorMode;
  }

  RoutingMode getRoutingMode() {
    return routingMode;
  }

  bool getEnableRepulsion() {
    return enableRepulsion;
  }

  double getRepulsionStrength() {
    return repulsionStrength;
  }

  double getMinEdgeDistance() {
    return minEdgeDistance;
  }

  int getMaxRepulsionIterations() {
    return maxRepulsionIterations;
  }

  double getMovementThreshold() {
    return movementThreshold;
  }
}

/// Anchor mode determines how edges connect to node boundaries.
///
/// Different modes provide trade-offs between performance and visual accuracy:
/// - [center]: Fastest, edges connect at node centers (default behavior)
/// - [cardinal]: Fast, edges connect at 4 compass points (N, S, E, W)
/// - [octagonal]: Moderate, edges connect at 8 compass points (N, NE, E, SE, S, SW, W, NW)
/// - [dynamic]: Most accurate, edges connect at exact perimeter intersection points
enum AnchorMode {
  /// Edges connect at node centers (default, backward compatible).
  center,

  /// Edges connect at 4 cardinal directions based on angle.
  cardinal,

  /// Edges connect at 8 octagonal directions based on angle.
  octagonal,

  /// Edges connect at exact perimeter intersection point for precise alignment.
  dynamic,
}

/// Routing mode determines how edge paths are generated between anchor points.
///
/// Different modes provide different visual styles:
/// - [direct]: Straight lines between anchor points (default, fastest)
/// - [orthogonal]: L-shaped Manhattan-style paths with right angles
/// - [bezier]: Smooth curved paths using control points
/// - [bundling]: Groups similar edges together to reduce visual clutter
enum RoutingMode {
  /// Direct straight line between anchor points (default).
  direct,

  /// L-shaped orthogonal paths with right angles (Manhattan distance).
  orthogonal,

  /// Smooth curved paths using bezier control points.
  bezier,

  /// Edge bundling groups similar edges together to reduce clutter.
  bundling,
}
