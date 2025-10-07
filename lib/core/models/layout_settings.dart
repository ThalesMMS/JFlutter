//
//  layout_settings.dart
//  JFlutter
//
//  Encapsula preferências visuais do canvas, como raios de nós, espessuras de
//  arestas, esquema de cores e grade, permitindo persistência e clonagem
//  imutável. Serve de base para personalizar experiências entre plataformas e
//  sincronizar o layout entre sessões do usuário.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

/// Layout settings for mobile UI
class LayoutSettings {
  /// Radius of state nodes
  final double nodeRadius;

  /// Thickness of transition edges
  final double edgeThickness;

  /// Color scheme for the layout
  final ColorScheme colorScheme;

  /// Whether to show the grid
  final bool showGrid;

  /// Whether to snap to grid
  final bool snapToGrid;

  /// Size of the grid
  final double gridSize;

  const LayoutSettings({
    this.nodeRadius = 20.0,
    this.edgeThickness = 2.0,
    this.colorScheme = const ColorScheme.light(),
    this.showGrid = false,
    this.snapToGrid = false,
    this.gridSize = 20.0,
  });

  /// Creates a copy of this layout settings with updated properties
  LayoutSettings copyWith({
    double? nodeRadius,
    double? edgeThickness,
    ColorScheme? colorScheme,
    bool? showGrid,
    bool? snapToGrid,
    double? gridSize,
  }) {
    return LayoutSettings(
      nodeRadius: nodeRadius ?? this.nodeRadius,
      edgeThickness: edgeThickness ?? this.edgeThickness,
      colorScheme: colorScheme ?? this.colorScheme,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      gridSize: gridSize ?? this.gridSize,
    );
  }

