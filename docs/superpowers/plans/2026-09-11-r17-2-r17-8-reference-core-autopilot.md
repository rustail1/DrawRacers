# R17.2–R17.8 Reference-Core Autopilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish every automatable R17 reference-core task so one final Studio run can produce the human evidence needed for the remaining origin/tuning decisions.

**Architecture:** Keep production gameplay owners unchanged unless a task explicitly authorizes a bounded change. Rider work stays client-presentation-only. Origin/body-feel work is implemented first as Studio-only evidence harnesses; production first-point origin and body tuning remain unchanged until human evidence. Reuse `R16ReferenceShapes` and `R16TrialRunner` rather than creating a second gameplay path.

**Tech Stack:** Roblox Luau, Rojo, Python contract tests, GitHub Actions/Rokit/Rojo build.

**Spec:** `docs/superpowers/specs/2026-09-11-r17-reference-core-design.md`

## Global Constraints

- Work directly on `main`; no PR workflow.
- TDD for every production/harness behavior change: RED commit -> verify expected failure -> minimal GREEN commit -> full verify/build/CI.
- Server remains authoritative for accepted ShapeSpec; network payload/remotes unchanged.
- Camera/rider remain client presentation only.
- Production first-point origin stays unchanged until R17.3 human evidence and R17.4 explicit decision.
- Production body density/friction/collider defaults stay unchanged until R17.6 human evidence.
- Motor defaults stay `-8 / 35000 / 120` during body-feel sweeps.
- No hidden forward propulsion and no fake human PASS.
- Automated evidence may print READY/PENDING but must never claim human camera/rider/solver feel acceptance.

---

### Task 1: Finish R17.0 documentation reconciliation

**Files:**
- Modify: `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`
- Modify: `docs/SESSION.md`

**Interfaces:**
- Consumes: `DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md`.
- Produces: owner docs matching the already-active production camera/rider and current R17 sequence.

- [ ] Replace future-only D09/E03 wording with active provisional R17 owners; keep RacerService at D05.
- [ ] Record R17 as current core program in SESSION with all human gates still pending.
- [ ] Commit docs only.

### Task 2: R17.2 rider deterministic mount/rig pose

**Files:**
- Modify: `tests/test_camera_rider_presentation.py`
- Modify: `src/client/Controllers/RiderPresentationController.lua`

**Interfaces:**
- Produces: one deterministic rider mount function relative to BodyCollider top and a presentation rig where only HumanoidRootPart is anchored; visible rig parts remain non-colliding/non-touching/non-querying/massless.

- [ ] RED: require `RIDER_MOUNT_Y_OFFSET`, `RIDER_MOUNT_X_OFFSET`, a root-only anchor policy, and no `riderHeight * 0.5` placement heuristic.
- [ ] Verify RED is isolated to rider contract.
- [ ] GREEN: anchor HRP only, leave child parts unanchored but massless/nonphysical, apply deterministic jockey pose after sanitization/scale, place via body-position mount offset without body rotation.
- [ ] Verify full suite/build/CI and commit.

### Task 3: R17.3 mechanical-origin comparison harness

**Files:**
- Create: `tests/test_r17_reference_core.py`
- Create: `src/server/Tests/R17OriginExperiment.lua`
- Modify: `src/shared/Math/StrokeMath.lua` only if pure candidate helpers are required.

**Interfaces:**
- Produces candidate transforms for `FIRST_POINT`, `BOUNDS_CENTER`, `GEOMETRY_CENTROID` without changing production ShapeSpec path.
- Uses canonical R16 reference shapes.

- [ ] RED: require three candidate policies and six canonical shapes.
- [ ] Verify expected missing-module RED.
- [ ] GREEN: build deterministic candidate points and print per-shape extents/readability descriptors; preserve order/proportions/network schema.
- [ ] Do not select a winner automatically.
- [ ] Verify and commit.

### Task 4: R17.5 live phase evidence harness

**Files:**
- Modify: `tests/test_r17_reference_core.py`
- Create: `src/server/Tests/R17PhaseEvidence.lua`

**Interfaces:**
- Produces live-Hinge phase samples using real RacerRuntime phase owner, not duplicate correction logic.

- [ ] RED: require live drift injection, Heartbeat sampling, max-error/continuous-excursion telemetry, motor sign checks, and cleanup.
- [ ] GREEN: run a bounded Studio-only experiment after injected drift and after redraw; print evidence, return boolean only for structural/safety invariants. Human solver-feel remains pending.
- [ ] Verify and commit.

### Task 5: R17.6 body-feel A/B evidence harness

**Files:**
- Modify: `tests/test_r17_reference_core.py`
- Create: `src/server/Tests/R17BodyFeelExperiment.lua`
- Modify: `src/server/Tests/R16TrialRunner.lua` only for reusable measurement options/telemetry.

**Interfaces:**
- Candidate density = `1.00, 0.60, 0.40`.
- Candidate friction = `0.45, 0.25, 0.10`.
- Collider-size evidence candidates = `3.0, 2.8, 2.6`, measurement-only unless explicitly selected later.
- Produces trial duration, body/belly contact time, leg contact time, air time, forward distance, average speed, stuck time.

- [ ] RED: require exact candidate arrays and telemetry keys.
- [ ] GREEN: Studio-only bounded sweeps reset all modified physical properties after each candidate and never persist a winner to production config.
- [ ] Keep motor values unchanged and anti-stall evidence visible.
- [ ] Verify and commit.

### Task 6: R17.7 reference-course evidence

**Files:**
- Modify: `tests/test_r17_reference_core.py`
- Create: `src/server/Tests/R17ReferenceCourseHarness.lua`

**Interfaces:**
- Reuses `R16ReferenceShapes`/`R16TrialRunner` across Flat/SmallSteps/GapSmall/WallMedium/LowTunnelWide.
- Produces one compact matrix for six shapes plus live-redraw evidence.

- [ ] RED: require exact shape/piece IDs and no second movement implementation.
- [ ] GREEN: run canonical matrix and print progress/completion/speed/anti-stall results; no automatic tuning mutation.
- [ ] Verify and commit.

### Task 7: R17.8 one-click final evidence aggregator

**Files:**
- Modify: `tests/test_r17_reference_core.py`
- Create: `src/server/Tests/R17FinalHarness.lua`
- Modify: `src/shared/Config/StudioHarnessConfig.lua`
- Modify: `src/server/Bootstrap.server.lua`

**Interfaces:**
- Adds `R17FINAL` mode while preserving default `G0`.
- Runs existing R16 evidence first, then R17 origin/phase/body/reference evidence, then starts existing human G0 harness.

- [ ] RED: require `R17FINAL` dispatch/order and final marker `[DrawRacers][R17FINAL] HUMAN REVIEW READY`.
- [ ] GREEN: synchronous ordered evidence; any structural automated failure blocks human handoff. Human-only comparisons print PENDING, not PASS.
- [ ] Verify and commit.

### Task 8: Final repository verification and handoff

**Files:**
- Modify docs only if needed to record automated closure; do not fabricate Studio results.

- [ ] Run fresh `python verify.py` in CI, Rokit, Rojo build.
- [ ] Diff-audit from R17.1 accepted base.
- [ ] Confirm no remotes/network schema/economy/meta/multiplayer changes.
- [ ] Give user one Studio procedure: set `Mode = "R17FINAL"`, Play once, send complete Output plus short camera/rider/leg video/screens.
- [ ] R17.4 production origin migration and final R17.6 tuning remain explicitly blocked on that single human evidence run.
