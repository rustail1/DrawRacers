# R16 Draw Climber Reference Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the current M0 racer core materially closer to the observable Draw Climber behavior: one drawing produces two motor-driven legs around fixed pivots while the cube stays upright, moves physically in X/Y, is mechanically locked in Z, and redraw preserves motion/phase.

**Architecture:** Preserve the existing authoritative flow `DrawingController -> StrokeRemoteTransport -> LegShapeService -> RacerRuntime -> LegAssembly`. `RacerStabilizer` remains the sole owner of body plane/orientation constraints, `PhysicsConfig` becomes the sole numeric owner for hub offsets/tuning, and existing B06/B07/B09/B10/B13/B14 specs remain the Roblox runtime acceptance owners. Reference parity is proved through RED->GREEN automated regressions plus mandatory Studio gates; no obstacle geometry, network contract, economy, race service, or DataStore scope is added.

**Tech Stack:** Roblox Studio / Luau, Rojo 7.7.0, Rokit, Python contract tests via `python verify.py`, GitHub Actions `Contract Verify`.

**Spec:** `docs/superpowers/specs/2026-09-10-r16-draw-climber-reference-parity-design.md`

## Global Constraints

- Work only on `main`; no branches/PRs for this project workflow.
- One accepted stroke -> one authoritative ShapeSpec -> exactly two same-XY physical legs.
- DrawInputRect center `(0,0)` remains the physical hub pivot; no recenter/mirror/auto-spoke.
- X/Y body translation stays physically free; Z stays mechanically locked by `PlaneConstraint`.
- Body orientation is upright on all axes; only legs rotate for locomotion.
- Initial right-minus-left leg phase is `180 degrees +/- 1 degree`.
- Post-redraw phase per side must remain within `5 degrees` of the captured pre-redraw phase modulo 360.
- `PhysicsConfig.LegGeometry` is the only numeric owner for hub offsets.
- Initial hub offsets: `HubOffsetX=0.0`, `HubOffsetY=-0.35`, `HubOffsetZAbs=1.62`.
- Do not tune motor/friction/mass until Stage A mechanics pass Studio Gate A.
- Do not alter canonical obstacle geometry to make physics pass.
- Every behavior-changing task: RED -> minimal GREEN -> fresh full CI -> Rojo build.
- Roblox solver/feel claims stay HUMAN/STUDIO PENDING until observed in Studio.

---

## Stage A — Mechanical reference parity

### Task 1: R16.1 Upright Body

**Files:**
- Modify: `tests/test_r15_planar_racer_physics.py`
- Create: `tests/test_r16_reference_parity.py`
- Modify: `src/server/Tests/B10StabilizationSpec.lua`
- Modify: `src/server/Runtime/RacerStabilizer.lua`

**Interfaces:**
- Consumes: current `RacerStabilizer:GetLaneConstraint(): PlaneConstraint`, `GetOrientationAlign(): AlignOrientation`.
- Produces: an always-on all-axis upright `AlignOrientation` while leaving the existing `PlaneConstraint` as the only Z-position owner.

- [ ] **Step 1: Write RED static regressions for the new orientation contract**

Add to `tests/test_r16_reference_parity.py`:

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
    assert "in-plane rotation around Z must remain unconstrained" not in b10
    assert "upright body angular deviation" in b10
    assert "body:ApplyImpulse" in b10
    assert "x/y translation must remain physically free" in b10
```

Update `tests/test_r15_planar_racer_physics.py` so R15 continues to require the mechanical `PlaneConstraint`, but no longer requires free rotation around world Z. Replace the old `PrimaryAxisParallel`/free-Z assertions with:

```python
assert 'Instance.new("PlaneConstraint")' in stabilizer
assert 'Instance.new("AlignPosition")' not in stabilizer
assert "Enum.AlignType.AllAxes" in stabilizer
assert "orientationAlign.CFrame = CFrame.identity" in stabilizer
```

- [ ] **Step 2: Run RED**

Run:

```bash
python verify.py
```

Expected: FAIL in the new R16.1 orientation contract because production still contains `PrimaryAxisParallel` and B10 still explicitly allows free world-Z body rotation.

- [ ] **Step 3: Extend B10 with a real upright + free-X/Y runtime check**

Keep all existing collision-matrix and lateral `PlaneConstraint` assertions. Replace the free-Z section with all-axis assertions:

```lua
assert(orientationAlign.Mode == Enum.OrientationAlignmentMode.OneAttachment)
assert(orientationAlign.AlignType == Enum.AlignType.AllAxes)
assert(orientationAlign.CFrame == CFrame.identity)
assert(orientationAlign.Enabled == true)
```

Add helpers:

```lua
local function bodyAngularDeviationDegrees(body: BasePart): number
    local x, y, z = body.CFrame:ToOrientation()
    return math.max(math.abs(math.deg(x)), math.abs(math.deg(y)), math.abs(math.deg(z)))
