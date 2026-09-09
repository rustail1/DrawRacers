# R16 Draw Climber Reference Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the M0 racer core behave materially closer to Draw Climber: one drawing produces two identical motor-driven legs around fixed pivots while the cube stays upright, moves physically in X/Y, is mechanically locked in Z, and redraw preserves motion and leg phase.

**Architecture:** Keep the authoritative chain `DrawingController -> StrokeRemoteTransport -> LegShapeService -> RacerRuntime -> LegAssembly`. `RacerStabilizer` owns body plane/orientation constraints. `PhysicsConfig.LegGeometry` owns hub offsets. Existing B06/B07/B09/B10/B13/B14 Studio specs remain runtime acceptance owners. No obstacle geometry, networking, multiplayer, economy, or DataStore scope is added.

**Tech Stack:** Roblox Studio / Luau, Rojo 7.7.0, Rokit, Python contract checks through `python verify.py`, GitHub Actions `Contract Verify`.

**Spec:** `docs/superpowers/specs/2026-09-10-r16-draw-climber-reference-parity-design.md`

## Global Constraints

- Work only on `main`; no branches/PRs for this project workflow.
- One accepted stroke -> one ShapeSpec -> exactly two same-XY physical legs.
- DrawInputRect `(0,0)` remains the physical hub pivot; no mirror/recenter/auto-spoke.
- X/Y body translation is physically free; Z is mechanically locked by `PlaneConstraint`.
- Body orientation is upright on all axes; only legs rotate for locomotion.
- Initial right-minus-left phase = `180 degrees +/- 1 degree`.
- Post-redraw phase per side stays within `5 degrees` of the captured pre-redraw phase modulo 360.
- `PhysicsConfig.LegGeometry` is the only numeric owner for hub offsets.
- Initial hub values: `HubOffsetX=0.0`, `HubOffsetY=-0.35`, `HubOffsetZAbs=1.62`.
- Motor/friction/mass tuning is forbidden until Stage A passes Studio Gate A.
- Canonical obstacle geometry is not modified to make physics pass.
- Every behavior change follows RED -> minimal GREEN -> full `python verify.py` -> GitHub CI/Rokit/Rojo build.
- Roblox solver/feel claims remain HUMAN/STUDIO PENDING until observed in Studio.

---

## Stage A — Mechanical reference parity

### Task 1 — R16.1 Upright Body

**Files**
- Modify: `tests/test_r15_planar_racer_physics.py`
- Create: `tests/test_r16_reference_parity.py`
- Modify: `src/server/Tests/B10StabilizationSpec.lua`
- Modify: `src/server/Runtime/RacerStabilizer.lua`

**RED static contract**

Create `tests/test_r16_reference_parity.py`:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r16_1_body_orientation_is_upright_not_free_about_z() -> None:
    stabilizer = read("src/server/Runtime/RacerStabilizer.lua")
    b10 = read("src/server/Tests/B10StabilizationSpec.lua")

    assert "Enum.AlignType.AllAxes" in stabilizer
    assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
    assert "Enum.AlignType.PrimaryAxisParallel" not in stabilizer
    assert "upright body angular deviation" in b10
    assert "x/y translation must remain physically free" in b10
    assert "in-plane rotation around Z must remain unconstrained" not in b10
```

Update the R15 regression so it still requires `PlaneConstraint` and forbids `AlignPosition`, but now requires `AllAxes`/`CFrame.identity` instead of free Z rotation.

Run `python verify.py`. Expected RED: R16.1 fails because current production still uses `PrimaryAxisParallel`.

**Runtime RED/acceptance in B10**

Keep the existing real lateral impulse test. Replace free-Z assertions with:

```lua
assert(orientationAlign.Mode == Enum.OrientationAlignmentMode.OneAttachment)
assert(orientationAlign.AlignType == Enum.AlignType.AllAxes)
assert(orientationAlign.CFrame == CFrame.identity)
assert(orientationAlign.Enabled == true)
```

Add:

```lua
local function bodyAngularDeviationDegrees(body: BasePart): number
    local x, y, z = body.CFrame:ToOrientation()
    return math.max(math.abs(math.deg(x)), math.abs(math.deg(y)), math.abs(math.deg(z)))
