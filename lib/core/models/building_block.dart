import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:collection/collection.dart';

/// Represents a building block for L-system visualization
abstract class BuildingBlock {
  final String id;
  final double x;
  final double y;
  final Color color;
  final double thickness;

  const BuildingBlock({
    required this.id,
    required this.x,
    required this.y,
    required this.color,
    required this.thickness,
  });

  /// Creates a line building block
  factory BuildingBlock.line({
    required String id,
    required double startX,
    required double startY,
    required double endX,
    required double endY,
    required Color color,
    required double thickness,
  }) {
    return LineBuildingBlock(
      id: id,
      startX: startX,
      startY: startY,
      endX: endX,
      endY: endY,
      color: color,
      thickness: thickness,
    );
  }

  /// Creates a circle building block
  factory BuildingBlock.circle({
    required String id,
    required double centerX,
    required double centerY,
    required double radius,
    required Color color,
    required double thickness,
  }) {
    return CircleBuildingBlock(
      id: id,
      centerX: centerX,
      centerY: centerY,
      radius: radius,
      color: color,
      thickness: thickness,
    );
  }

  /// Creates a rectangle building block
  factory BuildingBlock.rectangle({
    required String id,
    required double x,
    required double y,
    required double width,
    required double height,
    required Color color,
    required double thickness,
  }) {
    return RectangleBuildingBlock(
      id: id,
      x: x,
      y: y,
      width: width,
      height: height,
      color: color,
      thickness: thickness,
    );
  }

  /// Creates a polygon building block
  factory BuildingBlock.polygon({
    required String id,
    required List<Offset> points,
    required Color color,
    required double thickness,
  }) {
    return PolygonBuildingBlock(
      id: id,
      points: points,
      color: color,
      thickness: thickness,
    );
  }

  /// Creates a text building block
  factory BuildingBlock.text({
    required String id,
    required double x,
    required double y,
    required String text,
    required Color color,
    required double fontSize,
  }) {
    return TextBuildingBlock(
      id: id,
      x: x,
      y: y,
      text: text,
      color: color,
      fontSize: fontSize,
    );
  }

  /// Gets the bounding box of the building block
  Rect get boundingBox;

  /// Checks if a point is inside the building block
  bool contains(Offset point);

  /// Creates a copy with updated properties
  BuildingBlock copyWith({
    String? id,
    double? x,
    double? y,
    Color? color,
    double? thickness,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is BuildingBlock &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.color == color &&
        other.thickness == thickness;
  }

  @override
  int get hashCode {
    return Object.hash(id, x, y, color, thickness);
  }
}

/// A line building block
class LineBuildingBlock extends BuildingBlock {
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  const LineBuildingBlock({
    required super.id,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required super.color,
    required super.thickness,
  }) : super(x: startX, y: startY);

  @override
  Rect get boundingBox {
    final left = math.min(startX, endX);
    final top = math.min(startY, endY);
    final right = math.max(startX, endX);
    final bottom = math.max(startY, endY);
    
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool contains(Offset point) {
    // Simple point-to-line distance check
    final lineLength = math.sqrt(math.pow(endX - startX, 2) + math.pow(endY - startY, 2));
    if (lineLength == 0) return false;
    
    final distance = ((endY - startY) * point.dx - (endX - startX) * point.dy + endX * startY - endY * startX).abs() / lineLength;
    return distance <= thickness / 2;
  }

  @override
  BuildingBlock copyWith({
    String? id,
    double? x,
    double? y,
    Color? color,
    double? thickness,
    double? startX,
    double? startY,
    double? endX,
    double? endY,
  }) {
    return LineBuildingBlock(
      id: id ?? this.id,
      startX: startX ?? this.startX,
      startY: startY ?? this.startY,
      endX: endX ?? this.endX,
      endY: endY ?? this.endY,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LineBuildingBlock &&
        super == other &&
        other.startX == startX &&
        other.startY == startY &&
        other.endX == endX &&
        other.endY == endY;
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, startX, startY, endX, endY);
  }

  @override
  String toString() {
    return 'LineBuildingBlock(id: $id, start: ($startX, $startY), end: ($endX, $endY), color: $color, thickness: $thickness)';
  }
}

/// A circle building block
class CircleBuildingBlock extends BuildingBlock {
  final double centerX;
  final double centerY;
  final double radius;

  const CircleBuildingBlock({
    required super.id,
    required this.centerX,
    required this.centerY,
    required this.radius,
    required super.color,
    required super.thickness,
  }) : super(x: centerX, y: centerY);

  @override
  Rect get boundingBox {
    return Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    );
  }

  @override
  bool contains(Offset point) {
    final distance = math.sqrt(math.pow(point.dx - centerX, 2) + math.pow(point.dy - centerY, 2));
    return distance <= radius;
  }

