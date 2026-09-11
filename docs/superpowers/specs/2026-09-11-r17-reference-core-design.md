# R17 Reference-Core Parity Design

Status: **APPROVED PRODUCT-OWNER DESIGN / HUMAN EVIDENCE REQUIRED**
Date: 2026-09-11
Approved base: `810058fbe134922d6040f84379ae0fa4f8405e5b`

## Goal

Bring the DrawRacers M0 core closer to the observable feel/readability of the Draw Climber reference before expanding into meta, economy, or multiplayer scale. R17 is a bounded core-reconciliation program: camera input, rider presentation, leg mechanical-origin evidence, persistent twin-leg anti-phase, body/leg feel, and final reference-course acceptance.

R17 does **not** claim hidden Draw Climber implementation constants. Public reference behavior and user-supplied visual evidence are comparison targets; DrawRacers keeps its own server-authoritative Roblox architecture.

## Repository facts at approval

- One authoritative cleaned stroke becomes one `ShapeSpec`, duplicated into two physical `LegAssembly` instances.
- Current R16.3B mechanical origin translates the first cleaned stroke point to `(0,0)`.
- Left/right hubs are symmetric in Z and both hinge axes are `+Z`.
- Both motors use the same canonical locomotion sign; runtime phase correction was added in R16.4 follow-up to maintain approximately 180-degree anti-phase.
- Body collider is currently `3x3x3`; body density/friction/elasticity start at `1.0 / 0.45 / 0.05`.
- Leg collider thickness is `0.45`; leg density/friction/elasticity start at `1.0 / 1.0 / 0.02`.
- Production `RaceCameraController`, `CameraMath`, and `RiderPresentationController` already exist in M0 due Product Owner override work, even though older sequence documents still describe them as future D09/E03 owners.
- Human Studio gates remain pending unless supported by supplied Studio evidence. CI/Rojo build never promotes a human physics/feel gate.

## Product decision: reference-first core before B17 acceptance

R17 supersedes only the **sequence lock** that kept production camera/rider work at D09/E03 and authorizes bounded M0 reference-core work before B17. It does not authorize unrelated C01+ systems, multiplayer service expansion, meta, economy, persistence, rewards, or monetization.

The existing first-point mechanical origin remains production truth until R17.3 produces comparative Studio evidence and R17.4 records an explicit mechanical-origin decision. R17 authorization means the old first-point lock may be superseded later if evidence proves another deterministic origin better matches the intended two-leg reference behavior; it is not superseded merely by this design document.

## Invariants throughout R17

- Server remains authoritative for accepted stroke validation and `ShapeSpec`.
- Network payload remains `{sequence, points}` unless a later separately approved contract change proves otherwise.
- Exactly two physical legs use one accepted shape; presentation must not lie about authoritative collision geometry.
- Rider remains presentation-only and never contributes mass, collision, checkpoint/finish authority, or camera target authority.
- Camera remains client-only presentation and never sends orientation/gesture authority to the server.
- No hidden forward propulsion is added to fake reference feel.
- Motor sign is not reversed as a phase correction shortcut.
- Tuning changes are isolated and measured; mass, friction, collider size, motor torque/speed are not changed simultaneously.
- Human Studio evidence is required for solver behavior, camera feel, rider pose/readability, and final reference acceptance.

## R17.0 — Contract reconciliation

Record this override and reconcile current docs with actual implementation:

- `RaceCameraController` is an active M0 production presentation owner under R17 rather than a future-only D09 file.
- `RiderPresentationController` is an active provisional M0 presentation owner under R17; rider human visual acceptance remains pending.
- D09 becomes the 2-player/rival/readability extension and acceptance of the existing camera owner, not first introduction.
- E03 becomes the 8-player readability extension/acceptance of the existing rider owner, not first introduction.
- B17 remains blocked until the ordered R17 reference-core work is complete or Product Owner records another explicit gate decision.
- First-point origin remains current until R17.3/R17.4 evidence/decision.

## R17.1 — Desktop RMB camera ownership

### Current defect

The controller listens for `MouseButton2`, but a blanket `gameProcessed` early return can prevent the camera from claiming RMB after Roblox/CoreScripts consume the event. The controller also does not explicitly capture and restore `UserInputService.MouseBehavior`, so desktop free-look can fail or run out of cursor travel.

### Target behavior

