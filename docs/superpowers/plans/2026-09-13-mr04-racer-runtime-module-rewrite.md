# MR-04 RacerRuntime Module Rewrite Implementation Plan

> Execute with TDD on `main`. No branch/PR. Do not claim human physics/feel acceptance before MR-06 + G0.

**Goal:** Rewrite `RacerRuntime` as the single racer lifecycle/orchestration owner against the permanent `LegPairAssembly` API. Remove duplicate shape construction and redundant side-owner caches without changing player/network/race/presentation policy.

**Owner spec:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

**Engineering contract:** `docs/DEVELOPMENT_PRINCIPLES.md`

**MR-04 baseline:** `7e29c8ef2e392c2fc6257961502b2d4af9d7cc28`

## Responsibility

`RacerRuntime` owns one spawned racer model and its lifecycle orchestration:

- create/destroy the racer model/body shell;
- create exactly one persistent `LegPairAssembly` on first applied shape;
- own current authoritative `ShapeSpec` and `ShapeVersion` publication;
- own the short redraw/reshape timeline;
- own runtime-level preparation for recovery, but not recovery destination/teleport;
- own lifecycle of `RacerStabilizer` and `RacerAntiStall`;
- expose only the getters/shape operations required by services and harnesses.

It does **not** own leg segments, per-side mechanical construction, hinge creation, collision-safe geometry math, network payload validation, camera/rider/cosmetics or race result policy.

## KEEP / CHANGE / DELETE

### KEEP

- public `RacerRuntime.new`, `EnsureTemplate`, `GetModel`, `GetBody`, `GetStabilizer`, `GetAntiStall`, `GetLegPair`, `GetShapeVersion`, `GetCurrentShapeSpec`, `PrepareForRecovery`, `ApplyShape`, `ApplyValidatedShape`, `IsDestroyed`, `Destroy`;
- one invisible `3x3x3` `BodyCollider` and existing spawn/runtime attributes;
- current template compatibility markers (`LeftHub`, `RightHub`) and stabilizer staging attachments for this stage; dead compatibility cleanup belongs to MR-06;
- one persistent pair after first shape;
- initial phase-safety through `RedrawSpawnSafety` before first motor activation;
- redraw via `BeginGeometryReshape`, never pair replacement;
- shape version is published only after validated application succeeds;
- recovery preparation cancels reshape and completes current geometry without choosing a teleport destination;
- existing stabilizer/anti-stall lifecycle and current tuning values.

### CHANGE

- internal/test `ApplyShape` builds through shared `CanonicalLegShape`, not a private `StrokeMath + GeometryMath` pipeline;
- runtime no longer caches duplicate `leftLeg/rightLeg` private ownership aliases; return values are derived from the persistent pair;
- construction/state publication/teardown are organized into focused helpers so lifecycle ownership is explicit;
- `_CreateInitialLegPair` remains the only location that constructs `LegPairAssembly`.

### DELETE

- direct `StrokeMath` and `GeometryMath` dependencies from `RacerRuntime`;
- private `makeInternalShapeSpec` implementation that duplicates canonical anchoring/mapping/segment-plan construction;
- `self.leftLeg` and `self.rightLeg` fields and assignments;
- any pair construction outside `_CreateInitialLegPair`;
- any redraw/recovery body teleport or velocity reset inside runtime.

## Invariants

1. One runtime owns one model/body and at most one live pair.
2. After first shape, pair identity remains stable until runtime destruction.
3. `RacerRuntime` contains no `HingeConstraint`/leg-segment construction.
4. Internal shape construction uses `CanonicalLegShape.Build` and `PhysicsConfig` only once through the shared owner.
5. Validated shape version must increment by exactly one and is committed only after mechanical application succeeds.
6. Normal redraw never writes body `CFrame`, `AssemblyLinearVelocity`, `AssemblyAngularVelocity`, or `PivotTo`.
7. Recovery preparation never chooses a destination or resets velocity.
8. Exactly one runtime reshape heartbeat connection exists at a time; a new redraw cancels the previous generation.
9. Destroy is idempotent and disconnects reshape before destroying pair/assist owners/model.
10. MR-04 does not redesign camera, rider, cosmetics, networking, race rules, tuning or compatibility markers.

---

## Task 1 — RED boundary

Create `tests/test_mr04_racer_runtime_boundary.py` with assertions that:

