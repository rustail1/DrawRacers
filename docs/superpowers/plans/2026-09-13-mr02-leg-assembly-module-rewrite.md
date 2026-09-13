# MR-02 LegAssembly Module Rewrite Implementation Plan

> **Execution rule:** use `superpowers:executing-plans` + TDD. Repository `rustail1/DrawRacers`, branch `main` only. No branches/PRs.

**Goal:** replace legacy `LegAssembly` as one coherent one-side geometry owner. A side keeps one persistent root for its lifetime and materializes only the currently-built hub-to-tip prefix of an authoritative canonical `ShapeSpec`. Normal redraw must reuse the same side owner rather than staging/replacing an old/new side pair.

**Approved architecture:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

**Engineering rules:** `docs/DEVELOPMENT_PRINCIPLES.md`

## Execution status

- Plan baseline when written: `3807a8b78c02024108176d4429d502a2a89d9ccf`.
- Detailed plan checkpoint: `fa30280aaaeee4826c3b5c54cb6d8332cd41a60e`.
- Production module rewrite: `7d364c6c50de1d4af9a1f94183616da3e34e86c6`.
- Legacy static-contract alignment: `c1013876b7bb77f0ab08c5e8275bc6d861383cff`.
- CI on `c1013876...`: run `34765103357` -> **244 passed, 0 failed**, Rokit install PASS, Rojo build PASS.
- Final MR-02 cleanup still required before closure: migrate the wired B13 Studio spec away from the retired staged-side failure model, restore this detailed plan after the accidental shortened checkpoint edit, then require one fresh full CI run on the final MR-02 HEAD.

## Global constraints

- Re-fetch fresh `main` immediately before every repository write.
- MR-02 is a `MODULE_REWRITE`, not a compatibility patch.
- No parallel old/new `LegAssembly` implementations.
- No compatibility wrapper that reintroduces `staged`, `Commit`, `IsCommitted`, `SetRetiring`, `_Retiring`, or replacement-side handoff inside `LegAssembly`.
- Preserve canonical `segmentPlan` as the only geometry source.
- Preserve physical thickness `0.54`, visual thickness `0.78`, current socket `Z = ±1.5`, collision groups/material behavior, and structural phase supplied by `LegPairAssembly`.
- `LegAssembly` must not own a motor, `HingeConstraint`, player/network state, race rules, recovery destination, camera, or opposite-leg policy.
- `LegReshapeMath` remains the pure arc-length progress owner. Do not duplicate its math in runtime modules.
- Future full colliders and visuals must not be pre-created and hidden during a partial reshape. At any partial progress, materialized geometry is the completed prefix plus at most one temporary partial tip.
- Borrowed canonical arrays must never be cleared or mutated by `ReplaceGeometry` or `Destroy`.
- A pair-owned temporary initial staging container is allowed only as a bounded MR-02 bridge because current `RacerRuntime` still uses initial spawn phase safety. That bridge must be removed during MR-03/MR-04; it must not leak back into `LegAssembly`.
- Do not touch camera, rider, cosmetics, race rules, network schema, tuning values, or recovery destination policy.

---

## Task 1 — Establish the new module boundary as RED

**Files:**
- create `tests/test_mr02_leg_assembly_boundary.py`
- update `tests/test_b07_leg_assembly.py`
- update `tests/test_rcp04_rapid_reshape.py`
- update only directly conflicting redraw-contract tests when they encode retired staged-side internals

### 1.1 Required public boundary

The focused contract must require:

```text
LegAssembly.new
LegAssembly:ReplaceGeometry
LegAssembly:SetReshapeProgress
LegAssembly:CompleteReshape
LegAssembly:Destroy
LegReshapeMath.Evaluate
AxleWeld
Segments
Visual
```

It must forbid:

```text
staged
LegAssembly:Commit
LegAssembly:IsCommitted
LegAssembly:SetRetiring
_Retiring
HingeConstraint
ActuatorType
```

### 1.2 No geometry construction in the constructor

The constructor must not consume or iterate `shapeSpec.segmentPlan`. Geometry begins only after explicit `ReplaceGeometry(shapeSpec)`.

Static contract should also require private helpers representing actual runtime ownership, such as:

```text
clearGeometry
materializeCompleteSegment
partialEndpoint / partial-tip update path
```

### 1.3 Direct-consumer RED

`LegPairAssembly` must no longer call retired side APIs or use the normal-redraw pattern:

```text
buildStagedSides
stagedLeft / stagedRight
oldLeft / oldRight
SetRetiring
side Commit / IsCommitted
```

Normal redraw should target the persistent sides through `self.leftLeg:ReplaceGeometry(shapeSpec)` and `self.rightLeg:ReplaceGeometry(shapeSpec)`.

### 1.4 Confirm a meaningful RED

Before production replacement, the focused test set must fail because current production still uses the retired staged/retiring side lifecycle, not because of a file path/import/environment error.

---

