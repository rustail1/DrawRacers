# DrawRacers Core V3 Flat Physics Design

Status: **CURRENT DESIGN**

## Goal
Produce the smallest reliable Roblox mechanical core where one drawn shape becomes two opposed side legs on one shared axle and physically drives the racer forward on a flat lane.

## Architecture

```text
DrawingController
-> StrokeRemoteTransport
-> LegShapeService
-> CanonicalLegShape / GeometryMath
-> RacerRuntime
-> LegCoreController
   -> SharedAxle (1 HingeConstraint)
   -> Left LegGeometry (-Z)
   -> Right LegGeometry (+Z, 180°)
   -> LegClearanceController
```

The body remains physically simulated in X/Y. Z is lane-constrained and body orientation is stabilized by a dedicated Core V3 2.5D owner. No normal +X helper exists.

## Mechanical invariants
- one axle;
- one hinge;
- one motor owner;
- physical hinge never disabled;
- left/right use the same ShapeSpec;
- fixed 180° structural relation;
- pair is fully ghost or fully active;
- only leg/Track friction creates forward locomotion;
- body/Track friction is not the traction source;
- visual geometry is presentation-only;
- no legacy twin-drive or phase chase.

## Redraw
`ACTIVE -> PREVIEW -> WAIT_CLEAR -> ACTIVE`, fail-closed to `EMPTY`.

Commit accepted shape/version only after true ACTIVE. Failure clears invalid accepted presentation. Pending state must be exception-safe.

## Flat validation
Automated: C01–C07.
Human: ROUND, SMALL_ROUND, LONG, HOOK, ASYMMETRIC, then 20 moving redraws.

Obstacles and recovery remain out of the validation path until Flat Gate PASS.

## 2.5D lane decision
Approved next owner:
- Z-plane constraint;
- upright torque stabilization;
- X/Y translation untouched;
- no forward/vertical helper force.
