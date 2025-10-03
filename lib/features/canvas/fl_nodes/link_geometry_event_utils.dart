import 'dart:ui';

import 'package:fl_nodes/fl_nodes.dart';
import 'package:vector_math/vector_math_64.dart';

/// Payload extracted from fl_nodes link geometry events.
class LinkGeometryEventPayload {
  const LinkGeometryEventPayload({
    required this.linkId,
    required this.hasControlPoint,
    required this.controlPoint,
  });

  /// Identifier of the link whose geometry changed.
  final String linkId;

  /// Whether the upstream event explicitly carried control point data.
  final bool hasControlPoint;

  /// Updated world-space control point for the link curve.
  ///
  /// When `null`, the control point should be cleared or reset to default.
  final Offset? controlPoint;
}

/// Attempts to parse a link-geometry event emitted by fl_nodes.
///
/// The upstream package currently exposes a number of internal events for
/// control-point interactions (e.g. [LinkControlPointDragEvent]). These types
/// are not part of the public API, so this helper defensively inspects the
/// incoming [event] using `dynamic` accessors and returns a strongly-typed
/// payload when it recognises the expected shape.
LinkGeometryEventPayload? parseLinkGeometryEvent(NodeEditorEvent event) {
  final String? linkId = _readLinkId(event);
  if (linkId == null) {
    return null;
  }

  final (_ControlPointReadState state, Offset? controlPoint) =
      _readControlPoint(event);

  if (state == _ControlPointReadState.notFound) {
    return null;
  }

  return LinkGeometryEventPayload(
    linkId: linkId,
    hasControlPoint: state == _ControlPointReadState.found,
    controlPoint: controlPoint,
  );
}

String? _readLinkId(NodeEditorEvent event) {
  final dynamic dynamicEvent = event;
  try {
    final dynamic candidate = dynamicEvent.linkId;
    if (candidate is String && candidate.isNotEmpty) {
      return candidate;
    }
  } catch (_) {
    // Fall back to other shapes.
  }

  try {
    final dynamic link = dynamicEvent.link;
    if (link is Link) {
      return link.id;
    }
    if (link is Map) {
      final dynamic id = link['id'];
      if (id is String && id.isNotEmpty) {
        return id;
      }
    }
  } catch (_) {
    // Ignore – not the expected shape.
  }

  return null;
}

enum _ControlPointReadState { found, notFound }

(_ControlPointReadState, Offset?) _readControlPoint(NodeEditorEvent event) {
  final dynamic dynamicEvent = event;

  final Iterable<String> candidatePropertyNames = <String>[
    'controlPoint',
    'worldControlPoint',
    'position',
    'worldPosition',
    'offset',
    'anchor',
    'point',
  ];

  for (final property in candidatePropertyNames) {
    try {
      final dynamic value = switch (property) {
        'controlPoint' => dynamicEvent.controlPoint,
        'worldControlPoint' => dynamicEvent.worldControlPoint,
        'position' => dynamicEvent.position,
        'worldPosition' => dynamicEvent.worldPosition,
        'offset' => dynamicEvent.offset,
        'anchor' => dynamicEvent.anchor,
        'point' => dynamicEvent.point,
        _ => null,
      };

      final bool propertyWasPresent = value != null ||
          _hasProperty(dynamicEvent, property);

      if (!propertyWasPresent) {
        continue;
      }

      return (
        _ControlPointReadState.found,
        _coerceToOffset(value),
      );
    } catch (_) {
      // Try the next property name.
      continue;
    }
  }

  return (_ControlPointReadState.notFound, null);
}

bool _hasProperty(dynamic event, String property) {
  try {
    switch (property) {
      case 'controlPoint':
        event.controlPoint;
        return true;
      case 'worldControlPoint':
        event.worldControlPoint;
        return true;
      case 'position':
        event.position;
        return true;
      case 'worldPosition':
        event.worldPosition;
        return true;
      case 'offset':
        event.offset;
        return true;
      case 'anchor':
        event.anchor;
        return true;
      case 'point':
        event.point;
        return true;
    }
  } catch (_) {
    return false;
  }

  return false;
}

Offset? _coerceToOffset(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Offset) {
    return value;
  }
  if (value is Vector2) {
    return Offset(value.x, value.y);
  }
  if (value is List && value.length >= 2) {
    final dynamic first = value[0];
    final dynamic second = value[1];
    if (first is num && second is num) {
      return Offset(first.toDouble(), second.toDouble());
    }
  }
  if (value is Map) {
    final dynamic dx = value['dx'] ?? value['x'];
    final dynamic dy = value['dy'] ?? value['y'];
    if (dx is num && dy is num) {
      return Offset(dx.toDouble(), dy.toDouble());
    }
  }
  return null;
}
