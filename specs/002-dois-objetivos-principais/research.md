# Phase 0 Research

## References
- Primary: `References/automata-main`
- Supporting: `jflutter_js/examples`
- Optional: `References/AutomataTheory-master`, `References/nfa_2_dfa-main`, `References/turing-machine-generator-main`

## Canonical Cases (min 5 por tipo)
- DFA: aceitação, rejeição, cadeia vazia, ciclo, complementação
- NFA: não-determinismo, ε-transições, aceitação, rejeição, beira do alfabeto
- GLC: derivação válida, inválida, CNF/CYK simples, recursão esquerda, ambiguidades simples
- TM: aceita, rejeita, laço detectável por limite, transformação simples, limites de fita

## Performance & Offline
- ≥60fps; p95 frame < 20ms; sem pausas de GC > 50ms; memória < 400MB
- Operação offline, sandbox de arquivos, sem telemetria obrigatória

## Licensing
- Código Apache-2.0; compatibilidade com JFLAP 7.1 para ativos

## Decisions
- Relatório de conformidade por algoritmo; desvios em `docs/reference-deviations.md`

