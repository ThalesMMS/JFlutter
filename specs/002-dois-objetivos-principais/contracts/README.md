# Phase 1 Contracts

Objetivo: definir contratos de serialização/interop para `.jff`/JSON/SVG.

## Itens
- Import `.jff` (DFA/NFA/GLC/TM) → modelos imutáveis (`Alphabet`, `State`, `Transition`, `Configuration<T>`, `Trace`)
- Export JSON estável para resultados: `ValidationReport`, `SimulationResult`
- Export SVG para visualizações (onde aplicável)

## Notas
- Normalizar diferenças não semânticas (ordem de transições, whitespace)
- Registrar desvios em `docs/reference-deviations.md`
