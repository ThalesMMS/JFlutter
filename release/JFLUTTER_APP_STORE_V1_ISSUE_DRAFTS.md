# JFlutter Apple App Store v1.0 Issue Drafts

This file contains sequential GitHub issue drafts for getting **JFlutter** ready for Apple platform release, with explicit attention to the custom **graphview** fork used by the app.

---

## 1. Resolve Apple App Store legal strategy for JFlutter + JFLAP-derived content

**Goal**
Resolve whether the current licensing model is compatible with the intended Apple App Store release strategy.

**Why**
The repository declares Apache 2.0 for JFlutter, but also ships `LICENSE_JFLAP.txt` with a non-commercial restriction. This must be clarified before any public Apple release.

**Tasks**
- Review how much of the shipped app is considered derived from JFLAP.
- Determine whether Apple App Store distribution is allowed under the current licensing mix.
- Decide whether the app can be distributed only as a free app, or whether additional permissions are needed.
- Document the legal position in the repo.
- Align `README.md`, license files, and release docs with the final decision.

**Acceptance criteria**
- A written legal/distribution decision exists.
- Monetization constraints are explicitly documented.
- No licensing ambiguity remains for the Apple release.

---

## 2. Freeze Apple release scope: iPhone/iPad only vs iPhone/iPad + macOS

**Goal**
Choose the exact Apple-platform scope for v1.0.

**Why**
JFlutter contains `ios/` and `macos/` targets, but the product is described as mobile-first. The release plan must choose whether v1.0 is iOS/iPadOS only, or includes macOS as well.

**Tasks**
- Decide whether the first Apple release targets:
  - iPhone only
  - iPhone + iPad
  - iPhone + iPad + macOS
- Define supported device families for v1.0.
- Align screenshots, QA, and metadata with the chosen scope.

**Acceptance criteria**
- Apple release scope is written down.
- Device families and supported Apple targets are fixed for v1.0.
- No unsupported Apple target is implied in public copy.

---

## 3. Stabilize the custom graphview fork used by JFlutter

**Goal**
Make the app’s graph rendering dependency reproducible, auditable, and release-safe.

**Why**
JFlutter currently uses `dependency_overrides` pointing to a local path for `graphview`, which is not a robust release dependency strategy.

**Tasks**
- Inventory all JFlutter-critical changes made in the custom `graphview` fork.
- Decide whether to:
  - keep the fork as a separate repo,
  - vendor it into the main repo,
  - use a git dependency pinned to a commit/tag, or
  - upstream some changes and reduce fork delta.
- Document the chosen dependency strategy.

**Acceptance criteria**
- The graphview fork strategy is explicit and reproducible.
- No Apple release depends on an undocumented local-only package override.
- The release process can recreate the exact graphview version used by JFlutter.

---

## 4. Remove local path dependency overrides and replace them with a reproducible release dependency

**Goal**
Eliminate the `../graph` local override before Apple release.

**Tasks**
- Replace the local `dependency_overrides` graphview path with a reproducible dependency reference.
- Prefer a pinned git SHA or a tagged internal release if the fork remains separate.
- Ensure CI/build machines can resolve the dependency without manual directory layout assumptions.

**Acceptance criteria**
- `pubspec.yaml` no longer depends on a local sibling path for release builds.
- Any new machine can resolve dependencies deterministically.
- Release builds work without local folder conventions.

---

## 5. Audit graphview fork patches that are critical to JFlutter behavior

**Goal**
Separate essential graphview fork changes from nice-to-have changes.

**Tasks**
- Identify patches related to:
  - loop transition rendering
  - adaptive edge rendering
  - node editing/selection gestures
  - large-graph performance
  - iOS/macOS rendering behavior
- Mark each patch as release-critical, optional, or removable.
- Write a short changelog for the fork from JFlutter’s perspective.

**Acceptance criteria**
- There is a documented list of graphview fork deltas.
- JFlutter-critical patches are clearly identified.
- Non-critical fork complexity is reduced where possible.

---

## 6. Validate the graphview fork on iPhone, iPad, and macOS-sized canvases

**Goal**
Prove that the graphview-based canvas is stable on Apple platforms.

