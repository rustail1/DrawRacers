# B09 Two Legs + Phase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build two identical-XY physical legs from one shape, with canonical left/right hubs and a 180° right-leg starting phase.

**Architecture:** `LegAssembly` stays one-side-per-instance and gains side selection plus explicit initial phase. `RacerRuntime:ApplyShape` owns creation/destruction of the B09 pair from one point sequence. B10+ responsibilities remain untouched.

**Tech Stack:** Roblox Luau, Rojo 7.7.0, repository Python contract verifier, Studio Play harness.

**Spec:** `docs/superpowers/specs/2026-09-09-b09-two-legs-phase-design.md`

## Global Constraints
- Main branch only; no branch/PR workflow.
- Same normalized XY ShapeSpec for both sides; never mirror/invert XY.
- Canonical hub centers remain Left `(0,-0.75,-1.62)` and Right `(0,-0.75,+1.62)`.
- Hinge axis is +Z on both sides.
- AngularVelocity stays `-8.0 rad/s`; torque `35000`; acceleration `120`.
- Right phase starts at exactly `180°` from the B09 default.
- No stabilization/lane/network/atomic-redraw work is pulled into B09.

---

### Task 1: B09 failing contract and Studio spec

**Files:**
- Create: `tests/test_b09_two_legs_phase.py`
- Create: `src/server/Tests/B09TwoLegPhaseSpec.lua`

**Interfaces:**
- Consumes: existing `RacerRuntime.new`, `LegAssembly.new`, `PhysicsConfig`.
- Produces: executable acceptance expectations for two-side support, same mapped XY, +Z axes, identical motor values and 180° phase.

- [ ] **Step 1: Write the failing repository contract test** that requires `RightPhaseOffsetDegrees = 180`, both side names in `LegAssembly`, `RacerRuntime:ApplyShape`, and B09 Studio wiring.
- [ ] **Step 2: Run/replay the contract against the pre-B09 files and verify RED** because B09 production seams do not exist yet.
- [ ] **Step 3: Write the Studio B09 spec** to spawn one racer, call one ApplyShape with an asymmetric preset, compare left/right mapped points, hubs, motors and phase, then clean up.

### Task 2: Side-aware LegAssembly

**Files:**
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/LegAssembly.lua`
- Modify: `tests/test_b07_leg_assembly.py`

**Interfaces:**
- Consumes: `BuildParams { racerModel, side, normalizedPoints, motorEnabled, initialPhaseDegrees? }`.
- Produces: one `LeftLeg` or `RightLeg` using the corresponding hub; `GetMappedPoints`, `GetJoint`, `GetRoot`, `Destroy` remain available.

- [ ] **Step 1: Add `RightPhaseOffsetDegrees = 180`** to motor config.
- [ ] **Step 2: Generalize LegAssembly side resolution** without changing the existing mapping/collider rules.
- [ ] **Step 3: Apply phase as a root rotation around +Z before segment construction**; keep same motor sign on both sides.
- [ ] **Step 4: Make the historical B07 contract progression-safe** by removing its permanent `RightLeg` prohibition while preserving B07’s one-leg requirements.

### Task 3: One-shape two-leg RacerRuntime orchestration

**Files:**
- Modify: `src/server/Runtime/RacerRuntime.lua`

**Interfaces:**
- Produces: `RacerRuntime:ApplyShape(normalizedPoints: {Vector2}, motorEnabled: boolean?) -> (leftLeg, rightLeg)` and destroys those assemblies in `RacerRuntime:Destroy()`.

- [ ] **Step 1: Require LegAssembly in RacerRuntime.**
- [ ] **Step 2: Add `ApplyShape`** that replaces the current B09 pair and sends the same `normalizedPoints` to both sides, phase 0°/180°.
- [ ] **Step 3: Ensure runtime destroy cleans both assembly objects before the model is destroyed.**

### Task 4: Studio wiring and verification handoff

**Files:**
- Modify: `src/server/Bootstrap.server.lua`

**Interfaces:**
- Produces: `[DrawRacers][B09] two-leg same-XY/phase tests PASS` in Studio on acceptance.

- [ ] **Step 1: Wire `B09TwoLegPhaseSpec.run()` after B06/B07 structural specs and before/alongside the B08 harness.**
- [ ] **Step 2: Replay repository contract tests against final files and verify GREEN.**
- [ ] **Step 3: Human Studio gate:** user pulls, Stop→Play, confirms B09 PASS line and visible two-leg phase behavior; do not mark B09 ACCEPTED before this evidence.
