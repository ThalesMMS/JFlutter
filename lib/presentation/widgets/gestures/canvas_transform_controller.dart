import 'package:flutter/material.dart';

/// Manages pan and zoom transformations applied to the canvas.
class CanvasTransformController {
  CanvasTransformController({
    this.minScale = 0.5,
    this.maxScale = 3.0,
    double initialScale = 1.0,
    Offset initialPanOffset = Offset.zero,
  })  : _scale = initialScale,
        _panOffset = initialPanOffset,
        _initialScale = initialScale,
        _initialPanOffset = initialPanOffset;

  final double minScale;
  final double maxScale;

  double _scale;
  double _initialScale;
  Offset _panOffset;
  Offset _initialPanOffset;
  bool _isPanning = false;
  bool _isZooming = false;

  double get scale => _scale;
  Offset get panOffset => _panOffset;
  bool get isPanning => _isPanning;
  bool get isZooming => _isZooming;

  /// Converts a position from the local widget coordinates to canvas coordinates
  /// taking current pan and zoom into account.
  Offset toCanvasCoordinates(Offset position) {
    final translated = position - _panOffset;
    if (_scale == 0) {
      return translated;
    }
    return Offset(translated.dx / _scale, translated.dy / _scale);
  }

  /// Starts a panning gesture.
  void beginPan() {
    _isPanning = true;
    _isZooming = false;
  }

  /// Starts a zooming gesture, preserving the initial scale and offset
  /// so that deltas can be accumulated during the gesture.
  void beginZoom() {
    _isZooming = true;
    _isPanning = false;
    _initialScale = _scale;
    _initialPanOffset = _panOffset;
  }

  /// Applies a pan delta.
  void updatePan(Offset focalPointDelta) {
    if (!_isPanning) {
      return;
    }
    _panOffset += focalPointDelta;
  }

  /// Applies zoom and pan deltas when performing a multi-touch interaction.
  void updateZoom(double scaleDelta, Offset focalPointDelta) {
    if (!_isZooming) {
      return;
    }
    final newScale = _initialScale * scaleDelta;
    _scale = newScale.clamp(minScale, maxScale);
    _panOffset = _initialPanOffset + focalPointDelta;
  }

  /// Ends the current gesture interaction, clearing transient state.
  void endInteraction() {
    _isPanning = false;
    _isZooming = false;
  }
}
