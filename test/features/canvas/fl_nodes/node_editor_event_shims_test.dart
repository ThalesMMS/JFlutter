import 'dart:ui';

import 'package:fl_nodes/fl_nodes.dart' as fl;
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/features/canvas/fl_nodes/node_editor_event_shims.dart';

base class DragSelectionEndEvent extends fl.NodeEditorEvent {
  DragSelectionEndEvent(
    this.position,
    this.nodeIds, {
    required super.id,
  });

  final Offset position;
  final Set<String> nodeIds;
}

base class LinkSelectionEvent extends fl.NodeEditorEvent {
  LinkSelectionEvent(
    this.linkIds, {
    required super.id,
  });

  final Set<String> linkIds;
}

base class LinkDeselectionEvent extends fl.NodeEditorEvent {
  LinkDeselectionEvent(
    this.linkIds, {
    required super.id,
  });

  final Set<String> linkIds;
}

base class RemoveLinkEvent extends fl.NodeEditorEvent {
  RemoveLinkEvent(
    this.link, {
    required super.id,
  });

  final fl.Link link;
}

base class _UnrelatedEvent extends fl.NodeEditorEvent {
  const _UnrelatedEvent() : super(id: 'other');
}

void main() {
  group('parseDragSelectionEndEvent', () {
    test('returns payload when node identifiers are available', () {
      final event = DragSelectionEndEvent(
        const Offset(12, 24),
        {'a', 'b'},
        id: 'drag',
      );

      final payload = parseDragSelectionEndEvent(event);

      expect(payload, isNotNull);
      expect(payload!.nodeIds, equals({'a', 'b'}));
      expect(payload.position, equals(const Offset(12, 24)));
    });

    test('returns null for unrelated events', () {
      final payload = parseDragSelectionEndEvent(const _UnrelatedEvent());
      expect(payload, isNull);
    });
  });

  group('parseLinkSelectionEvent', () {
    test('extracts link identifiers from selection events', () {
      final event = LinkSelectionEvent({'edge-1', 'edge-2'}, id: 'selection');

      final payload = parseLinkSelectionEvent(event);

      expect(payload, isNotNull);
      expect(payload!.linkIds, equals({'edge-1', 'edge-2'}));
    });

    test('ignores non-selection events', () {
      final payload = parseLinkSelectionEvent(const _UnrelatedEvent());
      expect(payload, isNull);
    });
  });

  group('parseLinkDeselectionEvent', () {
    test('extracts link identifiers from deselection events', () {
      final event = LinkDeselectionEvent({'edge-3'}, id: 'deselection');

      final payload = parseLinkDeselectionEvent(event);

      expect(payload, isNotNull);
      expect(payload!.linkIds, equals({'edge-3'}));
    });

    test('ignores non-deselection events', () {
      final payload = parseLinkDeselectionEvent(const _UnrelatedEvent());
      expect(payload, isNull);
    });
  });

  group('parseRemoveLinkEvent', () {
    test('returns the link associated with the removal event', () {
      final link = fl.Link(
        id: 'edge-42',
        fromTo: (
          from: 'from-node',
          to: 'to-node',
          fromPort: 'outgoing',
          toPort: 'incoming',
        ),
        state: fl.LinkState(),
      );
      final event = RemoveLinkEvent(link, id: 'remove');

      final payload = parseRemoveLinkEvent(event);

      expect(payload, isNotNull);
      expect(payload!.link, equals(link));
    });

    test('returns null for events without link data', () {
      final payload = parseRemoveLinkEvent(const _UnrelatedEvent());
      expect(payload, isNull);
    });
  });
}
