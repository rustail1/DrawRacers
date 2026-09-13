# FEATURE LIST — SCOPE SOURCE OF TRUTH v1.4.7 / R17

Statuses: `BACKLOG | ACTIVE | ACCEPTED | CUT | LATER`

## Current milestone / canonical override
**Current milestone:** M0 — Physics Lab  
**Current gameplay feature:** Authoritative draw → physical locomotion → redraw → canonical obstacle lab → debug/tuning/reference-core evidence, implementation items **B03–B16** plus bounded R17 repair/evidence work.  
**Current implementation integrity:** R01–R12, R14.1–R14.11, R15/R15.1, R16 Stage A/B/C + R16.3B, and the bounded **R17 reference-core/shared-axle/camera-rider/reference-feel overrides** are present in `main` at repository level. Live Roblox solver/visual/human evidence remains **HUMAN STUDIO PENDING**.

Current R17 invariants:
- R16.3B stroke origin remains: after cleanup the **first cleaned point** becomes authoritative `(0,0)` by translation only; wide `1.75:1` semantic DrawInputRect remains isotropic by height.
- `LegPairAssembly` is the current mechanical owner: one **shared axle**, one `AxleRoot`, one `AxleJoint`, **one motor**, two rigid side `LegAssembly` objects.
- The rigid Left/Right copies use the same ShapeSpec and a fixed opposed relation, `RightPhaseOffsetDegrees = 180`; both rotate with the same shared motor direction/speed. There is no second side actuator and no runtime phase-chasing correction.
- Production `RaceCameraController`/`CameraMath` are active M0 owners under R17. Normal follow uses a **stable two-axis dead-zone** anchor before smoothing. Hold-RMB yaw is **full 360°**, pitch remains bounded, rendered orbit/return are smoothed, and body rotation is not camera authority.
- Instant redraw preserves the existing `AxleRoot`/`AxleJoint`, motor and current rotational phase. Only side geometry is replaced, then grows **hub-to-tip** on that stable axle through the bounded rapid reshape; BodyCollider CFrame and linear/angular velocity are not reset. Collision-safe phase search is initial-spawn safety only, not redraw behavior.
- Production `RiderPresentationController` is active as a normalized nonphysical human rider presentation owner under R17. E03 later extends/accepts the same owner for 8-player readability; it does not introduce a duplicate rider system.
- R17.6 compares **body density**, **leg density**, **motor speed**, and optional **body friction** only on temporary Studio racers. **Production tuning remains unchanged** until human Studio evidence is reviewed; `HUMAN BODY FEEL CHOICE PENDING`.
- R17.7 retains the canonical reference-course matrix. `R17FINAL` remains an explicit one-click ordered Studio evidence route, while normal Roblox Studio `Play` now uses committed **`G0`** as the fast manual CORE loop and skips automatic B03–B16/R17 startup evidence. No CI result may fabricate human acceptance.
- Studio Gate A — **HUMAN STUDIO PENDING**. Studio Gate B — **HUMAN STUDIO PENDING**. Studio Gate C — **HUMAN STUDIO PENDING**. B17/G0 remains **HUMAN_GATE PENDING**.

**Rule:** only one gameplay feature may be ACTIVE at a time. `SESSION.md` owns the evidence cursor; `25` owns implementation order. No C01 or later work may start without the required M0 human evidence and recorded B17/G0 PASS or an explicit Product Owner gate decision.

The 2026-09-10 Camera/Rider decision remains the original contract lock, but its old D09/E03-only implementation timing is superseded by the 2026-09-11 R17 Product Owner overrides. D09/E03 remain later multiplayer/readability extension-and-acceptance tasks for the already-existing `RaceCameraController` and `RiderPresentationController`; they are not duplicate implementations. The 2026-09-12 phase/default decisions supersede the intermediate 0°/R17FINAL-default interpretation without changing this scope.

## Bootstrap — required before M0
- ACCEPTED — A01 Git/Rojo baseline
- ACCEPTED — A02 shared/server/client roots
- ACCEPTED — A03 M0 scene
- ACCEPTED — A04 deployment registry + exact Studio root contract (`64/65/70`)

