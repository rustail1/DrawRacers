# R17 Opposed Leg Phase Correction — 2026-09-12

Status: **APPROVED PRODUCT OWNER CONTRACT CORRECTION / HUMAN STUDIO PENDING**

## Why this supersedes the prior co-phase wording

The Product Owner re-checked the Draw Climber reference and explicitly corrected the required visible relation between the two depth-separated copies of the drawn leg. The previous R17 co-phase (`0°`) interpretation is superseded.

## Current mechanical contract

- One player drawing still produces one authoritative ShapeSpec.
- The same ShapeSpec is duplicated onto the Left and Right sides of the cube; XY geometry is not mirrored or inverted.
- Production still uses one shared `AxleRoot`, one `AxleJoint`, and one motor for the pair. There are no independent side motors and no runtime phase-chasing controller.
- Left and Right are mounted on opposite Z sockets of the cube.
- The Right copy is structurally offset by **180°** around the shared axle relative to the Left copy: `RightPhaseOffsetDegrees = 180`.
- Both copies therefore rotate with the **same shared motor direction and angular speed**, while maintaining a fixed 180-degree relative phase.
- Redraw preserves the single live axle phase and rebuilds the pair with the same fixed 180-degree side relation.

## Supersession rule

Where any earlier R16/R17 document, test description, navigation note, or decision log says the current pair is `co-phase`, `0°`, or that `180°` was superseded, that wording is now historical and is superseded by this decision.

The shared-axle architecture itself is **not** reverted: one axle / one hinge / one motor remains the production design. Only the structural Left↔Right phase relation changes from `0°` to `180°`.

## Gate state

Repository checks may prove source/build consistency only. The corrected visual relation and physical feel remain **HUMAN STUDIO PENDING** until viewed in Roblox Studio. This decision does not promote B17/G0 or any human acceptance gate.
