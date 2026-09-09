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

## Trigger evidence
The pre-R15 Studio G0 session reached:
- `[DrawRacers][StudioGate] TOTAL 13 PASS / 0 FAIL`;
- `[DrawRacers][StudioGate] READY`;
- `[DrawRacers][G0] human harness ready`.

Despite the clean gate, normal play visibly allowed the racer to drift toward the side of the track. Debug telemetry showed `laneDeviation 0.418`, already above the old `0.35` normal lane-error allowance. The racer could then fall from a Z-side edge and only later trigger the existing R14.6 Y kill-plane recovery.

Root cause: the old stabilizer deliberately implemented a soft lane corridor (`LaneCorrectionDeadzone = 0.15`, `LaneNormalError = 0.35`, `LaneHardBound = 0.75`) and a full-orientation correction that remained disabled inside a 25-degree free-tilt envelope. That allowed lateral displacement and out-of-plane rotation which are not intended player verbs.

## Owner and implementation
`RacerStabilizer` remains the sole owner. No new movement service/controller was introduced.

Implementation:
- always-on world-space Z-only `AlignPosition`;
- `MaxAxesForce.X = 0` and `MaxAxesForce.Y = 0` so the planar lock does not own forward/vertical locomotion;
- `AlignOrientation` in `OneAttachment` mode with `AlignType = PrimaryAxisParallel`;
- attachment/constraint primary axis = world/local Z plane normal;
- in-plane rotation around world Z remains free;
- out-of-plane X/Y rotation is corrected;
- no intentional +X propulsion and no normal-operation hard snap.

Canonical starting values:
- `LaneNormalError = 0.03`
- `LaneHardBound = 0.08`
- `LaneMaxForceZ = 60000`
- `LaneResponsiveness = 40`
- `LaneMaxVelocity = 30`
- `OrientationResponsiveness = 40`
- `OrientationMaxTorque = 60000`
- `OrientationMaxAngularVelocity = 30`

`0.03` and `0.08` are diagnostic solver tolerances, not permitted lateral gameplay freedom.

## TDD / automated evidence
- R15 RED after all existing stabilization test owners were retargeted: commit `df95b11c4593f48ccda39c5cfe40f1ee90d6b265`, GitHub Actions run `34392903238` → **120 passed, 4 failed**. Failures were the intended old soft-lane/config mismatches.
- R15 production GREEN: commit `f0e943b5d6e8c48c2eb144cec43d2e5531dbcc48`, GitHub Actions run `34393130544` → **124 passed, 0 failed**, Rokit install PASS, Rojo build PASS.
- R15 docs reconciliation RED: commit `b90e020e23f6d8a19acbc0ba46e343bb0cd19fe8`, GitHub Actions run `34393250062` → **124 passed, 1 failed**, with the only failure proving owner/status docs still described the pre-R15 contract.

## Human acceptance still required
R15 runtime acceptance remains a Roblox Studio human gate. Required evidence includes:
- B03–B16 Studio runner remains `13 PASS / 0 FAIL` and reaches `READY`;
- normal `laneDeviation` stays <= `0.03` during representative legal shapes;
- deliberate asymmetric/lateral contact does not allow a visible Z-side escape; any unexplained excursion above `0.08` is FAIL evidence;
- in-plane rotation/tumble around world Z remains physical;
- out-of-plane X/Y rotation is suppressed;
- actual gap/fall behavior still reaches R14.6 Y recovery and preserves the accepted ShapeSpec/ShapeVersion.

## Status
**R15 IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING.**

**B17/G0: PENDING.**

R15 does not satisfy the separate empirical G0 requirement for six unique external testers.