**Tasks**
- Test node creation, dragging, self-loops, transition editing, selection, zoom, fit-to-content, reset, and highlights.
- Test FSA, PDA, and TM canvases independently.
- Test large graphs and dense transition layouts.
- Verify touch interactions on iPhone/iPad and pointer behavior on macOS if included.

**Acceptance criteria**
- All release-visible graph editing flows work on the chosen Apple targets.
- No graphview-specific blocker remains for App Store release.
- High-risk canvas issues are tracked separately.

---

## 7. Reconcile the real test baseline and clean up outdated QA scripts

**Goal**
Normalize the repository’s conflicting test/documentation baselines.

**Why**
The repo currently contains multiple inconsistent references to test counts and expected pass/fail totals.

**Tasks**
- Define the real current baseline for:
  - full suite
  - unit tests
  - widget tests
  - integration tests
  - golden tests
- Update `README.md`, `AGENTS.md`, `CLAUDE.md`, and helper scripts accordingly.
- Remove stale branch-specific text from scripts.

**Acceptance criteria**
- There is one authoritative test baseline.
- Scripts and docs report the same expectations.
- No release checklist relies on outdated numbers.

---

## 8. Fix the known failing suites before Apple release candidate

**Goal**
Remove currently known failures from the release path.

**Tasks**
- Fix the import/export failures related to epsilon serialization and SVG formatting.
- Fix the home page widget issues (overflow/tooltip behavior).
- Re-run the full suite and record the new baseline.

**Acceptance criteria**
- Known failing suites are either fixed or explicitly removed from release scope.
- Release candidate is not blocked by currently known baseline failures.

---

## 9. Define JFlutter v1.0 Apple release scope and hide unfinished areas

**Goal**
Freeze exactly what ships in the first Apple release.

**Suggested v1.0 candidate scope**
- FSA creation/editing/simulation
- Regex workflows that are already stable
- Grammar workflows that are stable enough for public release
- PDA/TM if their canvases and simulations are Apple-platform ready
- Offline examples library
- Import/export only for formats that pass round-trip validation

**Tasks**
- Decide which modules are in scope for v1.0.
- Hide or defer unstable areas.
- Align in-app navigation and store copy with the chosen scope.

**Acceptance criteria**
- A written v1.0 scope exists.
- Out-of-scope workflows are hidden or clearly deferred.
- The shipped UI reflects only supported v1.0 capabilities.

---

## 10. Make import/export and JFLAP interoperability release-safe

**Goal**
Harden one of the highest-risk user-facing areas before App Store release.

**Tasks**
- Fix JFF import edge cases.
- Fix JSON/SVG round-trip issues.
- Validate empty automata handling.
- Validate malformed import behavior and user-facing errors.
- Re-test import/export on Apple devices using real files.

**Acceptance criteria**
- Release-visible import/export paths are stable.
- Interoperability failures are predictable and well messaged.
- Import/export no longer carries known release-blocking defects.

---

## 11. Finalize file handling UX for Apple sandboxed environments

**Goal**
Ensure file import/export/share flows behave correctly under Apple sandboxing.

**Tasks**
- Audit document picker flows.
- Audit save/export flows for JFF, JSON, SVG, and snapshots.
- Validate examples loading, trace persistence, and local storage under iOS/macOS constraints.
- Ensure user-facing errors are clear when files cannot be accessed.

**Acceptance criteria**
- File operations work on the chosen Apple targets.
- Sandboxed file failures degrade gracefully.
- No critical file flow depends on unsupported assumptions.

---

## 12. Run a full UX polish pass across release-visible pages

**Goal**
Clean up the product experience before App Store screenshots and review.

**Tasks**
- Review FSA, Grammar, PDA, TM, Regex, Settings, and Help pages.
- Fix layout overflows, truncated labels, tooltip behavior, and low-quality empty states.
- Standardize success/error banners.
- Ensure touch-first behavior feels production-ready on iPhone/iPad.

**Acceptance criteria**
- No obviously unfinished page remains in the Apple build.
- Layout issues are resolved on supported Apple devices.
- UI polish is good enough for App Review and screenshots.

---

## 13. Review the educational copy, help content, and product framing for public release

**Goal**
Make the app understandable and appropriately framed for external users.

**Tasks**
- Review onboarding and contextual help text.
- Remove internal wording, migration wording, or contributor-only guidance from release-visible surfaces.
- Improve first-run clarity for students and educators.

