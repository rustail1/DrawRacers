# Decision Log — Core V3 fall recovery

Date: **2026-09-15**
Status: **APPROVED / HUMAN PHYSICS PENDING**
Classification: **CONTRACT_CHANGE**

## Decision

`Runtime/CoreV3/FallRecovery.lua` is the sole Core V3 out-of-bounds owner.
It observes `BodyCollider.Position.Y < FallThreshold`, latches one recovery per
threshold crossing, waits for any redraw transaction to finish, and restores
the same racer model to its saved spawn/checkpoint transform.

Recovery order is motor OFF, clear model velocities, permitted whole-model
`PivotTo`, restore the lane reference/center, clear velocities again, verify
the existing ACTIVE pair and one hinge, then motor ON. The current accepted
ShapeSpec, rider anchor and racer identity are preserved; no new racer is made.

`PivotTo` is authorized only inside this explicit out-of-bounds recovery. The
owner creates no force, locomotion, AntiStall or obstacle assistance.

## Initial threshold

`FallThreshold = -12 studs` is the local starting hypothesis. A recovered body
must rise above `FallThreshold + 4 studs` before the trigger rearms.

## Acceptance

Automated/static evidence covers one recovery per crossing, spawn/lane restore,
velocity reset, one hinge, accepted-shape/rider-anchor preservation and absence
of horizontal helpers. Final fall timing and physics remain **HUMAN PHYSICS PENDING**.
