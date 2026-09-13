# Draw Racers — CR3 Current Source of Truth

Date: 2026-09-14
Status: SOURCE/CONTRACT REPAIR IN PROGRESS; HUMAN STUDIO G0 PENDING

This file is the current mechanical entrypoint. Where older R16/R17/CR2 notes disagree with this file, CR3 wins. Historical documents remain evidence only.

## Current player-facing drawing contract

- `DrawInputRect` is a free drawing surface. The player may start anywhere inside it.
- There is no `PivotMarker`, no `START FROM THE DOT`, no `START_OFF_PIVOT`, and no `PivotStartRadiusNormalized` gate.
- There is no `AcceptedShapeThumbnail` inside the gameplay drawing surface.
- Raw semantic samples are still sent to the server; the server recomputes the canonical shape.
- Canonical cleanup remains clamp -> dedupe -> simplify -> resample.
- After cleanup, `CanonicalLegShape` chooses one actual support point from LEFT / TOP / RIGHT candidates using the first cleaned point only as a gesture hint.
- The canonical shape is translated by `-supportAnchor` only. CR3 does not rotate, mirror, reverse, auto-fit, or resize the authored shape.
- `presentationAnchor` is client presentation metadata used to render authoritative translated points back where the player drew them. It is not part of the network payload and is not physical authority.
- `StrokeResult.acceptedPoints` remains authoritative server output. The local origin may occur at any accepted point index.

## Current leg topology

- One `BodyCollider`.
- Two explicit persistent body attachments owned by `LegPairAssembly`:
  - `LeftLegMount`
  - `RightLegMount`
- Starting mount tuning:
  - `LegMountHorizontalFraction = 0.78`
  - `LegMountVerticalFraction = -0.72`
  - Z = 0
- Mounts are therefore inset near the lower-left and lower-right of the body, not at the midpoint of each side.
- Two persistent `LegDriveAssembly` instances remain because the two mechanical pivots are physically distinct.
- Each drive owns one `DriveJoint` HingeConstraint and one persistent `LegAssembly`.
- `LegDriveAssembly` consumes a supplied `bodyMount: Attachment`; it does not derive `+/- body.Size.X / 2` itself.
- No current `AxleRoot` / `AxleJoint` shared-motor owner exists.

## Current movement/phase contract

`LegPairAssembly` is the single semantic movement/phase command owner.

- It computes one extent-aware `baseOmega` from `LegDriveMath.ComputeAngularVelocity`.
- It sends the same `baseOmega` to both physical drive joints.
- Initial right phase is left phase + `RightPhaseOffsetDegrees = 180`.
- Pair phase error may be measured for telemetry only.
- There is no active differential phase chasing and no `ComputePhaseCorrection` locomotion path.
- There are no active `PhaseCorrectionGain`, `MaxPhaseCorrection`, or `PhaseDeadbandDegrees` tuning values.
- Normal locomotion does not CFrame-snap either drive to catch the other.

## Redraw / authority retained from CR2

The good CR2 infrastructure remains current:

- one shared canonical builder for client prediction and server recomputation;
- server authority over accepted shape and ShapeVersion;
- one redraw transaction per racer;
- old physical geometry remains active during visual staging;
- collision-safe mount-offset planning is bounded, track-only, and non-mutating;
- coordinated physical commit on both sides;
- BodyCollider CFrame and velocities are not reset by redraw;
- ShapeVersion publishes only after successful mechanical commit;
- failed redraw keeps the previous physical shape/version active;
- racer recovery remains independent of the drawing/presentation layer.

## Presentation rider

The player avatar rider is presentation-only. CR3 adds a small built-in cowboy presentation using non-colliding, non-touching, non-queryable, massless Parts welded to the cloned avatar Head. It must never write BodyCollider velocity, apply impulses, or participate in gameplay collision.

## Current tuning retained pending human Studio evidence

- `LegCanvasHalfSpan = 3.2`
- `MaxLegExtentFromHub = 4.5`
- `TargetTipSpeed = 10.5`
- `MinAngularVelocity = 1.5`
- `MaxAngularVelocity = 6.0`
- `RightPhaseOffsetDegrees = 180`
- body remains arcade-upright through the existing stabilizer (`RigidityEnabled = true`).

These numbers are source/build hypotheses until a fresh Studio G0 video accepts feel and placement.

## Human gate

Repository automation can prove source contracts and Rojo buildability only.

Current gate remains:

- `G0 / HUMAN STUDIO: PENDING`
- do not claim physical feel, leg attachment readability, phase stability, obstacle usefulness, or cowboy visual quality PASS without fresh Studio evidence;
- do not start M0.5, multiplayer, meta, economy, or shop work while the core G0 gate is unresolved.

## Superseded CR2 decisions

The following CR2 decisions are historical and MUST NOT return to active source/tests:

- mandatory fixed center drawing pivot;
- `START FROM THE DOT` / `START_OFF_PIVOT`;
- red center `PivotMarker`;
- gameplay `AcceptedShapeThumbnail` square;
- side-midpoint body mounts (`+/- body.Size.X / 2`, `Y = 0`);
- differential twin-motor phase correction/chasing.

See `docs/superpowers/specs/2026-09-14-core-repair-v3-free-draw-single-phase-design.md` for the approved design rationale.
