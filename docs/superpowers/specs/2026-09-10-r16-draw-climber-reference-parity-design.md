# R16 — Draw Climber Reference Parity Design

Date: 2026-09-10
Status: DESIGN APPROVED IN CHAT / WRITTEN SPEC AWAITING FINAL USER REVIEW
Repository: `rustail1/DrawRacers`
Base before this spec: `e18fef29a613f8796b445b8b4c8964fa99162441`

## 1. Goal

Bring the M0 core locomotion feel materially closer to the observable behavior of Draw Climber without copying unknown/private implementation details and without replacing the existing authoritative Roblox architecture.

Target player-facing loop:

`one drawing -> one authoritative ShapeSpec -> two identical physical legs -> fixed pivots on the cube -> motor-driven leg rotation -> upright body moves physically in X/Y -> redraw changes both legs atomically`.

R16 is a bounded pre-G0 correction inside the existing B03–B16/B17 scope. It does not authorize multiplayer/meta/economy/release work.

## 2. Reference boundary

We target observable core behavior, not hidden source-code parity. The original game's exact internal axle coordinates, rigidbody settings, phase math, motor torque, friction, camera constants, and solver parameters are not treated as known facts unless directly observable or independently evidenced.

Therefore:
- keep the existing server-authoritative ShapeSpec path;
- keep real Roblox physics and HingeConstraint-driven legs;
- do not introduce fake shape classification such as `if circle then speed`;
- do not introduce global slow motion during drawing in multiplayer;
- do not add paid movement power;
- do not add side walls or scripted forward movement as a substitute for leg physics.

## 3. Canonical final behavior

### 3.1 Player drawing

The player draws exactly one continuous shape.

One accepted stroke creates exactly one authoritative ShapeSpec. The same XY ShapeSpec is duplicated to both physical legs. It is not mirrored, recentered to its bounding box, or resized to a standard radius.

The DrawInputRect center `(0,0)` is the physical rotation pivot. The visible center marker is presentation of the actual mechanical pivot, not decoration.

### 3.2 Body translation

World axes remain:
- `+X` = race forward;
- `+Y` = up;
- `+Z` = lateral lane direction.

Final body translation contract:
- X translation: physically free;
- Y translation: physically free;
- Z translation: mechanically locked to `laneCenterZ` by the existing PlaneConstraint owner.

No normal-operation script may directly set body Y to climb or hover. Upward movement must come from physical leg/track contact; downward movement comes from gravity and collision loss.

### 3.3 Body rotation

The body is upright and does not intentionally tumble with the legs.

Final body rotation contract:
- rotation about world X: locked/corrected;
- rotation about world Y: locked/corrected;
- rotation about world Z: locked/corrected.

The body remains a physical assembly; the orientation system may apply corrective torque, but it must not provide forward propulsion or vertical lift.

Starting acceptance values:
- normal body angular deviation <= 1 degree;
- transient strong-contact deviation <= 3 degrees;
- after a transient disturbance, return to <= 1 degree within 0.25 s under the canonical B10 test setup.

### 3.4 Leg rotation

Only the legs rotate for locomotion.

Each side keeps one Hub + one LegRoot + welded physical segments + one HingeConstraint motor. Hinge axis remains local/world Z at neutral body orientation.

Both legs use the same motor direction. The right leg starts 180 degrees after the left leg.

Canonical phase acceptance:
- initial right-minus-left phase = 180 degrees +/- 1 degree;
- accepted redraw preserves current phase as closely as current runtime APIs permit;
- redraw must not reset both legs to launch phase.

## 4. Hub / axle geometry

Current hardcoded offsets in RacerRuntime must move to a single numeric owner in `PhysicsConfig.LegGeometry` (or a clearly named adjacent canonical geometry table consumed by RacerRuntime and tests).

Canonical starting values for R16 implementation:
- `HubOffsetX = 0.0`;
- `HubOffsetY = -0.35`;
- `HubOffsetZAbs = 1.62`;
- LeftHub = `(HubOffsetX, HubOffsetY, -HubOffsetZAbs)`;
- RightHub = `(HubOffsetX, HubOffsetY, +HubOffsetZAbs)`.

`-0.35` is an explicit project starting decision for reference parity, not a claim about the original game's hidden numeric value. It replaces the old hardcoded `-0.75` only after RED tests record the old contract.

Acceptance:
- hubs remain symmetric in Z;
- both hubs remain fixed relative to BodyCollider across redraw;
- hub location never depends on the submitted shape;
- a ROUND shape on flat does not cause BodyCollider to continuously scrape the track solely because of axle placement;
- canonical steps remain physically climbable by at least one legal shape.

## 5. Shape/pivot contract retained

R16 does not redesign GeometryMath.

Required invariants:
- normalized `(0,0)` maps to exact hub pivot;
- `MapPoint` remains isotropic in X/Y;
- no auto-centering by stroke bounds;
- no auto-spoke from hub to first stroke point;
- open strokes remain open;
- one ShapeSpec produces equivalent left/right XY segment plans;
- physical radius still depends on what the player drew.

If a new regression exposes a violation, fix only that violation inside the existing GeometryMath/LegAssembly ownership model.

