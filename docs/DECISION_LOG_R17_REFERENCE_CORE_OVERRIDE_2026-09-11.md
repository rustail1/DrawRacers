# Decision Log — R17 Reference-Core Override

Date: 2026-09-11  
Status: **APPROVED PRODUCT OWNER OVERRIDE / HUMAN EVIDENCE PENDING**  
Approved design: `docs/superpowers/specs/2026-09-11-r17-reference-core-design.md`

## Decision

Before B17/G0 can be accepted, DrawRacers will run the ordered **R17 reference-core parity pass**. R17 exists to make the current drawing/physics/presentation core behave and read closer to the observable Draw Climber reference before the project expands into M0.5, multiplayer scale, meta, economy, persistence, or monetization.

This is an explicit Product Owner sequence override. It supersedes the older wording that kept production camera/rider implementation strictly at D09/E03, but it does **not** promote any human Studio gate and does not authorize unrelated C01+ product systems.

## Ordered R17 sequence

1. **R17.0 Contract Reconcile** — record current production presentation ownership and this sequence override.
2. **R17.1 Desktop Camera Input** — reliable hold-RMB bounded orbit, cursor capture/restore, smooth return; LMB remains drawing.
3. **R17.2 Rider Mount/Pose** — deterministic nonphysical jockey/rodeo presentation.
4. **R17.3 Mechanical-Origin Experiment** — compare current first-point vs bounds-center vs deterministic geometry/reference-center using identical shapes/resets and Studio evidence.
5. **R17.4 Mechanical-Origin Migration** — only after R17.3 human evidence, record and implement one explicit authoritative origin decision.
6. **R17.5 Live Phase Lock** — prove 180-degree anti-phase under live hinges, redraw, and obstacle contact rather than command math alone.
7. **R17.6 Body Feel A/B** — isolate body density, friction, then collider-size sweeps; do not change motor tuning in the same sweep.
8. **R17.7 Reference Course Pass** — canonical shape matrix across unchanged flat/steps/wall/gap/tunnel with live redraw.
9. **R17.8 Final Core Human Gate** — consolidated server regressions + R16/R17 Studio/reference-feel acceptance.

B17 remains HUMAN_GATE PENDING until R17.8 evidence is recorded or a later explicit Product Owner decision changes that gate.

## Camera/rider ownership override

`RaceCameraController` and `CameraMath` already exist and are now authorized as the current M0 production camera owner/math under R17. D09 is therefore no longer the first introduction of the camera system; D09 later extends/accepts this same owner for the real 2-player rival slice.

`RiderPresentationController` already exists and is now authorized as a **provisional M0 presentation owner** under R17. It remains human-visual-acceptance pending. E03 later extends/accepts the same rider owner for the 8-player readability case; no second rider system is authorized.

This override does not move `RacerService`: production `RacerService` remains D05. M0 continues using the existing Studio-only resolver/harness boundary.

## R17.1 desktop camera contract

- LMB remains drawing and is never the camera orbit toggle.
- Hold RMB with an eligible Local Racer starts bounded camera orbit when world-camera ownership is allowed.
- Project UI/DrawCanvas and focused text input block camera claim.
- Eligible RMB may still be claimed when Roblox/CoreScripts mark the event `gameProcessed`; a blanket early return may not make production RMB orbit unreachable.
- When RMB orbit starts, save the previous `UserInputService.MouseBehavior` and use `LockCurrentPosition` so cursor travel does not run out at the screen edge.
- RMB release restores the exact saved mouse behavior and begins the existing smooth `0.40 s` return to canonical side view; release must not snap yaw/pitch to zero.
- Window focus loss, controller destroy, local-racer loss while held, and current-camera loss while held also restore mouse state so the cursor cannot remain trapped.
- Touch ownership rules remain unchanged by R17.1.
- Camera remains client-only; no camera RemoteEvent/RemoteFunction is added.

## Mechanical-origin boundary

R16.3B **first-cleaned-point -> `(0,0)` remains the current production mechanical origin during R17.0–R17.3**. This Decision Log authorizes a controlled comparison; it does not silently switch production to bounds-center or centroid.

Only R17.3 Studio evidence plus an explicit R17.4 Product Owner decision may supersede the production origin. Any migration must remain deterministic/server-owned, preserve one accepted shape duplicated to two legs, and keep the current network envelope unless separately approved.

## Phase boundary

The current bounded runtime phase correction remains provisional implementation evidence. R17.5 must prove actual phase convergence/stability under Roblox solver contact. Static/command-level GREEN alone does not close the phase feel gate.

## Body-feel tuning boundary

Current body and motor defaults stay unchanged until their ordered R17 steps. R17.6 starts by changing one variable family at a time:

- body density candidates: `1.00`, `0.60`, `0.40`;
- body friction candidates: `0.45`, `0.25`, `0.10` after density selection;
- body collider candidate sizes: `3.0`, `2.8`, `2.6` only if belly contact remains the proven limiter.

During these sweeps the leg motor remains `AngularVelocity=-8`, `MotorMaxTorque=35000`, `MotorMaxAcceleration=120`. Motor tuning is not an allowed shortcut for an unproven mass/pivot/contact problem.

## Preserved invariants

Unchanged unless a later ordered R17 decision explicitly says otherwise:

- server-authoritative accepted stroke validation and ShapeSpec;
- network request envelope `{sequence, points}`;
- exactly two physical legs from one accepted shape;
- no visual-only leg geometry that lies about authoritative collision shape;
- rider is presentation-only and cannot affect racer physics or race authority;
- camera is presentation-only and local;
- no hidden +X force or scripted +Y lift to fake reference feel;
- no cosmetic competitive physics effects;
- Rojo filesystem remains source of truth;
- no C01+, multiplayer-service, meta, economy, persistence or monetization scope under R17.

## Evidence rule

CI/Rokit/Rojo may prove repository/build contracts only. Roblox solver behavior, RMB camera feel, rider pose/readability, mechanical-origin reference feel, phase stability, body mass/contact feel, and B17/G0 acceptance remain **HUMAN STUDIO PENDING** until supplied evidence proves them.

Where older `16`, `21`, `25`, `SESSION` or the 2026-09-10 camera/rider Decision Log says camera/rider must remain future-only at D09/E03, **this R17 Decision Log is the newer explicit Product Owner override**. Those documents should be reconciled as R17 progresses; this Decision Log controls in the event of sequence wording conflict.
