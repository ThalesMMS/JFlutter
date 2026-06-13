import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/GraphView.dart';
import 'package:jflutter/core/models/fsa_transition.dart';
import 'package:jflutter/core/models/state.dart' as automaton;
import 'package:jflutter/presentation/widgets/fsa/epsilon_transition_painter.dart';
import 'package:vector_math/vector_math_64.dart';

const _imageWidth = 140;
const _imageHeight = 110;

void main() {
  group('EpsilonTransitionPainter', () {
    test('keeps regular transition shafts solid', () async {
      final bytes = await _renderTransition(
        transition: _regularTransition(),
      );

      expect(_alphaAt(bytes, 20, 40), greaterThan(0));
    });

    test('renders epsilon transition shafts with transparent dash gaps',
        () async {
      final bytes = await _renderTransition(
        transition: _epsilonTransition(),
      );

      expect(_alphaAt(bytes, 20, 40), equals(0));
    });

    test('keeps highlighted epsilon transition shafts dashed', () async {
      final bytes = await _renderTransition(
        transition: _epsilonTransition(),
        isHighlighted: true,
      );

      expect(_alphaAt(bytes, 20, 40), equals(0));
    });

    test('renders epsilon self-loops with transparent dash gaps', () async {
      final bytes = await _renderTransition(
        transition: _selfLoopEpsilonTransition(),
        selfLoop: true,
      );

      expect(_alphaAt(bytes, 98, 60), equals(0));
    });
  });
}

Future<ByteData> _renderTransition({
  required FSATransition transition,
  bool isHighlighted = false,
  bool selfLoop = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final sourceNode = Node.Id('source')
    ..position = (selfLoop ? const Offset(70, 80) : const Offset(10, 40))
    ..size = const Size(20, 20);
  final destinationNode = selfLoop
      ? sourceNode
      : (Node.Id('destination')
        ..position = const Offset(120, 40)
        ..size = const Size(20, 20));
  final edge = Edge(sourceNode, destinationNode);

  EpsilonTransitionPainter(
    fsaTransition: transition,
    isHighlighted: isHighlighted,
  ).render(canvas, edge, Paint());

  final picture = recorder.endRecording();
  final image = await picture.toImage(_imageWidth, _imageHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();

  return bytes!;
}

int _alphaAt(ByteData bytes, int x, int y) {
  return bytes.getUint8((y * _imageWidth + x) * 4 + 3);
}

FSATransition _regularTransition() {
  return FSATransition.deterministic(
    id: 'regular',
    fromState: _state('q0'),
    toState: _state('q1'),
    symbol: 'a',
  );
}

FSATransition _epsilonTransition() {
  return FSATransition.epsilon(
    id: 'epsilon',
    fromState: _state('q0'),
    toState: _state('q1'),
  );
}

FSATransition _selfLoopEpsilonTransition() {
  final state = _state('q0');
  return FSATransition.epsilon(
    id: 'epsilon-loop',
    fromState: state,
    toState: state,
  );
}

automaton.State _state(String id) {
  return automaton.State(
    id: id,
    label: id,
    position: Vector2.zero(),
  );
}