## 6. Motor, grip, mass tuning order

Do not tune multiple physics families simultaneously. After upright body, plane lock, pivot and phase are mechanically correct, tune in this order only:

1. `Motor.AngularVelocity`;
2. `Motor.MotorMaxTorque` / `MotorMaxAcceleration` only if required;
3. leg segment friction/elasticity;
4. body friction/elasticity only if still required;
5. anti-stall only as the final bounded safety net, never as normal locomotion.

Starting targets for the canonical M0 lab:
- ROUND_01 on flat: sustained body speed approximately 4–7 studs/s after initial contact settles;
- motor remains enabled and does not normally stall on flat;
- a generic round shape must not automatically defeat the wall/steps/tunnel matrix;
- antiStallActive should remain false during healthy ROUND flat movement after startup.

These ranges are acceptance targets, not hidden reference numbers.

## 7. Reference shape behavior matrix

Use the existing canonical presets in doc 73 and route all presets through the normal authoritative geometry path.

Required qualitative matrix:
- `ROUND_01`: reliable/fast baseline on FlatShort;
- `HOOK_01` or `ASYM_01`: observably better than ROUND_01 on at least one SmallSteps/ledge condition;
- `LONG_BAR_01`: observably useful for reach/gap interaction but not universal on all obstacles;
- `SMALL_ROUND_01`: observably useful in low-clearance situations;
- `SUBOPTIMAL_01`: legal but measurably worse than a suitable shape on at least one canonical piece.

Hard rule: no single tested shape may be best or equally dominant on every canonical obstacle. If one shape trivially solves the whole lab, G0 reference parity fails and tuning must continue before external testers.

## 8. Redraw behavior

Existing atomic redraw architecture stays.

Acceptance for one accepted redraw while moving:
- ShapeVersion increments exactly once;
- exactly two current leg models exist after commit;
- old/staged/retiring physical leg models do not remain active;
- BodyCollider CFrame is not reset solely because of redraw;
- BodyCollider linear velocity is not zeroed solely because of redraw;
- both legs switch to the same new ShapeSpec in one protected transaction;
- current phase is preserved closely enough that redraw does not visibly restart the gait.

Stress acceptance: 10 accepted redraws during movement without runtime error, leaked leg assemblies, body teleport, or phase reset to canonical launch every time.

## 9. Camera / Studio G0 presentation

This change remains Studio-only until the later production RaceCamera owner is permitted.

Goal: present the reference core as a readable side race rather than the current strong three-quarter view.

Starting G0 presentation constants:
- camera lateral view direction primarily along world `-Z` toward the racer plane;
- camera position follows body at approximately `Vector3.new(-6, 5, 16)` relative to BodyCollider;
- look-ahead target approximately `Vector3.new(7, 1, 0)` relative to BodyCollider;
- camera may be tuned only inside the Studio presentation harness during R16.

Acceptance:
- body, both visible leg silhouettes, and upcoming obstacle are readable simultaneously;
- racer remains roughly in the left-to-middle portion of the viewport rather than centered with no look-ahead;
- camera never changes racer CFrame/velocity;
- the observer Roblox Character is not visible in the gameplay framing;
- debug proxy remains non-collidable/non-query/non-touch.

## 10. Existing canonical obstacle course is sufficient

Do not add a new gameplay course before parity is proven. Use the existing M0 pieces:
- FlatShort;
- SmallSteps;
- SingleWallLow;
- GapSmall;
- LowTunnelWide.

R16 may add Studio-only measurement helpers/markers but must not alter obstacle geometry merely to make the current physics pass. Any obstacle-geometry change requires its own evidence and Source-of-Truth update.

## 11. Files / owners to touch

Expected production/config files:
- `src/server/Runtime/RacerStabilizer.lua` — upright body orientation owner;
- `src/server/Runtime/RacerRuntime.lua` — consume canonical hub offsets; preserve existing runtime ownership;
- `src/server/Runtime/LegAssembly.lua` — only if phase/motor regression exposes a real issue;
- `src/shared/Config/PhysicsConfig.lua` — hub offsets and physics tuning numbers;
- `src/client/Dev/M0G0PresentationHarness.lua` — Studio-only side presentation;
- `src/server/Tests/M0HumanHarness.lua` — only to keep observer out of presentation if needed, not to alter racer physics.

Expected tests:
- `src/server/Tests/B06RacerRuntimeSpec.lua` — hub/runtime structural contract;
- `src/server/Tests/B07LegAssemblySpec.lua` — pivot/geometry invariants if needed;
- `src/server/Tests/B09TwoLegPhaseSpec.lua` — same XY + 180-degree phase + redraw phase retention;
- `src/server/Tests/B10StabilizationSpec.lua` — real upright body + real lateral impulse + no propulsion;
- `src/server/Tests/B13AtomicRedrawSpec.lua` / B14 stress — redraw parity;
- Python regression files under `tests/` mirroring each repaired owner;
- a new R16 consistency/regression file may be added instead of overloading unrelated old tests.

