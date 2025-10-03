import 'package:collection/collection.dart';

import '../../../core/models/tm_transition.dart';

/// Metadata describing the current automaton rendered in the canvas.
class FlNodesAutomatonMetadata {
  const FlNodesAutomatonMetadata({
    required this.id,
    required this.name,
    required this.alphabet,
  });

  const FlNodesAutomatonMetadata.empty()
      : id = null,
        name = null,
        alphabet = const <String>[];

  final String? id;
  final String? name;
  final List<String> alphabet;

  FlNodesAutomatonMetadata copyWith({
    String? id,
    String? name,
    List<String>? alphabet,
  }) {
    return FlNodesAutomatonMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      alphabet: alphabet ?? this.alphabet,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alphabet': alphabet,
    };
  }

  factory FlNodesAutomatonMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const FlNodesAutomatonMetadata.empty();
    }
    final rawAlphabet = json['alphabet'];
    final alphabet = rawAlphabet is List
        ? rawAlphabet.cast<String>()
        : const <String>[];
    return FlNodesAutomatonMetadata(
      id: json['id'] as String?,
      name: json['name'] as String?,
      alphabet: alphabet,
    );
  }
}

/// Node rendered inside the fl_nodes editor.
class FlNodesCanvasNode {
  const FlNodesCanvasNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isAccepting,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final bool isInitial;
  final bool isAccepting;

  FlNodesCanvasNode copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    return FlNodesCanvasNode(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isAccepting: isAccepting ?? this.isAccepting,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    };
  }

  factory FlNodesCanvasNode.fromJson(Map<String, dynamic> json) {
    return FlNodesCanvasNode(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? json['id'] as String,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      isInitial: json['isInitial'] as bool? ?? false,
      isAccepting: json['isAccepting'] as bool? ?? false,
    );
  }
}

/// Directed edge rendered inside the fl_nodes editor.
class FlNodesCanvasEdge {
  const FlNodesCanvasEdge({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required this.symbols,
    this.lambdaSymbol,
    this.controlPointX,
    this.controlPointY,
    this.readSymbol,
    this.writeSymbol,
    this.direction,
    this.tapeNumber,
    this.popSymbol,
    this.pushSymbol,
    this.isLambdaInput,
    this.isLambdaPop,
    this.isLambdaPush,
  });

  final String id;
  final String fromStateId;
  final String toStateId;
  final List<String> symbols;
  final String? lambdaSymbol;
  final double? controlPointX;
  final double? controlPointY;
  final String? readSymbol;
  final String? writeSymbol;
  final TapeDirection? direction;
  final int? tapeNumber;
  final String? popSymbol;
  final String? pushSymbol;
  final bool? isLambdaInput;
  final bool? isLambdaPop;
  final bool? isLambdaPush;

  String get label {
    final hasPdaMetadata = popSymbol != null ||
        pushSymbol != null ||
        isLambdaInput != null ||
        isLambdaPop != null ||
        isLambdaPush != null;
    if (hasPdaMetadata) {
      final lambdaInput = isLambdaInput ?? (readSymbol == null || readSymbol!.isEmpty);
      final lambdaPop = isLambdaPop ?? (popSymbol == null || popSymbol!.isEmpty);
      final lambdaPush = isLambdaPush ?? (pushSymbol == null || pushSymbol!.isEmpty);
      final read = lambdaInput ? 'λ' : (readSymbol ?? '');
      final pop = lambdaPop ? 'λ' : (popSymbol ?? '');
      final push = lambdaPush ? 'λ' : (pushSymbol ?? '');
      return '$read, $pop/$push';
    }
    if (lambdaSymbol != null && lambdaSymbol!.isNotEmpty) {
      return lambdaSymbol!;
    }
    if (readSymbol != null || writeSymbol != null || direction != null) {
      final read = (readSymbol ?? '').isEmpty ? '∅' : readSymbol!;
      final write = (writeSymbol ?? '').isEmpty ? '∅' : writeSymbol!;
      final resolvedDirection = direction;
      final directionSymbol = switch (resolvedDirection) {
        TapeDirection.left => 'L',
        TapeDirection.right => 'R',
        TapeDirection.stay => 'S',
        null => '',
      };
      final suffix = directionSymbol.isEmpty ? '' : ',$directionSymbol';
      return '$read/$write$suffix';
    }
    final filtered = symbols.where((symbol) => symbol.isNotEmpty).toList();
    return filtered.join(',');
  }

