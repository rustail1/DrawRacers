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

Canonical B10 acceptance:
- normal body angular deviation <= 1.0 degree;
- injected strong-contact disturbance may transiently reach <= 3.0 degrees;
- after injection, return to <= 1.0 degree within 0.25 s;
- the same test must show non-zero allowed X/Y displacement from physical impulses so upright correction is not an accidental position lock.

### 3.4 Leg rotation

Only the legs rotate for locomotion.

Each side keeps one Hub + one LegRoot + welded physical segments + one HingeConstraint motor. Hinge axis remains local/world Z at neutral body orientation.

Both legs use the same motor direction. The right leg starts 180 degrees after the left leg.

Canonical phase acceptance:
- initial right-minus-left phase = 180 degrees +/- 1 degree;
- immediately before an accepted redraw, capture each leg phase relative to its own hub;
- immediately after the atomic redraw, each new leg phase must be within 5 degrees of that side's captured pre-redraw phase (modulo 360);
- repeated redraw must not reset either leg to canonical launch phase unless the racer itself was newly created.

## 4. Hub / axle geometry

`PhysicsConfig.LegGeometry` is the single numeric owner for hub offsets. RacerRuntime consumes these values and must not retain duplicate hub-position literals.

Canonical starting values for R16 implementation:
- `HubOffsetX = 0.0`;
- `HubOffsetY = -0.35`;
- `HubOffsetZAbs = 1.62`;
- LeftHub = `(HubOffsetX, HubOffsetY, -HubOffsetZAbs)`;
- RightHub = `(HubOffsetX, HubOffsetY, +HubOffsetZAbs)`.

`-0.35` is an explicit project starting decision for reference parity, not a claim about the original game's hidden numeric value. It replaces the old hardcoded `-0.75` only after RED tests record the old contract. Any later change to `HubOffsetY` requires Studio evidence from the fixed test protocol below and a separate config/test commit; it may not be silently hand-tuned.

Hub calibration Studio protocol:
- use ROUND_01 on FlatShort for 8 seconds after first accepted contact;
- then use HOOK_01 or ASYM_01 on SmallSteps for 10 seconds from first step contact;
- body must not continuously scrape the flat solely because of axle placement;
- at least one of HOOK_01/ASYM_01 must gain >= 8 studs of +X progress through/over the SmallSteps segment within the 10-second window;
- hubs remain symmetric in Z and fixed relative to BodyCollider before/after redraw.

If `HubOffsetY=-0.35` fails this protocol while all other R16.1 mechanics are correct, only then may the next experiment compare `-0.75`, `-0.35`, and `0.0`; the selected value becomes canonical in section 11 docs before motor tuning continues.

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

Do not tune multiple physics families simultaneously. After upright body, plane lock, pivot, hub and phase are mechanically correct and the Stage-A Studio gate passes, tune in this order only:

1. `Motor.AngularVelocity`;
2. `Motor.MotorMaxTorque` / `MotorMaxAcceleration` only if required;
3. leg segment friction/elasticity;
4. body friction/elasticity only if still required;
5. anti-stall only as the final bounded safety net, never as normal locomotion.

Canonical FlatShort speed protocol:
- use ROUND_01;
- ignore the first 2.0 s after stable track contact;
- measure average +X body speed over the next 3.0 s;
- target average = 4.0–7.0 studs/s;
- `antiStallActive` must remain false for the measured 3.0-second window;
- motor must remain enabled.

The canonical wall/steps/tunnel matrix must also prevent ROUND_01 from trivially dominating every obstacle. These ranges are project acceptance targets, not hidden reference numbers.

## 7. Reference shape behavior matrix

Use the existing canonical presets in doc 73 and route all presets through the normal authoritative geometry path. Each comparison starts from the same canonical spawn/checkpoint, zeroed body linear/angular velocity, the same current physics config, and no hidden obstacle changes.

Required measurable matrix:
- `ROUND_01` FlatShort: meets the 4.0–7.0 studs/s protocol in section 6;
- `HOOK_01` or `ASYM_01` SmallSteps: within 10 s from first step contact, achieves at least 4 studs more +X progress than ROUND_01 under the same reset conditions, OR reaches at least one higher canonical step when ROUND_01 is blocked; either condition is sufficient and must be recorded;
- `LONG_BAR_01` GapSmall/reach: must produce a distinct reach interaction, recorded as either successful far-edge contact/landing where SMALL_ROUND_01 fails, or >= 2 studs more +X progress across the gap attempt within 6 s; if neither occurs, LONG_BAR has no validated niche and R16 fails;
- `SMALL_ROUND_01` LowTunnelWide: must complete the tunnel or achieve >= 6 studs more +X progress within the tunnel than LONG_BAR_01 under the same 8-second window;
- `SUBOPTIMAL_01`: on at least one of FlatShort or SmallSteps, must be >= 20% worse in measured +X progress/speed than the best suitable tested shape for that piece.

