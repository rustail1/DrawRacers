# R17 Shared Axle + Camera Fidelity Decision — 2026-09-11

Status: **APPROVED PRODUCT OWNER CONTRACT CHANGE / HUMAN STUDIO PENDING**

## Evidence that triggered the change

Product Owner supplied a current DrawRacers gameplay video and a Draw Climber reference video. In the current build, each drawn side is individually rigid, but the two sides are driven by independent HingeConstraint motors and a runtime phase-correction controller. Under unequal contact load one side can lag while the other is accelerated, producing a visible relative-angle drift / apparent bending effect. The production camera also intentionally clamps RMB yaw to +/-40 degrees and applies pointer delta directly to the rendered orbit target without a separate smoothed rendered angle.

## Canonical R17.9 camera contract

- Hold RMB owns world camera input only outside DrawInputRect / active UI / focused text input.
- Horizontal yaw is **360-degree / continuous**: there is no +/-40 degree yaw wall.
- Pitch remains bounded to prevent upside-down inversion.
- Pointer/touch input changes target yaw/pitch; rendered yaw/pitch follow with frame-rate-independent damping.
- Releasing RMB returns smoothly to the canonical side-race framing.
- Camera remains client-only, follows Local Racer position rather than BodyCollider rotation, and sends no gameplay remote.

## Canonical R17.10-R17.14 leg drive contract

The previous twin independent motor + phase-recovery design is superseded for production locomotion.

Production now uses one **shared axle**, **one hinge**, and **one motor** for the pair of drawn sides:

```text
BodyCollider
  -> shared AxleJoint (one Motor)
      -> shared AxleRoot
          -> Left rigid side geometry at 0 degrees
          -> Right rigid side geometry at exactly 180 degrees
```

Consequences:

- both sides consume the same authoritative ShapeSpec;
- each side is a rigid geometry assembly welded to the shared axle root;
- relative phase is structural, not recovered by software;
- right-minus-left phase is exactly the configured `RightPhaseOffsetDegrees = 180` by construction;
- there is no per-side AngularVelocity correction, phase-sync Heartbeat owner, or independent side motor;
- accepted redraw stages a complete replacement LegPair off-world, copies the single live axle phase, commits the pair atomically, enables the one motor, then destroys the retiring pair;
- body CFrame / linear velocity / angular velocity are not reset by redraw;
- SubmitStroke / StrokeResult schema and server authority do not change.

## Socket / tunnel contract

- `LegSocketZAbs` is the side surface of the canonical 3-stud cube: `1.5` studs from center.
- The first-point mechanical origin remains current production policy until the separate origin comparison is resolved; this decision does not silently select bounds-center or centroid.
- Inner geometry remains non-colliding around the socket/hub safety radius.
- RacerLeg does not collide with RacerBody or another RacerLeg, while RacerLeg still collides with Track.
- Legs are not breakable, folding, or auto-shortened. A shape that is too large for a tunnel is allowed to stall and must be redrawn by the player.

## Tuning boundary

Motor defaults remain `AngularVelocity=-8`, `MotorMaxTorque=35000`, `MotorMaxAcceleration=120` during the mechanical migration. Mass/friction/body-collider tuning is a later empirical step after the one-DOF axle is verified. No obstacle geometry is changed to manufacture a pass.

## Gate state

Repository automation may prove source/build contracts only. Camera feel, visual rigidity, physical obstacle interaction, and the reference-feel result remain **HUMAN STUDIO PENDING** until the Product Owner runs the final Studio acceptance pass. B17/G0 is not promoted by this decision.
