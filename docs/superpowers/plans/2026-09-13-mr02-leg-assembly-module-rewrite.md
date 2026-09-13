# MR-02 LegAssembly Module Rewrite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:executing-plans` to implement this plan task-by-task on `main`. Do not create a branch or PR.

**Goal:** Replace legacy `LegAssembly` as one coherent module so one side owns one persistent root and materializes only the currently-built hub-to-tip canonical geometry, while direct consumers are migrated without preserving the retired staging/retiring API.

**Architecture:** `LegAssembly` becomes a focused one-side geometry owner. It accepts an explicit parent/container, side, persistent axle root/socket/phase, then receives canonical `ShapeSpec` data through `ReplaceGeometry`. `LegPairAssembly` is changed only as the direct consumer needed to use this new API; its broader axle/motor ownership rewrite remains MR-03.

**Tech Stack:** Roblox Studio / Luau strict, Rojo, Rokit, Python contract tests, GitHub Actions `Contract Verify`.

**Spec:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

**Engineering rules:** `docs/DEVELOPMENT_PRINCIPLES.md`

## Global Constraints

- Repository `rustail1/DrawRacers`, branch `main` only; no branches/PRs.
- Baseline for this plan: `3807a8b78c02024108176d4429d502a2a89d9ccf`; re-fetch `main` before every write.
- MR-02 is a `MODULE_REWRITE`: do not add a second implementation, compatibility branch, legacy wrapper, or renamed staging API inside `LegAssembly`.
- Preserve one side root welded to the shared axle, canonical `segmentPlan`, physical thickness `0.54`, visual thickness `0.78`, socket `Z=+-1.5`, existing collision/material configuration, and structural phase supplied by the pair.
- `LegAssembly` must not own motor, HingeConstraint, player/network/race/recovery destination/camera/opposite-leg policy.
- `LegReshapeMath` remains the pure arc-length owner; do not duplicate its math.
- Future full colliders/visual segments must not exist hidden during partial reshape. At a partial progress the materialized geometry is completed prefix plus at most one partial tip.
- Borrowed canonical tables are never mutated/cleared by `Destroy` or `ReplaceGeometry`.
- Any temporary direct-consumer staging container in `LegPairAssembly` is pair-owned and has an explicit removal checkpoint in MR-03; `LegAssembly` itself has no `staged`, `Commit`, `IsCommitted`, `SetRetiring`, or `_Retiring` concept.
- Do not touch camera, rider, cosmetics, race rules, network schema, tuning values, or recovery destination policy.

---

### Task 1: Establish the MR-02 contract as RED

**Files:**
- Create: `tests/test_mr02_leg_assembly_boundary.py`
- Modify: `tests/test_b07_leg_assembly.py`
- Modify: `tests/test_rcp04_rapid_reshape.py`

**Interfaces:**
- Consumes current `LegAssembly.lua` and `LegPairAssembly.lua` source.
- Produces the static architecture contract that the replacement must satisfy.

- [ ] **Step 1: Add the focused boundary test**

Create `tests/test_mr02_leg_assembly_boundary.py` with assertions equivalent to:

```python
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_mr02_leg_assembly_is_one_persistent_side_owner() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")

    for required in [
        "function LegAssembly.new",
        "function LegAssembly:ReplaceGeometry",
        "function LegAssembly:SetReshapeProgress",
        "function LegAssembly:CompleteReshape",
        "function LegAssembly:Destroy",
        'WaitForChild("LegReshapeMath")',
        "LegReshapeMath.Evaluate",
        '"AxleWeld"',
        '"Segments"',
        '"Visual"',
    ]:
        assert required in leg, f"missing MR-02 boundary token: {required}"

    for forbidden in [
        "staged",
        "function LegAssembly:Commit",
        "function LegAssembly:IsCommitted",
        "function LegAssembly:SetRetiring",
        "_Retiring",
        'Instance.new("HingeConstraint")',
        "ActuatorType",
    ]:
        assert forbidden not in leg, f"legacy/non-owner behavior remains in LegAssembly: {forbidden}"


def test_mr02_future_geometry_is_not_prebuilt_and_hidden() -> None:
    leg = read("src/server/Runtime/LegAssembly.lua")
    constructor = leg[leg.index("function LegAssembly.new"):leg.index("function LegAssembly:GetModel")]
    assert "shapeSpec.segmentPlan" not in constructor
    assert "for _, planned in params.shapeSpec.segmentPlan" not in constructor
    assert "materializeCompleteSegment" in leg
    assert "clearGeometry" in leg
    assert "partialEndpoint" in leg


def test_mr02_direct_consumer_no_longer_calls_retired_side_api() -> None:
    pair = read("src/server/Runtime/LegPairAssembly.lua")
    for forbidden in [
        ":Commit()",
        ":IsCommitted()",
        ":SetRetiring(",
    ]:
        assert forbidden not in pair, f"LegPairAssembly still calls retired LegAssembly API: {forbidden}"
```

