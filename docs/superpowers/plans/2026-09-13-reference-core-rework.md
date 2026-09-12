# Draw Racers Reference Core Rework Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework the Draw Racers core so redraw preserves axle/motion continuity, canvas and world-leg geometry match 1:1, legs are larger, reshape is rapid hub-to-tip, camera is calmer, rider sits correctly, and cosmetics are presentation-only.

**Architecture:** Keep server-authoritative raw-stroke validation, but move deterministic stroke-to-shape math into a shared pure module used by both client preview and server. Keep one long-lived axle/motor per racer and mutate only leg geometry on redraw. Presentation systems remain client-side and physics-neutral.

**Tech Stack:** Roblox Luau, Rojo, Python contract tests, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-09-13-reference-core-rework-design.md`

## Global Constraints

- Work only on `main`; no branches/PRs.
- Fetch fresh `main` before every write and stop on unexpected concurrent changes.
- Preserve G0 fast Studio workflow; do not re-enable long startup evidence suites.
- Human feel/visual gates can be `HUMAN_PENDING`, never fabricated as PASS.
- Prefer TDD: targeted RED contract first, then minimal production change, then full verify/Rojo/CI.
- Do not alter unrelated race/economy/network/level systems.

---

### Task 1: RCP-01 Stable Axle

**Files:**
- Modify: `src/server/Runtime/LegPairAssembly.lua`
- Modify: `src/server/Runtime/LegAssembly.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Test: extend the closest existing axle/runtime Python contract tests; create `tests/test_rcp01_stable_axle.py` only if no focused owner exists.

**Interfaces:**
- Produce a long-lived axle/joint owned across redraws.
- Geometry replacement must preserve current axle CFrame/phase and motor object.

- [ ] **Step 1: Investigate current redraw ownership and write RED contract.**

The RED contract must fail on the current behavior and assert at minimum that redraw does not construct a replacement axle/joint in the shape-apply path and that geometry has an explicit replace/update path on the existing pair.

Example static contract shape:

```python
from pathlib import Path

ROOT = Path(__file__).parents[1]

def test_redraw_reuses_existing_leg_pair_axle():
    runtime = (ROOT / "src/server/Runtime/RacerRuntime.lua").read_text()
    pair = (ROOT / "src/server/Runtime/LegPairAssembly.lua").read_text()
    assert "ReplaceGeometry" in pair or "ApplyShapeGeometry" in pair
    assert "self.legPair" in runtime
    assert "LegPairAssembly.new" not in runtime.split("function RacerRuntime:_ApplyShapeSpec", 1)[1].split("end\n\nfunction", 1)[0]
```

- [ ] **Step 2: Run the focused test and confirm RED for the intended reason.**

Run the repository's normal Python verifier or the focused pytest path. Do not change production code before observing RED.

- [ ] **Step 3: Refactor ownership minimally.**

Create axle/joint once for the pair/runtime lifecycle. Add a geometry replacement method that rebuilds only left/right leg geometry around the existing axle. Preserve `GetPhaseDegrees`, `SetEnabled`, current motor config and right-side structural phase contract.

- [ ] **Step 4: Preserve failure atomicity.**

Prepare/validate replacement geometry before destroying the currently valid geometry. If preparation fails, leave the current geometry intact.

- [ ] **Step 5: Run focused tests, full verifier, Rojo build and CI.**

Expected automated result: all existing tests plus RCP-01 tests pass; Rojo build succeeds. Record final SHA and mark visual continuity `HUMAN_PENDING`.

---

### Task 2: RCP-02 Larger and Separately Styled Legs

**Files:**
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/LegAssembly.lua`
- Test: create/extend a focused geometry config contract such as `tests/test_rcp02_leg_scale.py`.

**Interfaces:**
- Physical reach comes from geometry config.
- Physical thickness and visual thickness become distinct config values.

- [ ] **Step 1: Add RED assertions for separate physical/visual thickness and approximately doubled reach.**

```python
from pathlib import Path
import re

