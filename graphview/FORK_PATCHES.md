# Fork Patches

This document inventories JFlutter fork-specific changes to the `graphview`
package. It is organized by system area so maintainers can see which patches
are part of the fork surface, which files they touch, and why they diverge from
the upstream package.

Status markers:

- **Required**: core fork functionality depends on this patch.
- **Optional**: enhances UX or performance but can be disabled or avoided by
  configuration.
- **Experimental**: under development or not fully stable.

## Quick Reference

| Category | Patch Count |
| --- | ---: |
| Edge rendering | 5 |
| Performance | 4 |
| Interaction | 3 |
| Animation | 3 |
| API | 5 |
| Algorithms | 5 |
| **Total** | **25** |

## Edge Rendering Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| `AdaptiveEdgeRenderer` | `lib/edgerenderer/AdaptiveEdgeRenderer.dart` | **Required** | Adds adaptive connection points and routes edges through 4 routing modes (`direct`, `orthogonal`, `bezier`, `bundling`) and 4 anchor modes (`center`, `cardinal`, `octagonal`, `dynamic`). This is the main renderer for fork-specific edge routing behavior. |
| `AnimatedEdgeRenderer` | `lib/edgerenderer/AnimatedEdgeRenderer.dart` | **Optional** | Adds particle flow animation on edges. It is selected explicitly as a renderer and can be avoided when static edge rendering is preferred. |
| `OrthogonalEdgeRenderer` | `lib/edgerenderer/OrthogonalEdgeRenderer.dart` | **Optional** | Adds Manhattan-style L-shaped edge paths for graphs where right-angle routing is easier to read than direct lines. |
| Routing infrastructure | `lib/edgerenderer/routing/EdgeRoutingConfig.dart`, `lib/edgerenderer/routing/EdgeRepulsionSolver.dart`, `lib/edgerenderer/routing/VectorUtils.dart` | **Required** | Centralizes anchor mode, routing mode, movement threshold, and edge repulsion configuration used by adaptive routing. |
| Per-edge rendering and labels | `lib/Graph.dart`, `lib/edgerenderer/ArrowEdgeRenderer.dart`, `lib/tree/TreeEdgeRenderer.dart`, `lib/edgerenderer/EdgeRenderer.dart` | **Required** | Allows each `Edge` to carry `renderer`, `label`, `labelStyle`, `labelPosition`, `labelFollowsEdgeDirection`, and `labelWidget`; adds the `EdgeLabelPosition` enum so labels can be placed at start, middle, or end of an edge. |

## Performance Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| Barnes-Hut quadtree optimization | `lib/forcedirected/BarnesHutQuadtree.dart`, `lib/forcedirected/FruchtermanReingoldAlgorithm.dart`, `lib/forcedirected/FruchtermanReingoldConfiguration.dart` | **Optional** | Adds `useBarnesHut` and `theta` to reduce force-directed repulsion from O(n²) to approximately O(n log n) on large graphs. It remains configurable because it trades exactness for speed. |
| Rectangle-based repulsion distance | `lib/forcedirected/FruchtermanReingoldAlgorithm.dart` | **Required** | Computes repulsion from node rectangles instead of only node centers, which improves stability when nodes have real widget sizes or overlap. |
| Path caching in `RenderCustomLayoutBox` | `lib/renderobject/RenderCustomLayoutBox.dart` | **Required** | Adds `_pathCache`, `dirtyEdges`, and `_movementThreshold` so repeated paints can reuse edge paths unless relevant graph or node movement changes invalidate them. |
| Dirty edge tracking during node drag | `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/Graph.dart` | **Required** | Invalidates only incoming and outgoing edges for a dragged node once movement crosses the threshold, avoiding full edge cache rebuilds for local interaction. |

## Interaction Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| `GraphViewController` navigation and visibility API | `lib/controller/GraphViewController.dart`, `lib/widget/GraphView.dart` | **Required** | Provides `animateToNode`, `jumpToNode`, `zoomToFit`, `resetView`, `collapseNode`, `expandNode`, and `toggleNodeExpanded` for programmatic navigation and tree visibility control. |
| `NodeDraggingConfiguration` | `lib/config/NodeDraggingConfiguration.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart` | **Optional** | Adds node dragging with `enabled`, `onNodeDragStart`, `onNodeDragUpdate`, `onNodeDragEnd`, and `nodeLockPredicate` hooks. It can be disabled when graph positions should remain fixed. |
| Visibility tracking maps | `lib/controller/GraphViewController.dart`, `lib/delegate/GraphChildDelegate.dart` | **Required** | Tracks `collapsedNodes`, `hiddenBy`, and `expandingNodes` so collapsed subtrees stay hidden while nested collapse and expansion states remain consistent. |