- [ ] **Step 2: Replace stale B07 source-detail expectations**

Update `tests/test_b07_leg_assembly.py` so it still protects the B07 geometry contract but no longer requires `shapeSpec` in the constructor. Require instead:

```python
for token in [
    '"LeftLeg"', '"LegRoot"', '"Segments"', '"Visual"', '"RacerLeg"',
    'WeldConstraint', '"AxleWeld"', 'PhysicalLegSegmentThickness',
    'VisualLegSegmentThickness', 'SegmentOverlapAllowance',
    "function LegAssembly:ReplaceGeometry", "shapeSpec.segmentPlan",
    "axleRoot", "socketZ", "phaseDegrees",
]:
    assert token in leg
```

Keep the assertions that `LegAssembly` does not create a hinge and does not remap stroke data.

Change the destroy regression comment/assertion to the current contract:

```python
assert "table.clear(self.segmentPlan)" not in leg
assert "table.clear(self.mappedPoints)" not in leg
```

without mentioning staged/retiring sides.

- [ ] **Step 3: Replace the obsolete RCP-04 pair assertions**

In `tests/test_rcp04_rapid_reshape.py`, preserve pure reshape math, bounded duration, world-Y-only support, and runtime heartbeat assertions, but remove requirements for `stagedLeft`, `stagedRight`, `oldLeft:Destroy()`, and `oldRight:Destroy()`.

The pair-level assertion after MR-02 must instead require direct calls to the persistent sides:

```python
assert "self.leftLeg:ReplaceGeometry(shapeSpec)" in pair
assert "self.rightLeg:ReplaceGeometry(shapeSpec)" in pair
assert "self.leftLeg:SetReshapeProgress" in pair
assert "self.rightLeg:SetReshapeProgress" in pair
```

- [ ] **Step 4: Run the focused tests and confirm correct RED**

Run:

```bash
python -m pytest -q \
  tests/test_mr02_leg_assembly_boundary.py \
  tests/test_b07_leg_assembly.py \
  tests/test_rcp04_rapid_reshape.py
```

Expected: FAIL because current `LegAssembly` still exposes staging/retiring APIs and current `LegPairAssembly` still builds staged replacement sides. A path/import/environment failure is not an acceptable RED.

---

### Task 2: Rewrite `LegAssembly.lua` as one coherent side owner

**Files:**
- Rewrite: `src/server/Runtime/LegAssembly.lua`

**Interfaces:**
- Consumes: `PhysicsConfig`, `LegReshapeMath`, `StrokeTypes.ShapeSpec`, `CollisionGroups`, a caller-supplied `container`, `axleRoot`, `side`, `socketZ`, `phaseDegrees`.
- Produces:
  - `LegAssembly.new({container, side, axleRoot, socketZ, phaseDegrees})`
  - `:ReplaceGeometry(shapeSpec)`
  - `:SetReshapeProgress(progress)`
  - `:CompleteReshape()`
  - `:GetModel()`, `:GetRoot()`, `:GetSegments()`, `:GetMappedPoints()`, `:GetStructuralPhaseDegrees()`
  - `:Destroy()`

- [ ] **Step 1: Replace the build parameter contract**

The new parameter type is:

```lua
export type BuildParams = {
    container: Instance,
    side: string,
    axleRoot: Part,
    socketZ: number,
    phaseDegrees: number?,
}
```

Constructor validates only side/container/axle ownership inputs. It creates exactly one `Model`, `LegRoot`, `Segments` folder, `Visual` folder and `AxleWeld`. It does not accept or iterate a `ShapeSpec`.

- [ ] **Step 2: Keep geometry helpers focused**

Retain/refactor helpers for:

```lua
makeSegmentCFrame(rootCFrame, a, b)
configureVisualPart(part, color)
configurePhysicalPart(part, material)
weldParts(name, part0, part1, parent)
dynamicWeld(name, root, part)
setDynamicFrame(root, part, weld, a, b)
```

Add private helpers with explicit ownership:

```lua
local function destroyIfPresent(instance: Instance?)
    if instance then instance:Destroy() end
end

local function clearGeometry(self: any)
    -- Destroy only children of Segments/Visual and local part references.
    -- Never destroy model/root/axle weld and never mutate borrowed ShapeSpec tables.
end

local function materializeCompleteSegment(self: any, index: number)
    -- Create one physical collider and one matching visual segment for segmentPlan[index].
    -- Create the corresponding endpoint visual joint.
end

local function updatePartialTip(self: any, index: number?, endpoint: Vector2?)
    -- Create/update at most one physical tip and one visual tip when visible length > MIN_DYNAMIC_LENGTH.
    -- Destroy them when no partial segment exists.
end
```