**Acceptance criteria**
- Release-visible copy is clear and external-facing.
- No internal/migration text leaks into the shipped app.
- Educational framing is consistent.

---

## 14. Finalize Apple app identity: display name, bundle IDs, versioning, and signing plan

**Goal**
Lock down the release identity of the app.

**Tasks**
- Confirm final display name.
- Confirm bundle identifiers for iOS and macOS if applicable.
- Confirm versioning strategy from `pubspec.yaml` through Apple build numbers.
- Document signing requirements and version bump procedure.

**Acceptance criteria**
- Release identity is fixed.
- Version and build numbering are documented.
- Apple signing inputs are unambiguous.

---

## 15. Prepare iOS code signing, provisioning, and archive build workflow

**Goal**
Create a repeatable Apple archive process for the app.

**Tasks**
- Configure iOS signing for Release.
- Verify archive generation on a clean machine.
- Verify that Flutter/Pods/native config is correct for Release.
- Document the archive/upload workflow.

**Acceptance criteria**
- iOS release archive can be produced reliably.
- Signing works without ad hoc manual fixes.
- Archive workflow is documented end to end.

---

## 16. Decide whether macOS enters the first Apple release and validate it separately if included

**Goal**
Avoid silently shipping an under-tested macOS target.

**Tasks**
- If macOS is included, run dedicated desktop QA for editing, rendering, and file flows.
- If macOS is excluded, ensure release docs and store materials reflect that.
- Validate native runner, icons, and platform-specific behavior.

**Acceptance criteria**
- macOS is either release-ready or intentionally deferred.
- There is no accidental half-supported macOS release.

---

## 17. Finalize iPhone/iPad/macOS icons, launch assets, and screenshots

**Goal**
Prepare final visual assets for App Store Connect.

**Tasks**
- Freeze the app icon.
- Review generated launcher icons across Apple targets.
- Capture final screenshots from the actual release candidate.
- Ensure screenshots only show supported features and polished UI states.

**Acceptance criteria**
- Apple visual assets are complete and final.
- Screenshots match the shipped build.
- No placeholder, test, or debug visuals remain.

---

## 18. Review accessibility, typography, and input ergonomics on Apple devices

**Goal**
Make the app usable for real classroom and personal-study scenarios on Apple devices.

**Tasks**
- Test Dynamic Type pressure points.
- Review tap targets and gesture conflicts.
- Review keyboard navigation where applicable.
- Review contrast and readability in light/dark themes.

**Acceptance criteria**
- Basic accessibility checks pass for v1.0.
- Important flows are comfortable on iPhone and iPad.
- No major Apple-device input issue remains.

---

## 19. Audit offline behavior, local persistence, and data safety

**Goal**
Ensure the app behaves predictably without network access and preserves user data safely.

**Tasks**
- Validate offline examples library behavior.
- Validate settings persistence and trace persistence.
- Test app relaunch, cold start, and state restoration behavior.
- Check failure modes when persistent data is malformed or missing.

**Acceptance criteria**
- Offline behavior is reliable.
- Persisted user state is stable across launches.
- Data-loss scenarios are minimized and understood.

---

## 20. Complete App Privacy and data-flow disclosure prep

**Goal**
Prepare the privacy answers needed for Apple submission.

**Tasks**
- Map all stored and processed data types.
- Review local storage, examples, imported files, traces, diagnostics, and settings.
- Determine whether any analytics/crash reporting/networking is present.
- Draft App Privacy answers based on actual behavior.

**Acceptance criteria**
- App Privacy answers are prepared and defensible.
- A repo-level data-flow note exists for future maintenance.

---

## 21. Audit Apple-platform compliance items related to third-party and forked dependencies

**Goal**
Make sure dependencies do not become last-minute App Review blockers.

**Tasks**
- Review the graphview fork and other Flutter plugins used on Apple platforms.
- Check whether any dependency requires extra metadata, attribution, or review notes.
- Confirm dependency licenses are compatible with the intended release.

**Acceptance criteria**
- Apple release dependency review is complete.
- No dependency-related legal/compliance ambiguity remains.

---

## 22. Build a release-grade Apple QA matrix

