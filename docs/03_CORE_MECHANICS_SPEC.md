# 03 — CORE MECHANICS SPEC — CORE V3

Status: **CURRENT PRODUCT/MECHANICAL CONTRACT — 2026-09-15**

Primary mechanical authority: `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`.
Numeric owners remain split: Core V3 physics values -> `16`; DrawCanvas/world mapping -> `73`; UI geometry -> `59`; track geometry -> `60`; lifecycle -> `74`.

## A. Drawing input
- one continuous stroke per new shape;
- mouse/touch;
- self-intersection legal;
- open/closed stroke legal;
- redraw allowed during racing.

Flow:
`pointer down -> local preview -> pointer up -> cleanup/simplify -> SubmitStroke -> server validation -> ShapeSpec -> Core V3 rebuild`.

Invalid/tiny/stale input does not become a new mechanical shape.

## B. Shape processing
- client prediction and server authority use the same canonical semantics;
- server recomputes/validates from the submitted semantic stroke;
- after cleanup the first cleaned point becomes authoritative `(0,0)` by translation only;
- do not resize, rotate, mirror, reverse or normalize every shape to one standard radius;
- ShapeSpec with no `canCollide=true` drive segment is rejected as `NO_DRIVE_COLLIDERS`.

## C. Shape semantics
There is no movement classification such as "circle gets speed" or "hook gets climb". Real collider geometry and contact create the movement trade-off. Classification may exist only for analytics/debug/reference tests.

## D. One shared axle / opposed side legs
One stroke creates two depth-separated copies of the same XY ShapeSpec:
- LEFT on `-Z`;
- RIGHT on `+Z`;
- fixed structural **180°** relation;
- one shared `AxleRoot`;
- shared axle local X/Y fixed at the `BodyCollider` center, independent of ShapeSpec/redraw;
- exactly one `HingeConstraint`;
- exactly one motor command owner;
- no per-side actuator and no phase-chasing loop.

Current implementation owners are `Runtime/CoreV3/SharedAxle`, `LegGeometry`, `LegCoreController`, `FallRecovery` and `LegCoreConfig`.

The physical hinge stays connected even while motor drive is off. Motor OFF means `ActuatorType.None`; motor ON means `ActuatorType.Motor`.

## E. Movement source
Normal +X locomotion is only:
`motor -> shared axle -> drawn leg colliders -> leg/Track friction -> BodyCollider +X`.

During the Core V3 Flat Gate the following are forbidden as normal locomotion:
- constant +X VectorForce;
- LinearVelocity/BodyVelocity forward assist;
- AntiStall propulsion;
- obstacle-recovery propulsion;
- PivotTo/body CFrame/Position movement;
- hidden second hinge/motor.

BodyCollider remains collidable with Track but is not the traction source.

## F. 2.5D body behavior
The intended race is 2.5D:
- X translation = physical/free;
- Y translation = physical/free;
- Z translation = locked to lane plane;
- body orientation = stabilized upright;
- shared axle rotation = free through the one hinge.

The lane/orientation owner may constrain depth/orientation only. It must not add forward propulsion or vertical lift.

Preferred next implementation boundary is a dedicated Core V3 lane owner using a PlaneConstraint plus bounded torque-only orientation stabilization. This decision is approved but remains runtime/human pending until implemented and tested.

## G. Redraw transaction
Current state machine:
`EMPTY -> PREVIEW -> WAIT_CLEAR -> ACTIVE`, and `ACTIVE -> PREVIEW -> WAIT_CLEAR -> ACTIVE`; failure -> `EMPTY`.

Rules:
- old physical leg geometry is removed at rebuild start;
- both previews and both physical ghost sides are created together on the current axle;
- whole-pair required lift is calculated before one bounded +Y redraw hop;
- preview/ghost geometry follows the moving body/axle assembly;
- new physical colliders remain ghost/non-colliding until whole-pair clearance passes;
- after the hop, only bounded +Y clearance assistance may softly finish the lift;
- pair collision enables atomically;
- accepted ShapeVersion/ShapeSpec commits only after true ACTIVE;
- mechanical failure is fail-closed and reports reject;
- if a previous physical accepted shape was invalidated, accepted client presentation is cleared;
- pending state clears even on unexpected exception;
- redraw does not teleport/reset BodyCollider X/Y motion as a locomotion shortcut.

## H. Flat Gate before obstacles
`COREV3_TEST` runs C01–C08. `COREV3` runs the isolated human flat harness.

Dedicated fall recovery may use one whole-racer `PivotTo` only after `BodyCollider.Position.Y` crosses the configured out-of-bounds threshold. It preserves the accepted pair/one hinge and lane center, clears velocities and adds no forward or obstacle assistance.

Human sequence:
1. ROUND from rest;
2. SMALL_ROUND;
3. LONG;
4. HOOK;
5. ASYMMETRIC;
6. 20 redraws while moving.

Required causal evidence:
- no hidden +X movement without legs;
- one shared hinge/axle;
- LEFT -Z / RIGHT +Z / 180°;
- leg/Track contact;
- axle rotates relative to body;
- BodyCollider advances +X from physical contact only;
- pair activates atomically;
- lane depth/upright behavior is stable after the approved 2.5D owner lands;
- no teleport or horizontal helper.

No walls, steps, gaps, tunnels, obstacle recovery or later systems may enter this validation path until Flat Gate PASS.

## I. Obstacles after Flat PASS
Once Flat Gate is accepted, geometry should create understandable niches: rounded/wide for flat speed, long for reach, hook/asymmetric for climb/steps, compact for clearance. Do not hard-code shape-name bonuses.

## J. Rider/camera
Rider is client-side presentation only and never affects racer physics. One client-local `RiderAnchor` on BodyCollider owns its stable body-relative transform; the visual remains massless/non-colliding and uses no mover or physical racer connection. Camera follows the racer for side-view readability and does not inherit BodyCollider roll as camera authority.

## K. Evidence language
Automation can prove contracts/buildability. Roblox solver/feel requires Studio evidence. Until then use:
`AUTOMATED PASS / HUMAN PHYSICS PENDING`.
