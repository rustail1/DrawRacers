# DECISION LOG — CORE V3 2.5D LANE / UPRIGHT CONTRACT — 2026-09-15

Status: **APPROVED CONTRACT / IMPLEMENTATION + HUMAN PHYSICS PENDING**

## Observation
Current Core V3 permits the full racer assembly to drift/tip in 3D. In the target side-view game this creates failure states unrelated to the drawing decision: the cube can fall left/right in depth and the player is effectively asked to control 3D balance even though the intended gameplay is 2.5D.

## Decision
The racer is a physical 2.5D body:
- X translation remains free;
- Y translation remains free;
- Z translation is mechanically constrained to the lane plane;
- body orientation is stabilized upright;
- shared axle rotation remains free through the one Core V3 HingeConstraint.

Use a dedicated Core V3 owner. Preferred implementation is a `PlaneConstraint` for lane-plane confinement plus a bounded torque-only orientation constraint (`AlignOrientation` or equivalent). Do not use a position mover to push the racer forward.

## Non-goals
This decision does not authorize:
- +X movement assistance;
- AntiStall forward propulsion;
- obstacle recovery;
- motor/torque/mass retuning;
- a second hinge/motor;
- a return to CR2/CR3/R17 legacy locomotion modules.

## Acceptance
The body must remain centered in its lane and readable/upright while:
- legs still contact Track naturally;
- the body can rise/fall/bounce in Y;
- forward X movement still comes only from leg/Track reaction;
- C01–C07 remain green;
- human ROUND test proves locomotion without helper forces.
