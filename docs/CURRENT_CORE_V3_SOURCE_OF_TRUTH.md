# CURRENT CORE V3 SOURCE OF TRUTH

Status: **CURRENT / CANONICAL — 2026-09-15**

This document is the current mechanical/locomotion authority for DrawRacers. It supersedes the deleted CR2/CR3 twin-drive, staged-pair and old R15/R16/R17 mechanical implementation documents wherever they conflict.

## 1. Product reference and player-facing intent

The core reference is the observable **Draw Climber** idea: the player draws one shape and the geometry of that drawing physically determines locomotion. DrawRacers is an original Roblox implementation, not a literal copy.

Player expectation:
- side-view / 2.5D race readability;
- one visible cube/racer with a nonphysical rider presentation on top;
- one drawing input produces two depth-separated side legs;
- the player adapts the drawn shape to terrain rather than steering the racer directly;
- locomotion must visibly come from the drawn geometry contacting the Track.

## 2. Canonical shape pipeline

```text
DrawingController
-> SubmitStroke
-> StrokeRemoteTransport
-> LegShapeService
-> CanonicalLegShape / GeometryMath
-> ShapeSpec
-> RacerRuntime
-> CoreV3 LegCoreController
```

The authoritative stroke is translation-anchored to the first cleaned point. Do not resize, mirror, reverse or normalize every stroke to a standard wheel.

A ShapeSpec with zero usable `canCollide=true` drive segments is rejected as `NO_DRIVE_COLLIDERS` before mechanical activation.

## 3. One axle / one hinge mechanical contract

Per racer:
- exactly one shared `AxleRoot`;
- exactly one physical `HingeConstraint`;
- exactly one motor command owner;
- the shared axle local X/Y is exactly the `BodyCollider` center, with no vertical mount offset;
- LEFT leg lives on the `-Z` side;
- RIGHT leg lives on the `+Z` side;
- RIGHT is structurally fixed at **180°** relative to LEFT;
- both sides consume the same authoritative XY ShapeSpec;
- ShapeSpec geometry and redraw never move the body/axle mount;
- there is no second side hinge/motor and no runtime phase-chasing controller.

`HingeConstraint.Enabled` remains physically `true` for the lifetime of the Core V3 axle. Motor OFF is `ActuatorType.None`; motor ON is `ActuatorType.Motor`.

Current code owners:
- `src/server/Runtime/CoreV3/SharedAxle.lua`
- `src/server/Runtime/CoreV3/LegGeometry.lua`
- `src/server/Runtime/CoreV3/LegClearanceController.lua`
- `src/server/Runtime/CoreV3/LegCoreController.lua`
- `src/server/Runtime/CoreV3/FallRecovery.lua`
- `src/server/Runtime/CoreV3/LegCoreConfig.lua`
- `src/server/Runtime/RacerRuntime.lua`

Legacy `LegPairAssembly`, `LegDriveAssembly`, `LegAssembly`, `RacerAntiStall`, old `RacerStabilizer`, `LegCollisionSafety` and `RedrawSpawnSafety` may still physically exist in the repository until the post-Flat cleanup task, but they are **not current Core V3 locomotion owners and must not be reconnected to the active Core V3 path**.

## 4. 2.5D racer freedom contract

Approved target contract:

```text
TRANSLATION
X = FREE physical locomotion
Y = FREE physical bounce / lift / obstacle response
Z = LOCKED to lane plane

BODY ORIENTATION
upright = stabilized
axle rotation = free through the one HingeConstraint
```

The lane/orientation system may constrain only lane depth/orientation. It must not supply normal forward locomotion or vertical lift.

Preferred implementation boundary for the next Core V3 repair:
- a dedicated Core V3 lane owner using `PlaneConstraint` for Z-plane confinement;
- bounded `AlignOrientation` (or equivalent torque-only orientation constraint) for upright body stabilization;
- no `AlignPosition`/VectorForce/LinearVelocity that provides +X movement.

**Implementation status:** approved contract, **not yet human-accepted in the current Core V3 build**. Do not claim this gate PASS until Studio evidence exists.