  FlNodesCanvasEdge copyWith({
    String? id,
    String? fromStateId,
    String? toStateId,
    List<String>? symbols,
    String? lambdaSymbol,
    double? controlPointX,
    double? controlPointY,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
  }) {
    return FlNodesCanvasEdge(
      id: id ?? this.id,
      fromStateId: fromStateId ?? this.fromStateId,
      toStateId: toStateId ?? this.toStateId,
      symbols: symbols ?? this.symbols,
      lambdaSymbol: lambdaSymbol ?? this.lambdaSymbol,
      controlPointX: controlPointX ?? this.controlPointX,
      controlPointY: controlPointY ?? this.controlPointY,
      readSymbol: readSymbol ?? this.readSymbol,
      writeSymbol: writeSymbol ?? this.writeSymbol,
      direction: direction ?? this.direction,
      tapeNumber: tapeNumber ?? this.tapeNumber,
      popSymbol: popSymbol ?? this.popSymbol,
      pushSymbol: pushSymbol ?? this.pushSymbol,
      isLambdaInput: isLambdaInput ?? this.isLambdaInput,
      isLambdaPop: isLambdaPop ?? this.isLambdaPop,
      isLambdaPush: isLambdaPush ?? this.isLambdaPush,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': fromStateId,
      'to': toStateId,
      'symbols': symbols,
      if (lambdaSymbol != null) 'lambdaSymbol': lambdaSymbol,
      if (controlPointX != null) 'controlPointX': controlPointX,
      if (controlPointY != null) 'controlPointY': controlPointY,
      if (readSymbol != null) 'readSymbol': readSymbol,
      if (writeSymbol != null) 'writeSymbol': writeSymbol,
      if (direction != null) 'direction': direction!.name,
      if (tapeNumber != null) 'tapeNumber': tapeNumber,
      if (popSymbol != null) 'popSymbol': popSymbol,
      if (pushSymbol != null) 'pushSymbol': pushSymbol,
      if (isLambdaInput != null) 'isLambdaInput': isLambdaInput,
      if (isLambdaPop != null) 'isLambdaPop': isLambdaPop,
      if (isLambdaPush != null) 'isLambdaPush': isLambdaPush,
    };
  }

  factory FlNodesCanvasEdge.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    final symbols = rawSymbols is List
        ? rawSymbols.cast<String>()
        : rawSymbols is String && rawSymbols.isNotEmpty
            ? rawSymbols.split(',')
            : const <String>[];
    return FlNodesCanvasEdge(
      id: json['id'] as String,
      fromStateId: json['from'] as String,
      toStateId: json['to'] as String,
      symbols: symbols,
      lambdaSymbol: json['lambdaSymbol'] as String?,
      controlPointX: (json['controlPointX'] as num?)?.toDouble(),
      controlPointY: (json['controlPointY'] as num?)?.toDouble(),
      readSymbol: json['readSymbol'] as String?,
      writeSymbol: json['writeSymbol'] as String?,
      direction: (json['direction'] as String?) != null
          ? TapeDirection.values.firstWhere(
              (value) => value.name == json['direction'],
              orElse: () => TapeDirection.right,
            )
          : null,
      tapeNumber: json['tapeNumber'] as int?,
      popSymbol: json['popSymbol'] as String?,
      pushSymbol: json['pushSymbol'] as String?,
      isLambdaInput: json['isLambdaInput'] as bool?,
      isLambdaPop: json['isLambdaPop'] as bool?,
      isLambdaPush: json['isLambdaPush'] as bool?,
    );
  }
}

/// Snapshot of nodes, edges and metadata rendered in the canvas.
class FlNodesAutomatonSnapshot {
  const FlNodesAutomatonSnapshot({
    required this.nodes,
    required this.edges,
    required this.metadata,
  });

  const FlNodesAutomatonSnapshot.empty()
      : nodes = const <FlNodesCanvasNode>[],
        edges = const <FlNodesCanvasEdge>[],
        metadata = const FlNodesAutomatonMetadata.empty();

  final List<FlNodesCanvasNode> nodes;
  final List<FlNodesCanvasEdge> edges;
  final FlNodesAutomatonMetadata metadata;

  FlNodesAutomatonSnapshot copyWith({
    List<FlNodesCanvasNode>? nodes,
    List<FlNodesCanvasEdge>? edges,
    FlNodesAutomatonMetadata? metadata,
  }) {
    return FlNodesAutomatonSnapshot(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
      'metadata': metadata.toJson(),
    };
  }

  factory FlNodesAutomatonSnapshot.fromJson(Map<String, dynamic> json) {
    final rawNodes = (json['nodes'] as List?)?.cast<Map>() ?? const [];
    final rawEdges = (json['edges'] as List?)?.cast<Map>() ?? const [];
    return FlNodesAutomatonSnapshot(
      nodes: rawNodes
          .map((node) => FlNodesCanvasNode.fromJson(
                node.cast<String, dynamic>(),
              ))
          .toList(),
      edges: rawEdges
          .map((edge) => FlNodesCanvasEdge.fromJson(
                edge.cast<String, dynamic>(),
              ))
          .toList(),
      metadata: FlNodesAutomatonMetadata.fromJson(
        (json['metadata'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FlNodesAutomatonSnapshot &&
        const ListEquality<FlNodesCanvasNode>().equals(nodes, other.nodes) &&
        const ListEquality<FlNodesCanvasEdge>().equals(edges, other.edges) &&
        metadata.id == other.metadata.id &&
        metadata.name == other.metadata.name &&
        const ListEquality<String>().equals(
          metadata.alphabet,
          other.metadata.alphabet,
        );
  }

  @override
  int get hashCode => Object.hash(
        const ListEquality<FlNodesCanvasNode>().hash(nodes),
        const ListEquality<FlNodesCanvasEdge>().hash(edges),
        metadata.id,
        metadata.name,
        const ListEquality<String>().hash(metadata.alphabet),
      );
}