text = (Path(__file__).parents[1] / "src/shared/Config/PhysicsConfig.lua").read_text()
assert "VisualLegSegmentThickness" in text
assert re.search(r"LegCanvasHalfSpan\s*=\s*6\.", text)
assert re.search(r"MaxLegExtentFromHub\s*=\s*9\.", text)
```

- [ ] **Step 2: Update config, not hardcoded assembly constants.**

Start from `LegCanvasHalfSpan=6.30`, `MaxLegExtentFromHub=9.0`, physical thickness in 0.60-0.65 range and visual thickness in 0.85-0.95 range unless current code/evidence proves those values unsafe.

- [ ] **Step 3: Make LegAssembly consume visual thickness separately.**

Collider sizes use physical thickness; non-colliding visual parts use visual thickness. Do not alter BodyCollider.

- [ ] **Step 4: Verify and record `HUMAN_PENDING` for Flat/Step/Gap feel.**

---

### Task 3: RCP-03 Canonical Draw-to-Leg Parity and Larger Canvas

**Files:**
- Create: `src/shared/Math/LegShapeMath.lua`
- Modify: `src/server/Services/LegShapeService.lua`
- Modify: `src/client/Controllers/DrawingController.lua`
- Reuse: `src/shared/Math/StrokeMath.lua`, `src/shared/Math/GeometryMath.lua`
- Tests: create `tests/test_rcp03_canonical_shape_parity.py`; extend local preview tests as needed.

**Interfaces:**
- `LegShapeMath.BuildCanonical(rawPoints, strokeConfig, geometryConfig)` (or equivalent established naming) returns canonical normalized points, mapped points, bounds, extent, segment plan and debug counts without Workspace/Instance access.
- Client uses it for preview only; server recomputes from raw payload and remains authoritative.

- [ ] **Step 1: Write RED contracts for one shared canonical builder and server/client use.**

```python
from pathlib import Path
ROOT = Path(__file__).parents[1]
shape = ROOT / "src/shared/Math/LegShapeMath.lua"
assert shape.exists()
server = (ROOT / "src/server/Services/LegShapeService.lua").read_text()
client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text()
assert "LegShapeMath" in server
assert "LegShapeMath" in client
```

- [ ] **Step 2: Extract deterministic pipeline.**

Move the canonical sequence `ClampToRect -> Dedupe -> SimplifyRDP -> Resample -> AnchorToFirstPoint -> ComputeBounds -> BuildSegmentPlan` into the pure shared module while preserving reject semantics.

- [ ] **Step 3: Make server delegate to shared builder.**

Server still validates envelope/raw array and treats client as untrusted. It creates ShapeSpec from the shared result and applies it.

- [ ] **Step 4: Make main canvas show canonical centerline.**

Do not auto-fit gameplay preview. Use fixed isotropic semantic-to-pixel mapping. Rounded caps/joints may improve appearance, but do not introduce a different Bezier/Catmull-Rom trajectory.

- [ ] **Step 5: Increase drawing surface to ~2x area.**

Start around desktop height 0.39-0.40 and touch height 0.47-0.48 while preserving 1.75:1 aspect and safe-area behavior. Adjust surrounding hint/toast positions only as needed.

- [ ] **Step 6: Add parity coverage for straight, L, V, open-U, zigzag, small/large asymmetric strokes.**

Assert first canonical point is origin, point ordering/extent/segment endpoints match within epsilon, and main canvas does not per-shape auto-fit.

- [ ] **Step 7: Verify, build, CI; mark visual 1:1 Studio check `HUMAN_PENDING`.**

---

### Task 4: RCP-04 Rapid Hub-to-Tip Reshape

**Files:**
- Create: `src/shared/Math/LegReshapeMath.lua`
- Modify: `src/shared/Config/PhysicsConfig.lua`
- Modify: `src/server/Runtime/LegAssembly.lua`
- Modify: `src/server/Runtime/LegPairAssembly.lua`
- Modify: `src/server/Runtime/RacerRuntime.lua`
- Reassess minimally: `src/server/Runtime/RedrawSpawnSafety.lua`
- Tests: `tests/test_rcp04_leg_reshape.py` plus existing redraw safety contracts.

**Interfaces:**
- Pure reshape math maps `(segmentPlan, progress)` to full prefix plus at most one partial `a -> endpoint` segment by arc length.
- Pair applies one shared progress to both sides.
- Initial duration config: typical 0.08-0.12s, cap near 0.15s.

- [ ] **Step 1: RED test arc-length behavior.**

Ensure 50% progress means 50% total polyline length, not half the segment count; partial segment endpoint must advance from `a` toward `b`.

- [ ] **Step 2: Implement pure `LegReshapeMath`.**

No Workspace or Instances.

- [ ] **Step 3: Add deployment/reshape progress API to leg geometry.**

Physical and visual geometry use the same progress. No midpoint growth and no second visible pair.

- [ ] **Step 4: Integrate rapid reshape on the stable axle.**

Keep axle angle/motor state. Do not pre-add artificial support. Preserve current geometry if preparation fails.

- [ ] **Step 5: Reconcile redraw safety minimally.**

Remove only logic that requires phase teleport or whole-pair replacement if it conflicts with stable axle. Keep useful penetration detection if it remains valid.

- [ ] **Step 6: Verify automated contracts and mark solver/ground-lift feel `HUMAN_PENDING`.**

---

### Task 5: RCP-05 Camera Feel

**Files:**
- Modify: `src/client/Controllers/RaceCameraController.lua`
- Modify only if needed: `src/shared/Math/CameraMath.lua`
- Tests: extend existing camera contracts or create `tests/test_rcp05_camera_filtering.py`.

- [ ] **Step 1: Preserve side framing, look-ahead, screen anchor, RMB 360 yaw and pitch clamp in RED/static contracts.**
- [ ] **Step 2: Tune/structure separate high-frequency vertical filtering and dead-zone response without large lag.**
- [ ] **Step 3: Run all camera contracts and mark feel `HUMAN_PENDING` for Flat/Step/Fall video review.**

---

### Task 6: RCP-06 Rider Riding/Cowboy Pose

**Files:**
- Modify: `src/client/Controllers/RiderPresentationController.lua`
- Create config only if it keeps pose constants focused and reusable.
- Tests: focused rider presentation contract.

- [ ] **Step 1: RED contract requires rider presentation to remain non-colliding/massless and not delete all safe visual accessories indiscriminately.**
- [ ] **Step 2: Adjust seat offset and Motor6D transforms so pelvis sits on the cube, torso leans slightly forward, knees straddle the sides and arms read as a riding pose.**
- [ ] **Step 3: Preserve physics neutrality and verify; mark pose quality `HUMAN_PENDING`.**

---

### Task 7: RCP-07 Cosmetic Foundation

**Files:**
- Create: `src/shared/Config/CosmeticsCatalog.lua`
- Create: `src/client/Controllers/RacerCosmeticsController.lua`
- Modify integration/bootstrap only as minimally required.
- Tests: `tests/test_rcp07_cosmetics_contract.py`.

**Interfaces:**
- Independent `LegSkinId`, `CubeSkinId`, `RiderSkinId` presentation identifiers.
- Cosmetics may change only presentation properties, never physical config/geometry.

- [ ] **Step 1: RED contract ensures cosmetic modules do not write PhysicsConfig, collider size, ShapeSpec, motor, mass/friction or max reach.**
- [ ] **Step 2: Implement default catalog and presentation controller with no external assets required.**
- [ ] **Step 3: Integrate default IDs and verify existing gameplay geometry remains unchanged when skins change.**

---

### Task 8: Autonomous Bug Hunt / Regression Sweep

**Files:** only proven owner files for each discovered defect; no speculative refactors.

- [ ] **Step 1: Run full Python verifier and Rojo build on fresh HEAD.**
- [ ] **Step 2: Inspect CI failures/logs and fix only reproducible defects with a targeted RED test first.**
- [ ] **Step 3: Audit canonical-shape, stable-axle, reshape, camera, rider and cosmetics contracts for contradictory old assertions/docs.**
- [ ] **Step 4: Compare final diff against the approved spec and remove accidental scope creep.**
- [ ] **Step 5: Produce a final handoff note containing final SHA, completed RCP stages, automated evidence, remaining `HUMAN_PENDING` gates and exact Studio scenarios the user should run after returning.**

## Autopilot Stop Conditions

Stop mutating code and report `BLOCKED` if: main changes unexpectedly in a way that invalidates the active task; a required change would alter network/race/economy/player-data contracts outside approved scope; automated evidence is contradictory and root cause cannot be established; or a decision genuinely depends on human feel rather than technical correctness. Otherwise continue through technically independent tasks even when earlier visual gates remain `HUMAN_PENDING`.