  @override
  BuildingBlock copyWith({
    String? id,
    double? x,
    double? y,
    Color? color,
    double? thickness,
    double? centerX,
    double? centerY,
    double? radius,
  }) {
    return CircleBuildingBlock(
      id: id ?? this.id,
      centerX: centerX ?? this.centerX,
      centerY: centerY ?? this.centerY,
      radius: radius ?? this.radius,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CircleBuildingBlock &&
        super == other &&
        other.centerX == centerX &&
        other.centerY == centerY &&
        other.radius == radius;
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, centerX, centerY, radius);
  }

  @override
  String toString() {
    return 'CircleBuildingBlock(id: $id, center: ($centerX, $centerY), radius: $radius, color: $color, thickness: $thickness)';
  }
}

/// A rectangle building block
class RectangleBuildingBlock extends BuildingBlock {
  final double width;
  final double height;

  const RectangleBuildingBlock({
    required super.id,
    required super.x,
    required super.y,
    required this.width,
    required this.height,
    required super.color,
    required super.thickness,
  });

  @override
  Rect get boundingBox {
    return Rect.fromLTWH(x, y, width, height);
  }

  @override
  bool contains(Offset point) {
    return boundingBox.contains(point);
  }

  @override
  BuildingBlock copyWith({
    String? id,
    double? x,
    double? y,
    Color? color,
    double? thickness,
    double? width,
    double? height,
  }) {
    return RectangleBuildingBlock(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is RectangleBuildingBlock &&
        super == other &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, width, height);
  }

  @override
  String toString() {
    return 'RectangleBuildingBlock(id: $id, position: ($x, $y), size: ($width, $height), color: $color, thickness: $thickness)';
  }
}

/// A polygon building block
class PolygonBuildingBlock extends BuildingBlock {
  final List<Offset> points;

  PolygonBuildingBlock({
    required super.id,
    required this.points,
    required super.color,
    required super.thickness,
  }) : super(x: points.isNotEmpty ? points.first.dx : 0, y: points.isNotEmpty ? points.first.dy : 0);

  @override
  Rect get boundingBox {
    if (points.isEmpty) return Rect.zero;
    
    double left = points.first.dx;
    double top = points.first.dy;
    double right = points.first.dx;
    double bottom = points.first.dy;
    
    for (final point in points) {
      left = math.min(left, point.dx);
      top = math.min(top, point.dy);
      right = math.max(right, point.dx);
      bottom = math.max(bottom, point.dy);
    }
    
    return Rect.fromLTRB(left, top, right, bottom);
  }

  @override
  bool contains(Offset point) {
    if (points.length < 3) return false;
    
    // Ray casting algorithm
    bool inside = false;
    for (int i = 0, j = points.length - 1; i < points.length; j = i++) {
      if (((points[i].dy > point.dy) != (points[j].dy > point.dy)) &&
          (point.dx < (points[j].dx - points[i].dx) * (point.dy - points[i].dy) / (points[j].dy - points[i].dy) + points[i].dx)) {
        inside = !inside;
      }
    }
    return inside;
  }

  @override
  BuildingBlock copyWith({
    String? id,
    double? x,
    double? y,
    Color? color,
    double? thickness,
    List<Offset>? points,
  }) {
    return PolygonBuildingBlock(
      id: id ?? this.id,
      points: points ?? this.points,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is PolygonBuildingBlock &&
        super == other &&
        const ListEquality().equals(other.points, points);
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, const ListEquality().hash(points));
  }

  @override
  String toString() {
    return 'PolygonBuildingBlock(id: $id, points: $points, color: $color, thickness: $thickness)';
  }
}

/// A text building block
class TextBuildingBlock extends BuildingBlock {
  final String text;
  final double fontSize;

  const TextBuildingBlock({
    required super.id,
    required super.x,
    required super.y,
    required this.text,
    required super.color,
    required this.fontSize,
  }) : super(thickness: 0);

  @override
  Rect get boundingBox {
    // Approximate text bounds
    final textWidth = text.length * fontSize * 0.6;
    final textHeight = fontSize;
    
    return Rect.fromLTWH(x, y - textHeight, textWidth, textHeight);
  }

  @override
  bool contains(Offset point) {
    return boundingBox.contains(point);
  }

  @override
  BuildingBlock copyWith({
    String? id,
    double? x,
    double? y,
    Color? color,
    double? thickness,
    String? text,
    double? fontSize,
  }) {
    return TextBuildingBlock(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      text: text ?? this.text,
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is TextBuildingBlock &&
        super == other &&
        other.text == text &&
        other.fontSize == fontSize;
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, text, fontSize);
  }

  @override
  String toString() {
    return 'TextBuildingBlock(id: $id, position: ($x, $y), text: $text, color: $color, fontSize: $fontSize)';
  }
}
