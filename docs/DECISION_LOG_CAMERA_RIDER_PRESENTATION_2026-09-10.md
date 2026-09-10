# Decision Log — Camera + Rider Presentation Contract Lock

Date: 2026-09-10  
Status: **APPROVED CONTRACT LOCK / IMPLEMENTATION SEQUENCE-GATED**  
Base repository head for this decision: `ff31314b319b7b7738ff4d4d0662788ae29a7979`

## Decision

Draw Racers will keep the canonical physical racer as the existing cube + two player-drawn physical legs, while production presentation later gains two related systems:

1. a stable local-racer camera with bounded temporary free-look;
2. a separate normalized mini-avatar rider presentation for human racers.

This decision changes presentation WHAT/WHY only. It does **not** authorize early production implementation, change current M0 runtime, or move the current R16/B17 human gate.

## Sequence lock

- Current milestone remains **M0 — Physics Lab**.
- Current next action remains the ordered `R16FINAL` Studio evidence path followed by B17/G0 human acceptance.
- Production `RaceCameraController` remains **D09**. It must not be implemented before D01–D08 merely because this contract now defines its behavior.
- `RiderPresentationController` is introduced at **E03** as part of the full 8-player readability presentation pass.
- No C01-or-later runtime work is authorized by this Decision Log.

## Production camera contract — D09

`RaceCameraController` is the sole production owner of active-race camera follow/orbit/return behavior.

Canonical behavior:
- camera follows only the Local Racer during active play;
- camera target is derived from racer world **position**, not racer orientation;
- BodyCollider roll/pitch/yaw and small physics jitter are not inherited by camera orientation;
- an independent smoothed camera target follows X responsively and Y more softly;
- small vertical motion inside the configured dead-zone does not move the vertical camera target;
- larger climbs/falls converge smoothly so vertical gameplay remains readable;
- canonical side/3-quarter framing keeps look-ahead and upcoming obstacle readability from `08/16/59`;
- other racers may be visible but never become the active-race camera target automatically;
- ordinary physics impacts do not create implicit camera shake; any deliberate shake is a separate presentation effect and obeys Reduce Motion.

Starting D09 hypotheses owned numerically by `16`:
- `VerticalDeadZone = 0.50 studs`;
- `VerticalDampingTime = 0.22 s`;
- `OrbitYawLimit = ±40°`;
- `OrbitPitchLimit = ±18°`;
- `OrbitReturnTime = 0.40 s`.

Existing production starting values in `16` remain authoritative for FOV, look-ahead, side distance, screen anchor and the base damping family.

### Desktop free-look

- LMB remains drawing input and is never the camera orbit toggle.
- Holding RMB starts bounded free-look only when world-camera input is allowed by UI focus priority.
- RMB motion changes only bounded orbit yaw/pitch around the **smoothed** local-racer camera target.
- Camera roll remains zero.
- Releasing RMB automatically returns to canonical side framing using the configured return time.
- No second click is required to return.

### Touch free-look

- A touch that begins inside `DrawInputRect` belongs to drawing until end/cancel.
- A touch that begins on another active UI control belongs to that UI until end/cancel.
- A touch may become a camera gesture only when it begins outside DrawCanvas and outside active UI.
- Ownership does not switch mid-gesture merely because the finger crosses another region.

Camera state is local presentation only. No camera orientation/gesture RemoteEvent is added.

## Rider presentation contract — E03

The existing cube shell remains the canonical racer body. The shell itself still has no limbs/character rig. A human racer may additionally display a **separate**, presentation-only `RiderPresentation` above the cube.

Production owner: `RiderPresentationController`.

Responsibilities:
- bind a human Player identity to the replicated racer presentation mapping;
- render one standardized mini-avatar visual rig for that human racer;
- apply a deterministic jockey/frog-rider pose;
- normalize visual scale and enforce a readability envelope;
- create/cleanup rider presentation with racer lifecycle.

The rider must never:
- own or influence locomotion;
- change BodyCollider size, mass, friction, collision or orientation constraints;
- change leg ShapeSpec, LegAssembly geometry, motor values or collision;
- participate in checkpoints/finish authority;
- become the active-race camera authority target;
- create competitive advantage from Roblox body scale, bundle or accessories.

Any rider BasePart presentation must be nonphysical: `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`. A client-only visual implementation is preferred when it preserves visibility and lifecycle requirements.

### Rider size/readability

Starting visual hypothesis:
- target normalized scale equivalent: **0.65**;
- Studio comparison sweep: **0.55 / 0.65 / 0.75**;
- choose only from real 2-player/8-player readability evidence.

Oversized bundles/accessories may not expand gameplay geometry or dominate the race view. Production implementation must use a deterministic visual envelope/fallback when an appearance cannot fit the accepted presentation bounds.

Initial pose:
- seated over the upper/central-rear part of the cube;
- knees/legs visually to the sides;
- torso slightly leaning forward;
- arms directed forward/toward the cube;
- no required bob/lean animation in the first implementation.

Additional bob/lean is later presentation polish and needs its own acceptance if introduced.

Bots do not imitate a human avatar. Bot identity remains the explicit `BOT #N` presentation contract.

## Identity / mapping contract

Production human racer models expose a server-authored `OwnerUserId:number` presentation identifier. Bot racers do not impersonate a human `OwnerUserId`.

`OwnerUserId` is a replicated presentation lookup key, not a client authority surface and not a replacement for `RacerService`'s server mapping.

## Architecture ownership

- `RaceCameraController` owns camera only.
- `RiderPresentationController` owns rider visual lifecycle only.
- `InputController` continues to normalize the drawing pointer only; it does not become a general camera manager.
- `DrawingController` continues to own DrawCanvas stroke state/preview/submit/result.
- `RacerRuntime` remains physical racer runtime authority and does not absorb avatar rendering.
- `CosmeticService` remains authoritative for Draw Racers cosmetic ownership/equip; Roblox avatar rider rendering does not duplicate cosmetic entitlement logic.

No `GameManager`, broad `RacerPresentationManager`, duplicate movement controller, or camera Remote family is authorized by this decision.

## Current G0 boundary

The current `M0G0PresentationHarness` remains a Studio-only temporary presentation owner and is **not changed by this Contract Lock**. The current R16/B17 evidence must be completed against the existing M0 runtime before D09/E03 production work.

A later bounded Studio camera prototype would require its own explicit approval; this Decision Log does not silently turn the G0 harness into production architecture.

## Invariants preserved

Unchanged by this contract:
- first-point authoritative stroke origin;
- one ShapeSpec duplicated to two physical legs;
- 180° leg phase contract;
- stroke/network schema and Remote names;
- physical leg/body collision rules;
- motor/torque/acceleration/friction values;
- RacerStabilizer, lane lock and RacerAntiStall;
- obstacle geometry and finish/checkpoint authority;
- Rojo mapping;
- current R16 Stage A/B/C and B17/G0 human-gate status.

## Acceptance boundary

Documentation approval does not prove camera feel or rider readability.

D09 requires deterministic camera math/controller verification plus real Roblox Studio camera acceptance. E03 requires deterministic nonphysical rider invariants plus 2-player and 8-player visual/readability evidence on supported device layouts.

Until those ordered tasks are reached and human evidence exists, status is **CONTRACT LOCKED / IMPLEMENTATION PENDING**.