## Task 2 — Rewrite `src/server/Runtime/LegAssembly.lua` coherently

### 2.1 Constructor contract

Target constructor:

```lua
LegAssembly.new({
    container = <Instance>,
    side = "Left" | "Right",
    axleRoot = <Part>,
    socketZ = <number>,
    phaseDegrees = <number?>,
})
```

Constructor owns exactly:
- one side `Model` (`LeftLeg` or `RightLeg`);
- one persistent `LegRoot`;
- one `AxleWeld` to the shared axle;
- one `Segments` folder;
- one `Visual` folder;
- local lifecycle references.

Constructor does **not** accept authoritative geometry and does not prebuild segments.

### 2.2 Geometry helpers

Keep geometry helper responsibilities explicit:

```text
makeSegmentCFrame
configureVisualPart
configurePhysicalPart
weldParts
dynamicWeld
setDynamicFrame
destroyIfPresent
clearGeometry
ensureVisualJoint
materializeCompleteSegment
destroyPartialTip / ensurePartialTip / updatePartialTip
validateShapeSpec
```

`clearGeometry` destroys only owned current geometry children/references. It must preserve the persistent side model/root/axle weld and must not mutate caller-owned `ShapeSpec` arrays.

### 2.3 `ReplaceGeometry(shapeSpec)`

Required behavior:
1. assert live owner;
2. validate `segmentPlan`, mapped data, collider cap, endpoints and minimum legal segment lengths **before** deleting current local geometry;
3. clear only current side geometry;
4. borrow authoritative `segmentPlan` / `mappedPoints`;
5. reset materialized-prefix state;
6. enter progress `0` with no prebuilt future full collider.

No remapping/simplifying/resampling belongs here.

### 2.4 `SetReshapeProgress(progress)`

Use `LegReshapeMath.Evaluate(segmentPlan, progress)`.

At `progress == 0`:
- no complete physical segment exists;
- no hidden full future collider exists.

At `0 < progress < 1`:
- materialize only completed canonical prefix segments;
- materialize/update at most one partial tip for the current segment;
- visual and physical tip use the same canonical endpoints;
- physical/visual thickness may differ, centerline may not.

At `progress == 1`:
- all complete canonical segments exist;
- temporary partial tip is removed.

If progress moves backward, rebuild only the required prefix rather than keeping hidden future segments.

### 2.5 `CompleteReshape()`

Equivalent to setting progress to `1`, with no new lifecycle owner.

### 2.6 Getters and destroy

Keep only legitimate public getters needed by direct consumers/tests:

```text
GetModel
GetRoot
GetSegments
GetMappedPoints
GetStructuralPhaseDegrees
```

`GetSegments()` means currently materialized complete collider segments; after complete reshape its count equals canonical segment-plan length.

`Destroy()` is idempotent and destroys only owned Instances/references. No `table.clear` on borrowed authoritative arrays.

---

## Task 3 — Migrate direct consumer `LegPairAssembly` without doing MR-03 early

### 3.1 New side construction

Pair creates a side owner with explicit container/axle/socket/phase, then calls `ReplaceGeometry(shapeSpec)` and, when initial full geometry is needed, `CompleteReshape()`.

### 3.2 Bounded initial staging bridge

Current `RacerRuntime` still stages an initial pair for collision-safe phase selection. Until MR-03/MR-04 rewrite that lifecycle, `LegPairAssembly` may own a detached temporary `Folder` for initial side models.

Rules:
- the temporary folder belongs to the pair, not `LegAssembly`;
- side API has no staged mode;
- `Commit()` at pair level may reparent persistent side models and the axle into the real `Legs` folder;
- this bridge has an explicit deletion checkpoint: MR-03/MR-04.

### 3.3 Normal redraw is in-place side geometry replacement

`BeginGeometryReshape(shapeSpec)` must:

```text
keep pair identity
keep axle identity
keep hinge/motor identity
keep LeftLeg owner identity
keep RightLeg owner identity
enable bounded reshape support
LeftLeg:ReplaceGeometry(shapeSpec)
RightLeg:ReplaceGeometry(shapeSpec)
set both sides to progress 0
return the same side owners
```

It must not allocate `stagedLeft`, `stagedRight`, `oldLeft`, `oldRight`, replacement models, or retiring names.

`ReplaceGeometry(shapeSpec)` may perform the same replacement and immediately complete both sides if an immediate complete result is required by its caller.

### 3.4 Remove retired side API usage

Remove all direct consumer calls to:

```text
LegAssembly:Commit
LegAssembly:IsCommitted
LegAssembly:SetRetiring
buildStagedSides
old/new side handoff
```

Do not rename these into a new compatibility API.

---

## Task 4 — Update Studio behavior evidence for the new module boundary

### 4.1 B07 one-side spec

`B07LegAssemblySpec.lua` must construct an empty persistent side owner, then call `ReplaceGeometry(shapeSpec)`.

