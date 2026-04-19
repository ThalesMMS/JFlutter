part of graphview;

class EiglspergerNodeData {
  bool isDummy = false;
  bool isPVertex = false;
  bool isQVertex = false;
  Segment? segment;
  int layer = -1;
  int position = -1;
  int rank = -1;
  double measure = -1;
  Set<Node> reversed = {};
  List<Node> predecessorNodes = [];
  List<Node> successorNodes = [];
  LineType lineType;

  EiglspergerNodeData(this.lineType);

  bool get isSegmentVertex => isPVertex || isQVertex;
  bool get isReversed => reversed.isNotEmpty;

  @override
  String toString() {
    return 'EiglspergerNodeData{isDummy: $isDummy, isPVertex: $isPVertex, isQVertex: $isQVertex, segment: $segment, layer: $layer, position: $position, rank: $rank, measure: $measure, reversed: $reversed, lineType: $lineType}';
  }
}
