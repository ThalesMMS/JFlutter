# Reference Deviations

## GraphView Sugiyama Coordinate Assignment

- File: `graphview/lib/layered/SugiyamaCoordinateAssignment.dart`
- Referenced implementation path: `References/graphview/lib/layered/SugiyamaCoordinateAssignment.dart`
- Status: the local `References/` checkout is not present in this workspace, so this entry records the intended parity target and the maintained fork deltas.

Intentional deltas:

- Coordinate averaging: keeps the four directional layout sweeps and balances them through median-style averaging for stable placement.
- Boundary alignment: resolves overlaps with node-size-aware half extents rather than only previous-node full extents.
- Type-1 conflicts: stores conflicts by node with all conflicting neighbors so layer-local positions do not collapse distinct conflicts.
- Dummy-node handling: applies `postStraighten()` before final orientation-specific `position` assignment so straightened dummy coordinates are reflected in rendered positions.
