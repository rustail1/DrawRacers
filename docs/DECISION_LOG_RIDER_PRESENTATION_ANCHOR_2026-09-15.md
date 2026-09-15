# Decision Log — Rider presentation anchor ownership

Date: **2026-09-15**
Status: **APPROVED / HUMAN PRESENTATION PENDING**
Classification: **CONTRACT_CHANGE**

## Decision

`RiderPresentationController` owns exactly one client-local `RiderAnchor`
Attachment on each visible human racer's `BodyCollider`. The rider visual stays
under `Workspace.Runtime.RacePresentation`, but its stable transform is derived
from `RiderAnchor.WorldCFrame`, so movement, redraw hop and explicit respawn all
share the same body-local presentation reference.

Every rider BasePart remains `CanCollide=false`, `CanTouch=false`,
`CanQuery=false` and `Massless=true`. Exactly one part in each disconnected
visual assembly is anchored; no rider mover, force or physical joint to the
racer is created. This prevents loose avatar/accessory assemblies from falling
independently while keeping the rider outside racer mass and locomotion physics.

The real Roblox Character remains a separate lifecycle/appearance source. It is
never used as racer support or attached to BodyCollider by this owner.

## Non-goals

No changes to Core V3 drive, lane/upright constraints, centered leg mount,
clearance, motor, racer mass/friction, camera authority, or fall recovery.

## Acceptance

Static evidence covers hierarchy/flags/no-mover ownership. Stable seated pose,
hop/respawn following and readability remain **HUMAN STUDIO PENDING**.