- `RacerRuntime` requires `CanonicalLegShape`;
- it no longer requires/uses `StrokeMath` or `GeometryMath`;
- `ApplyShape` obtains a canonical result through `CanonicalLegShape.Build` and delegates to existing mechanical application;
- `LegPairAssembly.new` appears exactly once and only inside `_CreateInitialLegPair`;
- runtime contains no `Instance.new("HingeConstraint")` and no physical segment construction;
- no `self.leftLeg`/`self.rightLeg` ownership aliases remain;
- `_ApplyShapeSpec` redraw uses the existing `self.legPair:BeginGeometryReshape(shapeSpec)` and never constructs a pair;
- `PrepareForRecovery` cancels reshape + completes pair and contains no `PivotTo`/CFrame/velocity policy;
- `ApplyValidatedShape` applies first, then commits `currentShapeSpec` and `ShapeVersion`;
- `Destroy` cancels reshape before pair/model destruction.

Run full repository verification and confirm RED for the intended duplicate-pipeline/private-cache reasons.

---

## Task 2 — Rewrite RacerRuntime coherently

Rewrite `src/server/Runtime/RacerRuntime.lua` as one lifecycle owner while preserving the public surface.

### Shared canonical internal shape

Replace direct `StrokeMath`/`GeometryMath` calls with:

```lua
local CanonicalLegShape = require(...CanonicalLegShape)

local function makeInternalShapeSpec(normalizedPoints: {Vector2}): ShapeSpec
    local canonical, reason = CanonicalLegShape.Build(
        normalizedPoints,
        PhysicsConfig.StrokeProcessing,
        PhysicsConfig.LegGeometry
    )
    assert(canonical ~= nil, reason or "internal shape rejected")
    return {
        version = 0,
        normalizedPoints = canonical.normalizedPoints,
        mappedPoints = canonical.mappedPoints,
        bounds = canonical.bounds,
        extent = canonical.extent,
        segmentPlan = canonical.segmentPlan,
        debugRawPointCount = canonical.debugRawPointCount,
        debugPhysicsPointCount = canonical.debugPhysicsPointCount,
        debugId = string.format("internal-shape-p%d", #normalizedPoints),
    }
end
```

This preserves the internal/test version semantics while removing a second geometry pipeline.

### Persistent pair ownership

`_CreateInitialLegPair` is the only constructor site. On success it assigns only `self.legPair`; callers obtain the side objects from that pair. Do not store side aliases on runtime.

For first shape, return `legPair:GetLeftLeg(), legPair:GetRightLeg()`.

For redraw, `BeginGeometryReshape` returns the same persistent sides; start the short timeline and return those values without caching them.

### State publication

Keep validated state transactional:

1. validate incoming version/schema;
2. mechanically apply the shape;
3. only after success set `self.currentShapeSpec` and model debug/version attributes.

Do not add rollback copies of the old mechanical architecture; failures propagate and are handled by the existing authority/transport boundary.

### Recovery

`PrepareForRecovery` only:

- cancels active reshape;
- calls `CompleteReshapeForRecovery` when pair exists.

No spawn lookup, body teleport or velocity reset enters this module.

### Destroy

Idempotent order:

1. mark destroyed;
2. cancel reshape;
3. destroy pair;
4. destroy anti-stall/stabilizer;
5. destroy model;
6. clear owned references.

---

## Task 3 — Migrate direct tests/consumers only when proven stale

Expected likely stale legacy contracts:

- B06/R16 source tests that require direct `StrokeMath`/`GeometryMath` internal shape construction or runtime side caches;
- any static assertion treating compatibility hubs as current mechanical actuator owners.

Do **not** remove `LeftHub`/`RightHub` or `RuntimeAttachments` in MR-04 solely for cleanup; MR-06 owns dead compatibility removal after the mechanical modules are all rewritten.

Preserve all behavior-oriented harness contracts for B06/B08/B09/B10/B13/B14/R16/R17/G0.

---

## Task 4 — Verification/self-review

Fresh final-head evidence required:

- `python verify.py`: all PASS;
- Rokit/toolchain setup PASS;
- `rojo build default.project.json` PASS;
- GitHub Actions `Contract Verify` SUCCESS;
- compare MR-04 baseline → final HEAD shows no unrelated camera/rider/cosmetics/race/network/tuning edits;
- runtime has one canonical shape dependency, one pair constructor site, no duplicate side ownership cache, no body teleport/reset redraw/recovery policy;
- human Studio gates remain PENDING.