## Animation Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| Expand/collapse animation | `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/renderobject/GraphViewWidget.dart`, `lib/controller/GraphViewController.dart` | **Optional** | Adds `enableAnimation`, `animatedPositions`, and fade-in/fade-out handling for collapsing and expanding edges. Consumers can pass `animated: false` to disable it. |
| `AnimatedEdgeConfiguration` | `lib/edgerenderer/AnimatedEdgeRenderer.dart` | **Optional** | Provides particle animation parameters such as speed, count, size, color, spacing, and opacity for animated edge flows. |
| Dual animation controllers in `_GraphViewState` | `lib/widget/GraphView.dart` | **Required** | Separates `_panController` for viewport navigation from `_nodeController` for expand/collapse animation so graph navigation and node visibility transitions do not share timing state. |

## API Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| `GraphView.builder()` constructor | `lib/widget/GraphView.dart`, `lib/GraphView.dart`, `lib/delegate/GraphChildDelegate.dart` | **Required** | Establishes the current builder API with `builder`, `controller`, `initialNode`, `autoZoomToFit`, `panAnimationDuration`, `toggleAnimationDuration`, `centerGraph`, and `nodeDraggingConfig`. |
| `Node.Id()` constructor pattern | `lib/Graph.dart`, `MIGRATION.md` | **Required** | Replaces widget-backed `Node()` construction with stable ID-backed nodes, improving cache behavior and separating graph data from widget presentation. |
| `Graph.getNodeUsingId()` | `lib/Graph.dart`, `MIGRATION.md` | **Required** | Replaces deprecated `getNodeAtUsingData()` lookup with ID-based lookup that matches the `Node.Id()` migration path. |
| `GraphObserver` and graph generation tracking | `lib/Graph.dart`, `lib/renderobject/RenderCustomLayoutBox.dart` | **Required** | Notifies render objects when the graph changes and increments `graph.generation` for dirty tracking and cache invalidation. |
| New enums | `lib/Graph.dart`, `lib/edgerenderer/routing/EdgeRoutingConfig.dart` | **Required** | Adds `LineType`, `EdgeLabelPosition`, `AnchorMode`, and `RoutingMode` to make rendering styles, label placement, anchor selection, and routing modes explicit API choices. |

## Algorithm Patches

| Patch Name | Affected Files | Status | Rationale |
| --- | --- | --- | --- |
| Additional tree layouts | `lib/tree/BaloonLayoutAlgorithm.dart`, `lib/tree/CircleLayoutAlgorithm.dart`, `lib/tree/RadialTreeLayoutAlgorithm.dart`, `lib/tree/TidierTreeLayoutAlgorithm.dart` | **Optional** | Adds `BalloonLayoutAlgorithm`, `CircleLayoutAlgorithm`, `RadialTreeLayoutAlgorithm`, and `TidierTreeLayoutAlgorithm` as selectable layout strategies beyond the original tree layout. |
| `BuchheimWalkerAlgorithm` enhancements | `lib/tree/BuchheimWalkerAlgorithm.dart`, `lib/tree/BuchheimWalkerConfiguration.dart`, `lib/tree/BuchheimWalkerNodeData.dart`, `lib/util/orientation_utils.dart` | **Required** | Improves orientation handling, spacing, and shared tree-layout behavior used directly by tree and mind map layouts. |
| `MindmapAlgorithm` | `lib/mindmap/MindMapAlgorithm.dart` | **Required** | Adds bilateral LEFT/RIGHT subtree placement by mirroring subtrees around the root for mind map style graph layouts. |
| `MindmapEdgeRenderer` | `lib/mindmap/MindmapEdgeRenderer.dart` | **Required** | Flips effective edge orientation for negative-coordinate nodes so mind map connectors align with the side of the root where each subtree is rendered. |
| `TreeEdgeRenderer` enhancements | `lib/tree/TreeEdgeRenderer.dart` | **Required** | Adds curved and L-shaped tree paths, orientation-aware routing, self-loop support, and label rendering for tree-family algorithms. |

## File Reference Appendix