Expected owner/status docs after behavior is proven:
- `docs/03_CORE_MECHANICS_SPEC.md`;
- `docs/16_BALANCE_TUNING.md`;
- `docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`;
- `docs/SESSION.md`;
- `docs/FEATURE_LIST.md`;
- `docs/DECISION_LOG_R16_DRAW_CLIMBER_REFERENCE_PARITY_2026-09-10.md`.

Do not touch network contracts, StrokeMath, economy/meta, race services, DataStore, multiplayer services, or later milestone systems unless a failing regression proves a direct dependency.

## 12. Ordered implementation stages

### R16.1 — Upright Body

RED first:
- old B10 behavior allowing free world-Z body rotation must fail the new contract;
- add real angular impulse/disturbance test;
- assert body can still translate X/Y;
- assert stabilizer adds no intentional +X or +Y force.

GREEN:
- change orientation constraint configuration so all body axes are held upright while keeping PlaneConstraint for Z translation;
- no position teleports per frame.

Studio acceptance:
- cube stays visually upright under ROUND/HOOK/ASYM contact;
- legs rotate independently;
- cube can rise/fall in Y.

### R16.2 — Hub Calibration

RED first:
- tests require hub offsets from config rather than hardcoded literals;
- require `HubOffsetY=-0.35`, `HubOffsetZAbs=1.62` initially;
- verify symmetry and redraw stability.

GREEN:
- replace hardcoded hub offsets with canonical config consumption.

Studio acceptance:
- ROUND flat no chronic body scraping;
- at least one legal shape climbs canonical steps;
- hub visual relationship remains stable during redraw.

### R16.3 — Pivot / one stroke -> two legs

Prefer verification-only. Add regressions first. Change production only on demonstrated failure.

Acceptance:
- one accepted stroke = one ShapeSpec = exactly two same-XY legs;
- center marker = hub pivot;
- no mirror/recenter/spoke.

### R16.4 — Twin-leg phase

RED first:
- initial phase difference 180 +/-1 degree;
- same motor sign/direction;
- redraw retains pre-redraw phase relationship rather than resetting both to launch phase.

GREEN only if existing behavior fails.

### R16.5 — Motor / grip / mass

One parameter family per commit/experiment. Do not change obstacle geometry in this stage.

Acceptance targets are section 6 plus the shape matrix in section 7.

### R16.6 — Vertical physics

Regression must prove no normal-operation script directly drives Y position/velocity for locomotion.

Studio acceptance:
- steps raise body through physical contact;
- gap lowers body through gravity;
- R14.6 recovery only occurs after real Y fall.

### R16.7 — Reference shape matrix

Run fixed shapes against fixed canonical pieces and record outcomes. This is an empirical Studio gate, not merely a static test.

### R16.8 — Redraw parity

Run atomic/stress tests plus live moving redraws. Preserve body state and phase.

### R16.9 — G0 side presentation

Tune only the Studio presentation harness to the side-view contract in section 9.

### R16.10 — Canonical obstacle pass

Run the whole lab using multiple legal shapes. Do not alter course geometry to hide physics defects.

### R16.11 — Docs/evidence reconciliation

Only after R16.1–R16.10 implementation evidence is green and Studio observations are recorded:
- remove old body-tumble contract from docs;
- record actual chosen constants;
- keep B17/G0 HUMAN_GATE pending until the external protocol is completed.

## 13. Test discipline

Every behavior-changing stage follows RED -> minimal GREEN -> fresh full CI.

Automated baseline for every production stage:
- `python verify.py` = 0 failures;
- pinned Rokit install succeeds in CI;
- `rojo build default.project.json` succeeds.

Roblox solver claims require Studio evidence. CI cannot mark physics/human checkpoints PASS.

Do not mark R16 complete if any required Studio behavior is still unobserved.

## 14. R16 final technical acceptance

Before returning to B17 external testing, all of these must be true in one current-main Studio session or recorded current-main evidence set:

- StudioGate reaches `13 PASS / 0 FAIL` and `READY`;
- G0 human harness starts only after READY;
- no red DrawRacers runtime error;
- normal `laneDeviation <= 0.03`; unexplained excursion `>0.08` is FAIL;
- body is upright: normal angular deviation <=1 degree;
- strong contact may transiently reach <=3 degrees and returns <=1 degree within 0.25 s in the canonical test;
- X/Y body translation remains physical/free;
- no scripted Y locomotion;
- one accepted drawing creates exactly two same-XY legs;
- physical pivot equals DrawCanvas center `(0,0)`;
- right leg initial phase equals left +180 degrees +/-1 degree;
- redraw does not teleport/reset body and does not visibly restart gait;
- ROUND, HOOK/ASYM, LONG_BAR, SMALL_ROUND have observably different useful niches;
- no tested shape is universal-best across Flat/Steps/Wall/Gap/Tunnel;
- gap/recovery preserves accepted ShapeSpec/ShapeVersion;
- G0 camera is readable side-view with upcoming obstacle visibility;
- observer Roblox Character is absent from gameplay framing.

## 15. Hard stop

R16 completion does not itself pass B17/G0. After local technical reference parity, the empirical gate protocol still requires the project's external tester evidence. No C01/M0.5/multiplayer/meta work begins merely because R16 is technically green.
