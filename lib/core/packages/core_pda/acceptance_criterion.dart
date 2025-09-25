/// Acceptance criteria for pushdown automata
enum PDAAcceptanceCriterion {
  /// Accept by final state
  finalState,
  
  /// Accept by empty stack
  emptyStack,
  
  /// Accept by both final state and empty stack
  both,
}

/// Acceptance mode for PDA simulation
enum PDAAcceptanceMode {
  /// Accept by final state only
  finalState,
  
  /// Accept by empty stack only
  emptyStack,
  
  /// Accept by both final state and empty stack
  both,
}
