# R15 Planar Racer Physics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Constrain every racer to its X/Y gameplay plane so Z drift and out-of-plane rotation cannot become gameplay, while preserving free X/Y translation and free physical rotation around world Z.

**Architecture:** Keep `RacerStabilizer` as the sole owner. `AlignPosition` becomes an always-on world-space Z-only servo, and `AlignOrientation` becomes a one-attachment `PrimaryAxisParallel` constraint that aligns the racer's plane normal with world Z while leaving spin around that normal free. No side walls, steering, per-frame teleports, or new movement service are introduced.

**Tech Stack:** Roblox Luau, `AlignPosition`, `AlignOrientation`, `PhysicsConfig`, Studio specs, Python contract tests, Rojo 7.7.0, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-10-r15-planar-racer-physics-design.md`

## Global Constraints

- Work only on `main`; no PR/feature-branch implementation flow.
- X translation stays physical/free.
- Y translation stays physical/free.
- Z translation is constrained to `laneCenterZ`.
- Rotation around world Z stays physical/free.
- Out-of-plane rotation around world X/Y is constrained.
- No invisible side walls.
- No per-Heartbeat CFrame teleport as the normal solution.
- No changes to drawing, stroke processing, leg geometry, motor direction, camera, obstacle geometry, or production recovery ownership.
- Starting planar defaults: `LaneNormalError=0.03`, `LaneHardBound=0.08`, `LaneMaxForceZ=60000`, `LaneResponsiveness=40`, `LaneMaxVelocity=30`, `OrientationResponsiveness=40`, `OrientationMaxTorque=60000`, `OrientationMaxAngularVelocity=30`.
- Human Studio G0 remains PENDING until the user supplies runtime evidence.

---

### Task 1: Add RED contract coverage for planar semantics

**Files:**
- Create: `tests/test_r15_planar_racer_physics.py`
- Modify: `src/server/Tests/B10StabilizationSpec.lua`

**Interfaces:**
- Consumes: `PhysicsConfig.Stabilization`, `RacerRuntime:GetStabilizer()`, `RacerStabilizer:GetLaneAlign()`, `RacerStabilizer:GetOrientationAlign()`.
- Produces: executable/static contract requiring always-on Z-only position authority and plane-normal-only orientation authority.

- [ ] **Step 1: Write the failing Python regression**

Create `tests/test_r15_planar_racer_physics.py` with checks equivalent to:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r15_stabilizer_is_continuous_z_only_planar_lock() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")

    assert "LaneCorrectionDeadzone" not in stabilizer
    assert "self.laneAlign.Enabled = true" in stabilizer
    assert "Vector3.new(0, 0, config.LaneMaxForceZ)" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" in stabilizer
    assert "orientationAlign.PrimaryAxis = Vector3.zAxis" in stabilizer
    assert "orientationAlign.Enabled = true" in stabilizer

    for token in [
        "LaneNormalError = 0.03",
        "LaneHardBound = 0.08",
        "LaneMaxForceZ = 60000",
        "LaneResponsiveness = 40",
        "LaneMaxVelocity = 30",
        "OrientationResponsiveness = 40",
        "OrientationMaxTorque = 60000",
        "OrientationMaxAngularVelocity = 30",
    ]:
        assert token in config


def test_r15_b10_checks_free_xy_locked_z_and_plane_normal_orientation() -> None:
    spec = read("src/server/Tests/B10StabilizationSpec.lua")
    for token in [
        "PrimaryAxisParallel",
        "PrimaryAxis",
        "Vector3.zAxis",
        "lane constraint must remain continuously enabled",
        "planar orientation constraint must remain continuously enabled",
        "in-plane rotation around Z",
        "out-of-plane",
    ]:
        assert token in spec
```

- [ ] **Step 2: Strengthen B10 with the intended runtime assertions before changing production**

Replace old deadzone/free-tilt assertions with assertions requiring:

```lua
assert(laneAlign.Enabled == true, "lane constraint must remain continuously enabled")
assert(laneAlign.MaxAxesForce.X == 0)
assert(laneAlign.MaxAxesForce.Y == 0)
assert(laneAlign.MaxAxesForce.Z == config.LaneMaxForceZ)
assert(orientationAlign.Enabled == true, "planar orientation constraint must remain continuously enabled")
assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel)
assert(orientationAlign.PrimaryAxis == Vector3.zAxis)
```

Add a pure configuration/runtime check that an in-plane body rotation around Z does not cause the constraint target to become `AllAxes`, and an out-of-plane disturbance keeps the plane-normal constraint active.

