# R15 Planar Racer Physics Design

Date: 2026-09-10
Status: USER-APPROVED DIRECTION; WRITTEN SPEC REVIEW PENDING
Owner: Product Owner / engineering handoff

## Goal
Make DrawRacers locomotion intentionally 2.5D: the racer remains physically free in the forward/vertical gameplay plane while lateral drift and out-of-plane rotation are removed from gameplay.

The product rule is:
- X translation = physical/free (forward/backward);
- Y translation = physical/free (up/down/jump/fall);
- Z translation = locked to the racer's lane center;
- rotation around world Z = physical/free (the racer may pitch/tumble in the gameplay side-view plane);
- rotation around world X/Y = constrained so the racer cannot turn sideways out of the gameplay plane.

This preserves shape-driven physics while removing accidental Roblox lateral drift as a failure source.

## Why this is the correct product behavior
The player's meaningful input is the drawn leg/wheel shape, not steering. Obstacles should test the consequences of that shape in the X/Y plane. A racer falling from the side of its lane because contact forces accumulated along Z is not an intended skill test and weakens the causal loop `draw shape -> physical result`.

The implementation therefore treats each race lane as a physical 2.5D plane, not a soft corridor with meaningful lateral freedom.

## Scope
R15 changes only the existing racer stabilization contract and its tests/docs. It does not add steering, invisible side walls, a new movement controller, a new physics system, production checkpoint logic, camera behavior, drawing logic, leg geometry, motor semantics, obstacle geometry, or race progression.

Existing owner remains `RacerStabilizer`. No new broad service/controller is introduced.

## R15.1 — Continuous planar position lock
`RacerStabilizer` keeps the existing lane center as the authoritative Z plane.

The current deadzone-based behavior is replaced by continuous Z-only correction. The normal constraint is active continuously rather than waiting for a gameplay-sized lateral error.

Design requirements:
- no intentional force/velocity is added on X;
- no intentional force/velocity is added on Y;
- normal operation keeps `abs(body.Position.Z - laneCenterZ)` within a very small solver tolerance;
- the old `0.15 / 0.35 / 0.75` lateral values are no longer interpreted as permitted gameplay movement;
- no invisible Track/Default wall geometry is used to contain the racer.

Implementation approach:
- keep the existing `AlignPosition` ownership in `RacerStabilizer`;
- configure it as an always-enabled world-space Z-only servo (`MaxAxesForce.X = 0`, `MaxAxesForce.Y = 0`);
- remove the lane correction deadzone from enable/disable behavior;
- use the exact initial planar defaults in R15.3;
- retain a small hard safety bound only as diagnostic/failsafe protection against solver explosions, not as normal allowed lateral travel.

A hard safety projection/snap is permitted only if Studio evidence shows that the Roblox solver can exceed the hard bound under an injected extreme lateral impulse despite the continuous constraint. It must operate on the whole racer assembly, preserve X/Y position, preserve in-plane Z-axis rotation, preserve the current ShapeSpec/ShapeVersion, zero only lateral velocity as needed, and must not run every frame during normal motion.

## R15.2 — Planar orientation lock
The current full-orientation correction is replaced with an orientation constraint whose target is only the plane normal.

Required behavior:
- the racer's local gameplay-plane normal remains aligned with world Z;
- yaw/roll components that point the racer out of the X/Y plane are suppressed;
- rotation around world Z remains free and physical;
- collisions may still make the racer lean, tumble, flip, and recover inside the X/Y side-view plane;
- the stabilizer must not force the cube upright merely because it rotated around Z.

Implementation approach:
- use the existing `OrientationAttachment` owned by `RacerStabilizer`;
- explicitly orient its primary axis to represent the racer's plane normal;
- configure `AlignOrientation` for primary-axis-only alignment to canonical world Z;
- remove the current all-Euler `OrientationFreeTiltDegrees` gating because out-of-plane freedom is no longer a gameplay feature;
- keep the planar orientation constraint continuously enabled;
- preserve free rotation around the aligned normal.

Exact Roblox attachment/CFrame axis semantics must be covered by the Studio B10 regression before the change is accepted.

## R15.3 — Exact initial physics defaults
`PhysicsConfig.Stabilization` moves from soft-lane values to these exact R15 starting defaults:

- `LaneCorrectionDeadzone = 0.0` (kept only if compatibility requires the key; it must not disable the constraint);
- `LaneNormalError = 0.03` stud;
- `LaneHardBound = 0.08` stud;
- `LaneMaxForceZ = 60000`;
- `LaneResponsiveness = 40`;
- `LaneMaxVelocity = 30`;
- `OrientationResponsiveness = 40`;
- `OrientationMaxTorque = 60000`;
- `OrientationMaxAngularVelocity = 30`;
- `OrientationFreeTiltDegrees` is removed from runtime semantics; remove the key if no compatibility test requires it.