Preserve assertions for:
- exact side socket position;
- no hinge inside the side owner;
- exact `AxleWeld` relation;
- canonical mapped points;
- physical collider collision group and hidden presentation;
- separate nonphysical visual geometry;
- final segment count/collision semantics;
- clean destroy.

Add partial-materialization behavior:

```text
progress 0 -> zero complete colliders
progress 0.5 -> fewer complete colliders than full plan and at most one partial tip
progress 1 -> exactly canonical full plan and no temporary partial tip
```

### 4.2 B13 redraw spec migration

The old B13 Studio spec intentionally tested the retired implementation by monkey-patching `LegAssembly.new`, `LegAssembly.Commit`, and post-commit side handoff. After MR-02 this is obsolete implementation evidence and must be replaced, not preserved.

New B13 behavior-level evidence must verify:
- first valid shape creates a live pair;
- invalid redraw fails closed and does not change authoritative `ShapeVersion` or pair/axle/joint/side identities;
- a second valid redraw increments `ShapeVersion` exactly once;
- successful redraw keeps the same pair, axle, joint, LeftLeg owner, RightLeg owner and side models;
- live axle phase is not reset by redraw;
- body `CFrame`, linear velocity and angular velocity are not reset by redraw;
- no `LeftLeg_Retiring`, `RightLeg_Retiring`, or `AxleRoot_Retiring` leak exists;
- exactly two side models and one axle remain;
- `PrepareForRecovery()` completes the transient geometry to the authoritative current segment plan.

Do not reintroduce artificial staged-side commit failure injection merely to preserve historical B13 code structure.

---

## Task 5 — Replace stale static tests only where architecture intentionally changed

Existing tests are not sacred when they assert a deleted implementation. For each failure after the rewrite:

1. read the exact failure and current owner;
2. prove whether it protects a current invariant or only the retired staged-side mechanism;
3. if invariant is current, adapt the assertion to the new behavior;
4. if it reveals a real production defect, fix production instead;
5. never weaken an expectation just to obtain GREEN.

Known legitimate migrations for MR-02 include old assertions requiring:
- `oldLeft:Destroy()` / `oldRight:Destroy()`;
- `buildStagedSides`;
- staged `pcall`/commit rollback;
- side-retiring names as a normal redraw mechanism;
- exact source spelling `PhysicsConfig.Motor.AngularVelocity` when the same config object is read through a local alias.

The replacement invariants are persistent pair/axle/joint/side identity, correct motor source, bounded vertical reshape support, and no body motion reset.

---

## Task 6 — Verification and self-review

### 6.1 Focused checks

Run the MR-02-focused contracts, including at minimum:

```text
tests/test_mr02_leg_assembly_boundary.py
tests/test_b07_leg_assembly.py
tests/test_rcp04_rapid_reshape.py
tests/test_rcp01_stable_axle.py
tests/test_b13_atomic_redraw.py
tests/test_bg01_canvas_world_orientation_parity.py
```

### 6.2 Repository-complete verification

Require:

```bash
python verify.py
rokit install --no-trust-check
rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx
```

For remote execution, a fresh `Contract Verify` job on the exact final MR-02 HEAD may provide this evidence when logs show all three stages completed.

### 6.3 Diff/self-review checklist

Confirm:

```text
LegAssembly is a coherent replacement, not old code plus branches.
No staged/Commit/IsCommitted/SetRetiring/_Retiring remains in LegAssembly.
No HingeConstraint/motor/network/player/race/recovery destination logic exists in LegAssembly.
No future full collider is pre-created during reshape.
LegPairAssembly normal redraw does not create replacement sides.
Any remaining pair-level initial staging bridge is isolated and explicitly deferred to MR-03/MR-04.
B07 and B13 Studio specs test current behavior rather than retired internals.
No camera/rider/cosmetics/tuning/network-schema production files changed.
```

### 6.4 Commit/checkpoint policy

Production rewrite checkpoint message:

```text
refactor: rewrite single-side leg assembly
```

Test-only legacy contract migrations may use a separate reviewable commit.

Final MR-02 HEAD must have a fresh successful `Contract Verify` run.

---

## MR-02 exit criteria

MR-02 is repository-level complete only when all are true:

- `LegAssembly` owns exactly one persistent side root plus current canonical physical/visual geometry.
- Side API has no staging/retiring lifecycle.
- Normal redraw reuses the same side owners.
- Hub-to-tip reshape materializes only the visible/current prefix rather than hiding a prebuilt full future leg.
- Physical and visual centerlines derive from the same canonical segment endpoints.
- Borrowed canonical shape tables are not mutated by side lifecycle.
- Direct consumer is migrated without adding a second side implementation.
- B07/B13 evidence is aligned with the current architecture.
- `python verify.py`, Rokit install, Rojo build, and CI are GREEN on the final MR-02 HEAD.
- No human physics/feel PASS is inferred from automation.
- Next module is MR-03 `LegPairAssembly`; camera/rider/cosmetics remain untouched.
