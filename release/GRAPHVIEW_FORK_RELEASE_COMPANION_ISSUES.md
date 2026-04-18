# graph Release Companion Issue Drafts for JFlutter

This companion file contains issue drafts specifically for the custom `graph` fork that JFlutter depends on.

---

## 1. Document all JFlutter-specific patches carried by the fork

**Goal**
Create a complete inventory of fork-specific changes that JFlutter depends on.

**Tasks**
- List all rendering, interaction, performance, and API changes made in the fork.
- Mark each change as required, optional, or experimental.
- Add a short rationale for every retained divergence from upstream.

**Acceptance criteria**
- A patch inventory exists.
- Every meaningful fork delta is documented.

---

## 2. Tag a reproducible release of the fork for JFlutter consumption

**Goal**
Give JFlutter a stable graphview fork version to depend on.

**Tasks**
- Choose a tag/versioning strategy.
- Create a release tag for the fork version used by JFlutter v1.0.
- Document which JFlutter version maps to which fork tag.

**Acceptance criteria**
- A reproducible fork version exists.
- JFlutter can pin to a tag or commit SHA.

---

## 3. Reduce fork delta from upstream wherever possible

**Goal**
Minimize maintenance burden before public release.

**Tasks**
- Compare current fork behavior against upstream graphview.
- Upstream generic improvements where practical.
- Keep only JFlutter-specific deltas in the fork.

**Acceptance criteria**
- Fork delta is intentionally small.
- Upstream-sync strategy is documented.

---

## 4. Validate iOS and macOS rendering behavior in the fork

**Goal**
Ensure the fork behaves correctly on Apple platforms.

**Tasks**
- Test self-loops, grouped edges, curved/adaptive edges, highlights, zoom, and hit-testing.
- Test large graphs and dense edge cases.
- Record Apple-specific rendering issues.

**Acceptance criteria**
- Apple-platform fork QA is complete.
- No release-critical rendering bug remains unresolved.

---

## 5. Benchmark performance for JFlutter-critical graph workloads

**Goal**
Ensure the fork can handle real JFlutter canvases acceptably.

**Tasks**
- Benchmark typical FSA/PDA/TM graph sizes used in JFlutter.
- Compare baseline vs patched behavior where possible.
- Document hotspots and any tuning changes.

**Acceptance criteria**
- Performance expectations are documented.
- JFlutter-critical graph sizes are handled acceptably.

---

## 6. Clean up public documentation for the fork

**Goal**
Make the fork understandable to future maintainers.

**Tasks**
- Update README/changelog for the fork.
- Explain that it is used by JFlutter and why.
- Document any new APIs or behavioral differences from upstream.

**Acceptance criteria**
- The fork has usable public documentation.
- JFlutter-specific changes are discoverable.

---

## 7. Confirm license and attribution handling for the fork

**Goal**
Keep dependency licensing clean for the app release.

**Tasks**
- Confirm the fork retains correct upstream license text.
- Add attribution notes if needed.
- Ensure modified files carry required notices.

**Acceptance criteria**
- The fork’s license posture is clear.
- JFlutter can reference the fork cleanly in its release materials.

---

## 8. Add regression tests for fork-only behavior

**Goal**
Protect the changes that make the fork necessary.

**Tasks**
- Add tests for loop rendering, edge routing, node dragging, and any patched behavior JFlutter relies on.
- Add performance regression coverage where feasible.

**Acceptance criteria**
- Fork-only behavior is covered by automated tests.
- Future refactors are less risky.

---

## 9. Decide long-term dependency strategy for JFlutter

**Goal**
Avoid indefinite ad hoc dependency management.

**Tasks**
- Decide whether the fork remains separate, is vendored, or is partially upstreamed.
- Document long-term maintenance ownership.
- Set expectations for release sync between JFlutter and graph.

**Acceptance criteria**
- Long-term dependency strategy is explicit.
- Maintenance burden is understood.

---

## 10. Prepare a release note specifically for the fork version used by JFlutter v1.0

**Goal**
Make it easy to identify the exact fork release included in JFlutter’s Apple release.

**Tasks**
- Write a short release note describing the fork state used by the app.
- Link it to the JFlutter v1.0 release plan.

**Acceptance criteria**
- The exact fork version used by JFlutter v1.0 is clearly documented.
