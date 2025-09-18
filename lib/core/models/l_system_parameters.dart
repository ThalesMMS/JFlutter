import 'package:flutter/material.dart';

/// Parameters for rendering L-systems
class LSystemParameters {
  final double initialX;
  final double initialY;
  final double initialAngle;
  final double stepSize;
  final double angleIncrement;
  final Color lineColor;
  final double lineThickness;
  final Color backgroundColor;
  final bool showGrid;
  final double gridSize;
  final Color gridColor;

  const LSystemParameters({
    this.initialX = 0.0,
    this.initialY = 0.0,
    this.initialAngle = 0.0,
    this.stepSize = 10.0,
    this.angleIncrement = 90.0,
    this.lineColor = Colors.black,
    this.lineThickness = 2.0,
    this.backgroundColor = Colors.white,
    this.showGrid = false,
    this.gridSize = 20.0,
    this.gridColor = Colors.grey,
  });

  /// Creates parameters for the dragon curve
  factory LSystemParameters.dragon() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 5.0,
      angleIncrement: 90.0,
      lineColor: Colors.blue,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the Sierpinski triangle
  factory LSystemParameters.sierpinski() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 8.0,
      angleIncrement: 120.0,
      lineColor: Colors.red,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the Koch curve
  factory LSystemParameters.koch() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 6.0,
      angleIncrement: 90.0,
      lineColor: Colors.green,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the Hilbert curve
  factory LSystemParameters.hilbert() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 4.0,
      angleIncrement: 90.0,
      lineColor: Colors.purple,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the Peano curve
  factory LSystemParameters.peano() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 3.0,
      angleIncrement: 90.0,
      lineColor: Colors.orange,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the Gosper curve
  factory LSystemParameters.gosper() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 4.0,
      angleIncrement: 60.0,
      lineColor: Colors.teal,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the snowflake
  factory LSystemParameters.snowflake() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 0.0,
      stepSize: 6.0,
      angleIncrement: 60.0,
      lineColor: Colors.cyan,
      lineThickness: 2.0,
    );
  }

  /// Creates parameters for the plant
  factory LSystemParameters.plant() {
    return const LSystemParameters(
      initialX: 0.0,
      initialY: 0.0,
      initialAngle: 90.0,
      stepSize: 8.0,
      angleIncrement: 25.0,
      lineColor: Colors.green,
      lineThickness: 2.0,
    );
  }

  /// Validates the parameters
  bool isValid() {
    return stepSize > 0 &&
        angleIncrement >= 0 &&
        angleIncrement < 360 &&
        lineThickness > 0 &&
        gridSize > 0;
  }

  /// Creates a copy with updated properties
  LSystemParameters copyWith({
    double? initialX,
    double? initialY,
    double? initialAngle,
    double? stepSize,
    double? angleIncrement,
    Color? lineColor,
    double? lineThickness,
    Color? backgroundColor,
    bool? showGrid,
    double? gridSize,
    Color? gridColor,
  }) {
    return LSystemParameters(
      initialX: initialX ?? this.initialX,
      initialY: initialY ?? this.initialY,
      initialAngle: initialAngle ?? this.initialAngle,
      stepSize: stepSize ?? this.stepSize,
      angleIncrement: angleIncrement ?? this.angleIncrement,
      lineColor: lineColor ?? this.lineColor,
      lineThickness: lineThickness ?? this.lineThickness,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showGrid: showGrid ?? this.showGrid,
      gridSize: gridSize ?? this.gridSize,
      gridColor: gridColor ?? this.gridColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LSystemParameters &&
        other.initialX == initialX &&
        other.initialY == initialY &&
        other.initialAngle == initialAngle &&
        other.stepSize == stepSize &&
        other.angleIncrement == angleIncrement &&
        other.lineColor == lineColor &&
        other.lineThickness == lineThickness &&
        other.backgroundColor == backgroundColor &&
        other.showGrid == showGrid &&
        other.gridSize == gridSize &&
        other.gridColor == gridColor;
  }

  @override
  int get hashCode {
    return Object.hash(
      initialX,
      initialY,
      initialAngle,
      stepSize,
      angleIncrement,
      lineColor,
      lineThickness,
      backgroundColor,
      showGrid,
      gridSize,
      gridColor,
    );
  }

  @override
  String toString() {
    return 'LSystemParameters(initialX: $initialX, initialY: $initialY, initialAngle: $initialAngle, stepSize: $stepSize, angleIncrement: $angleIncrement)';
  }
}
