# Research: Feature Removal Analysis

This document outlines the research performed to identify all code and documentation related to the out-of-scope features defined in `Requisitos.md`.

## Analysis of Out-of-Scope Features

### 1. L-Systems, Turtle Graphics, and Fractals
- **Conclusion**: The core implementation files (`l_system_generator.dart`, `turtle_state.dart`) were already removed in previous commits.
- **Action**: Remove remaining references from documentation (`CHANGELOG.md`, `specs/*.md`).

### 2. Advanced Parsing (LR, SLR, LALR)
- **Conclusion**: The primary implementation exists in `lib/core/models/parse_table.dart` within the `ParseType` enum and in `lib/core/algorithms/grammar_parser.dart` which contained LR parsing logic.
- **Action**:
    - Refactor `parse_table.dart` to remove `lr`, `slr`, and `lalr` from `ParseType`.
    - Refactor `grammar_parser.dart` to remove the LR parsing strategy and table generation.
    - Update documentation that references these features.

### 3. Brute-Force Parser for Unrestricted Grammars
- **Conclusion**: The implementation was part of `lib/core/algorithms/grammar_parser.dart` as a parsing strategy.
- **Action**: Remove the brute-force strategy from `grammar_parser.dart` and update any documentation that references it.