end
```

After the existing lateral-impulse test, put the body at canonical upright state, unanchor it, inject a 2.5-degree orientation disturbance, and verify recovery:

```lua
body.CFrame = CFrame.new(-18, 8, laneCenterZ) * CFrame.Angles(0, 0, math.rad(2.5))
body.AssemblyLinearVelocity = Vector3.zero
body.AssemblyAngularVelocity = Vector3.zero
stabilizer:Step()
local peakDeviation = bodyAngularDeviationDegrees(body)
assert(peakDeviation <= 3.0, string.format("upright body angular deviation peak %.4f", peakDeviation))

for _ = 1, 15 do
    RunService.Heartbeat:Wait()
end
assert(bodyAngularDeviationDegrees(body) <= 1.0, "upright body angular deviation did not recover")
```

Then prove X/Y are not accidentally locked by the orientation fix:

```lua
local freeStart = body.Position
body:ApplyImpulse(Vector3.new(body.AssemblyMass * 25, body.AssemblyMass * 12, 0))
for _ = 1, 6 do
    RunService.Heartbeat:Wait()
end
local freeDelta = body.Position - freeStart
assert(math.abs(freeDelta.X) > 0.01 or math.abs(freeDelta.Y) > 0.01, "x/y translation must remain physically free")
assert(math.abs(body.Position.Z - laneCenterZ) <= config.LaneHardBound, "upright correction escaped lane plane")
```

- [ ] **Step 4: Implement minimal upright orientation in RacerStabilizer**

In `RacerStabilizer.new`, keep the current `PlaneConstraint` unchanged. Change only orientation target semantics:

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

Do not set body position, CFrame, AssemblyLinearVelocity, or apply +X/+Y forces in `Step()`.

- [ ] **Step 5: Run GREEN verification**

Run:

```bash
python verify.py
```

Expected: all contract tests PASS.

- [ ] **Step 6: Commit**

```bash
git add tests/test_r15_planar_racer_physics.py tests/test_r16_reference_parity.py src/server/Tests/B10StabilizationSpec.lua src/server/Runtime/RacerStabilizer.lua
git commit -m "fix: keep R16 racer body upright"
```

- [ ] **Step 7: Require fresh CI before Task 2**

Required evidence: `Contract Verify` success, `python verify.py` zero failures, Rokit install PASS, `rojo build default.project.json` PASS.

---

### Task 2: R16.2 Hub Calibration / Single Numeric Owner

**Files:**
- Modify: `tests/test_r16_reference_parity.py`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Modify: `src/server/Tests/B06RacerRuntimeSpec.lua`

**Interfaces:**
- Consumes: `PhysicsConfig.LegGeometry`.
- Produces: canonical `HubOffsetX`, `HubOffsetY`, `HubOffsetZAbs` consumed by RacerRuntime template construction and tests.

- [ ] **Step 1: Write RED owner/config regression**

Append:

```python
def test_r16_2_hub_offsets_have_one_numeric_owner() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    b06 = read("src/server/Tests/B06RacerRuntimeSpec.lua")

    for token in [
        "HubOffsetX = 0.0",
        "HubOffsetY = -0.35",
        "HubOffsetZAbs = 1.62",
    ]:
        assert token in config

    assert "PhysicsConfig.LegGeometry.HubOffsetX" in runtime
    assert "PhysicsConfig.LegGeometry.HubOffsetY" in runtime
    assert "PhysicsConfig.LegGeometry.HubOffsetZAbs" in runtime
    assert "Vector3.new(0, -0.75, -1.62)" not in runtime
    assert "Vector3.new(0, -0.75, 1.62)" not in runtime
    assert "PhysicsConfig.LegGeometry.HubOffsetY" in b06