Hard rule: no single tested shape may win or tie every measured canonical piece. If one shape trivially solves the whole lab, R16 reference parity fails and tuning must continue before external testers.

## 8. Redraw behavior

Existing atomic redraw architecture stays.

Acceptance for one accepted redraw while moving:
- ShapeVersion increments exactly once;
- exactly two current leg models exist after commit;
- old/staged/retiring physical leg models do not remain active;
- BodyCollider CFrame is not reset solely because of redraw;
- BodyCollider linear velocity is not zeroed solely because of redraw;
- both legs switch to the same new ShapeSpec in one protected transaction;
- each side's post-redraw phase is within 5 degrees of its captured pre-redraw phase modulo 360.

Stress acceptance: 10 accepted redraws during movement without runtime error, leaked leg assemblies, body teleport, velocity reset, or repeated phase reset to launch.

## 9. Camera / Studio G0 presentation

This change remains Studio-only until the later production RaceCamera owner is permitted.

Goal: present the reference core as a readable side race rather than the current strong three-quarter view.

Exact starting G0 presentation constants for the first R16.9 implementation:
- `CAMERA_OFFSET = Vector3.new(-6, 5, 16)`;
- `CAMERA_LOOK_AHEAD = Vector3.new(7, 1, 0)`;
- camera remains Scriptable and follows only the current DebugTarget body;
- the camera does not alter body physics.

These are starting project constants, not claimed reference internals. Any later camera tuning is limited to the Studio-only harness and must retain the acceptance below.

Acceptance:
- body and upcoming obstacle are simultaneously visible through Flat/Steps/Wall;
- at least one complete leg silhouette is readable at all times on the side-facing camera; depth-separated second leg may overlap visually because the race is 2.5D;
- racer center remains between 25% and 50% of viewport width during normal follow, leaving forward look-ahead space;
- camera never changes racer CFrame/velocity;
- observer Roblox Character is not visible in gameplay framing;
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
- `src/shared/Config/PhysicsConfig.lua` — single numeric owner for hub offsets and physics tuning numbers;
- `src/client/Dev/M0G0PresentationHarness.lua` — Studio-only side presentation;
- `src/server/Tests/M0HumanHarness.lua` — only to keep observer out of presentation if needed, not to alter racer physics.

Expected tests:
- `src/server/Tests/B06RacerRuntimeSpec.lua` — hub/runtime structural contract;
- `src/server/Tests/B07LegAssemblySpec.lua` — pivot/geometry invariants if needed;
- `src/server/Tests/B09TwoLegPhaseSpec.lua` — same XY + 180-degree phase + redraw phase retention;
- `src/server/Tests/B10StabilizationSpec.lua` — real upright body + real lateral impulse + no propulsion/lift;
- `src/server/Tests/B13AtomicRedrawSpec.lua` / B14 stress — redraw parity;
- Python regression files under `tests/` mirroring each repaired owner;
- one dedicated R16 regression file may aggregate cross-owner static contracts, but it must not replace the Studio physics specs.

Owner/status docs after behavior is proven:
- `docs/03_CORE_MECHANICS_SPEC.md`;
- `docs/16_BALANCE_TUNING.md`;
- `docs/73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`;
- `docs/SESSION.md`;
- `docs/FEATURE_LIST.md`;
- `docs/DECISION_LOG_R16_DRAW_CLIMBER_REFERENCE_PARITY_2026-09-10.md`.

Do not touch network contracts, StrokeMath, economy/meta, race services, DataStore, multiplayer services, or later milestone systems unless a failing regression proves a direct dependency.

## 12. Ordered implementation stages and mandatory gates

### Stage A — mechanical parity: R16.1–R16.4

#### R16.1 — Upright Body

RED first:
- old B10 behavior allowing free world-Z body rotation must fail the new contract;
- add real angular disturbance test using the section 3.3 timing/tolerance;
- assert body can still translate X/Y;
- assert stabilizer adds no intentional +X or +Y force/lift.