## 5. Forward movement source

Normal forward motion is only:

```text
motor
-> shared axle
-> drawn physical leg segments
-> leg <-> Track contact/friction
-> BodyCollider moves +X
```

Forbidden as normal locomotion during the Core V3 Flat Gate:
- constant +X `VectorForce`;
- `LinearVelocity` / `BodyVelocity` forward assist;
- AntiStall forward propulsion;
- obstacle-recovery forward propulsion;
- `PivotTo`, body CFrame or Position teleport for movement;
- hidden second actuator.

BodyCollider remains collidable with the Track but Core V3 body friction is intentionally near zero; traction belongs to the legs.

## 6. Redraw transaction

Current redraw state machine:

```text
EMPTY -> PREVIEW -> WAIT_CLEAR -> ACTIVE
ACTIVE -> PREVIEW -> WAIT_CLEAR -> ACTIVE
failure -> EMPTY
```

Rules:
- motor command is off during PREVIEW/WAIT_CLEAR, but the physical hinge remains connected;
- old physical leg geometry is removed at rebuild start;
- both new previews and both physical ghost sides are created together on the current axle;
- initial required lift is calculated from the whole ghost pair before one bounded +Y hop;
- all preview/ghost geometry follows the moving body/axle assembly;
- both physical sides remain ghost/non-colliding through PREVIEW/WAIT_CLEAR;
- if the initial hop is insufficient, only the bounded +Y clearance owner may softly finish the lift;
- both sides become physical atomically;
- only after real `ACTIVE` does `ShapeVersion` / accepted ShapeSpec commit;
- mechanical failure is fail-closed and reports reject; accepted UI state is cleared when the old physical shape has been invalidated;
- `mechanicalPending` must always clear, including unexpected exceptions.

## 7. Flat Gate

Before obstacles, prove the fundamental causal loop on one flat Track.

Required automated Studio suite: **C01–C08**.

The root historical Python `verify.py` suite is not the Core V3 mechanical authority; it still contains superseded CR2/R17 implementation-detail contracts and must be migrated/retired in a separate bounded task rather than forcing legacy architecture back into Core V3.

Human reference shapes:
- ROUND
- SMALL_ROUND
- LONG
- HOOK
- ASYMMETRIC

Human Flat Gate requires:
1. no hidden +X movement without legs;
2. one shared hinge/axle;
3. LEFT -Z / RIGHT +Z;
4. fixed 180° relation;
5. real leg/Track contact;
6. axle rotates relative to body;
7. body advances +X from contact only;
8. redraw does not teleport/reset racer;
9. pair activates atomically;
10. 20 moving redraws remain stable.

`COREV3_TEST` runs C01–C08. `COREV3` is the isolated human flat-physics harness.

The dedicated Y-threshold `CoreV3/FallRecovery` owner may return an out-of-bounds racer to its saved spawn. This is not obstacle recovery or locomotion assistance. Until the Flat Gate passes, do not re-enable walls, steps, gaps, tunnels, obstacle recovery or old locomotion helpers in the Core V3 validation path.

## 8. Evidence/status language

Static/source/unit success is not Roblox physics success.

If Studio physics has not been observed:

```text
AUTOMATED PASS / HUMAN PHYSICS PENDING
```

Never promote the Flat Gate to PASS from CI/static checks alone.

## 9. Current execution workflow

Current development phase is **local-file / local-folder only**.
- no Git/GitHub/branch/PR/commit workflow is required;
- the local project folder/archive is the session baseline;
- edit a separate copy/overlay when possible;
- Rojo/Roblox Studio remain the runtime/human validation path;
- Git workflow may be re-enabled only by an explicit Product Owner decision.

## 10. Current next bounded task

Do not retune motor/torque/mass merely because the racer can fall sideways. The next approved architecture repair is the 2.5D body freedom owner:

**Z lane-plane lock + upright orientation stabilization, with X/Y translation still physical and no forward helper.**

Then rerun C01–C08 and the human ROUND flat test before changing locomotion coefficients.