```

- [ ] **Step 2: Run RED**

Run `python verify.py`.

Expected: FAIL because hub offsets are still hardcoded in `RacerRuntime` and config does not own them.

- [ ] **Step 3: Move offsets into PhysicsConfig**

Inside `LegGeometry` add exactly:

```lua
HubOffsetX = 0.0,
HubOffsetY = -0.35,
HubOffsetZAbs = 1.62,
```

- [ ] **Step 4: Consume config in RacerRuntime**

Replace hardcoded constants with:

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

Use `hubOffset(-1)` for LeftHub and `hubOffset(1)` for RightHub.

- [ ] **Step 5: Make B06 assert config-derived offsets**

Require `PhysicsConfig` and define:

```lua
local geometry = PhysicsConfig.LegGeometry
local expectedLeft = Vector3.new(geometry.HubOffsetX, geometry.HubOffsetY, -geometry.HubOffsetZAbs)
local expectedRight = Vector3.new(geometry.HubOffsetX, geometry.HubOffsetY, geometry.HubOffsetZAbs)
assertVectorClose(body.CFrame:PointToObjectSpace(leftHub.Position), expectedLeft, 1e-4, "LeftHub offset")
assertVectorClose(body.CFrame:PointToObjectSpace(rightHub.Position), expectedRight, 1e-4, "RightHub offset")
```

- [ ] **Step 6: Run GREEN + commit**

Run `python verify.py`; expected zero failures. Commit:

```bash
git add tests/test_r16_reference_parity.py src/shared/Config/PhysicsConfig.lua src/server/Runtime/RacerRuntime.lua src/server/Tests/B06RacerRuntimeSpec.lua
git commit -m "fix: centralize R16 hub geometry"
```

- [ ] **Step 7: Require fresh CI before Task 3**

Same CI/build evidence as Task 1.

---

### Task 3: R16.3 Pivot + One Stroke -> Two Legs Verification

**Files:**
- Modify: `tests/test_r16_reference_parity.py`
- Modify only on demonstrated failure: `src/shared/Math/GeometryMath.lua`, `src/server/Runtime/RacerRuntime.lua`, `src/server/Runtime/LegAssembly.lua`
- Runtime verification owners: `src/server/Tests/B07LegAssemblySpec.lua`, `src/server/Tests/B09TwoLegPhaseSpec.lua`

**Interfaces:**
- Consumes: existing `ShapeSpec`, `GeometryMath.MapPoint`, `RacerRuntime:_ApplyShapeSpec`.
- Produces: no new subsystem; this task proves the existing pivot/duplication contract before tuning.

- [ ] **Step 1: Add verification regression**

Append:

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
    assert "no automatic" not in runtime.lower()  # no hidden runtime recenter helper is introduced
```

If the final assertion is too brittle against comments, replace it during self-review with a direct forbidden-token list for any actual recenter helper discovered in the file; do not change production merely to satisfy wording.

- [ ] **Step 2: Run verification**

Run `python verify.py`.

Expected on the current architecture: PASS. If this task fails, stop Stage A and repair only the demonstrated pivot/duplication violation before continuing.

- [ ] **Step 3: Commit verification-only change if PASS**

```bash
git add tests/test_r16_reference_parity.py
git commit -m "test: lock R16 fixed pivot twin-leg contract"
```

- [ ] **Step 4: Fresh CI**

Require full CI/build GREEN before phase work.

---

### Task 4: R16.4 Twin-Leg Phase + Redraw Retention

**Files:**
- Modify: `tests/test_r16_reference_parity.py`
- Modify: `src/server/Tests/B09TwoLegPhaseSpec.lua`
- Modify only if demonstrated failure: `src/server/Runtime/RacerRuntime.lua`, `src/server/Runtime/LegAssembly.lua`
- Reuse: `src/server/Tests/B13AtomicRedrawSpec.lua`

**Interfaces:**
- Consumes: `PhysicsConfig.Motor.RightPhaseOffsetDegrees`, `captureLegPhaseDegrees`, existing B13 phase preservation helper.
- Produces: explicit modulo-360 phase acceptance in B09 while preserving the existing atomic redraw mechanism.

- [ ] **Step 1: Add static regression requiring explicit phase-delta and B13 retention**

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

- [ ] **Step 2: Run RED**

Run `python verify.py`.

Expected: B09 portion fails because current B09 asserts left=0/right=abs(180) but does not explicitly own modulo-360 right-minus-left phase delta.

- [ ] **Step 3: Upgrade B09 without changing production**

Add:

