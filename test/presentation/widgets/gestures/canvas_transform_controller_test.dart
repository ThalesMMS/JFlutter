import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/gestures/canvas_transform_controller.dart';

void main() {
  group('CanvasTransformController', () {
    test('converts local coordinates to canvas coordinates with no transform', () {
      final controller = CanvasTransformController();

      const position = Offset(100, 50);
      expect(controller.toCanvasCoordinates(position), equals(position));
    });

    test('applies pan offset when converting coordinates', () {
      final controller = CanvasTransformController();

      controller.beginPan();
      controller.updatePan(const Offset(20, -10));

      final canvasPoint = controller.toCanvasCoordinates(const Offset(30, 10));
      expect(canvasPoint, const Offset(10, 20));
    });

    test('applies scaling when converting coordinates', () {
      final controller = CanvasTransformController();

      controller.beginZoom();
      controller.updateZoom(2.0, Offset.zero);

      final canvasPoint = controller.toCanvasCoordinates(const Offset(40, 0));
      expect(canvasPoint, const Offset(20, 0));
    });

    test('clamps zoom according to limits', () {
      final controller = CanvasTransformController(minScale: 0.5, maxScale: 2.0);

      controller.beginZoom();
      controller.updateZoom(10.0, Offset.zero);
      expect(controller.scale, equals(2.0));

      controller.beginZoom();
      controller.updateZoom(0.01, Offset.zero);
      expect(controller.scale, equals(0.5));
    });
  });
}
