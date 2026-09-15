# SESSION — CURRENT EXECUTION CURSOR

Date: **2026-09-15**
Status: **CORE V3 FLAT PHYSICS REPAIR / HUMAN PHYSICS PENDING**
Execution: **LOCAL FILE / LOCAL FOLDER — NO GIT**

## Current Source of Truth
Primary mechanical owner: `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`.
Current design: `superpowers/specs/2026-09-15-core-v3-flat-physics-design.md`.
Current plan: `superpowers/plans/2026-09-15-core-v3-flat-physics-current-plan.md`.

Deleted CR2/CR3/twin-drive/old MR documents are historical and must not be reconstructed as current instructions.

## Current implemented Core V3
- drawing pipeline remains `DrawingController -> StrokeRemoteTransport -> LegShapeService -> CanonicalLegShape/GeometryMath -> ShapeSpec`;
- `RacerRuntime` routes accepted shapes into Core V3;
- `LegCoreController` owns `EMPTY/PREVIEW/WAIT_CLEAR/ACTIVE`;
- `SharedAxle` owns one AxleRoot + exactly one HingeConstraint + one motor command;
- the approved shared-axle mount is the BodyCollider center on local X/Y, with no vertical offset;
- Left leg is on -Z; Right leg is on +Z and structurally 180° opposed;
- pair collision activates atomically;
- redraw accepted state commits only after true ACTIVE; failures are fail-closed;
- no normal +X helper/AntiStall/Stabilizer is active in the Core V3 flat path;
- C01–C08 exist; `COREV3_TEST` runs them; `COREV3` runs the isolated flat human harness;
- rider remains presentation-only/nonphysical.

## Newly approved decision — next bounded repair
The game is 2.5D. Current live behavior can fall/drift sideways in full 3D, which is not intended gameplay.

Approved target:
- X translation free;
- Y translation free;
- Z locked to lane plane;
- BodyCollider stabilized upright with torque/orientation constraint only;
- axle rotation remains free;
- no forward/vertical helper force is introduced.

Preferred implementation: dedicated Core V3 lane owner using PlaneConstraint + bounded orientation stabilization. This contract is approved but runtime/human acceptance is still pending.

## Current Flat Gate
First prove one ROUND from rest:
1. no hidden +X motion before legs;
2. one shared axle/hinge;
3. real leg/Track contact;
4. relative axle/body rotation;
5. body moves +X only from leg traction;
6. lane depth remains stable;
7. body stays readable/upright;
8. no teleport or forward helper.

Then: SMALL_ROUND -> LONG -> HOOK -> ASYMMETRIC -> 20 moving redraws.

No walls/steps/gaps/tunnels or obstacle recovery until Flat Gate PASS.

## Current exact next task
Implement/validate the dedicated Core V3 FallRecovery owner: one Y-threshold recovery to saved spawn/lane, same racer/accepted pair/hinge/rider anchor, cleared velocities and no locomotion or obstacle helper. Runtime physics acceptance remains human-pending.

## Status language
Current status remains:
`AUTOMATED/STATIC EVIDENCE AVAILABLE / HUMAN PHYSICS PENDING`

Do not claim Roblox physics PASS without Studio evidence.
