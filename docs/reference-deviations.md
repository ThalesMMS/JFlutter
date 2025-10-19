# Reference Deviations Log

This log captures intentional deviations between the JFlutter implementation and the authoritative
reference sources tracked in the `References/` directory. Use it to document rationale, mitigation
plans, and review cadence whenever behaviour diverges from the upstream projects we mirror.

## How to record a deviation

1. Confirm the deviation is intentional (or temporarily accepted) and scoped.
2. Add or update an entry in the relevant table below, linking to the affected code/tests and the
   upstream reference or expectation.
3. Describe the rationale, user impact, and any mitigation or follow-up tasks.
4. Include an owner and a "last reviewed" date so that the deviation is re-evaluated regularly.
5. When the deviation is resolved, move the entry to the **Resolved deviations** section and capture
   the resolution details.

> **Template**
>
> | Area | Reference baseline | Description | Rationale & impact | Mitigation / follow-up | Owner | Last reviewed |
> | --- | --- | --- | --- | --- | --- | --- |

---

## Active deviations

### Algorithmic & performance deviations

| Area | Reference baseline | Description | Rationale & impact | Mitigation / follow-up | Owner | Last reviewed |
| --- | --- | --- | --- | --- | --- | --- |
| NFA→DFA subset construction cap | [`lib/core/algorithms/nfa_to_dfa_converter.dart`](../lib/core/algorithms/nfa_to_dfa_converter.dart) vs. theoretical 2^n DFA state expansion | Hard ceiling of 1 000 DFA states during subset construction to prevent mobile memory exhaustion. | Prevents OOM freezes observed on mobile profiles when exploring large NFAs; may reject edge cases that theoretical model can explore. | Revisit once streaming/partial evaluation strategies are implemented; explore progressive disclosure UI. | Core algorithms WG | 2024-05-30 |

### Tooling, fixtures, and test coverage deviations

| Area | Reference baseline | Description | Rationale & impact | Mitigation / follow-up | Owner | Last reviewed |
| --- | --- | --- | --- | --- | --- | --- |
| Import/Export round-trip suite | Python `automata-main` serializers & SVG fixtures | 19 known integration test failures tied to epsilon serialization mismatches and SVG viewBox formatting for empty automata. | Ensures broader feature work can continue; exporters remain usable but require manual verification for affected artifacts. | Track fixes under IO stabilization epic; update fixtures and regenerate SVG baselines once serializers are aligned. | Interop WG | 2024-05-30 |
| Widget harness regressions | Flutter widget suites mirroring reference UI contracts | 11 widget tests disabled/missing due to unimplemented widgets (`error_banner`, `import_error_dialog`, `retry_button`) and outdated finders. | Avoids blocking CI while UI rearchitecture completes; limited automated coverage for certain error paths. | Restore widgets and update harnesses; re-enable tests when parity achieved. | Presentation WG | 2024-05-30 |

---

## Resolved deviations

Log former deviations here with the resolution summary so future contributors can trace context.

| Area | Resolution | Date |
| --- | --- | --- |
| _None yet_ | — | — |

---

## Review cadence

This document should be revalidated during each milestone planning session and whenever reference
sources in `References/` are updated. Owners listed above are responsible for keeping their entries
current and escalating when timelines or impacts change.
