part of graphview;

/// Configuration for the Fruchterman-Reingold force-directed layout algorithm.
///
/// This class controls the behavior of the force-directed graph layout,
/// including repulsion and attraction forces, iteration count, and optional
/// Barnes-Hut optimization for large graphs.
class FruchtermanReingoldConfiguration {
  /// Default number of iterations for the force simulation.
  static const int DEFAULT_ITERATIONS = 100;

  /// Default strength of repulsion force between nodes.
  static const double DEFAULT_REPULSION_RATE = 0.2;

  /// Default maximum distance for repulsion as a percentage of graph dimensions.
  static const double DEFAULT_REPULSION_PERCENTAGE = 0.4;

  /// Default strength of attraction force along edges.
  static const double DEFAULT_ATTRACTION_RATE = 0.15;

  /// Default attraction percentage (reserved for future use).
  static const double DEFAULT_ATTRACTION_PERCENTAGE = 0.15;

  /// Default padding between disconnected clusters.
  static const int DEFAULT_CLUSTER_PADDING = 15;

  /// Default minimum threshold to prevent division by zero in force calculations.
  static const double DEFAULT_EPSILON = 0.0001;

  /// Default interpolation factor for smooth position updates (0.0-1.0).
  static const double DEFAULT_LERP_FACTOR = 0.05;

  /// Default threshold for detecting convergence (reserved for future use).
  static const double DEFAULT_MOVEMENT_THRESHOLD = 0.6;

  /// Default setting for Barnes-Hut optimization (disabled by default).
  static const bool DEFAULT_USE_BARNES_HUT = false;

  /// Default theta parameter for Barnes-Hut approximation (lower = more accurate).
  static const double DEFAULT_THETA = 0.5;

  /// Number of iterations to run the force simulation.
  ///
  /// More iterations generally produce better layouts but take longer to compute.
  int iterations;

  /// Strength multiplier for repulsion forces between nodes.
  ///
  /// Higher values push nodes further apart. Typical range: 0.1 - 0.5.
  double repulsionRate;

  /// Maximum distance for repulsion as a percentage of graph dimensions.
  ///
  /// Nodes further apart than this distance do not repel each other.
  /// Typical range: 0.3 - 0.5.
  double repulsionPercentage;

  /// Strength multiplier for attraction forces along edges.
  ///
  /// Higher values pull connected nodes closer together. Typical range: 0.1 - 0.3.
  double attractionRate;

  /// Attraction percentage (reserved for future use).
  double attractionPercentage;

  /// Padding between disconnected graph clusters in pixels.
  int clusterPadding;

  /// Minimum threshold to prevent division by zero in distance calculations.
  ///
  /// Should be a small positive value, typically 0.0001.
  double epsilon;

  /// Interpolation factor for smoothing position updates.
  ///
  /// Lower values (0.01-0.05) create smoother animations but slower convergence.
  /// Higher values (0.1-0.3) converge faster but may appear jerky.
  /// Range: 0.0 (no movement) to 1.0 (instant movement).
  double lerpFactor;

  /// Movement threshold for detecting convergence (reserved for future use).
  double movementThreshold;

  /// Whether to randomize node positions at initialization.
  ///
  /// If true, nodes start at random positions. If false, they keep their
  /// current positions, which is useful for incremental layouts.
  bool shuffleNodes = true;

  /// Whether to use Barnes-Hut algorithm for repulsion calculations.
  ///
  /// When enabled, reduces repulsion complexity from O(n²) to O(n log n)
  /// for large graphs (recommended for 100+ nodes). May be slightly less
  /// accurate than the naive O(n²) approach.
  bool useBarnesHut;

  /// Theta parameter for Barnes-Hut approximation accuracy.
  ///
  /// Lower values (0.3-0.5) are more accurate but slower.
  /// Higher values (0.7-1.0) are faster but less accurate.
  /// Typical value: 0.5. Only used when useBarnesHut is true.
  double theta;

  FruchtermanReingoldConfiguration({
    this.iterations = DEFAULT_ITERATIONS,
    this.repulsionRate = DEFAULT_REPULSION_RATE,
    this.attractionRate = DEFAULT_ATTRACTION_RATE,
    this.repulsionPercentage = DEFAULT_REPULSION_PERCENTAGE,
    this.attractionPercentage = DEFAULT_ATTRACTION_PERCENTAGE,
    this.clusterPadding = DEFAULT_CLUSTER_PADDING,
    this.epsilon = DEFAULT_EPSILON,
    this.lerpFactor = DEFAULT_LERP_FACTOR,
    this.movementThreshold = DEFAULT_MOVEMENT_THRESHOLD,
    this.shuffleNodes = true,
    this.useBarnesHut = DEFAULT_USE_BARNES_HUT,
    this.theta = DEFAULT_THETA
  });

}