| Category | Source Files | Test Coverage |
| --- | --- | --- |
| Edge rendering | `lib/edgerenderer/AdaptiveEdgeRenderer.dart`, `lib/edgerenderer/AnimatedEdgeRenderer.dart`, `lib/edgerenderer/ArrowEdgeRenderer.dart`, `lib/edgerenderer/CurvedEdgeRenderer.dart`, `lib/edgerenderer/EdgeRenderer.dart`, `lib/edgerenderer/OrthogonalEdgeRenderer.dart`, `lib/edgerenderer/routing/EdgeRoutingConfig.dart`, `lib/edgerenderer/routing/EdgeRepulsionSolver.dart`, `lib/edgerenderer/routing/VectorUtils.dart`, `lib/Graph.dart`, `lib/tree/TreeEdgeRenderer.dart` | `test/anchor_calculation_test.dart`, `test/arrow_renderer_adaptive_test.dart`, `test/backward_compatibility_test.dart`, `test/curved_edge_renderer_test.dart`, `test/edge_label_test.dart`, `test/edge_repulsion_integration_test.dart`, `test/edge_repulsion_test.dart`, `test/edge_routing_config_test.dart`, `test/per_edge_renderer_test.dart`, `test/performance_test.dart`, `test/routing_algorithms_test.dart`, `test/vector_utils_test.dart` |
| Performance | `lib/forcedirected/BarnesHutQuadtree.dart`, `lib/forcedirected/FruchtermanReingoldAlgorithm.dart`, `lib/forcedirected/FruchtermanReingoldConfiguration.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/Graph.dart` | `test/algorithm_performance_test.dart`, `test/barnes_hut_performance_test.dart`, `test/barnes_hut_quadtree_test.dart`, `test/dirty_tracking_test.dart`, `test/distance_threshold_test.dart`, `test/fruchterman_reingold_algorithm_test.dart`, `test/graphview_perfomance_test.dart`, `test/path_caching_test.dart`, `test/performance_test.dart` |
| Interaction | `lib/controller/GraphViewController.dart`, `lib/config/NodeDraggingConfiguration.dart`, `lib/delegate/GraphChildDelegate.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart` | `test/controller_tests.dart`, `test/node_dragging_test.dart` |
| Animation | `lib/edgerenderer/AnimatedEdgeRenderer.dart`, `lib/renderobject/GraphViewWidget.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart` | `test/backward_compatibility_test.dart`, `test/controller_tests.dart`, `test/per_edge_renderer_test.dart` |
| API | `lib/Graph.dart`, `lib/GraphView.dart`, `lib/controller/GraphViewController.dart`, `lib/delegate/GraphChildDelegate.dart`, `lib/renderobject/RenderCustomLayoutBox.dart`, `lib/widget/GraphView.dart`, `MIGRATION.md` | `test/backward_compatibility_test.dart`, `test/controller_tests.dart`, `test/edge_label_test.dart`, `test/graph_test.dart`, `test/per_edge_renderer_test.dart` |
| Algorithms | `lib/tree/BaloonLayoutAlgorithm.dart`, `lib/tree/BuchheimWalkerAlgorithm.dart`, `lib/tree/BuchheimWalkerConfiguration.dart`, `lib/tree/BuchheimWalkerNodeData.dart`, `lib/tree/CircleLayoutAlgorithm.dart`, `lib/tree/RadialTreeLayoutAlgorithm.dart`, `lib/tree/TidierTreeLayoutAlgorithm.dart`, `lib/tree/TreeEdgeRenderer.dart`, `lib/mindmap/MindMapAlgorithm.dart`, `lib/mindmap/MindmapEdgeRenderer.dart`, `lib/util/orientation_utils.dart` | `test/baloon_layout_algorithm_test.dart`, `test/backward_compatibility_test.dart`, `test/buchheim_walker_algorithm_test.dart`, `test/circle_layout_algorithm_test.dart`, `test/mindmap_algorithm_test.dart`, `test/radial_tree_layout_algorithm_test.dart`, `test/tidier_tree_layout_algorithm_test.dart` |

## Migration Cross-References

See [MIGRATION.md](MIGRATION.md) for patches that affect the deprecated API
migration path:

- Prefer `Node.Id()` over widget-based `Node()` construction.
- Move widget creation into `GraphView.builder()` instead of storing widgets on
  graph nodes.
- Use `Graph.getNodeUsingId()` in place of `Graph.getNodeAtUsingData()`; the
  deprecation warnings for `Node()`, `Node.data`, and `getNodeAtUsingData()`
  point users to the builder and ID-based API.