- LMB remains drawing-only.
- Hold RMB over world space with an eligible Local Racer -> begin bounded camera orbit.
- RMB camera ownership may proceed even if CoreScripts set `gameProcessed=true`, provided no focused text box and no active project UI/DrawCanvas owns the pointer position.
- On orbit begin, save previous `MouseBehavior` and set `LockCurrentPosition`.
- On RMB release, window-focus loss, controller destroy, local-racer loss while held, or camera loss while held: restore the exact saved `MouseBehavior` and clear the hold state.
- Releasing RMB does not snap the view. Existing yaw/pitch values return smoothly to zero using the existing `0.40 s` return contract.
- Touch ownership rules remain unchanged.

### Verification boundary

Automated tests can prove ownership ordering/state-restoration code and unchanged LMB/network invariants. Only Roblox Studio can prove the actual RMB feel, cursor capture, orbit readability, and smooth return.

## R17.2 — Rider mount and pose

Replace the current approximate `body top + riderHeight/2` placement with deterministic rider mounting relative to the cube. Keep one anchored presentation root while allowing the rig hierarchy required for a stable jockey/frog-rider pose; all rider geometry remains non-colliding, non-touching, non-querying, and gameplay-massless. Validate scale `0.55 / 0.65 / 0.75` only in Studio; do not choose from guesswork.

## R17.3 — Mechanical-origin experiment

Do not change production origin blindly. Add a Studio-only comparison using identical cleaned shapes and resets for:

1. current first-point origin;
2. bounds-center origin;
3. deterministic geometry/reference-center candidate.

Run canonical shapes `ROUND_01`, `LONG_BAR_01`, `SMALL_ROUND_01`, `HOOK_01`, `ASYM_01`, `SUBOPTIMAL_01` through flat/steps/gap/wall/tunnel evidence. Compare opposite-leg readability, progress, completion, belly contact, stuck time, and phase stability. The experiment must not alter the network schema.

## R17.4 — Mechanical-origin migration

Only after R17.3 human evidence, record one explicit origin decision. Implement the winning deterministic server-owned origin through `LegShapeService`/pure geometry owners, keep one `ShapeSpec` duplicated to both legs, preserve point order/proportions, and update accepted-preview semantics/tests/docs consistently.

## R17.5 — Live phase-lock acceptance

Extend evidence beyond command math. Under live hinges and real contact, measure phase error over time after injected drift, redraw, and obstacle loading. Initial acceptance target:

- steady-state phase error `<=5 deg`;
- no continuous excursion `>10 deg` longer than `0.25 s` after correction has authority;
- neither motor reverses canonical locomotion sign;
- average commanded motor velocity remains the configured base value.

Exact acceptance may be refined only from observed Studio evidence, not to manufacture a pass.

## R17.6 — Body feel A/B tuning

Tune only after leg origin/phase are trustworthy. Use isolated sweeps:

1. body density: `1.00 -> 0.60 -> 0.40` candidate comparison;
2. body friction: `0.45 -> 0.25 -> 0.10` candidate comparison using the selected density;
3. body collider size: `3.0 -> 2.8 -> 2.6` only if belly scraping remains the proven limiter.

Motor defaults remain `AngularVelocity=-8`, `MotorMaxTorque=35000`, `MotorMaxAcceleration=120` during these sweeps. Motor tuning is a later step only if mass/contact evidence proves it necessary.

Studio telemetry adds trial duration, body/belly contact time, leg contact time, air time, forward distance, average speed, and stuck time so tuning is data-backed.

## R17.7 — Reference-course pass

Run the canonical shape matrix through unchanged Flat/Steps/Wall/Gap/Tunnel pieces, including live redraw during motion. Validate that different legal shapes create meaningful obstacle advantages without one universal winner, while racer movement remains primarily shape/physics driven rather than body scraping or assists.

## R17.8 — Final core human gate

Run the full server regression gate plus the consolidated R16/R17 evidence path. Human acceptance must cover:

- RMB orbit/cursor capture/return;
- rider seated presentation/readability;
- two legs visually/mechanically opposite and stable under motion/redraw/contact;
- selected mechanical origin;
- body/leg feel and belly-contact result;
- canonical obstacle matrix;
- no new DrawRacers runtime red errors.

Only after recorded Studio evidence may R17/B17 be promoted according to the project gate documents.

## Explicitly out of scope

R17 does not implement C01 track authoring, RaceService/RacerService production multiplayer flow, rewards, profile persistence, economy, cosmetics ownership, FTUE routing, bots, monetization, or 8-player product scale. Existing future architecture remains intact.