```lua
local function angularDistanceDegrees(a: number, b: number): number
    local delta = (a - b + 180) % 360 - 180
    return math.abs(delta)
end
```

After reading both initial phases:

```lua
local phaseDifference = (math.deg(rightPhaseZ) - math.deg(leftPhaseZ) + 360) % 360
assert(
    angularDistanceDegrees(phaseDifference, PhysicsConfig.Motor.RightPhaseOffsetDegrees) <= 1.0,
    string.format("phase difference expected %.3f got %.3f", PhysicsConfig.Motor.RightPhaseOffsetDegrees, phaseDifference)
)
assert(leftJoint.AngularVelocity == rightJoint.AngularVelocity, "both leg motors must use the same direction/sign")
```

Do not alter `RacerRuntime` or `LegAssembly` if B09/B13 already pass.

- [ ] **Step 4: Run GREEN + commit**

Run `python verify.py`; expected zero failures. Commit:

```bash
git add tests/test_r16_reference_parity.py src/server/Tests/B09TwoLegPhaseSpec.lua
git commit -m "test: lock R16 twin-leg phase semantics"
```

- [ ] **Step 5: Fresh CI**

Require full CI/build GREEN.

---

### Stage A Studio Gate — mandatory before motor/friction tuning

Use current `main`, fresh `rojo build`, Studio Play.

Required log evidence:

```text
[DrawRacers][B06] RacerTemplate/RacerRuntime tests PASS
[DrawRacers][B09] two-leg same-XY/phase tests PASS
[DrawRacers][B10] stabilization/lane tests PASS
[DrawRacers][StudioGate] TOTAL 13 PASS / 0 FAIL
[DrawRacers][StudioGate] READY
[DrawRacers][G0] human harness ready
```

Required observation:
- `laneDeviation` normal <= 0.03 and no unexplained > 0.08;
- body visually remains upright while ROUND/HOOK/ASYM legs rotate;
- body still moves in X and Y physically;
- body cannot drift in Z;
- hubs are symmetric and stable after redraw;
- one accepted drawing produces exactly two legs;
- no red DrawRacers runtime errors.

Hub calibration measurement:
- ROUND_01 on FlatShort: observe 8 s after first stable contact; reject chronic body scraping attributable to axle height;
- HOOK_01 or ASYM_01 on SmallSteps: at least +8 studs X progress within 10 s from first step contact.

If Stage A fails, do not start Task 5. Return to the first failed mechanical owner.

---

## Stage B — Empirical locomotion tuning

### Task 5: R16.5 Motor / Grip / Mass Tuning

**Files:**
- Modify one parameter family at a time: `src/shared/Config/PhysicsConfig.lua`
- Modify physical properties only when that family is selected: `src/server/Runtime/LegAssembly.lua`, `src/server/Runtime/RacerRuntime.lua`
- Test: new/extended `tests/test_r16_reference_parity.py`; Studio measurement helper may be added under `src/server/Tests/` but must remain Studio-only.

**Procedure:**
- Baseline ROUND_01 FlatShort: ignore first 2 s stable contact, measure average +X body speed for next 3 s.
- Target 4.0–7.0 studs/s, motor enabled, antiStallActive false during measurement.
- If outside target, change only `Motor.AngularVelocity`, RED the expected config value/range, CI, then Studio remeasure.
- Only if speed/obstacle torque proves insufficient after angular velocity: tune `MotorMaxTorque`/`MotorMaxAcceleration` as one family.
- Only after motor family passes: tune leg friction/elasticity.
- Body physical properties are the final physical-properties family before anti-stall.
- Never change obstacle geometry in this task.

Each experiment is a separate commit with recorded before/after Studio evidence in the R16 decision log draft.

---

### Task 6: R16.6 Vertical Physics Contract

**Files:**
- Modify: `tests/test_r16_reference_parity.py`
- Modify only on violation: `src/server/Runtime/RacerStabilizer.lua`, `src/server/Runtime/RacerAntiStall.lua`, G0 recovery harness.

Add a static regression forbidding normal locomotion writes to body Y/CFrame Y/AssemblyLinearVelocity Y in the stabilizer/anti-stall path. Studio acceptance: steps raise body by physical leg contact, gap lowers body through gravity, R14.6 recovery triggers only after real Y fall.

---

### Task 7: R16.7 Reference Shape Matrix