**Goal**
Create a manual QA checklist tied to the real v1.0 release scope.

**Tasks**
- Cover first launch, examples loading, import/export, editing, simulations, help, settings, and errors.
- Cover iPhone and iPad layouts; macOS too if included.
- Cover file-based workflows with real sample files.
- Record pass/fail per device and platform.

**Acceptance criteria**
- Manual QA matrix exists.
- All release-visible workflows are tested on Apple targets.
- Bugs found during QA become tracked issues.

---

## 23. Refresh golden, widget, and integration coverage for release-critical screens

**Goal**
Strengthen confidence in the parts of the app users will actually see.

**Tasks**
- Refresh goldens for core pages and dialogs.
- Add release-critical widget coverage for navigation, settings, home page, import errors, and core panels.
- Add Apple-targeted integration smoke tests where practical.

**Acceptance criteria**
- Release-critical screens have meaningful automated coverage.
- Golden baselines are current.
- Automation supports the Apple release process.

---

## 24. Run performance and memory checks for large automata and complex canvases

**Goal**
Ensure the graphview-based experience remains smooth on Apple devices.

**Tasks**
- Benchmark large DFA/NFA/PDA/TM examples.
- Measure canvas performance during drag/zoom/highlight flows.
- Profile graphview fork hotspots and rendering regressions.
- Tune performance where needed for real devices.

**Acceptance criteria**
- Large-graph performance is acceptable on target Apple hardware.
- No severe jank or memory issue remains in release-critical flows.

---

## 25. Finalize diagnostics, logging, and release build behavior

**Goal**
Ensure the release build is clean and not developer-noisy.

**Tasks**
- Audit debug prints, verbose logs, and developer-only diagnostics.
- Ensure release builds do not expose internal debugging output unnecessarily.
- Keep only what is needed for safe troubleshooting.

**Acceptance criteria**
- Release build output is clean.
- Internal development noise is removed from the user experience.

---

## 26. Write Apple App Store listing copy aligned with the actual shipped scope

**Goal**
Produce accurate public-facing store copy.

**Tasks**
- Draft subtitle, description, keywords, and What’s New.
- Frame the app clearly as an educational automata/formal language tool.
- Avoid promising unfinished modules or unstable interoperability features.

**Acceptance criteria**
- Store copy is accurate and polished.
- Public messaging matches the shipped app.

---

## 27. Publish support URL, privacy policy, and release support materials

**Goal**
Prepare the public URLs required for submission.

**Tasks**
- Publish support page.
- Publish privacy policy.
- Provide concise support/contact information.
- Ensure links are stable and production-ready.

**Acceptance criteria**
- Required public URLs are live.
- Apple submission metadata can be completed without placeholders.

---

## 28. Create the App Store Connect record and fill Apple metadata

**Goal**
Prepare the app record for submission.

**Tasks**
- Create the app entry.
- Fill name, SKU, category, pricing/distribution, age rating, privacy, and screenshot metadata.
- Confirm supported devices/families.

**Acceptance criteria**
- App Store Connect record is complete.
- No required field is left unresolved.

---

## 29. Produce the first Apple release candidate and validate it on real hardware

**Goal**
Create the real release candidate binary and verify it.

**Tasks**
- Build the signed release candidate.
- Install it on real supported Apple devices.
- Run the release QA matrix.
- Confirm screenshots and metadata still match the binary.

**Acceptance criteria**
- Release candidate is signed and testable.
- Real-device QA passes for the v1.0 scope.

---

## 30. Submit to TestFlight / App Review and handle launch feedback

**Goal**
Complete the Apple release flow through review and public launch.

**Tasks**
- Upload the release candidate.
- Resolve processing issues.
- Use TestFlight/internal review as needed.
- Submit for App Review.
- Address reviewer feedback and publish the release.

**Acceptance criteria**
- The app reaches App Review with a clean candidate.
- Review feedback is handled quickly.
- JFlutter ships publicly on the chosen Apple platform scope.

---

## Optional follow-up: companion issue set for the `graph` fork

If you want, create a second issue file just for the fork repository with:
- release tagging/versioning
- fork delta documentation
- upstream sync strategy
- performance benchmarks
- iOS/macOS rendering QA
- README/changelog cleanup
- dependency publishing strategy for JFlutter
