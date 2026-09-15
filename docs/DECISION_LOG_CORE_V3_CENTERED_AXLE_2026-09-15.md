# Decision Log — Core V3 centered axle

Date: **2026-09-15**
Status: **APPROVED / HUMAN PHYSICS PENDING**
Classification: **CONTRACT_CHANGE**

## Decision

The single Core V3 shared axle is mounted at the `BodyCollider` mechanical center:

- axle local X = `0`;
- axle local Y = `0`;
- LEFT and RIGHT mounts remain symmetric on `-Z` and `+Z`;
- RIGHT remains structurally `180°` opposed to LEFT;
- exactly one `HingeConstraint` and one motor owner remain authoritative;
- ShapeSpec geometry and redraw do not change the body/axle mount position.

The temporary lower-mount `VerticalFraction = -0.50` workaround is removed.

## Non-goals

This decision does not change lane/upright constraints, motor speed or torque,
friction, body/axle mass, redraw hop, clearance, rider, or fall recovery.

## Acceptance

Automated/static evidence must prove the centered X/Y mount, symmetric Z mounts,
one hinge, fixed 180° phase, and absence of the lower-offset workaround. Final
physics/visual acceptance remains a short Roblox Studio check by the Product Owner.