end
```

Inject a 2.5-degree disturbance, wait at most 15 Heartbeats, require final deviation <=1 degree. Then apply an X/Y impulse and require non-zero X or Y displacement while Z remains within `LaneHardBound`.

**Minimal GREEN**

In `RacerStabilizer.new`, keep the current `PlaneConstraint` unchanged and replace only orientation semantics:

```lua
orientationAttachment.Axis = Vector3.zAxis
orientationAttachment.SecondaryAxis = Vector3.yAxis

local orientationAlign = Instance.new("AlignOrientation")
orientationAlign.Name = "OrientationAlign"
orientationAlign.Mode = Enum.OrientationAlignmentMode.OneAttachment
orientationAlign.Attachment0 = orientationAttachment
orientationAlign.AlignType = Enum.AlignType.AllAxes
orientationAlign.CFrame = CFrame.identity
orientationAlign.RigidityEnabled = false
orientationAlign.ReactionTorqueEnabled = false
orientationAlign.Responsiveness = config.OrientationResponsiveness
orientationAlign.MaxTorque = config.OrientationMaxTorque
orientationAlign.MaxAngularVelocity = config.OrientationMaxAngularVelocity
orientationAlign.Enabled = true
orientationAlign.Parent = body
```

Do not write body position/CFrame/linear velocity in `Step()` and do not add +X/+Y forces.

Run `python verify.py`. Commit `fix: keep R16 racer body upright`. Require fresh CI + Rokit + Rojo build before Task 2.

---

### Task 2 — R16.2 Hub Calibration / Single Numeric Owner

**Files**
- Modify: `tests/test_r16_reference_parity.py`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Modify: `src/server/Tests/B06RacerRuntimeSpec.lua`

**RED**

Append:

```python
def test_r16_2_hub_offsets_have_one_numeric_owner() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    b06 = read("src/server/Tests/B06RacerRuntimeSpec.lua")

    for token in ["HubOffsetX = 0.0", "HubOffsetY = -0.35", "HubOffsetZAbs = 1.62"]:
        assert token in config
    assert "PhysicsConfig.LegGeometry.HubOffsetX" in runtime
    assert "PhysicsConfig.LegGeometry.HubOffsetY" in runtime
    assert "PhysicsConfig.LegGeometry.HubOffsetZAbs" in runtime
    assert "Vector3.new(0, -0.75, -1.62)" not in runtime
    assert "Vector3.new(0, -0.75, 1.62)" not in runtime
    assert "PhysicsConfig.LegGeometry.HubOffsetY" in b06
```

Run `python verify.py`. Expected RED: config does not own hub values and runtime still owns `-0.75` literals.

**GREEN**

Add to `PhysicsConfig.LegGeometry`:

```lua
HubOffsetX = 0.0,
HubOffsetY = -0.35,
HubOffsetZAbs = 1.62,
```

In `RacerRuntime` consume them through:

```lua
local function hubOffset(sideSign: number): Vector3
    local geometry = PhysicsConfig.LegGeometry
    return Vector3.new(
        geometry.HubOffsetX,
        geometry.HubOffsetY,
        geometry.HubOffsetZAbs * sideSign
    )