- [ ] **Step 3: Run RED**

Run:

```bash
python verify.py
```

Expected: new R15 checks fail because current implementation still uses `LaneCorrectionDeadzone`, disables `LaneAlign`, uses full-axis orientation correction, and old soft-lane numbers.

- [ ] **Step 4: Commit RED**

```bash
git add tests/test_r15_planar_racer_physics.py src/server/Tests/B10StabilizationSpec.lua
git commit -m "test: define R15 planar racer physics"
```

---

### Task 2: Implement continuous position and orientation plane lock

**Files:**
- Modify: `src/server/Runtime/RacerStabilizer.lua`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify only if required by axis ownership: `src/server/Runtime/RacerRuntime.lua`

**Interfaces:**
- Consumes: existing `LaneAlignAttachment` and `OrientationAttachment` moved from template staging into `BodyCollider`.
- Produces: `LaneAlign` with permanent Z-only authority and `OrientationAlign` with permanent plane-normal-only authority.

- [ ] **Step 1: Replace soft-lane numbers with planar defaults**

In `PhysicsConfig.Stabilization`, remove `LaneCorrectionDeadzone` and `OrientationFreeTiltDegrees`, and set:

```lua
Stabilization = {
    LaneNormalError = 0.03,
    LaneHardBound = 0.08,
    LaneMaxForceZ = 60000,
    LaneResponsiveness = 40,
    LaneMaxVelocity = 30,
    OrientationResponsiveness = 40,
    OrientationMaxTorque = 60000,
    OrientationMaxAngularVelocity = 30,
},
```

- [ ] **Step 2: Make AlignPosition continuously Z-only**

In `RacerStabilizer.new`, keep:

```lua
laneAlign.ForceLimitMode = Enum.ForceLimitMode.PerAxis
laneAlign.ForceRelativeTo = Enum.ActuatorRelativeTo.World
laneAlign.MaxAxesForce = Vector3.new(0, 0, config.LaneMaxForceZ)
laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, params.laneCenterZ)
```

but set:

```lua
laneAlign.Enabled = true
```

In `Step()`, continue refreshing only the unconstrained X/Y target components while keeping canonical Z:

```lua
self.laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, self.laneCenterZ)
self.laneAlign.Enabled = true
```

Do not write `body.Position`, `body.CFrame`, X velocity, or Y velocity in normal operation.

- [ ] **Step 3: Configure AlignOrientation for plane-normal-only alignment**

Use official Roblox `AlignOrientation` semantics: `Mode=OneAttachment` plus `AlignType=PrimaryAxisParallel` applies torque only when primary axes become misaligned, leaving rotation around the aligned axis free.

Configure:

```lua
orientationAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
orientationAlign.Attachment0 = orientationAttachment
orientationAlign.AlignType = Enum.AlignType.PrimaryAxisParallel
orientationAlign.PrimaryAxis = Vector3.zAxis
orientationAlign.RigidityEnabled = false
orientationAlign.ReactionTorqueEnabled = false
orientationAlign.Responsiveness = config.OrientationResponsiveness
orientationAlign.MaxTorque = config.OrientationMaxTorque
orientationAlign.MaxAngularVelocity = config.OrientationMaxAngularVelocity
orientationAlign.Enabled = true
```

Ensure `orientationAttachment.Axis = Vector3.zAxis` before the constraint is activated. Prefer owning that assignment in `RacerStabilizer` immediately after taking the attachment; touch `RacerRuntime.lua` only if Studio proves the template attachment orientation must be explicit before reparenting.

Do not use `CFrame.identity`/`AllAxes` as the gameplay orientation target.

- [ ] **Step 4: Simplify Step() to diagnostics, not enable/disable gameplay gates**

Replace deadzone and Euler-angle gating with:

```lua
local errorZ = body.Position.Z - self.laneCenterZ
local absoluteError = math.abs(errorZ)

self.laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, self.laneCenterZ)
self.laneAlign.Enabled = true
self.orientationAlign.Enabled = true
self.model:SetAttribute("LaneNormalBoundExceeded", absoluteError > config.LaneNormalError)
self.model:SetAttribute("LaneHardBoundExceeded", absoluteError > config.LaneHardBound)
```

Do not add a hard snap yet. The spec allows it only if Studio evidence proves the continuous constraint cannot hold the plane under deliberate lateral disturbance.

- [ ] **Step 5: Run focused/full GREEN**

Run:

```bash
python verify.py
```

Expected: all contract checks PASS.

- [ ] **Step 6: Build the place**

Run locally or through CI:

