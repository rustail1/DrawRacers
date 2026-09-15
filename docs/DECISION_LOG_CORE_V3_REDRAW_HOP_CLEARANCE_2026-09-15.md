# Decision Log — Core V3 redraw hop and clearance

Date: **2026-09-15**
Status: **APPROVED / HUMAN PHYSICS PENDING**
Classification: **CONTRACT_CHANGE**

## Decision

Core V3 redraw uses one bounded physical transaction:

1. disable the motor and remove the old pair;
2. create both new preview and physical ghost sides on the persistent axle;
3. calculate initial required lift from the complete non-colliding pair;
4. apply one impulse at the BodyCollider center, only along `+Y`;
5. show PREVIEW while all ghost geometry follows the body/axle assembly;
6. enter WAIT_CLEAR and, only if necessary, use the existing bounded soft lift;
7. enable both sides atomically, enable the requested motor state, and enter ACTIVE.

Failure remains fail-closed to EMPTY. Redraw never uses PivotTo, CFrame/Position
teleport, a `+X` force, or independent side activation.

## Initial hop hypothesis

The previous `3.5 studs/s` target produced only about `0.03 stud` of ballistic
rise at default Roblox gravity. The new local starting hypothesis is a target
vertical velocity of `20 studs/s`, capped to `24 studs/s` of added velocity.
From rest this is about `1.02 studs` of ballistic rise: visible but bounded.

## Non-goals

No change to the centered mount, lane/upright owners, motor, friction, mass,
rider, or fall recovery. Final timing/feel remains a human Studio gate.