end
```

Use `hubOffset(-1)` for LeftHub and `hubOffset(1)` for RightHub. In B06 compute expected offsets from config rather than literals.

Run `python verify.py`. Commit `fix: centralize R16 hub geometry`. Require fresh CI/build before Task 3.

---

### Task 3 — R16.3 Pivot / One Stroke -> Two Legs Verification

**Files**
- Modify: `tests/test_r16_reference_parity.py`
- Production only on demonstrated failure: `GeometryMath.lua`, `RacerRuntime.lua`, `LegAssembly.lua`
- Runtime owners: B07/B09

**Verification test**

```python
def test_r16_3_one_shape_builds_two_same_xy_legs_about_fixed_pivot() -> None:
    geometry = read("src/shared/Math/GeometryMath.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    leg = read("src/server/Runtime/LegAssembly.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")

    assert "local mapped = clamped * geometry.LegCanvasHalfSpan" in geometry
    assert "stagedLeftLeg = LegAssembly.new" in runtime
    assert "stagedRightLeg = LegAssembly.new" in runtime
    assert runtime.count("shapeSpec = shapeSpec") >= 2
    assert "root.CFrame = hub.CFrame" in leg
    assert "assertSamePoints(leftLeg:GetMappedPoints(), rightLeg:GetMappedPoints())" in b09
    assert "shapeSpec.normalizedPoints" not in runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("function RacerRuntime:ApplyShape", 1)[0]
```

The final assertion prevents `_ApplyShapeSpec` from rewriting/recentering normalized points; it may only consume the already-authoritative `segmentPlan`/mapped geometry.

Run `python verify.py`. Expected current result: PASS. If it fails, stop and repair only the demonstrated pivot/duplication violation. Commit verification-only test and require fresh CI.

---

### Task 4 — R16.4 Twin-Leg Phase + Redraw Retention

**Files**
- Modify: `tests/test_r16_reference_parity.py`
- Modify: `src/server/Tests/B09TwoLegPhaseSpec.lua`
- Production only on demonstrated failure: `RacerRuntime.lua`, `LegAssembly.lua`
- Reuse: `src/server/Tests/B13AtomicRedrawSpec.lua`

**RED**

```python
def test_r16_4_phase_is_180_and_redraw_retains_each_side() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    b09 = read("src/server/Tests/B09TwoLegPhaseSpec.lua")
    b13 = read("src/server/Tests/B13AtomicRedrawSpec.lua")

    assert "RightPhaseOffsetDegrees = 180" in config
    assert "angularDistanceDegrees" in b09
    assert "phase difference" in b09
    assert "angularDistanceDegrees(leftPhaseAfter, leftPhaseBefore)" in b13
    assert "angularDistanceDegrees(rightPhaseAfter, rightPhaseBefore)" in b13
```

Run `python verify.py`. Expected RED: B09 does not explicitly own modulo-360 right-minus-left phase difference.

**GREEN**

Add to B09:

```lua
local function angularDistanceDegrees(a: number, b: number): number
    local delta = (a - b + 180) % 360 - 180
    return math.abs(delta)
end
```

After reading initial phases:

```lua
local phaseDifference = (math.deg(rightPhaseZ) - math.deg(leftPhaseZ) + 360) % 360
assert(
    angularDistanceDegrees(phaseDifference, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 1.0,
    string.format("phase difference expected %.3f got %.3f", PhysicsConfig.Motor.RightPhaseOffsetDegrees, phaseDifference)
)
assert(leftJoint.AngularVelocity == rightJoint.AngularVelocity, "both leg motors must use the same direction/sign")
```

Do not change production if B09 and existing B13 retention pass. Run `python verify.py`, commit `test: lock R16 twin-leg phase semantics`, require fresh CI/build.

---

## Stage A Studio Gate — mandatory before Stage B

Fresh current-main Rojo build, Studio Play. Required logs: B06 PASS, B09 PASS, B10 PASS, `TOTAL 13 PASS / 0 FAIL`, `READY`, G0 harness ready.

Required observations:
- normal `laneDeviation <=0.03`, no unexplained `>0.08`;
- body stays upright while ROUND/HOOK/ASYM legs rotate;
- body still moves physically in X and Y;
- body cannot drift in Z;
- one accepted drawing produces exactly two same-XY legs;
- hubs remain symmetric/stable through redraw;
- no red DrawRacers runtime errors.

Hub protocol: ROUND_01 FlatShort for 8 s after stable contact must not cause chronic body scraping from axle height; HOOK_01 or ASYM_01 must gain at least +8 studs X on SmallSteps within 10 s from first step contact. If Gate A fails, Stage B is blocked.

---

## Stage B — Empirical locomotion tuning

### Task 5 — R16.5 Motor / Grip / Mass

Run ROUND_01 on FlatShort. Ignore first 2 s of stable contact, then measure average +X speed for 3 s. Target 4.0–7.0 studs/s with motor enabled and antiStallActive false. Tune exactly one family per experiment/commit: AngularVelocity -> torque/acceleration -> leg friction/elasticity -> body friction/elasticity -> anti-stall last. No obstacle edits.

Each experiment records before/after config value and Studio metric in the R16 decision log draft, then runs full `python verify.py` + CI/Rojo build.

### Task 6 — R16.6 Vertical Physics

Add a regression proving `RacerStabilizer` and normal anti-stall code do not set Y position/CFrame/AssemblyLinearVelocity for climbing. Studio acceptance: steps raise Y through leg collision; gap lowers Y through gravity; recovery occurs only after real Y fall.

### Task 7 — R16.7 Shape Matrix

Fixed resets and fixed obstacle geometry. Record spec metrics exactly: ROUND flat 4–7 studs/s; HOOK/ASYM steps >=4 studs more X in 10 s than ROUND or one higher step; LONG_BAR gap has far-edge contact/landing where SMALL_ROUND fails or >=2 studs more X in 6 s; SMALL_ROUND tunnel completes or gains >=6 studs more X than LONG_BAR in 8 s; SUBOPTIMAL >=20% worse than the best suitable shape on Flat or Steps; no single shape wins/ties every piece.

Stage B remains HUMAN/STUDIO PENDING until these measurements are recorded.

---

## Stage C — Redraw, presentation, full lab

### Task 8 — R16.8 Redraw Parity

Extend B13/B14 and R16 static regressions. Run 10 moving redraws: ShapeVersion +1 per accept; exactly two active leg models; no staged/retiring leaks; no body teleport/velocity reset; each side phase delta <=5 degrees from captured pre-redraw phase.

### Task 9 — R16.9 G0 Side Presentation

RED requires exact Studio-only constants:

```lua
local CAMERA_OFFSET = Vector3.new(-6, 5, 16)
local CAMERA_LOOK_AHEAD = Vector3.new(7, 1, 0)
```

Modify only `M0G0PresentationHarness.lua` and, if necessary solely to hide the observer, `M0HumanHarness.lua`. Acceptance: racer center 25–50% viewport width, upcoming obstacle visible, at least one full leg silhouette readable, observer absent, debug proxy non-physical, camera never alters racer physics.

### Task 10 — R16.10 Canonical Obstacle Pass

Use unchanged FlatShort, SmallSteps, SingleWallLow, GapSmall, LowTunnelWide. Run full shape matrix and moving redraw sequence. Any obstacle defect requires separate evidence-backed change; no geometry edits are allowed as a parity shortcut.

---

## Task 11 — R16.11 Docs / Evidence Reconciliation

Create `tests/test_r16_docs_consistency.py` first. RED requires `03`, `16`, `73`, `SESSION`, `FEATURE_LIST` to state the final actual values/behavior selected by Stages A–C: upright body; X/Y free/Z locked; final hub offsets and physics constants; one shape -> two same-XY legs; pivot `(0,0)`; phase 180 degrees; exact current-main Studio evidence; B17 external HUMAN_GATE still pending.

Then update those docs and create `docs/DECISION_LOG_R16_DRAW_CLIMBER_REFERENCE_PARITY_2026-09-10.md`. Run full `python verify.py`, GitHub CI, Rokit, and Rojo build. Do not fabricate Studio evidence or pass B17.

## Final Definition of Done

R16 is technically complete only when automated CI/build is green **and** Stage A/B/C Studio evidence proves the design spec. R16 completion does not pass B17; external tester evidence remains a separate human gate before C01/M0.5.
