# Research Findings: JFlutter Mobile Port

**Date**: 2024-12-19  
**Purpose**: Resolve NEEDS CLARIFICATION items and establish technical foundation

## Mobile Accessibility Requirements

### Decision
Implement WCAG 2.1 AA compliance with Flutter accessibility features:
- Semantic labels for all interactive elements
- High contrast mode support
- Screen reader compatibility
- Minimum 44dp touch targets
- Voice-over navigation support

### Rationale
Educational apps must be accessible to all students, including those with disabilities. Flutter provides excellent accessibility support through Semantics widgets and platform-specific adaptations.

### Alternatives Considered
- Basic accessibility (insufficient for educational use)
- Full WCAG 2.1 AAA (overkill for mobile app)
- Custom accessibility solution (unnecessary complexity)

## Performance Limits for Large Automata

### Decision
Support automata with up to 200 states/nodes with performance targets:
- <500ms for automata <50 states
- <2s for automata 50-100 states  
- <5s for automata 100-200 states
- Memory limit: 100MB per automaton

### Rationale
Mobile devices have limited memory and processing power. 200 states is sufficient for educational purposes while maintaining reasonable performance. Most academic exercises use <50 states.

### Alternatives Considered
- Unlimited size (would cause performance issues)
- 50 state limit (too restrictive for advanced courses)
- Cloud processing (adds complexity and network dependency)

## JFLAP File Format Compatibility

### Decision
Support JFLAP 7.1 file formats:
- XML format for automata (.jff files)
- XML format for grammars (.cfg files)
- Binary format for complex structures
- Export to standard formats (PNG, SVG)

### Rationale
Students need to exchange files with desktop JFLAP users. XML format is well-documented and easily parseable in Dart.

### Alternatives Considered
- Custom format only (would isolate users)
- JSON format (less compatible with existing ecosystem)
- Multiple format support (unnecessary complexity)

## Touch Gesture Patterns for Graph Editing

### Decision
Implement mobile-optimized touch patterns:
- Tap to select states/transitions
- Long press for context menus
- Pinch to zoom, pan with single finger
- Drag to move states
- Double-tap to edit labels
- Swipe gestures for navigation

### Rationale
These patterns follow established mobile UI conventions while providing precise control needed for automaton editing.

### Alternatives Considered
- Desktop mouse patterns (inappropriate for touch)
- Custom gestures (confusing for users)
- Voice commands (unreliable and slow)

## Flutter State Management Patterns

### Decision
Use Provider pattern with Riverpod for complex state:
- Provider for global app state
- StateNotifier for automaton state
- Consumer for UI updates
- Local state with setState for simple components

### Rationale
Provider is mature, well-documented, and handles complex state efficiently. Riverpod provides better testing and dependency injection.

### Alternatives Considered
- BLoC (more complex for this use case)
- Redux (overkill for single-user app)
- setState only (insufficient for complex state)

## Mobile UI Layout Strategy

### Decision
Implement responsive layout with same section divisions as JFLAP:
- Bottom navigation for main sections (Automata, Grammars, Help)
- Floating action buttons for primary actions
- Drawer menu for secondary functions
- Modal sheets for detailed editing
- Tab navigation within sections

### Rationale
Maintains familiar JFLAP structure while adapting to mobile constraints. Bottom navigation is standard for mobile apps.

### Alternatives Considered
- Tab bar at top (harder to reach on mobile)
- Single screen with scrolling (loses section organization)
- Custom navigation (confusing for users)

## Algorithm Implementation Strategy

### Decision
Port core algorithms from JFLAP source with Dart optimizations:
- NFA to DFA: Subset construction with optimized data structures
- DFA minimization: Hopcroft's algorithm with mobile memory management
- Grammar parsing: LL/LR with efficient table generation
- Simulation: Step-by-step execution with pause/resume

### Rationale
Educational accuracy requires correct algorithms. Dart's performance is sufficient for educational-scale problems.

### Alternatives Considered
- Simplified algorithms (would mislead students)
- Web-based processing (adds network dependency)
- Native code (unnecessary complexity)

## File Storage Strategy

### Decision
Local file storage with JSON serialization:
- SharedPreferences for app settings
- File system for automata/grammar files
- JSON format for easy debugging and portability
- Automatic backup to device storage

### Rationale
Offline operation is essential for educational use. JSON is human-readable and easily debuggable.

### Alternatives Considered
- Cloud storage (requires network, privacy concerns)
- Binary format (harder to debug)
- SQLite (overkill for simple data)

## Testing Strategy

### Decision
Comprehensive testing approach:
- Unit tests for all algorithms
- Widget tests for UI components  
- Integration tests for user workflows
- Golden tests for visual regression
- Performance tests for large automata

### Rationale
Educational software must be reliable. Flutter's testing framework provides excellent coverage.

### Alternatives Considered
- Manual testing only (insufficient for complex algorithms)
- Unit tests only (misses UI integration issues)
- External testing service (adds complexity and cost)
