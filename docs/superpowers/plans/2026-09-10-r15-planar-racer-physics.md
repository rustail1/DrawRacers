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

Create `tests/test_r15_planar_racer_physics.py`:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r15_stabilizer_is_continuous_z_only_planar_lock() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    config = read("src/shared/Config/PhysicsConfig.lua")

    assert "LaneCorrectionDeadzone" not in stabilizer
    assert "OrientationFreeTiltDegrees" not in stabilizer
    assert "self.laneAlign.Enabled = true" in stabilizer
    assert "Vector3.new(0, 0, config.LaneMaxForceZ)" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" in stabilizer
    assert "orientationAlign.PrimaryAxis = Vector3.zAxis" in stabilizer
    assert "orientationAttachment.Axis = Vector3.zAxis" in stabilizer
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

    assert "LaneCorrectionDeadzone" not in config
    assert "OrientationFreeTiltDegrees" not in config


def test_r15_b10_checks_planar_constraint_shape() -> None:
    spec = read("src/server/Tests/B10StabilizationSpec.lua")
    for token in [
        "PrimaryAxisParallel",
        "orientationAlign.PrimaryAxis == Vector3.zAxis",
        "lane constraint must remain continuously enabled",
        "planar orientation constraint must remain continuously enabled",
        "in-plane rotation around Z must remain unconstrained",
        "out-of-plane disturbance must keep planar correction active",
    ]:
        assert token in spec
```

- [ ] **Step 2: Rewrite the B10 stabilization assertions as the RED Studio contract**

Keep the existing collision-matrix assertions. After obtaining `laneAlign` and `orientationAlign`, use:

```lua
assert(laneAlign.Mode == Enum.PositionAlignmentMode.OneAttachment)
assert(laneAlign.ForceLimitMode == Enum.ForceLimitMode.PerAxis)
assert(laneAlign.ForceRelativeTo == Enum.ActuatorRelativeTo.World)
assert(laneAlign.MaxAxesForce.X == 0, "B10 planar lock must apply zero X force")
assert(laneAlign.MaxAxesForce.Y == 0, "B10 planar lock must apply zero Y force")
assert(laneAlign.MaxAxesForce.Z == config.LaneMaxForceZ, "B10 planar lock must apply only configured Z force")
assert(laneAlign.Enabled == true, "lane constraint must remain continuously enabled")
assert(math.abs(laneAlign.Position.Z - 2.5) <= 1e-6, "planar Z target must equal canonical lane center")

assert(orientationAlign.Mode == Enum.OrientationAlignmentMode.OneAttachment)
assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel)
assert(orientationAlign.PrimaryAxis == Vector3.zAxis)
assert(orientationAlign.RigidityEnabled == false)
assert(orientationAlign.Enabled == true, "planar orientation constraint must remain continuously enabled")
```

Then replace the old free-tilt/deadzone scenarios with:

```lua
body.CFrame = CFrame.new(body.Position) * CFrame.Angles(0, 0, math.rad(70))
stabilizer:Step()
assert(orientationAlign.Enabled == true, "in-plane rotation around Z must remain unconstrained")
assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel, "in-plane rotation must not promote to AllAxes")

body.CFrame = CFrame.new(body.Position) * CFrame.Angles(math.rad(30), 0, 0)
stabilizer:Step()
assert(orientationAlign.Enabled == true, "out-of-plane disturbance must keep planar correction active")
assert(orientationAlign.AlignType == Enum.AlignType.PrimaryAxisParallel)

body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneNormalError + 0.005)
stabilizer:Step()
assert(laneAlign.Enabled == true)
assert(model:GetAttribute("LaneNormalBoundExceeded") == true)
assert(model:GetAttribute("LaneHardBoundExceeded") == false)

