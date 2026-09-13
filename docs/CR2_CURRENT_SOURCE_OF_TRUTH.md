# CORE REPAIR v2 — CURRENT SOURCE OF TRUTH

Date: 2026-09-14  
Status: **SOURCE/CONTRACT IMPLEMENTED; HUMAN STUDIO G0 PENDING**

This file is the current mechanical override for Draw Racers. It supersedes current-mechanics wording in historical R16/R17/MR documents and in older sections of `03`, `11`, `16`, `21`, `22`, `24`, `65`, `73`, `SESSION`, and `FEATURE_LIST` wherever those sections still describe first-point translation, Z-separated side sockets, one shared axle/one shared motor, destructive hub-to-tip physical redraw, or non-rigid body orientation. Historical evidence remains retained for regression traceability; it is not current implementation authority.

## Canonical pipeline

`DrawingController -> CanonicalLegShape -> LegShapeService -> RacerRuntime -> LegPairAssembly -> Left/Right LegDriveAssembly -> LegAssembly`

- `CanonicalLegShape` is the single shared canonical shape builder.
- Client submits raw semantic `{ sequence, points }`; payload schema unchanged.
- Server recomputes canonical geometry and publishes ShapeVersion only after mechanical commit.
- `StrokeResult.acceptedPoints` are server-authoritative fixed-pivot canonical points; client renders those accepted points.

## Fixed pivot / drawing contract

- DrawInputRect remains the wide isotropic semantic surface: X `±1.75`, Y `±1.0`.
- The visible mechanical **fixed pivot** is semantic `(0,0)`.
- Pointer-down must begin inside `PivotStartRadiusNormalized`; otherwise reject as `START_OFF_PIVOT` / show `START FROM THE DOT`.
- A legal first sample may snap to `Vector2.zero`, but the builder does **not** subtract the first point from every later point.
- No `presentationAnchor` enters ShapeSpec, network authority, or physics.
- Current starting mapping: `LegCanvasHalfSpan = 3.2`, `MaxLegExtentFromHub = 4.5`.

## Twin-pivot / twin-drive topology

The old **shared axle** topology is retired by CORE REPAIR v2.

- Left mechanical pivot: body-local `X = -BodyCollider.Size.X/2`, `Y=0`, `Z=0`.
- Right mechanical pivot: body-local `X = +BodyCollider.Size.X/2`, `Y=0`, `Z=0`.
- `LegPairAssembly` owns two persistent `LegDriveAssembly` instances.
- `LeftDrive` and `RightDrive` each own one `DriveRoot`, one `DriveJoint` HingeConstraint motor, and one persistent child `LegAssembly`.
- Exactly two drive hinges exist for an active racer. There is no current `AxleRoot`/`AxleJoint` shared-motor owner.
- Both legs consume the same canonical ShapeSpec and target `RightPhaseOffsetDegrees = 180`.
- `LegPairAssembly` coordinates bounded phase correction; it does not CFrame-snap drive roots during normal play.
- Base drive speed is extent-aware via `TargetTipSpeed = 10.5`, `MinimumDriveRadius`, `MinAngularVelocity = 1.5`, and `MaxAngularVelocity = 6.0`.

## Redraw transaction

- Normal redraw preserves BodyCollider, pair, both drives, both DriveJoints, and both side LegAssembly owners.
- Existing **old physical** geometry remains active while the candidate shape stages visual-only geometry.
- `LegCollisionSafety` evaluates bounded Track-only mount offsets without moving the body/drives.
- On safe **commit**, full pending physical geometry is synchronously swapped in; old geometry is then destroyed.
- Failed staging/safety/commit leaves the old accepted shape/version intact.
- Redraw does not intentionally zero or teleport body motion.

## Body / lane contract

- X/Y translation remains physical gameplay.
- Z translation is mechanically lane-locked by PlaneConstraint.
- Body stays arcade-**upright** on all axes through `AlignOrientation` with identity basis and `RigidityEnabled = true`.
- Stabilizer adds no intentional forward propulsion or vertical lift.

## Collision / presentation

- Physical leg collider segments are hidden and Track-colliding according to the canonical collision matrix.
- Visible leg curve is nonphysical (`CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`).
- Camera remains production side-view ownership with hold-RMB **full 360** yaw target, bounded pitch, smoothing, and return.
- Rider/cosmetics stay presentation-only and are outside mechanical authority.

## Current Studio gate

Repository contracts/buildability are not live physics proof. Normal Studio `Play` remains `G0` for the direct human CORE loop. Required live checks include shape-to-world parity, alternating 180° twin-drive behavior, redraw continuity, Flat/Steps/Wall/Gap/Tunnel trade-offs, recovery, upright/lane behavior, camera feel, and rider readability.

**HUMAN STUDIO PENDING. B17/G0 HUMAN_GATE PENDING. Do not start M0.5/multiplayer/meta/economy/shop until the human gate is recorded or a bounded repair decision is made.**
