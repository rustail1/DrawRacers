# FEATURE LIST — SCOPE SOURCE OF TRUTH v1.6.0 / CORE V3

Statuses: `BACKLOG | ACTIVE | ACCEPTED | CUT | LATER`

## Current milestone — M0 Core V3 Flat Physics
**ACTIVE. HUMAN PHYSICS PENDING.**

Current product invariant: drawing is locomotion. The current mechanical contract is `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`.

Current Core V3 invariants:
- free draw in DrawInputRect; authoritative first-cleaned-point translation anchor;
- one shared axle;
- exactly one HingeConstraint/motor owner;
- LEFT -Z / RIGHT +Z; fixed 180° relation;
- X/Y physical freedom; approved Z lane-plane lock + upright stabilization;
- no normal +X helper;
- redraw `PREVIEW -> WAIT_CLEAR -> ACTIVE`, fail-closed;
- accepted ShapeVersion commits only after true ACTIVE;
- C01–C07 automated Studio suite;
- isolated human flat mode before obstacles.

Current next task: implement/validate the dedicated 2.5D lane/upright owner, then rerun C01–C07 and the human ROUND flat test.

**Hard gate:** M0.5/multiplayer/meta/economy/shop remain blocked until the Core V3 Flat Gate is human-accepted or the Product Owner records another explicit bounded decision.

## Bootstrap
- ACCEPTED — filesystem/Rojo project baseline.
- ACCEPTED — shared/server/client roots.
- ACCEPTED — current drawing pipeline and Core V3 isolated harness modes.

## M0 — Core V3 Flat Physics
- ACCEPTED — DrawCanvas input + local preview.
- ACCEPTED — server-authoritative shape pipeline.
- ACTIVE — one shared axle / one hinge / opposed side legs.
- ACTIVE — transactional redraw + clearance + fail-closed result path.
- ACTIVE — C01–C07 regression suite.
- ACTIVE / NEXT — Z lane-plane lock + upright stabilization without forward assist.
- HUMAN GATE — ROUND, reference shape suite, 20 moving redraws.

## M0.5 — Adaptation Acceptance
- BACKLOG — Mixed adaptation test track using `60` geometry
- BACKLOG — Shape-suite protocol
- BACKLOG — Universal-shape failure check
- BACKLOG — G1 record

## M1 — 2-Player Rival Slice
- BACKLOG — TrackPiece contract + TrackBuilder using `30/60`
- BACKLOG — Race state machine
- BACKLOG — Ordered checkpoints / finish authority
- BACKLOG — 2 isolated lanes / no racer collision
- BACKLOG — Rival shape visibility
- BACKLOG — 2-player camera/HUD matching `59`
- BACKLOG — D09 extend current stable Local-Racer `RaceCameraController` for rival readability without replacing the R17 owner (`16/21/25/59/68`)
- BACKLOG — Fast rematch
- BACKLOG — Network/security tests + G2

## M2 — 8-Player Product Vertical Slice
- BACKLOG — 8 lane scaling
- BACKLOG — STAGING two-place provisioning (`64/70`)
- BACKLOG — First 10 authored tracks T01–T10 from `60/67`