  /// Converts the layout settings to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'nodeRadius': nodeRadius,
      'edgeThickness': edgeThickness,
      'colorScheme': {
        'primary': colorScheme.primary.value,
        'secondary': colorScheme.secondary.value,
        'surface': colorScheme.surface.value,
        'background': colorScheme.surface.value,
        'error': colorScheme.error.value,
        'onPrimary': colorScheme.onPrimary.value,
        'onSecondary': colorScheme.onSecondary.value,
        'onSurface': colorScheme.onSurface.value,
        'onBackground': colorScheme.onSurface.value,
        'onError': colorScheme.onError.value,
      },
      'showGrid': showGrid,
      'snapToGrid': snapToGrid,
      'gridSize': gridSize,
    };
  }

  /// Creates layout settings from a JSON representation
  factory LayoutSettings.fromJson(Map<String, dynamic> json) {
    const defaultScheme = ColorScheme.light();
    final colorSchemeData = (json['colorScheme'] as Map?)
        ?.cast<String, dynamic>();

    return LayoutSettings(
      nodeRadius: (json['nodeRadius'] as num?)?.toDouble() ?? 20.0,
      edgeThickness: (json['edgeThickness'] as num?)?.toDouble() ?? 2.0,
      colorScheme: colorSchemeData == null
          ? defaultScheme
          : ColorScheme.light(
              primary: _colorFromJson(
                colorSchemeData,
                'primary',
                defaultScheme.primary,
              ),
              secondary: _colorFromJson(
                colorSchemeData,
                'secondary',
                defaultScheme.secondary,
              ),
              surface: _colorFromJson(
                colorSchemeData,
                'surface',
                defaultScheme.surface,
              ),
              error: _colorFromJson(
                colorSchemeData,
                'error',
                defaultScheme.error,
              ),
              onPrimary: _colorFromJson(
                colorSchemeData,
                'onPrimary',
                defaultScheme.onPrimary,
              ),
              onSecondary: _colorFromJson(
                colorSchemeData,
                'onSecondary',
                defaultScheme.onSecondary,
              ),
              onSurface: _colorFromJson(
                colorSchemeData,
                'onSurface',
                defaultScheme.onSurface,
              ),
              onError: _colorFromJson(
                colorSchemeData,
                'onError',
                defaultScheme.onError,
              ),
            ),
      showGrid: json['showGrid'] as bool? ?? false,
      snapToGrid: json['snapToGrid'] as bool? ?? false,
      gridSize: (json['gridSize'] as num?)?.toDouble() ?? 20.0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LayoutSettings &&
        other.nodeRadius == nodeRadius &&
        other.edgeThickness == edgeThickness &&
        other.colorScheme == colorScheme &&
        other.showGrid == showGrid &&
        other.snapToGrid == snapToGrid &&
        other.gridSize == gridSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      nodeRadius,
      edgeThickness,
      colorScheme,
      showGrid,
      snapToGrid,
      gridSize,
    );
  }

  @override
  String toString() {
    return 'LayoutSettings(nodeRadius: $nodeRadius, edgeThickness: $edgeThickness, showGrid: $showGrid, snapToGrid: $snapToGrid, gridSize: $gridSize)';
  }

  /// Gets the diameter of state nodes
  double get nodeDiameter => nodeRadius * 2;

  /// Gets the minimum touch target size (44dp for accessibility)
  double get minTouchTargetSize => 44.0;

  /// Checks if the node radius meets accessibility requirements
  bool get meetsAccessibilityRequirements => nodeDiameter >= minTouchTargetSize;

  /// Gets the recommended node radius for accessibility
  double get accessibleNodeRadius => minTouchTargetSize / 2;

  /// Gets the grid step size
  double get gridStep => gridSize;

  /// Gets the half grid step size
  double get halfGridStep => gridSize / 2;

  /// Gets the quarter grid step size
  double get quarterGridStep => gridSize / 4;

  /// Checks if a position should snap to grid
  bool shouldSnapToGrid(Vector2 position) {
    if (!snapToGrid) return false;

    final snappedX = (position.x / gridSize).round() * gridSize;
    final snappedY = (position.y / gridSize).round() * gridSize;

    return (position.x - snappedX).abs() < 5.0 &&
        (position.y - snappedY).abs() < 5.0;
  }

  /// Snaps a position to the grid
  Vector2 snapPositionToGrid(Vector2 position) {
    if (!snapToGrid) return position;

    return Vector2(
      (position.x / gridSize).round() * gridSize,
      (position.y / gridSize).round() * gridSize,
    );
  }

  /// Gets the grid position for a given position
  Vector2 getGridPosition(Vector2 position) {
    return Vector2(
      (position.x / gridSize).floor() * gridSize,
      (position.y / gridSize).floor() * gridSize,
    );
  }

  /// Gets the grid cell index for a given position
  Vector2 getGridCell(Vector2 position) {
    return Vector2(
      (position.x / gridSize).floor().toDouble(),
      (position.y / gridSize).floor().toDouble(),
    );
  }

  /// Gets the position for a given grid cell
  Vector2 getPositionFromGridCell(Vector2 cell) {
    return Vector2(cell.x * gridSize, cell.y * gridSize);
  }

  /// Creates default layout settings
  factory LayoutSettings.defaultSettings() {
    return const LayoutSettings();
  }

  /// Creates layout settings optimized for mobile
  factory LayoutSettings.mobileOptimized() {
    return const LayoutSettings(
      nodeRadius: 25.0, // Larger for touch
      edgeThickness: 3.0, // Thicker for visibility
      showGrid: true,
      snapToGrid: true,
      gridSize: 25.0, // Larger grid for touch
    );
  }

  /// Creates layout settings optimized for accessibility
  factory LayoutSettings.accessibilityOptimized() {
    return const LayoutSettings(
      nodeRadius: 30.0, // Larger for accessibility
      edgeThickness: 4.0, // Thicker for visibility
      showGrid: true,
      snapToGrid: true,
      gridSize: 30.0, // Larger grid for accessibility
    );
  }

  /// Creates layout settings optimized for small screens
  factory LayoutSettings.smallScreenOptimized() {
    return const LayoutSettings(
      nodeRadius: 15.0, // Smaller for small screens
      edgeThickness: 2.0,
      showGrid: false,
      snapToGrid: false,
      gridSize: 15.0,
    );
  }

  /// Creates layout settings optimized for large screens
  factory LayoutSettings.largeScreenOptimized() {
    return const LayoutSettings(
      nodeRadius: 30.0, // Larger for large screens
      edgeThickness: 3.0,
      showGrid: true,
      snapToGrid: true,
      gridSize: 30.0,
    );
  }
}

Color _colorFromJson(Map<String, dynamic>? data, String key, Color fallback) {
  final value = data?[key];
  if (value is int) {
    return Color(value);
  }
  return fallback;
}
