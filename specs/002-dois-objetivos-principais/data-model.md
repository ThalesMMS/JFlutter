# Phase 1 Data Model

## Shared Types
- Alphabet
- State
- Transition
- Configuration<T>
- Trace

## ValidationReport
- algorithmType: DFA|NFA|GLC|TM
- caseId: string
- status: conform|deviation
- diff: string|object

## SimulationResult
- accepted: boolean
- steps: int
- finalState: string|null
- trace: Trace