## M0 — Physics Lab
- ACCEPTED — DrawCanvas input + stroke preview (`59` layout; B01+B02)
- ACTIVE / IMPLEMENTED — B03–B16 core locomotion/redraw/obstacle/debug pipeline.
- CLOSED / REPAIR COMPLETE — R01–R12 implementation-integrity series.
- CLOSED / IMPLEMENTATION-REGRESSION-CI-DOCS — R14.1–R14.11 runtime/tooling/evidence closure; Studio checkpoints: HUMAN PENDING.
- CLOSED / HISTORICAL FOUNDATION — R15.1 mechanical `PlaneConstraint` Z lock; its historical free-world-Z orientation detail is superseded by R16.1.
- ACTIVE / R16 Stage A / R16.1–R16.4 IMPLEMENTED; Studio Gate A — HUMAN STUDIO PENDING.
- ACTIVE / R16 Stage B / R16.5–R16.7 IMPLEMENTED/AUTOMATED GREEN; Studio Gate B — HUMAN STUDIO PENDING.
- ACTIVE / R16 Stage C / R16.8–R16.10 IMPLEMENTED/AUTOMATED GREEN; Studio Gate C — HUMAN STUDIO PENDING.
- ACTIVE / R16.3B retained stroke-origin/reference-parity contract; HUMAN STUDIO PENDING.
- ACTIVE / R17 reference-core implementation — origin comparison evidence, one shared axle with fixed **180°** rigid sides, stable two-axis dead-zone camera, stable-phase rapid **hub-to-tip** redraw reshape, isolated body/leg/motor/friction evidence, reference-course matrix, normalized rider presentation, explicit `R17FINAL` evidence mode, and **G0 manual CORE as the committed Studio default**.
- BACKLOG / HUMAN_GATE — B17/G0; **hard stop before M0.5** and still required after local technical Studio review.

## Historical implementation/evidence record retained for regressions
The following historical facts remain intentionally present because repository regressions assert them and later work depends on the same boundaries:

### R01–R12
- R01 geometry authority; R02 drawing/network correctness; R03 physics contract; R04 debug correctness; R05 selectable G0 Studio integration; R06 docs consistency; R07 review fixes; R08 final core closure; R09–R12 bounded bug sweep.
- pre-R06: **66 passed, 0 failed**.
- R08/R09 repair line retained; R09 bounded repair: **80 passed, 0 failed**.
- R10/R11/R12 final code head `e2bedd34696bb99da43878c19d7984c9134c8bef`, run `34363706915` → **88 passed, 0 failed**.

