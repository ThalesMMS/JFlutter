import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:jflutter/core/models/state.dart' as automaton_state;
import 'package:jflutter/presentation/widgets/automaton_canvas/index.dart';

Future<bool> _hasStrokeNear(ui.Image image, Offset point, {int radius = 3}) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (byteData == null) {
    return false;
  }

  final width = image.width;
  final height = image.height;
  final minX = math.max(0, point.dx.round() - radius).toInt();
  final maxX = math.min(width - 1, point.dx.round() + radius).toInt();
  final minY = math.max(0, point.dy.round() - radius).toInt();
  final maxY = math.min(height - 1, point.dy.round() + radius).toInt();

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final offset = (y * width + x) * 4;
      final alpha = byteData.getUint8(offset + 3);
      if (alpha > 0) {
        return true;
      }
    }
  }

  return false;
}

Future<ui.Image> _renderPainter(AutomatonPainter painter, Size size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  painter.paint(canvas, size);
  final picture = recorder.endRecording();
  return picture.toImage(size.width.toInt(), size.height.toInt());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonPainter transition preview', () {
    final startState = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2(120, 120),
      isInitial: true,
    );

    test('draws directional preview curve toward pointer', () async {
      final pointer = const Offset(240, 160);
      final painter = AutomatonPainter(
        states: [startState],
        transitions: const [],
        selectedState: null,
        transitionStart: startState,
        transitionPreviewPosition: pointer,
      );

      final image = await _renderPainter(painter, const Size(400, 300));
      expect(await _hasStrokeNear(image, pointer, radius: 6), isTrue);
    });

    test('draws self-loop preview when pointer stays near state', () async {
      final pointer = const Offset(125, 120);
      final painter = AutomatonPainter(
        states: [startState],
        transitions: const [],
        selectedState: null,
        transitionStart: startState,
        transitionPreviewPosition: pointer,
      );

      final image = await _renderPainter(painter, const Size(300, 240));
      final loopSamplePoint = Offset(startState.position.x, startState.position.y - 65);
      expect(await _hasStrokeNear(image, loopSamplePoint, radius: 5), isTrue);
    });
  });
}
