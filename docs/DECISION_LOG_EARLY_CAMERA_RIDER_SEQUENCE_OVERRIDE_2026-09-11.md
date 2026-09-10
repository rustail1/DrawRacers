# Decision Log — Early Camera + Rider Presentation Sequence Override

Date: 2026-09-11  
Status: **PRODUCT OWNER APPROVED / BOUNDED SEQUENCE OVERRIDE**  
Approval context: Product Owner explicitly authorized an autonomous overnight implementation of the already-locked Camera + Rider presentation contract before the normal D09/E03 cursor, followed by bounded bug-sweep work.  
Base repository head: `2694eb102f5358421a4e3905c5d64801e1b8f8e7`

## Decision

The behavior contract in `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md` remains authoritative. This decision changes **only implementation order** for one isolated presentation slice:

1. `CameraMath` + `RaceCameraController` may be implemented now against the currently replicated M0/G0 racer model;
2. `RiderPresentationController` may be implemented now as a client-only/nonphysical human-racer visual keyed by the already replicated `OwnerUserId` presentation identifier;
3. the current Studio G0 presentation harness must relinquish active camera ownership when the production camera exists, so there is still one active camera owner.

This decision supersedes only the earlier “do not implement before D09/E03” sequence-gating sentences in `25`, `21`, `26`, `FEATURE_LIST`, and the 2026-09-10 Camera/Rider Decision Log for these three presentation modules. All observable Camera/Rider behavior from that earlier Decision Log remains unchanged.

## Hard boundary — what this does NOT unlock

This override does **not** authorize any other later-phase production task. In particular it does not authorize:
- C01–C04 TrackPiece/adaptation implementation;
- D01–D08 race/multiplayer/RacerService/progress/network systems;
- D10–D12 HUD/results/social gate work;
- E00–E02 provisioning/8-lane/content work;
- E04+ persistence/economy/analytics/bot/FTUE work;
- new gameplay RemoteEvents or camera network authority;
- server-side avatar/rider physics;
- changes to BodyCollider, LegAssembly physics, motor values, lane stabilization, checkpoints, rewards, or ShapeSpec authority.

`RacerService` remains D05 and must not be implemented as collateral work. The early camera/rider must resolve the currently replicated racer presentation using the existing `OwnerUserId` attribute and later remain compatible with D05 without becoming its substitute.

## Camera implementation boundary

`RaceCameraController` becomes the sole production camera owner whenever a local human racer with matching `OwnerUserId` exists.

Required behavior remains exactly the locked contract:
- target derives from Local Racer world **position**, never BodyCollider orientation;
- frame-rate-independent target smoothing;
- X follows responsively while Y uses `VerticalDeadZone=0.50` and `VerticalDampingTime=0.22`;
- canonical starting values from `16`: FOV `60`, look-ahead `11`, height `10`, side/Z distance `23`, position damping `0.16`, look-target damping `0.12`;
- desktop free-look is hold RMB, yaw limited to `±40°`, pitch to `±18°`;
- releasing RMB returns automatically using `0.40 s` return time;
- LMB/DrawCanvas remains drawing-owned;
- touch orbit may begin only outside `DrawInputRect` and other active UI and ownership never switches mid-gesture;
- no implicit physics camera shake and no camera Remote family.

The existing `M0G0PresentationHarness` may remain responsible for the Studio-only nonphysical debug body proxy, but it no longer writes `CurrentCamera.CameraType`, `FieldOfView`, or `CFrame` once production camera ownership is introduced.

## Rider implementation boundary

`RiderPresentationController` is presentation-only and may start early using the existing `OwnerUserId` mapping.

Required invariants:
- client-side visual only under the presentation tree;
- target normalized scale `0.65` for the first implementation;
- deterministic jockey/frog-rider pose above the cube;
- every rider BasePart is `CanCollide=false`, `CanTouch=false`, `CanQuery=false`, `Massless=true`;
- rider does not alter BodyCollider, leg geometry, motors, stabilization, race authority, camera target, checkpoints, finish, rewards, or Draw Racers cosmetic ownership;
- oversized/accessory appearance must have deterministic presentation fallback. For this first bounded implementation, accessories are excluded from the rider clone so arbitrary accessory bounds cannot create a competitive/readability advantage;
- bots do not receive a human-avatar rider.

## Evidence and acceptance

Repository verification may establish **AUTOMATED GREEN** only. Camera feel, RMB/touch ergonomics, pose/readability, and 2/8-player composition remain **HUMAN STUDIO PENDING** until real Roblox Studio evidence exists.

This early slice does not mark R16 Studio Gate A/B/C or B17/G0 PASS. Existing human-gate facts remain exactly as previously recorded.

## Exit / future integration

When normal D09 is reached, the already implemented `RaceCameraController` is extended/integrated rather than duplicated. When E03 is reached, the existing `RiderPresentationController` receives full 2/8-player readability acceptance rather than creating a second rider system.

Any implementation need outside the boundary above is a new contract/scope question and is not authorized by this Decision Log.
