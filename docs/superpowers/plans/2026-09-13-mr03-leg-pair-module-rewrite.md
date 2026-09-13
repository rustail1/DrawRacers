# MR-03 LegPairAssembly Module Rewrite Implementation Plan

> REQUIRED: execute with TDD on `main`. No branch/PR. Human Roblox physics acceptance remains pending until MR-06 + G0.

**Goal:** Rewrite `LegPairAssembly` around one permanent axle, one motor and two permanent side assemblies. Remove the temporary staged/commit construction lifecycle completely. Initial phase-safety may select a phase before first motor activation, but it must not create a second pair.

**Owner spec:** `docs/superpowers/specs/2026-09-13-core-module-rewrite-design.md`

**Engineering contract:** `docs/DEVELOPMENT_PRINCIPLES.md`

**MR-03 baseline:** `fdd02538b7c49fd1eebc6728d4ec868ad43a12e7`

## Responsibility

`LegPairAssembly` owns the persistent mechanical leg pair for one racer: one `AxleRoot`, one `AxleJoint`, one left `LegAssembly`, one right `LegAssembly`, motor state, axle phase, shared reshape progress and temporary reshape gravity support.

It does **not** own player/network authority, race rules, recovery destination, track policy, drawing input, camera, rider presentation or cosmetics.

## Boundary

### Inputs

`LegPairAssembly.new({ racerModel, shapeSpec, motorEnabled?, initialPhaseDegrees? })`

### Public operations kept

- `GetRoot()`
- `GetJoint()`
- `GetLeftLeg()`
- `GetRightLeg()`
- `GetPhaseDegrees()`
- `ReplaceGeometry(shapeSpec)`
- `BeginGeometryReshape(shapeSpec)`
- `SetReshapeProgress(progress)`
- `CompleteReshapeForRecovery()`
- `SetEnabled(enabled)`
- `Destroy()`

### Public operation added for one-time initial placement

`SetInitialPhaseDegrees(phaseDegrees)`

This operation is valid only before the motor has ever been enabled. It moves the existing axle/side assembly to a collision-safe initial phase without replacing the pair or racer body. Once the motor has been enabled, initial phase is frozen and the method must reject further calls.

### APIs/state deleted

- `staged` constructor option
- `stagingContainer`
- `committed`
- `Commit()`
- `IsCommitted()`
- pair replacement during initial phase selection

## KEEP / CHANGE / DELETE

### KEEP

- one `AxleRoot` and one motorized `HingeConstraint`;
- `AxleMotorAttachment` on body and `MotorAttachment` on axle;
- current motor tuning from `PhysicsConfig.Motor`;
- right structural phase offset from `RightPhaseOffsetDegrees`;
- two side owners with identical canonical XY geometry;
- redraw changes side geometry in place;
- world-Y-only bounded reshape support;
- recovery can force reshape completion;
- idempotent destroy.

### CHANGE

- construction is always the final persistent pair; there is no detached staging pair;
- initial collision-safe phase selection uses the same pair, while motor is disabled;
- `RacerRuntime:_CreateInitialLegPair` constructs exactly once, calls `RedrawSpawnSafety.ChoosePhase` on that pair, applies the selected phase through `SetInitialPhaseDegrees`, then enables the motor.

### DELETE

- staged constructor branch;
- temporary detached side folder;
- parent-on-commit lifecycle;
- `Commit/IsCommitted` guards;
- destroy/rebuild pair when the selected initial phase differs from zero;
- stale tests that require staged/commit internals.

## Invariants

1. One racer owns exactly one live pair identity until racer destruction.
2. The pair owns exactly one `AxleRoot` and one `HingeConstraint`.
3. Left/right `LegAssembly` identities persist across redraw.
4. Redraw never writes body `CFrame`, `AssemblyLinearVelocity` or `AssemblyAngularVelocity`.
5. Initial phase selection never creates a second `LegPairAssembly`.
6. `SetInitialPhaseDegrees` is usable only before first motor activation.
7. Motor tuning and structural 180-degree right-side phase remain unchanged.
8. Reshape support remains vertical only and turns off when reshape completes/destroys.
9. Recovery completion finishes both current side geometries without choosing a destination.
10. Destroy remains idempotent and removes pair-owned resources.

---

## Task 1 — RED boundary

Create `tests/test_mr03_leg_pair_boundary.py`.

Required assertions:

