# Core V3 Suspended Start Design

Status: APPROVED IN CHAT / 2026-09-16

## Goal

Before the first accepted drawing, the racer waits motionless above the flat
Track. The first physical leg pair releases the racer, after which gravity,
the axle motor, and leg/Track contact are the only locomotion owners.

## Contract

- `EMPTY` owns a temporary anchored start hold with zero linear/angular velocity.
- The flat harness derives axle height from the current leg presentation envelope:
  `TrackTopY + SuspendedAxleHeightAboveTrack`.
- `SuspendedAxleHeightAboveTrack = 5.15` studs: the current `4.5` radial cap,
  `0.27` physical half-thickness, `0.08` clearance padding, and a deliberate
  `0.30` presentation gap that keeps the waiting cube visibly suspended.
- Failed first construction retains the hold.
- Successful first `ACTIVE` commit releases the hold once and starts from zero
  Body linear/angular velocity.
- The hold never returns on redraw, locomotion, obstacle contact, or fall recovery.
- No `AlignPosition`, hover force, +X force, speed controller, or new actuator.
- One SharedAxle, one HingeConstraint, centered axle, opposed sides, current motor,
  mass, friction, rider, camera, clearance, and redraw behavior remain unchanged.

## Ownership

- `RacerRuntime` owns the pre-first-shape lifecycle hold and release.
- `LegCoreConfig.Start` owns the suspended axle-height constant.
- `CoreV3FlatHarness` consumes the height for the isolated human reference lane.

## Acceptance

- A fresh racer is anchored and exactly still before any shape.
- External impulses cannot move it while `EMPTY`.
- A rejected first shape leaves it held.
- The first accepted pair enters `ACTIVE`, releases the zeroed Body/axle, then
  enables both physical sides and the motor in the same activation callback.
- Release begins with zero Body velocity and no horizontal helper.
- The ROUND reaches the Track through gravity/leg geometry and advances only after
  real leg contact.

This stage deliberately does not rewrite redraw. Redraw continuity is the next
separate observable behavior after human acceptance of the suspended start.
