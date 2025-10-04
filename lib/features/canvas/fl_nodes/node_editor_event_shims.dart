import 'dart:ui';

import 'package:fl_nodes/fl_nodes.dart';

/// Payload extracted from drag-selection end events emitted by fl_nodes.
class DragSelectionEndEventPayload {
  const DragSelectionEndEventPayload({
    required this.nodeIds,
    this.position,
  });

  /// Identifiers of the nodes involved in the drag gesture.
  final Set<String> nodeIds;

  /// World-space position reported by the event, when available.
  final Offset? position;
}

/// Payload extracted from link-selection events emitted by fl_nodes.
class LinkSelectionEventPayload {
  const LinkSelectionEventPayload({required this.linkIds});

  /// Identifiers of the selected links.
  final Set<String> linkIds;
}

/// Payload extracted from link-deselection events emitted by fl_nodes.
class LinkDeselectionEventPayload {
  const LinkDeselectionEventPayload({required this.linkIds});

  /// Identifiers of the links that were deselected.
  final Set<String> linkIds;
}

/// Payload extracted from link-removal events emitted by fl_nodes.
class RemoveLinkEventPayload {
  const RemoveLinkEventPayload({required this.link});

  /// Link instance associated with the removal event.
  final Link link;
}

/// Attempts to coerce a drag-selection end event into a typed payload.
DragSelectionEndEventPayload? parseDragSelectionEndEvent(
  NodeEditorEvent event,
) {
  if (!_matchesRuntimeType(event, 'DragSelectionEndEvent')) {
    return null;
  }

  final dynamic dynamicEvent = event;

  final Set<String>? nodeIds = _extractIdSet(() {
    try {
      return dynamicEvent.nodeIds;
    } catch (_) {
      return null;
    }
  });

  if (nodeIds == null) {
    return null;
  }

  final Offset? position = _extractOffset(() {
    try {
      return dynamicEvent.position;
    } catch (_) {
      return null;
    }
  });

  return DragSelectionEndEventPayload(
    nodeIds: nodeIds,
    position: position,
  );
}

/// Attempts to coerce a link-selection event into a typed payload.
LinkSelectionEventPayload? parseLinkSelectionEvent(NodeEditorEvent event) {
  if (!_matchesRuntimeType(event, 'LinkSelectionEvent')) {
    return null;
  }

  final dynamic dynamicEvent = event;
  final Set<String>? linkIds = _extractIdSet(() {
    try {
      return dynamicEvent.linkIds;
    } catch (_) {
      return null;
    }
  });

  if (linkIds == null) {
    return null;
  }

  return LinkSelectionEventPayload(linkIds: linkIds);
}

/// Attempts to coerce a link-deselection event into a typed payload.
LinkDeselectionEventPayload? parseLinkDeselectionEvent(
  NodeEditorEvent event,
) {
  if (!_matchesRuntimeType(event, 'LinkDeselectionEvent')) {
    return null;
  }

  final dynamic dynamicEvent = event;
  final Set<String>? linkIds = _extractIdSet(() {
    try {
      return dynamicEvent.linkIds;
    } catch (_) {
      return null;
    }
  });

  if (linkIds == null) {
    return null;
  }

  return LinkDeselectionEventPayload(linkIds: linkIds);
}

/// Attempts to coerce a link-removal event into a typed payload.
RemoveLinkEventPayload? parseRemoveLinkEvent(NodeEditorEvent event) {
  if (!_matchesRuntimeType(event, 'RemoveLinkEvent')) {
    return null;
  }

  final dynamic dynamicEvent = event;
  try {
    final dynamic candidate = dynamicEvent.link;
    if (candidate is Link) {
      return RemoveLinkEventPayload(link: candidate);
    }
  } catch (_) {
    return null;
  }

  return null;
}

bool _matchesRuntimeType(NodeEditorEvent event, String expectedName) {
  final String typeName = event.runtimeType.toString();
  if (typeName == expectedName) {
    return true;
  }
  if (typeName.endsWith('.$expectedName')) {
    return true;
  }
  return false;
}

Set<String>? _extractIdSet(dynamic Function() accessor) {
  try {
    final dynamic value = accessor();
    if (value == null) {
      return null;
    }

    if (value is Set<String>) {
      return Set<String>.unmodifiable(value);
    }
    if (value is Iterable) {
      final Set<String> ids = <String>{};
      for (final dynamic element in value) {
        final String? id = _extractId(element);
        if (id != null) {
          ids.add(id);
        }
      }
      if (ids.isNotEmpty) {
        return Set<String>.unmodifiable(ids);
      }
      if (value is Iterable && value.isEmpty) {
        return const <String>{};
      }
      return null;
    }

    final String? id = _extractId(value);
    if (id != null) {
      return Set<String>.unmodifiable(<String>{id});
    }
  } catch (_) {
    return null;
  }

  return null;
}

String? _extractId(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return value;
  }

  if (value is Map) {
    final dynamic idCandidate =
        value['id'] ?? value['linkId'] ?? value['nodeId'];
    if (idCandidate is String && idCandidate.isNotEmpty) {
      return idCandidate;
    }
  }

  try {
    final dynamic candidate = value.id;
    if (candidate is String && candidate.isNotEmpty) {
      return candidate;
    }
  } catch (_) {
    // Ignore and continue exploring other shapes.
  }

  try {
    final dynamic candidate = value.linkId;
    if (candidate is String && candidate.isNotEmpty) {
      return candidate;
    }
  } catch (_) {
    // Ignore and continue exploring other shapes.
  }

  try {
    final dynamic candidate = value.nodeId;
    if (candidate is String && candidate.isNotEmpty) {
      return candidate;
    }
  } catch (_) {
    // Ignore and continue exploring other shapes.
  }

  return null;
}

Offset? _extractOffset(dynamic Function() accessor) {
  try {
    final dynamic value = accessor();
    if (value is Offset) {
      return value;
    }
    if (value is List && value.length >= 2) {
      final dynamic dx = value[0];
      final dynamic dy = value[1];
      if (dx is num && dy is num) {
        return Offset(dx.toDouble(), dy.toDouble());
      }
    }
    if (value is Map) {
      final dynamic dx = value['dx'] ?? value['x'];
      final dynamic dy = value['dy'] ?? value['y'];
      if (dx is num && dy is num) {
        return Offset(dx.toDouble(), dy.toDouble());
      }
    }
  } catch (_) {
    return null;
  }

  return null;
}
