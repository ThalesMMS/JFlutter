part of graphview;

class ContainerX {
  List<Segment> segments = [];
  int index = -1;
  int pos = -1;
  double measure = -1;

  ContainerX();

  void append(Segment segment) {
    segments.add(segment);
  }

  void join(ContainerX other) {
    segments.addAll(other.segments);
    other.segments.clear();
  }

  int size() => segments.length;

  bool contains(Segment segment) => segments.contains(segment);

  bool get isEmpty => segments.isEmpty;

  static ContainerX createEmpty() => ContainerX();

  // Split container at segment position
  static ContainerPair split(ContainerX container, Segment key) {
    final index = container.segments.indexOf(key);
    if (index == -1) {
      return ContainerPair(container, ContainerX());
    }

    final leftSegments = container.segments.sublist(0, index);
    final rightSegments = container.segments.sublist(index + 1);

    final leftContainer = ContainerX();
    leftContainer.segments = leftSegments;

    final rightContainer = ContainerX();
    rightContainer.segments = rightSegments;

    return ContainerPair(leftContainer, rightContainer);
  }

  // Split container at position
  static ContainerPair splitAt(ContainerX container, int position) {
    if (position <= 0) {
      return ContainerPair(ContainerX(), container);
    }
    if (position >= container.size()) {
      return ContainerPair(container, ContainerX());
    }

    final leftSegments = container.segments.sublist(0, position);
    final rightSegments = container.segments.sublist(position);

    final leftContainer = ContainerX();
    leftContainer.segments = leftSegments;

    final rightContainer = ContainerX();
    rightContainer.segments = rightSegments;

    return ContainerPair(leftContainer, rightContainer);
  }

  @override
  String toString() =>
      'Container(${segments.length} segments, pos: $pos, measure: $measure)';
}

class ContainerPair {
  final ContainerX left;
  final ContainerX right;

  ContainerPair(this.left, this.right);
}

// Segment represents a vertical edge span between P and Q vertices
class Segment {
  final Node pVertex; // top vertex (P-vertex)
  final Node qVertex; // bottom vertex (Q-vertex)
  int index = -1;
  final int id;

  static int _nextId = 0;

  Segment(this.pVertex, this.qVertex) : id = _nextId++;

  static void resetIds() {
    _nextId = 0;
  }

  @override
  bool operator ==(Object other) => identical(this, other);

  @override
  int get hashCode => id;

  @override
  String toString() => 'Segment($id)';
}

// Virtual edge for container connections
class VirtualEdge {
  final Object source;
  final Object target;
  final int weight;

  VirtualEdge(this.source, this.target, this.weight);

  @override
  String toString() => 'VirtualEdge($source -> $target, weight: $weight)';
}

// Layer element that can be either a Node or Container
abstract class LayerElement {
  int index = -1;
  int pos = -1;
  double measure = -1;
}

// Node wrapper for layer elements
class NodeElement extends LayerElement {
  final Node node;
  NodeElement(this.node);

  @override
  String toString() => 'NodeElement(${node.toString()})';
}

// Container wrapper for layer elements
class ContainerElement extends LayerElement {
  final ContainerX container;
  ContainerElement(this.container);

  @override
  String toString() => 'ContainerElement(${container.toString()})';
}
