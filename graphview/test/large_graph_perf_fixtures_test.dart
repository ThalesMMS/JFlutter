import 'package:flutter_test/flutter_test.dart';

import 'support/large_graph_perf_fixtures.dart';

void main() {
  test('createLargeGraphFixture rejects non-positive node counts', () {
    expect(
      () => createLargeGraphFixture(
        nodeCount: 0,
        topology: GraphTopology.chain,
      ),
      throwsA(
        isA<ArgumentError>().having((error) => error.name, 'name', 'nodeCount'),
      ),
    );
  });

  test('createLargeGraphFixture registers isolated nodes', () {
    final fixture = createLargeGraphFixture(
      nodeCount: 1,
      topology: GraphTopology.chain,
    );

    expect(fixture.nodes, hasLength(1));
    expect(fixture.edges, isEmpty);
    expect(fixture.graph.nodes, hasLength(1));
    expect(fixture.graph.nodes.single, same(fixture.nodes.single));
  });
}