body.CFrame = CFrame.new(body.Position.X, body.Position.Y, 2.5 + config.LaneHardBound + 0.005)
stabilizer:Step()
assert(laneAlign.Enabled == true)
assert(model:GetAttribute("LaneHardBoundExceeded") == true)
```

These assertions intentionally fail against the current soft-lane implementation.

- [ ] **Step 3: Run RED**

Run:

```bash
python verify.py
```

Expected: the new R15 Python checks fail because current production still uses `LaneCorrectionDeadzone`, `OrientationFreeTiltDegrees`, disabled-at-rest constraints, `AllAxes` orientation behavior, and old soft-lane numbers.

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

In `PhysicsConfig.Stabilization`, replace the current block with:

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

In `RacerStabilizer.new`, retain world/per-axis force limiting and set:

```lua
laneAlign.ForceLimitMode = Enum.ForceLimitMode.PerAxis
laneAlign.ForceRelativeTo = Enum.ActuatorRelativeTo.World
laneAlign.MaxAxesForce = Vector3.new(0, 0, config.LaneMaxForceZ)
laneAlign.MaxVelocity = config.LaneMaxVelocity
laneAlign.Responsiveness = config.LaneResponsiveness
laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, params.laneCenterZ)
laneAlign.Enabled = true
```

Do not enable `RigidityEnabled`; use the configured bounded force/responsiveness first so contacts remain physical.

- [ ] **Step 3: Configure AlignOrientation for plane-normal-only alignment**

Immediately after taking `OrientationAttachment`, set:

```lua
orientationAttachment.Axis = Vector3.zAxis
```

Configure the existing constraint as:

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

Do not set `CFrame.identity` as an all-axis target. `PrimaryAxisParallel` is the intended owner of out-of-plane correction and leaves rotation around the aligned primary axis free.

- [ ] **Step 4: Simplify `Step()` to continuous targets plus diagnostics**

Replace deadzone and Euler-angle gating with:

```lua
local config = PhysicsConfig.Stabilization
local body = self.body
local errorZ = body.Position.Z - self.laneCenterZ
local absoluteError = math.abs(errorZ)

self.laneAlign.Position = Vector3.new(body.Position.X, body.Position.Y, self.laneCenterZ)
self.laneAlign.Enabled = true
self.orientationAlign.Enabled = true
self.model:SetAttribute("LaneNormalBoundExceeded", absoluteError > config.LaneNormalError)
self.model:SetAttribute("LaneHardBoundExceeded", absoluteError > config.LaneHardBound)
```

Do not write `body.Position`, `body.CFrame`, `AssemblyLinearVelocity.X/Y`, or any forward force. Do not add a hard snap in this task; the spec permits one only after concrete Studio solver failure evidence.

- [ ] **Step 5: Run full GREEN**

Run:

```bash
python verify.py
```

Expected: all contract checks PASS, including the new R15 regression.

- [ ] **Step 6: Build the Rojo place**

Run:

```bash
rojo build default.project.json -o DrawRacersDev.rbxlx
```

Expected: build succeeds.

- [ ] **Step 7: Commit implementation**

```bash
git add src/server/Runtime/RacerStabilizer.lua src/shared/Config/PhysicsConfig.lua
# Add RacerRuntime.lua only if Studio/API evidence required an explicit template-axis change there.
git commit -m "fix: lock racer physics to gameplay plane"
```

---

### Task 3: Reconcile physics-owner documentation after automated GREEN

**Files:**
- Create: `tests/test_r15_docs_consistency.py`
- Modify: `docs/03_CORE_MECHANICS_SPEC.md`
- Modify: `docs/16_BALANCE_TUNING.md`
- Modify: `docs/SESSION.md`
- Modify: `docs/FEATURE_LIST.md`
- Create: `docs/DECISION_LOG_R15_PLANAR_RACER_PHYSICS_2026-09-10.md`

**Interfaces:**
- Consumes: implemented R15 semantics and exact starting values.
- Produces: one non-contradictory owner story for planar locomotion; G0 remains human-pending.

- [ ] **Step 1: Add docs RED before changing owner docs**

Create `tests/test_r15_docs_consistency.py`:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r15_owner_docs_define_planar_locomotion_without_passing_g0() -> None:
    core = read("docs/03_CORE_MECHANICS_SPEC.md")
    balance = read("docs/16_BALANCE_TUNING.md")
    session = read("docs/SESSION.md")
    features = read("docs/FEATURE_LIST.md")

    assert "X/Y gameplay plane" in core
    assert "Z translation is locked" in core
    assert "rotation around world Z remains physical and free" in core

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
        assert token in balance

    assert "0.35 stud" not in balance
    assert "0.75 stud" not in balance
    assert "R15" in session and "HUMAN STUDIO PENDING" in session
    assert "B17/G0" in session and "PENDING" in session
    assert "R15" in features and "HUMAN STUDIO PENDING" in features
```

