# R17 Shared Axle + Camera Fidelity Decision — 2026-09-11

Status: **APPROVED PRODUCT OWNER CONTRACT CHANGE / HUMAN STUDIO PENDING**

## Evidence that triggered the change

Product Owner supplied a current DrawRacers gameplay video and a Draw Climber reference video. In the then-current build, each drawn side was individually rigid, but the two sides were driven by independent HingeConstraint motors and a runtime phase-correction controller. Under unequal contact load one side could lag while the other was accelerated, producing visible relative-angle drift / apparent bending. The production camera also intentionally clamped RMB yaw to +/-40 degrees and applied pointer delta directly to the rendered orbit target without a separate smoothed rendered angle.

A later human-video comparison on 2026-09-12 exposed a second reference mismatch after the shared-axle migration: the interim `180°` local side offset put one copy above the cube while the other wrapped below it, producing a cage-like silhouette. In the supplied reference footage the two depth-separated side copies visibly maintain the **same angular orientation** while rotating. Therefore the shared axle architecture remains correct, but the current side relation is superseded to **co-phase / 0° local difference**. This is a visible-reference contract correction, not a claim about the reference game's internal implementation.

## Canonical R17.9 camera contract

- Hold RMB owns world camera input only outside DrawInputRect / active UI / focused text input.
- Horizontal yaw is **360-degree / continuous**: there is no +/-40 degree yaw wall.
- Pitch remains bounded to prevent upside-down inversion.
- Pointer/touch input changes target yaw/pitch; rendered yaw/pitch follow with frame-rate-independent damping.
- Releasing RMB returns smoothly to the canonical side-race framing.
- Camera remains client-only, follows Local Racer position rather than BodyCollider rotation, and sends no gameplay remote.

## Canonical R17.10-R17.14 leg drive contract

The previous twin independent motor + phase-recovery design is superseded for production locomotion.

Production uses one **shared axle**, **one hinge**, and **one motor** for the pair of drawn sides:

```text
BodyCollider
  -> shared AxleJoint (one Motor)
      -> shared AxleRoot
          -> Left rigid side geometry at local phase 0 degrees
          -> Right rigid side geometry at local phase 0 degrees (co-phase)
```

Consequences:

- both sides consume the same authoritative ShapeSpec;
- each side is a rigid geometry assembly welded to the shared axle root;
- both side copies remain **co-phase** while being separated physically at opposite Z sockets;
- `RightPhaseOffsetDegrees = 0` is structural, not recovered by software;
- there is no per-side AngularVelocity correction, phase-sync Heartbeat owner, or independent side motor;
- accepted redraw stages a complete replacement LegPair off-world, copies the single live axle phase, commits the pair atomically, enables the one motor, then destroys the retiring pair;
- body CFrame / linear velocity / angular velocity are not reset by redraw;
- SubmitStroke / StrokeResult schema and server authority do not change.

The old `RightPhaseOffsetDegrees = 180` wording in earlier R16/R17 records is historical/superseded where it conflicts with this human-video correction.

## Rider mount correction from human video

The same 2026-09-12 Studio video showed that placing the normalized rider from a fixed HumanoidRootPart offset buried most of the avatar inside the 3-stud cube. Current presentation therefore mounts the visual from a deterministic seat reference (`LowerTorso`, then `Torso`, then HumanoidRootPart fallback) and aligns that reference just above the cube top. Rider remains client-only, non-colliding, massless and non-authoritative. Visual seating remains **HUMAN STUDIO PENDING** until the corrected build is viewed in Studio.

## Socket / tunnel contract

- `LegSocketZAbs` is the side surface of the canonical 3-stud cube: `1.5` studs from center.
- The first-point mechanical origin remains current production policy until the separate origin comparison is resolved; this decision does not silently select bounds-center or centroid.
- Inner geometry remains non-colliding around the socket/hub safety radius.
- RacerLeg does not collide with RacerBody or another RacerLeg, while RacerLeg still collides with Track.
- Legs are not breakable, folding, or auto-shortened. A shape that is too large for a tunnel is allowed to stall and must be redrawn by the player.

## Tuning boundary

Motor defaults remain `AngularVelocity=-8`, `MotorMaxTorque=35000`, `MotorMaxAcceleration=120` during the mechanical migration. Mass/friction/body-collider tuning is a later empirical step after the one-DOF axle is verified. No obstacle geometry is changed to manufacture a pass.

## Gate state

Repository automation may prove source/build contracts only. Camera feel, visual rigidity, rider seating, physical obstacle interaction, and the reference-feel result remain **HUMAN STUDIO PENDING** until the Product Owner runs the corrected Studio acceptance pass. B17/G0 is not promoted by this decision.