- `LegPairAssembly.lua` contains exactly one `Instance.new("HingeConstraint")`;
- it contains `SetInitialPhaseDegrees` and a guard proving initial phase cannot be changed after motor activation;
- it contains none of `staged`, `stagingContainer`, `committed`, `Commit`, `IsCommitted`, `LegPairStaging`;
- `RacerRuntime:_CreateInitialLegPair` contains exactly one `LegPairAssembly.new`;
- `_CreateInitialLegPair` still calls `RedrawSpawnSafety.ChoosePhase`;
- it applies the result through `SetInitialPhaseDegrees` and enables the motor only after phase selection;
- no initial path destroys/recreates the pair just because phase changed;
- redraw path still uses `BeginGeometryReshape` and contains no `LegPairAssembly.new`.

Run repository verification and confirm RED specifically because the staged/commit lifecycle still exists.

---

## Task 2 — Rewrite `LegPairAssembly.lua`

Replace the module coherently rather than patching the old state machine.

Construction sequence:

1. Validate racer/body/legs/shape inputs.
2. Ensure body motor attachment.
3. Create one axle root directly under `Legs` at `initialPhaseDegrees` (default 0).
4. Create one axle attachment and one disabled motorized hinge.
5. Create reshape support attachment/force.
6. Create left/right `LegAssembly` owners directly under `Legs`.
7. Materialize the supplied initial shape completely.
8. Initialize `motorEverEnabled = false`, `destroyed = false`.
9. If constructor `motorEnabled == true`, enable through `SetEnabled(true)` so the activation lock is recorded in one place.

`SetInitialPhaseDegrees`:

- assert pair is live;
- assert `motorEverEnabled == false` and current joint is disabled;
- validate finite numeric phase;
- set only `axleRoot.CFrame = axleBaseCFrame(body) * CFrame.Angles(0,0,math.rad(phase))`;
- do not write body transform or velocity;
- return/allow `GetPhaseDegrees` to reflect the selected phase.

`SetEnabled`:

- when enabling, set `motorEverEnabled = true` before/with `joint.Enabled = true`;
- disabling later must **not** reopen initial phase editing.

Redraw and reshape:

- no commit assertions;
- same left/right owners receive `ReplaceGeometry`;
- shared progress is forwarded to both;
- support remains bounded vertical force only.

Destroy:

- destroy side owners, support instances and axle root;
- clear local references;
- no staging cleanup branch exists.

---

## Task 3 — Atomically migrate direct initial consumer

Modify only `RacerRuntime:_CreateInitialLegPair` as needed for MR-03.

Target flow:

```lua
local legPair = LegPairAssembly.new({
    racerModel = model,
    shapeSpec = shapeSpec,
    motorEnabled = false,
    initialPhaseDegrees = 0,
})

local selectedPhaseDegrees, fallback, score = RedrawSpawnSafety.ChoosePhase(model, legPair, 0)
legPair:SetInitialPhaseDegrees(selectedPhaseDegrees)
legPair:SetEnabled(motorEnabled == true)

self.legPair = legPair
self.leftLeg = legPair:GetLeftLeg()
self.rightLeg = legPair:GetRightLeg()
```

On any error before ownership transfer, destroy this one pair and rethrow. Do not construct a replacement pair.

Do not rewrite the rest of `RacerRuntime`; that is MR-04.

---

## Task 4 — Migrate stale tests

Update tests that encode the old staging lifecycle only when CI proves they are stale.

Preserve current behavior contracts:

- phase safety still exists for initial placement;
- structural right phase remains 180 degrees;
- pair/axle/joint/side identities persist across redraw;
- B13/B14 moving redraw never teleports or resets body velocity;
- B08 one-motor contract remains exact;
- recovery/reshape support ownership remains pair-local.

Do not weaken tests merely to get GREEN.

---

## Task 5 — Verification and review

Required fresh evidence on final MR-03 HEAD:

- `python verify.py`: all PASS;
- Rokit/toolchain setup PASS;
- `rojo build default.project.json` PASS;
- GitHub Actions `Contract Verify` SUCCESS;
- compare/diff shows no camera/rider/cosmetics/race/economy scope expansion;
- no staged/commit lifecycle remains in `LegPairAssembly` or its initial direct consumer;
- no human physics/feel PASS is claimed.

MR-03 exits only when the intended boundary is simpler and the obsolete pair-construction lifecycle is gone.