### R14.1–R14.11
- Authoritative accepted preview, Studio gate runner, collision contract, bounded pending/network failure, recovery, atomic rollback, validation UX, pinned CI/Rojo build, shared types/remotes and docs/evidence reconciliation.
- Historical code/tooling head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626` → **120 passed, 0 failed**, successful **Rojo build**.
- Studio checkpoints: HUMAN PENDING. B17/G0 remains HUMAN_GATE.

### R15/R15.1 hard 2.5D foundation
- First force-based R15 Studio attempt failed despite automation: live `laneDeviation 5.199`.
- R15.1 production moved the Z lock to `PlaneConstraint` while X/Y remain physical.
- R15.1 automated evidence head `be44304bf00391e05c7d7750609730a7368ebc87`, run `34394991926` → **125 passed, 0 failed**, successful Rojo build.
- R15.1 remains **HUMAN STUDIO PENDING** historically; R16.1 superseded only its old free-Z-rotation detail.

### R16 Stage A / R16.3B
- R16.1 upright body: world X/Y/Z rotation locked/corrected while X/Y translation remains physical and Z remains lane-plane locked.
- R16.2 hub offsets remain owned by `PhysicsConfig.LegGeometry`.
- R16.3B supersedes R16.3A bounds-center semantics: the **first-point / first cleaned point** becomes mechanical origin `(0,0)` by translation only; no shape-size normalization, mirror or hidden spoke.
- Historical R16.4 target was 180° twin-leg phase. An intermediate R17 shared-axle interpretation changed the rigid relation to 0°. The 2026-09-12 reference correction supersedes that intermediate interpretation and restores the current fixed **180°** relation on the one-axle/one-motor architecture.
- Stage-A historical repository head `81c7d84c542160f07fc4fe986df89e5aa69f8f73`, run `34448666472` → **142 passed, 0 failed**.

### R16 Stage B
- **R16.5–R16.7 IMPLEMENTED/AUTOMATED GREEN** historically: flat-speed measurement, solver-owned Y evidence and full reference-shape comparative matrix.
- Historical Stage-B head `2197882e4c641e7c1d17a6dfc538f23fd1a521e6`, run `34451426807` → **145 passed, 0 failed**, Rokit install PASS and **Rojo build PASS**.
- Studio Gate B — HUMAN STUDIO PENDING.

### R16 Stage C
**R16 Stage C implementation authorized by Product Owner** on 2026-09-10.
- **R16.8–R16.10 IMPLEMENTED/AUTOMATED GREEN** historically: moving redraw parity, side presentation/observer isolation, canonical Wall + obstacle pass.
- Historical R16.10 code head `3838a994f5b5164b64f3cdee934e5bc84f7be7a4`, run `34454820796` → **149 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**.
- Studio Gate A — HUMAN STUDIO PENDING. Studio Gate B — HUMAN STUDIO PENDING. Studio Gate C — HUMAN STUDIO PENDING.
- **R16.11 must not freeze** before Studio Gate C is actually recorded. Under R17, final evidence freeze must also include the current shared-axle/180° relation/camera/rider/origin/body-feel decisions.

### R17 current reference-core repair/evidence
- R17.3 — Studio-only origin comparison retains production first-point origin until a human decision explicitly changes it.
- R17.5 — shared-axle evidence verifies exactly one hinge/motor, structural **180° Left↔Right opposition**, same motor direction/speed, and redraw axle continuity.
- R17.6 — body density `{1.00, 0.60, 0.45, 0.35}`, leg density `{1.00, 0.60, 0.40}`, motor speed `{-8.0, -10.0, -11.5, -12.5}`, and body friction `{0.45, 0.25, 0.10}` are isolated evidence candidates on temporary racers. **Production tuning remains unchanged**; `HUMAN BODY FEEL CHOICE PENDING`.
- R17.7 — canonical reference-course matrix reuses the existing trial runner for Flat/Steps/Wall/Gap/Tunnel across the reference shape set.
- R17.8 — `R17FINAL` remains an explicit ordered R16 Stage-C + R17 evidence mode before human review handoff; it is **not** the normal Play default. Normal Play uses `G0` for direct CORE iteration.
- R17.9 — `RaceCameraController` supports a stable two-axis dead-zone normal follow, full 360 yaw target, bounded pitch and smoothed rendered orbit/return.
- R17.10–R17.14 — `LegPairAssembly` owns one shared axle/`AxleJoint`/motor, fixed **180°** rigid sides and the safe socket/collision contract. Redraw preserves that axle and current phase while replacement side geometry performs a bounded rapid **hub-to-tip** reshape; no whole-pair redraw phase search or per-side phase-chasing owner remains.
- Human camera feel, rigid-leg visual/solver behavior, rider pose/readability, origin/body-feel choice and B17 remain **HUMAN STUDIO PENDING**.

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
- BACKLOG — E03 extend/accept current normalized nonphysical human `RiderPresentationController` for 8-player readability (`21/25/62/65/68`)
- BACKLOG — FTUE
- BACKLOG — Lineup/results/podium exact UI from `59`
- BACKLOG — One-tap requeue
- BACKLOG — Canonical profile/save lifecycle
- BACKLOG — Coins + RewardService with `61` starting table
- BACKLOG — Cosmetic inventory/equip
- BACKLOG — Atomic Coin catalog purchase (`71`)
- BACKLOG — First vertical-slice subset of `62` launch catalog
- BACKLOG — Visible status basics
- BACKLOG — Analytics funnels/events
- BACKLOG — Audio/VFX/haptic semantic presentation (`47/68/69/70`)
- BACKLOG — Settings/accessibility/rival-shape safety controls (`37/39/68`)
- BACKLOG — Mobile performance/network pass + G3

## M3 — Alpha Product Loop / PUBLIC-LAUNCH CONTENT
All items below remain required before public release, not optional polish.
- BACKLOG — Complete T01–T20 authored tracks and both launch themes (`60/62/67/69`)
- BACKLOG — Mastery Points, access tiers and visible titles (`61`)
- BACKLOG — Garage/collection final layout (`59`) and catalog (`62`)
- BACKLOG — First-session ownership pacing using `61`
- BACKLOG — Required cold-start Bot Fill (`40/74/75`)
- BACKLOG — Full 20 produced launch cosmetics + Trail_None (`62/69/70`)
- BACKLOG — Launch audio/VFX set (`47/62`)
- BACKLOG — G4 session/rematch record
- BACKLOG — Admin/observability (`34`)
- BACKLOG — Save/migration/handoff fault matrix (`31/24`)
- BACKLOG — Content registry/provenance binding (`36/48/69/70`)
- BACKLOG — G5 free cosmetic/status desire record

## M4 — Monetization / Soft Launch
- BACKLOG — Three launch Pass SKUs from `61/62`
- BACKLOG — Contextual Starter Style offer
- BACKLOG — Post-purchase theatre
- BACKLOG — Pass entitlement reconciliation (`71`)
- BACKLOG — `56` receipt/idempotency implementation/tests if any Developer Product is enabled
- BACKLOG — Monetization analytics
- BACKLOG — Discovery creative A/B/C from `62` + G6
- BACKLOG — Price/offer experiments after sufficient sample
- LATER — Coin Developer Products activation (predefined but disabled until G5 + explicit enable decision)

## M5 — Release / LiveOps Foundation
- BACKLOG — Config-driven public course rotation
- BACKLOG — Cosmetic collection configs
- BACKLOG — Standard LiveOps event constructor/config path
- BACKLOG — Measurement-contract workflow / rollback
- BACKLOG — First 30-day content buffer implementation (`76`)
- BACKLOG — PROD two-place/SKU/asset provisioning (`64/70`)
- BACKLOG — Production release checklist / rollback drill
- BACKLOG — Final device/performance matrix
- BACKLOG — Localization/accessibility pass
- BACKLOG — Safety/moderation pass
- BACKLOG — IP/name/asset provenance clearance
- BACKLOG — G7 content-production record when applicable

## LATER — explicit post-release / data-dependent scope
- LATER — friend/party quality layer
- LATER — private-server-specific features
- LATER — rewarded video
- LATER — subscription
- LATER — seasonal paid progression
- LATER — ranked season/tournament
- LATER — procedural/endless generator
- LATER — console/gamepad drawing UX
- LATER — VictoryPose/PodiumFX category beyond launch FinishFX
- LATER — paid random items

## Explicit CUT unless new Product Owner Decision
- CUT — paid speed/torque/grip/radius/hitbox/redraw advantage
- CUT — racer-vs-racer physical collisions
- CUT — combat/weapons
- CUT — free-form public drawing/art publishing
- CUT — pets as stat power
- CUT — rebirth/stat simulator
- CUT — mandatory gacha
- CUT — giant lobby delaying first race
- CUT — battle pass before explicit post-launch need

## Production completeness — release blockers
Every item must be ACCEPTED or explicitly CUT by Product Owner Decision before public release:
- BACKLOG — Save migrations/recovery (`31`)
- BACKLOG — Security threat-model pass (`32`)
- BACKLOG — 8-player performance/device matrix (`33/57`)
- BACKLOG — Rival drawing safety controls (`39`)
- BACKLOG — Release/rollback playbook validation (`35`)
- BACKLOG — Localization/accessibility (`37/59`)
- BACKLOG — Discovery creative pack (`38/62`)
- BACKLOG — UI screenshot matrix (`59`)
- BACKLOG — Exact launch TrackPiece/content validation (`60`)
- BACKLOG — Economy/progression table implementation (`61`)
- BACKLOG — Launch art/content manifest complete (`62/69/70`)
- BACKLOG — Empirical gates G0–G7 as required (`55`)
- BACKLOG — Coin catalog + Pass entitlement transaction tests (`71`)
- BACKLOG — Developer Product receipt tests if enabled (`56`)
- BACKLOG — Current final documentation audit (`78`) remains PASS after any spec change

Any unlisted feature requires a scope decision before documentation/implementation.

## R16 PRE-STUDIO CLOSURE P0–P6
**Historical repository closure record; Studio acceptance remains pending.**

P0–P6 record the bounded pre-Studio repair sequence: P0 plan/contract reconciliation under the then-current R16.3A centering rule; P1 real elapsed B10 recovery timing; P2 isolated flat benchmark; P3 real below-kill-Y recovery evidence; P4 shared full six-shape matrix with winner-set intersection; P5 Wall suitable-success plus SUBOPTIMAL negative-control proof with dedicated WallContactTimeout preserved; P6 repository status/decision reconciliation and full CI/toolchain verification. R16.3B supersedes only the old shape-origin/input-surface semantics; R17 supersedes the old two-independent-motor and presentation-timing details while preserving the evidence trail. The 2026-09-12 phase correction changes only the current structural side relation to 180° on the same shared axle.

**Studio Gate A — HUMAN STUDIO PENDING**  
**Studio Gate B — HUMAN STUDIO PENDING**  
**Studio Gate C — HUMAN STUDIO PENDING**  
**B17/G0 — HUMAN_GATE PENDING**

`AUTOMATED GREEN` may be recorded only from a fresh successful current-head CI/toolchain run and never marks any Studio or external human gate PASS.