```bash
rojo build default.project.json -o DrawRacersDev.rbxlx
```

Expected: build succeeds.

- [ ] **Step 7: Commit implementation**

```bash
git add src/server/Runtime/RacerStabilizer.lua src/shared/Config/PhysicsConfig.lua src/server/Runtime/RacerRuntime.lua
git commit -m "fix: lock racer physics to gameplay plane"
```

Only include `RacerRuntime.lua` if it actually changed.

---

### Task 3: Reconcile physics-owner documentation after automated GREEN

**Files:**
- Modify: `docs/03_CORE_MECHANICS_SPEC.md`
- Modify: `docs/16_BALANCE_TUNING.md`
- Modify: `docs/SESSION.md`
- Modify: `docs/FEATURE_LIST.md`
- Create or update: `docs/DECISION_LOG_R15_PLANAR_RACER_PHYSICS_2026-09-10.md`
- Test: add/extend focused docs consistency regression under `tests/`

**Interfaces:**
- Consumes: implemented R15 semantics and exact starting values.
- Produces: one non-contradictory owner story for planar locomotion; G0 remains human-pending.

- [ ] **Step 1: Add docs RED before updating docs**

Add a regression requiring owner docs to contain these semantics:

```python
assert "X/Y gameplay plane" in core
assert "Z translation" in core and "locked" in core
assert "rotation around world Z" in core and "free" in core
assert "LaneNormalError" not in balance or "0.03" in balance
assert "0.35 stud" not in balance
assert "0.75 stud" not in balance
assert "G0" in session and "PENDING" in session
```

Run `python verify.py`; expected docs consistency FAIL.

- [ ] **Step 2: Update core mechanics**

In `docs/03_CORE_MECHANICS_SPEC.md`, replace the soft lane wording with an explicit planar contract:

```text
Racer locomotion is 2.5D. X/Y are the physical gameplay plane. Z translation is locked to the racer's lane center and is not player steering/gameplay. Rotation around world Z remains physical and free; out-of-plane X/Y rotation is constrained.
```

- [ ] **Step 3: Update tuning ownership**

In `docs/16_BALANCE_TUNING.md`, replace `Z stays near lane center` plus `0.15/0.35/0.75` allowed-error language with the exact R15 defaults and clarify that `0.03`/`0.08` are diagnostic solver tolerances, not gameplay freedom.

- [ ] **Step 4: Update status/evidence without passing human G0**

Record:

```text
R15 IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING
B17/G0 PENDING
```

and document the original Studio evidence (`laneDeviation 0.418` plus side-fall/recovery) as the trigger for R15.

- [ ] **Step 5: Run GREEN and commit docs**

```bash
python verify.py
git add docs tests
git commit -m "docs: record R15 planar physics contract"
```

Expected: all checks PASS.

---

### Task 4: Fresh CI and human Studio acceptance handoff

**Files:**
- No production files unless a new reproducible Studio defect is found.

**Interfaces:**
- Consumes: R15 implementation and docs.
- Produces: automated evidence plus one bounded human Studio checklist.

- [ ] **Step 1: Verify current `main` and fresh CI**

Confirm the implementation head and wait for the push-triggered Contract Verify workflow.

Required evidence:

```text
python verify.py -> 0 failed
Rokit install -> PASS
rojo build default.project.json -> PASS
```

- [ ] **Step 2: Human Studio G0 checklist**

User runs a freshly built/synced place and verifies:

```text
[DrawRacers][StudioGate] TOTAL 13 PASS / 0 FAIL
[DrawRacers][StudioGate] READY
[DrawRacers][G0] human harness ready
```

Then:

1. Draw at least three legal shapes and redraw while moving.
2. Verify forward/backward X movement remains physical.
3. Verify jump/fall Y movement remains physical.
4. Verify the cube can tumble/rotate in the side-view X/Y plane.
5. Verify no visible sideways Z steering/drift and `laneDeviation` normally stays <= `0.03`.
6. If possible, deliberately create a strong asymmetric contact; excursion above `0.08` is FAIL evidence.
7. Verify falling through the actual gap still triggers R14.6 recovery and the accepted shape/version survives.

- [ ] **Step 3: If Studio passes, record human evidence separately**

Only after the user supplies runtime evidence may R15 be marked Studio PASS. Do not automatically promote B17/G0; the external tester requirement remains separate.

- [ ] **Step 4: If Studio fails, stop and debug the specific failure**

Do not tune multiple constants blindly. Capture `laneDeviation`, body orientation, `LaneHardBoundExceeded`, screenshot/video, and Output around the failure, then use one RED reproduction per fix.
