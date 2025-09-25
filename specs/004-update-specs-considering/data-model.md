# Data Model Changes for Feature Removal

This document specifies the data model entities that will be removed from the project to align with the updated `Requisitos.md`.

## Entities to be Removed

The following entities and concepts will be completely removed from the codebase:

- **`LSystem`**: All data models and classes related to L-System rules, axioms, and generation.
- **`TurtleState`**: The data model representing the state of the turtle for turtle graphics, including position, angle, and pen status.
- **`ParseType` (out-of-scope variants)**: The `enum` values `lr`, `slr`, and `lalr` will be removed from the `ParseType` enum in `lib/core/models/parse_table.dart`.
- **LR/SLR `ParseTable` Logic**: Any fields or methods within `ParseTable` or related classes that are specific to LR, SLR, or LALR parsing will be removed.
- **Brute-Force Parser Logic**: Any data structures or models that were exclusively used by the brute-force parsing strategy will be removed from `lib/core/algorithms/grammar_parser.dart`.

No new entities will be added as part of this feature removal process.