These are starting defaults, not hidden target values. They may be tuned only if Studio evidence shows solver instability or visible drift. Any tuning must preserve the product invariants: Z is not gameplay movement, rotation around world Z remains free, and the stabilizer adds no intentional X propulsion.

Acceptance target in ordinary G0 play is `laneDeviation <= 0.03` stud. Any deviation above `0.08` stud is a hard FAIL unless it occurs only in the explicit artificial stress injection and immediately recovers without side escape.

## R15.4 — B10 and regression coverage
B10 becomes the executable owner of the planar stabilization contract.

Required automated/static checks:
- lane constraint is continuously enabled;
- position actuator has zero X/Y authority and Z-only authority;
- target Z remains exactly `laneCenterZ`;
- orientation constraint is continuously enabled and primary-axis-only / plane-normal-only;
- in-plane world-Z rotation is not intentionally corrected;
- no code path adds intentional +X movement;
- `LaneNormalBoundExceeded` / `LaneHardBoundExceeded`, if retained, describe diagnostic solver deviation rather than permitted player motion;
- config matches the exact R15 initial defaults unless a later evidence-backed tuning record changes them.

Required Studio checks:
1. spawn an unanchored racer on the canonical flat surface;
2. apply a strong artificial lateral Z impulse/velocity;
3. verify the racer remains/recenters within the planar tolerance and does not leave the lane plane;
4. apply/induce out-of-plane angular disturbance and verify it is suppressed;
5. induce normal in-plane tumble around world Z and verify it remains physical/free;
6. verify the motor/legs still produce forward movement through Track collision and the stabilizer itself adds no forward propulsion.

## R15.5 — G0 human acceptance
After automated GREEN, the existing G0 harness is used without adding a new presentation or race system.

Human Studio acceptance:
- `StudioGate TOTAL 13 PASS / 0 FAIL` remains true;
- draw multiple legal shapes and redraw repeatedly;
- racer moves forward/backward from real leg/Track contacts;
- racer jumps/falls vertically and can tumble in the side-view plane;
- racer never visibly drives or falls off the track through the left/right Z edges;
- debug `laneDeviation` stays <= 0.03 stud during ordinary play;
- any `laneDeviation > 0.08` stud is FAIL unless it belongs to the explicit injected lateral stress and immediately recovers;
- deliberate gap/fall still triggers R14.6 recovery because Y fell below the recovery threshold, not because the racer escaped sideways;
- accepted ShapeSpec/ShapeVersion survives recovery as already required by R14.6.

This G0 check is a human gate. CI cannot mark it PASS.

## Documentation reconciliation
The following product/technical docs are updated in the implementation only after the new contract is tested:
- `docs/03_CORE_MECHANICS_SPEC.md`: state explicitly that locomotion is planar and lateral steering/drift is not gameplay;
- `docs/16_BALANCE_TUNING.md`: replace `Z stays near lane center` / soft-lane allowances with hard planar-lock semantics and the exact R15 defaults;
- status/decision evidence docs: record R15 and keep B17/G0 PENDING until human acceptance is complete.

If another architecture document repeats the old soft-lane semantics, the implementation plan must include that file in the reconciliation rather than leaving a contradiction.

## Files expected to change
Primary production scope:
- `src/server/Runtime/RacerStabilizer.lua`
- `src/shared/Config/PhysicsConfig.lua`

Primary test scope:
- `src/server/Tests/B10StabilizationSpec.lua`
- a focused Python/static R15 regression test under `tests/`

Documentation scope:
- `docs/03_CORE_MECHANICS_SPEC.md`
- `docs/16_BALANCE_TUNING.md`
- R15 decision/status evidence files as required by the existing project workflow

`RacerRuntime.lua` may change only if the existing `OrientationAttachment` needs explicit canonical axis setup that cannot be owned entirely inside `RacerStabilizer`. No unrelated RacerRuntime refactor is allowed.

## Non-goals
- no player steering input;
- no side-wall collision geometry;
- no teleport-to-lane every Heartbeat as the normal solution;
- no changes to DrawingController/StrokeMath/GeometryMath/LegShapeService/LegAssembly shape construction;
- no motor direction/torque redesign unless R15 testing proves an independent pre-existing motor defect;
- no camera changes;
- no production checkpoint/recovery service;
- no new movement/God controller;
- no automatic B17/G0 PASS.

## TDD and verification policy
Implementation uses RED -> verify RED -> minimal GREEN -> fresh full GREEN.

Minimum evidence before claiming R15 code complete:
- focused R15 regression RED observed before production change;
- `python verify.py` GREEN;
- pinned Rokit/Rojo build GREEN in CI;
- B10 Studio spec GREEN;
- human G0 planar physics check completed by the user.

Until the final Studio check is supplied, status is `IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING`, never G0 PASS.