- [ ] **Step 3: Implement `ReplaceGeometry` as the only geometry replacement entry**

Required behavior:

```lua
function LegAssembly:ReplaceGeometry(shapeSpec: ShapeSpec)
    assert(not self.destroyed, "LegAssembly is destroyed")
    assert(type(shapeSpec) == "table" and type(shapeSpec.segmentPlan) == "table", "shapeSpec missing segmentPlan")
    assert(#shapeSpec.segmentPlan > 0, "LegAssembly requires at least one planned segment")
    assert(#shapeSpec.segmentPlan <= PhysicsConfig.LegGeometry.MaxColliderSegmentsPerLeg, "shapeSpec segmentPlan exceeds collider cap")

    clearGeometry(self)
    self.segmentPlan = shapeSpec.segmentPlan
    self.mappedPoints = shapeSpec.mappedPoints or {}
    self.materializedCompleteSegments = 0
    self:SetReshapeProgress(0)
end
```

Validate each segment endpoint/length before accepting the new plan. Do not clear or edit `shapeSpec.segmentPlan` / `shapeSpec.mappedPoints`.

- [ ] **Step 4: Implement hub-to-tip materialization without hidden future colliders**

`SetReshapeProgress` evaluates the plan with `LegReshapeMath.Evaluate`. For every newly-complete index, call `materializeCompleteSegment`. If progress goes backward, clear materialized geometry and rebuild only the completed prefix. Then update at most one partial tip from `state.partialSegmentIndex`/`state.partialEndpoint`.

At progress `0`: no full collider exists. At `0 < p < 1`: only completed prefix plus optional partial tip exists. At progress `1`: all canonical full segments exist and the temporary partial tip is destroyed.

- [ ] **Step 5: Implement `CompleteReshape` and lifecycle**

```lua
function LegAssembly:CompleteReshape()
    return self:SetReshapeProgress(1)
end
```

`Destroy` destroys the model and local instance references, but does not `table.clear` borrowed canonical tables.

- [ ] **Step 6: Keep getters source-compatible where still legitimate**

`GetSegments` returns the currently materialized complete collider array; at progress 1 this equals the full canonical plan length. `GetMappedPoints` returns the currently borrowed canonical mapped points. Structural phase remains immutable for the owner lifetime.

---

### Task 3: Migrate the direct consumer without completing MR-03 early

**Files:**
- Modify: `src/server/Runtime/LegPairAssembly.lua`

**Interfaces:**
- Consumes the new `LegAssembly.new(...container...)`, `ReplaceGeometry`, `SetReshapeProgress`, `CompleteReshape` API.
- Preserves current pair public API for `RacerRuntime` until MR-03/MR-04.

- [ ] **Step 1: Replace `buildLeg` with the new side construction contract**

Use a caller-selected container:

```lua
local function buildLeg(params: LegBuildParams)
    local leg = LegAssembly.new({
        container = params.container,
        side = params.side,
        axleRoot = params.axleRoot,
        socketZ = params.socketZ,
        phaseDegrees = params.phaseDegrees,
    })
    leg:ReplaceGeometry(params.shapeSpec)
    return leg
end
```

`LegBuildParams` no longer contains `staged`; it contains `container: Instance`.

- [ ] **Step 2: Keep pair-level initial staging outside `LegAssembly` only as a bounded MR-02 bridge**

If current `RacerRuntime` still constructs a staged pair for initial-spawn safety, `LegPairAssembly` owns a detached temporary `Folder`/`Model` container for its sides. On pair `Commit`, it reparents each side model into `legsFolder` and destroys the temporary container. This bridge is explicitly deleted in MR-03/MR-04 when pair construction is rewritten; do not expose it through `LegAssembly`.

- [ ] **Step 3: Replace side-replacement redraw with in-place side geometry calls**

`BeginGeometryReshape(shapeSpec)` must stop building `stagedLeft/stagedRight` and stop retiring/destroying side owners. It performs:

```lua
self.reshapeForcedComplete = false
self:_SetReshapeSupportEnabled(true)
self.leftLeg:ReplaceGeometry(shapeSpec)
self.rightLeg:ReplaceGeometry(shapeSpec)
self.leftLeg:SetReshapeProgress(0)
self.rightLeg:SetReshapeProgress(0)
return self.leftLeg, self.rightLeg
```

`ReplaceGeometry(shapeSpec)` becomes the same in-place geometry operation, completed immediately if its caller expects immediate geometry:

```lua
self.leftLeg:ReplaceGeometry(shapeSpec)
self.rightLeg:ReplaceGeometry(shapeSpec)
self.leftLeg:CompleteReshape()
self.rightLeg:CompleteReshape()
```