GREEN:
- change orientation constraint configuration so all body axes are held upright while keeping PlaneConstraint for Z translation;
- no position teleports per frame.

#### R16.2 — Hub Calibration implementation

RED first:
- tests require hub offsets from `PhysicsConfig.LegGeometry`, not RacerRuntime literals;
- require starting `HubOffsetY=-0.35`, `HubOffsetZAbs=1.62`;
- verify symmetry and redraw stability.

GREEN:
- replace hardcoded hub offsets with canonical config consumption.

#### R16.3 — Pivot / one stroke -> two legs

Prefer verification-only. Add regressions first. Change production only on demonstrated failure.

Acceptance:
- one accepted stroke = one ShapeSpec = exactly two same-XY legs;
- center marker = hub pivot;
- no mirror/recenter/spoke.

#### R16.4 — Twin-leg phase

RED first:
- initial phase difference 180 +/-1 degree;
- same motor sign/direction;
- each side's redraw phase delta <=5 degrees modulo 360.

GREEN only if existing behavior fails.

### Mandatory Studio Gate A

Do not begin R16.5 tuning until current-main Studio evidence shows:
- StudioGate `13 PASS / 0 FAIL`, READY;
- laneDeviation normal <=0.03 and no unexplained >0.08;
- body upright tolerance from section 3.3;
- body still rises/falls in Y from physics;
- hub protocol in section 4 executed;
- one stroke visibly produces two matching physical legs;
- right/left phase behavior is visually consistent with the recorded 180-degree contract.

If HubOffsetY=-0.35 fails only the hub calibration while mechanical parity passes, run the explicit three-value hub experiment from section 4 before proceeding.

### Stage B — feel parity: R16.5–R16.7

#### R16.5 — Motor / grip / mass

One parameter family per RED/experiment/GREEN commit. Do not change obstacle geometry in this stage. Use section 6 protocol.

#### R16.6 — Vertical physics

Regression must prove no normal-operation script directly drives Y position/velocity for locomotion.

Studio acceptance:
- steps raise body through physical contact;
- gap lowers body through gravity;
- R14.6 recovery only occurs after real Y fall.

#### R16.7 — Reference shape matrix

Run and record the exact measurable matrix from section 7.

### Mandatory Studio Gate B

Do not begin presentation/final integration until all section 7 niches are evidenced and no universal tested shape exists.

### Stage C — integration/presentation: R16.8–R16.10

#### R16.8 — Redraw parity

Run atomic/stress tests plus live moving redraws using section 8 tolerances.

#### R16.9 — G0 side presentation

Apply the exact starting constants from section 9, then tune only if acceptance requires it.

#### R16.10 — Canonical obstacle pass

Run the whole unchanged lab using multiple legal shapes. Do not alter course geometry to hide physics defects.

### Mandatory Studio Gate C

One current-main session/evidence set must satisfy section 14 before docs are frozen.

### R16.11 — Docs/evidence reconciliation

Only after Gates A, B and C pass:
- remove old body-tumble contract from docs;
- record actual selected hub/motor/grip/camera constants;
- record RED/GREEN/CI and Studio evidence;
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
- body normal angular deviation <=1.0 degree;
- injected strong-contact test peak <=3.0 degrees and returns <=1.0 degree within 0.25 s;
- X/Y body translation remains physical/free;
- no scripted Y locomotion;
- one accepted drawing creates exactly two same-XY legs;
- physical pivot equals DrawCanvas center `(0,0)`;
- right leg initial phase equals left +180 degrees +/-1 degree;
- each side's accepted-redraw phase delta <=5 degrees modulo 360;
- ROUND FlatShort average speed over the fixed measurement window is 4.0–7.0 studs/s with antiStallActive false;
- HOOK/ASYM, LONG_BAR and SMALL_ROUND each satisfy at least one exact niche criterion from section 7;
- SUBOPTIMAL satisfies its >=20% worse criterion;
- no tested shape wins/ties every canonical piece;
- 10 moving redraws pass section 8 without teleport/reset/leak;
- gap/recovery preserves accepted ShapeSpec/ShapeVersion;
- G0 camera satisfies viewport/readability criteria from section 9;
- observer Roblox Character is absent from gameplay framing.

## 15. Hard stop

R16 completion does not itself pass B17/G0. After local technical reference parity, the empirical gate protocol still requires the project's external tester evidence. No C01/M0.5/multiplayer/meta work begins merely because R16 is technically green.