**Files:**
- Prefer Studio-only measurement/report helper under `src/server/Tests/`.
- Do not alter `GeometryMath`, obstacle geometry, or add shape classification.

Run fixed reset conditions and record the exact section-7 metrics from the spec:
- ROUND flat 4–7 studs/s;
- HOOK/ASYM steps >=4 studs more X progress than ROUND in 10 s or one higher canonical step;
- LONG_BAR gap distinct niche: far-edge contact/landing where SMALL_ROUND fails, or >=2 studs more X in 6 s;
- SMALL_ROUND tunnel: completes or >=6 studs more X than LONG_BAR in 8 s;
- SUBOPTIMAL >=20% worse than best suitable shape on Flat or Steps;
- no single tested shape wins/ties every measured piece.

Stage B stays HUMAN/STUDIO PENDING until these measurements are recorded.

---

### Stage B Studio Gate

Do not enter Stage C until Tasks 5–7 satisfy their measurement protocol on current `main` and current canonical obstacle geometry.

---

## Stage C — Redraw, presentation, full lab

### Task 8: R16.8 Redraw Parity

**Files:**
- Modify: `src/server/Tests/B13AtomicRedrawSpec.lua`, `src/server/Tests/B14RedrawStressSpec.lua`, `tests/test_r16_reference_parity.py`.
- Production runtime only on demonstrated failure.

Acceptance:
- 10 accepted redraws while moving;
- ShapeVersion +1 per accept;
- exactly two current leg models after each commit;
- no staged/retiring leaks;
- no body teleport or velocity reset;
- each side phase delta <=5 degrees from its captured pre-redraw phase.

---

### Task 9: R16.9 G0 Side Presentation

**Files:**
- Modify: `src/client/Dev/M0G0PresentationHarness.lua`
- Modify only if needed to hide observer: `src/server/Tests/M0HumanHarness.lua`
- Test: `tests/test_r16_reference_parity.py`

RED requires exact starting constants:

```lua
local CAMERA_OFFSET = Vector3.new(-6, 5, 16)
local CAMERA_LOOK_AHEAD = Vector3.new(7, 1, 0)
```

GREEN changes only Studio presentation. Acceptance: racer center 25–50% viewport width, upcoming obstacle readable, at least one full leg silhouette readable, observer Character absent, debug proxy non-physical, camera never changes racer physics.

---

### Task 10: R16.10 Canonical Obstacle Pass

Use unchanged `FlatShort`, `SmallSteps`, `SingleWallLow`, `GapSmall`, `LowTunnelWide`. No production obstacle geometry changes. Run full shape matrix and live redraw sequence. Any obstacle defect discovered is a separate evidence-backed change, not an R16 tuning shortcut.

---

### Stage C Studio Gate

Required in one current-main evidence set:
- StudioGate 13/0, READY, G0 harness ready;
- upright body + hard Z plane;
- fixed pivot and two same-XY legs;
- 180-degree initial phase and <=5-degree redraw phase preservation;
- different measured shape niches;
- redraw stable while moving;
- side camera readable and observer absent;
- gap/recovery retains ShapeSpec/ShapeVersion;
- no DrawRacers runtime errors.

---

## Task 11: R16.11 Docs / Evidence Reconciliation

**Files:**
- Modify: `docs/03_CORE_MECHANICS_SPEC.md`
- Modify: `docs/16_BALANCE_TUNING.md`
- Modify: `docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`
- Modify: `docs/SESSION.md`
- Modify: `docs/FEATURE_LIST.md`
- Create: `docs/DECISION_LOG_R16_DRAW_CLIMBER_REFERENCE_PARITY_2026-09-10.md`
- Test: create `tests/test_r16_docs_consistency.py`

RED first requires owner docs to state:
- upright body, no intentional tumble;
- X/Y free, Z mechanical plane;
- final selected hub offsets and motor/physical values;
- one shape -> two same-XY legs;
- pivot `(0,0)`;
- 180-degree phase;
- R16 technical status and exact Studio evidence;
- B17/G0 external HUMAN_GATE remains pending.

Then update docs to match the actual values selected by Stages A–C. Run `python verify.py`, full CI, and Rojo build. Do not fabricate Studio evidence or promote B17.

---

## Final R16 Definition of Done

R16 is technically complete only when automated CI/build is green **and** Stage A/B/C Studio evidence proves the final acceptance list from the design spec. R16 completion does not pass B17. External tester protocol remains a separate human gate before C01/M0.5.