Do not create new side owners during normal redraw.

- [ ] **Step 4: Remove all calls to retired side APIs**

Delete use of:

```lua
leftLeg:Commit()
rightLeg:Commit()
leftLeg:IsCommitted()
rightLeg:IsCommitted()
leftLeg:SetRetiring(...)
rightLeg:SetRetiring(...)
buildStagedSides(...)
```

Do not replace them with renamed compatibility methods.

---

### Task 4: Update the Studio B07 behavior spec to the new public API

**Files:**
- Modify: `src/server/Tests/B07LegAssemblySpec.lua`

**Interfaces:**
- Uses `LegAssembly.new` followed by `ReplaceGeometry` and `CompleteReshape`.
- Continues to verify exact B07 one-side world geometry and cleanup.

- [ ] **Step 1: Construct the owner without ShapeSpec**

Replace construction with:

```lua
local leg = LegAssembly.new({
    container = legsFolder,
    side = "Left",
    axleRoot = axleRoot,
    socketZ = -PhysicsConfig.LegGeometry.LegSocketZAbs,
    phaseDegrees = 0,
})
leg:ReplaceGeometry(shapeSpec)
leg:CompleteReshape()
```

- [ ] **Step 2: Preserve geometry assertions**

Keep exact socket position, no hinge, `AxleWeld`, canonical mapped points, full segment count at completed progress, collision-group/material/presentation separation, and destroy cleanup assertions.

- [ ] **Step 3: Add partial-materialization assertions**

Before `CompleteReshape`, use a second replacement/progress fixture or reorder the fixture to assert:

```lua
leg:ReplaceGeometry(shapeSpec)
assert(#leg:GetSegments() == 0, "progress 0 must not prebuild future full colliders")
leg:SetReshapeProgress(0.5)
assert(#leg:GetSegments() < #shapeSpec.segmentPlan, "partial reshape must materialize only the completed prefix")
leg:CompleteReshape()
assert(#leg:GetSegments() == #shapeSpec.segmentPlan, "complete reshape must match canonical plan")
```

The test must inspect `Segments` descendants as needed to prove there is at most one `ReshapeTipCollider` during partial progress.

---

### Task 5: Focused GREEN, full regression, and checkpoint

**Files:**
- No new production scope beyond Tasks 1-4.

**Interfaces:**
- Produces a GREEN MR-02 checkpoint while MR-03 remains next.

- [ ] **Step 1: Run focused MR-02 tests**

```bash
python -m pytest -q \
  tests/test_mr02_leg_assembly_boundary.py \
  tests/test_b07_leg_assembly.py \
  tests/test_rcp04_rapid_reshape.py \
  tests/test_rcp01_stable_axle.py \
  tests/test_b13_atomic_redraw.py
```

Expected: PASS. If an old test fails only because it encodes the retired old/new side handoff, replace that assertion with the target invariant (persistent side owner / persistent axle); do not restore legacy production code.

- [ ] **Step 2: Run repository verification**

```bash
python verify.py
```

Expected: zero failures.

- [ ] **Step 3: Install pinned toolchain and build Rojo project**

```bash
rokit install --no-trust-check
rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx
```

Expected: both commands exit successfully.

- [ ] **Step 4: Self-review the diff**

Confirm all are true:

```text
LegAssembly.lua is a coherent replacement, not old code plus branches.
No staged/Commit/IsCommitted/SetRetiring/_Retiring remains in LegAssembly.
No HingeConstraint/motor/network/player/race/recovery destination logic exists in LegAssembly.
No future full collider is pre-created during reshape.
LegPairAssembly no longer calls retired LegAssembly APIs.
Any pair-owned temporary initial staging bridge is explicitly isolated for removal in MR-03.
No camera/rider/cosmetics/tuning/network schema files changed.
```

- [ ] **Step 5: Commit the GREEN implementation checkpoint**

Commit message:

```text
refactor: rewrite single-side leg assembly
```

- [ ] **Step 6: Verify fresh CI on that exact HEAD**

Require GitHub Actions `Contract Verify` for the implementation commit with successful contract checks, Rokit install, and Rojo build. CI GREEN is repository evidence only; no Roblox physics/feel PASS is claimed.

## MR-02 Exit Criteria

- `LegAssembly` has one responsibility: one persistent side root plus current canonical physical/visual geometry.
- Its public API has no staging/retiring lifecycle.
- Redraw materializes hub-to-tip prefix geometry rather than hiding a prebuilt future leg.
- Physical and visual centerlines come from the same canonical segment endpoints.
- Direct pair consumer is migrated without adding a second side implementation.
- Automated verification/build/CI are GREEN on the implementation HEAD.
- MR-03 is next and owns the complete rewrite of `LegPairAssembly`; no camera/rider/cosmetics work starts.