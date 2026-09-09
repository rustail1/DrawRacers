# DECISION LOG — R15 PLANAR RACER PHYSICS — 2026-09-10

## Decision
Use **hard 2.5D planar racer physics** for DrawRacers.

Product contract:
- X translation = physical/free forward/backward movement;
- Y translation = physical/free jump/fall movement;
- Z translation = locked to the racer's canonical lane center;
- rotation around world Z = physical/free in-plane tumble;
- out-of-plane rotation around world X/Y = constrained.

Player steering, invisible side walls, and normal-operation per-Heartbeat teleport are not part of this solution.

## Original R15 trigger
The pre-R15 Studio G0 session reached:
- `[DrawRacers][StudioGate] TOTAL 13 PASS / 0 FAIL`;
- `[DrawRacers][StudioGate] READY`;
- `[DrawRacers][G0] human harness ready`.

Despite that clean gate, normal play showed visible side drift. The first captured debug evidence included `laneDeviation 0.418`, above the old `0.35` normal lane-error allowance. That proved the original soft lane corridor (`LaneCorrectionDeadzone = 0.15`, `LaneNormalError = 0.35`, `LaneHardBound = 0.75`) did not match the intended no-steering product contract.

## Original R15 implementation and evidence
R15 initially replaced the soft corridor with an always-on Z-only `AlignPosition` and `PrimaryAxisParallel` orientation correction. This removed deadzones/free-tilt semantics and reduced the diagnostic bounds to `LaneNormalError = 0.03` / `LaneHardBound = 0.08`.

Automated evidence for that first implementation:
- complete test-owner RED commit `df95b11c4593f48ccda39c5cfe40f1ee90d6b265`, run `34392903238` → **120 passed, 4 failed**;
- production GREEN commit `f0e943b5d6e8c48c2eb144cec43d2e5531dbcc48`, run `34393130544` → **124 passed, 0 failed**, Rokit PASS, Rojo build PASS;
- docs RED commit `b90e020e23f6d8a19acbc0ba46e343bb0cd19fe8`, run `34393250062` → **124 passed, 1 failed**.

The first R15 implementation was **not** accepted by the Studio human gate.

## R15.1 Studio failure evidence
A fresh real Studio G0 session again reached:
- `[DrawRacers][B10] stabilization/lane tests PASS`;
- `[DrawRacers][StudioGate] TOTAL 13 PASS / 0 FAIL`;
- `[DrawRacers][StudioGate] READY`;
- `[DrawRacers][G0] human harness ready`;
- three server-accepted strokes with `ShapeVersion = 3` and motors enabled.

During that same session the debug panel showed **`laneDeviation 5.199`** and the racer was visibly able to travel sideways. This is far beyond `LaneHardBound = 0.08`, so the human R15 Studio checkpoint is an explicit FAIL, not a PASS.

The red-looking B12/B13 lines in that session were expected injected failure-path tests: each owning B12/B13 spec completed PASS. They are not the cause of the lateral escape.

## R15.1 root cause
The hard product invariant had been implemented using the wrong mechanism. `AlignPosition` is a finite-force mover/follower; even with high Z-only force, real leg/contact impulses can overpower it. It therefore cannot be treated as an exact gameplay-plane constraint.

The previous B10 also had an evidence blind spot: it anchored the body and mainly inspected constraint properties. It verified configuration shape, not real lateral solver behavior, so it could report PASS while the interactive racer escaped by several studs.

## R15.1 implementation
`RacerStabilizer` remains the sole owner; no new movement service/controller was introduced.

The bounded repair replaces force-following lane correction with a mechanical `PlaneConstraint`:
- an invisible anchored `LanePlaneReference` is created at the canonical lane-center Z;
- it is non-collidable, non-touchable and non-queryable;
- `PlaneConstraint` joins the reference attachment to the body lane attachment and stays enabled;
- X/Y translation remains physical/free;
- rotation around world Z remains physical/free;
- `PrimaryAxisParallel` `AlignOrientation` still suppresses out-of-plane X/Y rotation;
- no `AlignPosition`, no lane-force tuning, no side walls, no intentional +X propulsion, and no normal-operation CFrame/PivotTo correction.

Canonical diagnostics remain:
- `LaneNormalError = 0.03`
- `LaneHardBound = 0.08`
- `OrientationResponsiveness = 40`
- `OrientationMaxTorque = 60000`
- `OrientationMaxAngularVelocity = 30`

The removed `LaneMaxForceZ`, `LaneResponsiveness`, and `LaneMaxVelocity` values belonged only to the failed force-following implementation and are no longer contract owners.

## R15.1 regression coverage
B10 now includes real physics evidence instead of property checks only. It unanchors the racer body, applies a large lateral impulse, samples several Heartbeats, and requires `maxObservedLaneDeviation <= LaneHardBound`. This specifically covers the class of failure observed in the human Studio session.

TDD evidence:
- R15.1 RED commit `8574b918988b8e26551140f2e0d3005caded8fe8`, GitHub Actions run `34394769781` → **123 passed, 2 failed**. Both failures were the intended missing mechanical-plane / real-lateral-impulse contracts.
- R15.1 production GREEN head `be44304bf00391e05c7d7750609730a7368ebc87`, GitHub Actions run `34394991926` → **125 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**.
- R15.1 docs-evidence RED commit `a77338bdc40644cfc1e74d104c7c46d025f05c99`, run `34395165597` → **124 passed, 1 failed**, with the single failure proving Source of Truth still described the failed AlignPosition version.

## Human acceptance still required
R15.1 runtime acceptance remains a Roblox Studio human gate. Required evidence:
- B03–B16 Studio runner remains `13 PASS / 0 FAIL` and reaches `READY`;
- B10's new live lateral-impulse regression PASSes in Studio;
- normal `laneDeviation` stays <= `0.03` during representative legal shapes;
- deliberate asymmetric/lateral contacts do not allow a visible Z-side escape; any unexplained excursion above `0.08` is FAIL evidence;
- in-plane rotation/tumble around world Z remains physical;
- out-of-plane X/Y rotation is suppressed;
- an actual track gap still causes a Y fall and R14.6 recovery while preserving accepted ShapeSpec/ShapeVersion.

## Status
**R15.1 IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING.**

**B17/G0: PENDING.**

R15.1 does not satisfy the separate empirical G0 requirement for six unique external testers.