Run `python verify.py`; expected FAIL because the current docs still describe soft-lane behavior.

- [ ] **Step 2: Update core mechanics**

In `docs/03_CORE_MECHANICS_SPEC.md`, replace the soft lane wording with this exact product contract:

```text
Racer locomotion is 2.5D. X/Y are the physical gameplay plane. Z translation is locked to the racer's lane center and is not player steering/gameplay. Rotation around world Z remains physical and free; out-of-plane X/Y rotation is constrained.
```

- [ ] **Step 3: Update tuning ownership**

In `docs/16_BALANCE_TUNING.md`, replace the `Z stays near lane center` and `0.15/0.35/0.75` gameplay-tolerance wording. Record the exact R15 configuration names/values:

```text
LaneNormalError = 0.03
LaneHardBound = 0.08
LaneMaxForceZ = 60000
LaneResponsiveness = 40
LaneMaxVelocity = 30
OrientationResponsiveness = 40
OrientationMaxTorque = 60000
OrientationMaxAngularVelocity = 30
```

State that `0.03` and `0.08` are diagnostic solver tolerances, not permitted lateral gameplay freedom.

- [ ] **Step 4: Create the R15 decision record and status evidence**

Create `docs/DECISION_LOG_R15_PLANAR_RACER_PHYSICS_2026-09-10.md` containing:

```text
Decision: hard 2.5D planar racer physics.
Trigger evidence: Studio G0 reached READY/13 PASS/0 FAIL, but normal play showed laneDeviation 0.418 and side-edge falls followed by R14.6 Y recovery.
Owner: RacerStabilizer.
Implementation: always-on Z-only AlignPosition + PrimaryAxisParallel AlignOrientation.
Status: R15 IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING.
B17/G0: PENDING.
```

Update `docs/SESSION.md` and `docs/FEATURE_LIST.md` with the same status. Do not mark G0 PASS.

- [ ] **Step 5: Run GREEN and commit docs**

```bash
python verify.py
git add tests/test_r15_docs_consistency.py docs/03_CORE_MECHANICS_SPEC.md docs/16_BALANCE_TUNING.md docs/SESSION.md docs/FEATURE_LIST.md docs/DECISION_LOG_R15_PLANAR_RACER_PHYSICS_2026-09-10.md
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

Confirm the implementation head and the push-triggered Contract Verify run. Required evidence:

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
6. Deliberately create a strong asymmetric contact if practical; excursion above `0.08` is FAIL evidence.
7. Verify falling through the actual gap still triggers R14.6 recovery and the accepted shape/version survives.

- [ ] **Step 3: Record human evidence only after the user supplies it**

If the checklist passes, record R15 Studio PASS in a subsequent evidence-only change. Do not automatically promote B17/G0; its external tester requirement remains separate.

- [ ] **Step 4: Stop on any Studio failure and debug that single failure**

Capture `laneDeviation`, body orientation, `LaneHardBoundExceeded`, screenshot/video, and Output around the failure. Create one RED reproduction per defect; do not sweep multiple constants blindly.
