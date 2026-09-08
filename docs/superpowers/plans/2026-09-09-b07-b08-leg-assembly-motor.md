# B07-B08 Leg Assembly + Motor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one canonical physical leg from cleaned shape points and drive it with one canonical hinge motor on the M0 flat lane.

**Architecture:** Add one focused `LegAssembly` runtime module under `src/server/Runtime`. It owns one side's LegRoot, HingeConstraint, physical segments, welds and cleanup. Extend physics config with exact B07/B08 constants, extend collision setup so `Track/RacerBody/RacerLeg` obey the launch matrix, and add Studio-only B07/B08 specs/harness without introducing the B09 right-leg/phase system.

**Tech Stack:** Roblox Luau, Rojo 7.7.0, Python repository contract checks, Roblox Studio Play acceptance.

**Spec:** `docs/superpowers/specs/2026-09-09-b07-b08-leg-assembly-motor-design.md`

## Global Constraints
- Work directly on `main` only; no branches/PRs.
- B09 right-leg duplication/phase is out of scope.
- LegCanvasHalfSpan = 3.15 studs.
- MaxLegExtentFromHub = 4.5 studs.
- PhysicalLegSegmentThickness = 0.45 studs.
- InnerHubNoCollisionRadius = 0.65 studs.
- Segment minimum mapped length = 0.08 stud; overlap allowance = 0.06 stud.
- AngularVelocity = -8.0 rad/s; MotorMaxTorque = 35000; MotorMaxAcceleration = 120.
- One leg has exactly one HingeConstraint motor.
- No intentional +X force, velocity assignment, teleport or hidden propulsion.
- RacerLeg↔Track collides; RacerLeg↔RacerBody and RacerLeg↔RacerLeg do not.

---

### Task 1: B07 repository contract test

**Files:**
- Create: `tests/test_b07_leg_assembly.py`

**Interfaces:**
- Consumes: existing repo paths/config.
- Produces: static contract for the new `LegAssembly`, B07 constants and Studio spec wiring.

- [ ] **Step 1: Write the failing test**

Create assertions that require `src/server/Runtime/LegAssembly.lua`, B07 constants in `PhysicsConfig.lua`, `src/server/Tests/B07LegAssemblySpec.lua`, and bootstrap wiring. Assert the implementation tokens include canonical mapping/cap, `RacerLeg`, welds, `LegRoot`, `HubJoint`, `Segments`, `Visual`, and no RightLeg construction.

- [ ] **Step 2: Run test to verify it fails**

Run: `python verify.py`
Expected: FAIL in `test_b07_leg_assembly.py` because `LegAssembly.lua` / B07 constants/spec do not exist.

- [ ] **Step 3: Commit the red test**

Commit only the new contract test.

---

### Task 2: B07 one-leg constructor

**Files:**
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Create: `src/server/Runtime/LegAssembly.lua`
- Create: `src/server/Tests/B07LegAssemblySpec.lua`
- Modify: `src/server/Bootstrap.server.lua`

**Interfaces:**
- Consumes: `RacerRuntime:GetModel()`, canonical `LeftHub`, cleaned normalized `Vector2` points.
- Produces: `LegAssembly.new({ side = "Left", racerModel = Model, normalizedPoints = {Vector2}, motorEnabled = boolean? })`, `GetModel()`, `GetRoot()`, `GetJoint()`, `GetSegments()`, `SetEnabled(boolean)`, `Destroy()`.

- [ ] **Step 1: Extend exact physics config**

Add `LegGeometry` and `Motor` tables with the exact numeric constants in Global Constraints.

- [ ] **Step 2: Implement collision setup**

In the existing racer collision setup, ensure `Track`, `RacerBody`, `RacerLeg` groups exist and set: body↔body=false, body↔leg=false, leg↔leg=false, body↔track=true, leg↔track=true.

- [ ] **Step 3: Implement minimal `LegAssembly`**

Map normalized points with isotropic 3.15 scale, radial-clamp each mapped point to 4.5, skip mapped segments below 0.08, build `Segment_01..NN` with length+0.06 and 0.45 short axes, weld each to LegRoot, and create exact LeftLeg tree. Use a +Z attachment axis and create one disabled/optional motorized HingeConstraint. Do not fabricate a center spoke.

- [ ] **Step 4: Add B07 Studio behavior spec**

Spawn a B06 racer, build one LeftLeg from a legal shape, assert exact tree, hub/root coincidence, segment cap, weld ownership, canonical collision groups and cleanup, then destroy all test runtime instances. Print `[DrawRacers][B07] one-leg geometry tests PASS`.

- [ ] **Step 5: Wire B07 spec into Studio bootstrap**

Run it after B06.

- [ ] **Step 6: Run repository contract checks**

Run: `python verify.py`
Expected: B07 contract test PASS and no existing regression failures.

---

### Task 3: B08 repository contract test

**Files:**
- Create: `tests/test_b08_one_hinge_motor.py`

**Interfaces:**
- Consumes: B07 `LegAssembly`.
- Produces: static guard for exact motor defaults, one motor/leg and a Studio movement harness without hidden +X propulsion.

- [ ] **Step 1: Write the failing test**

Require exact `AngularVelocity`, `MotorMaxTorque`, `MotorMaxAcceleration`, `ActuatorType`, B08 Studio harness/spec tokens, and prohibit `AssemblyLinearVelocity`, `VectorForce`, `LinearVelocity`, `ApplyImpulse`, and explicit +X body translation inside `LegAssembly.lua` and the B08 harness.

- [ ] **Step 2: Run test to verify it fails**

Run: `python verify.py`
Expected: FAIL because B08 harness/spec is not yet present.

- [ ] **Step 3: Commit the red test**

Commit only the new B08 contract test.

---

### Task 4: B08 motor + flat movement harness

**Files:**
- Modify: `src/server/Runtime/LegAssembly.lua`
- Create: `src/server/Tests/B08OneHingeMotorHarness.lua`
- Modify: `src/server/Bootstrap.server.lua`
- Modify: `src/server/M0TestScene.lua`

**Interfaces:**
- Consumes: B07 LeftLeg tree and M0 flat lane.
- Produces: one enabled hinge motor and observable Studio diagnostics for physical flat movement.

- [ ] **Step 1: Mark M0 flat lane as Track collision**

Register/assign the `Track` collision group to the lane without changing A03 geometry.

- [ ] **Step 2: Enable canonical hinge motor**

`HubJoint.ActuatorType = Enum.ActuatorType.Motor`, `AngularVelocity = -8.0`, `MotorMaxTorque = 35000`, `MotorMaxAcceleration = 120`. Exactly one joint exists for LeftLeg.

- [ ] **Step 3: Add Studio movement harness**

Spawn one test racer at a safe X/Y/Z on the flat lane, attach one LeftLeg built from canonical ROUND_01, enable the motor, make only Studio acceptance presentation visible, capture starting X, and print displacement/speed diagnostics after physics has advanced. Do not create RightLeg and do not apply +X force/velocity/teleport.

- [ ] **Step 4: Wire B08 harness into Studio bootstrap**

Run after deterministic B03-B07 specs. Print `[DrawRacers][B08] one-hinge flat harness ready` and later a diagnostic `[DrawRacers][B08] deltaX=... speedX=...`.

- [ ] **Step 5: Run repository contract checks**

Run: `python verify.py`
Expected: all contract tests PASS.

- [ ] **Step 6: Human Studio acceptance**

Run Play. Require B07 PASS line, B08 harness-ready line, one visible one-leg racer on the flat lane, and observable positive X displacement generated by contact. Human records PASS/FAIL before B09 begins.
