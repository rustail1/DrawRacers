# FEATURE LIST — SCOPE SOURCE OF TRUTH v1.5.0 / MR-06

Statuses: `BACKLOG | ACTIVE | ACCEPTED | CUT | LATER`

## CR3 CURRENT OVERRIDE — canonical current state
`docs/CR3_CURRENT_SOURCE_OF_TRUTH.md` is the current mechanical owner. The active CR3 contract is **free draw** anywhere inside `DrawInputRect`, deterministic geometry-derived **support anchor** selection, explicit lower `LeftLegMount` / `RightLegMount` attachments, and two physical drive hinges commanded by a **single movement/phase owner** in `LegPairAssembly` with the same base omega and an initial 180° relation. Server authority and transactional redraw remain intact; the cowboy rider is client-only presentation.

Repository checks prove source contracts and buildability only. Live contact/solver feel, mount readability, paired motion, redraw feel, obstacle usefulness, camera/rider presentation and the product gate remain **HUMAN STUDIO PENDING**. Normal Studio `Play` remains `G0`; **B17/G0 remains HUMAN_GATE PENDING**, so M0.5/multiplayer/meta/economy/shop remain blocked until that gate or another explicit bounded Product Owner decision.

All CR2/R17 “current” wording below is retained as historical regression context and is superseded by CR3 wherever it conflicts.

## CR2 CURRENT OVERRIDE — canonical current state
`docs/CR2_CURRENT_SOURCE_OF_TRUTH.md` is the current mechanical owner. CORE REPAIR v2 keeps M0 scope unchanged but replaces the lower historical first-point/shared-axle mechanics with the **fixed visible pivot** + **twin-drive** implementation. Drawing starts near semantic `(0,0)`; `LegPairAssembly` owns persistent Left/Right `LegDriveAssembly` owners with two `DriveJoint` motors and a 180° target. The old one-motor **shared axle** topology is **retired**. Redraw stages candidate visuals while old physical geometry remains active, then collision-safe commit swaps the prepared geometry without replacing pair/drive/joint/side ownership.

This is repository/source/contract/build closure only. Live solver/contact/feel, obstacle trade-offs, camera/rider readability and empirical acceptance remain **HUMAN STUDIO PENDING**. Normal Studio `Play` remains `G0`; **B17/G0 remains HUMAN_GATE PENDING**, so M0.5/multiplayer/meta/economy/shop remain blocked until that gate or another explicit bounded Product Owner decision.

## Current milestone / canonical override
**Current milestone:** M0 — Physics Lab  
**Current gameplay feature:** Authoritative draw → physical locomotion → redraw → canonical obstacle lab → debug/tuning/reference-core evidence, implementation items **B03–B16** plus bounded R17 repair/evidence work.  
**Current implementation integrity:** R01–R12, R14.1–R14.11, R15/R15.1, R16 Stage A/B/C + R16.3B, the bounded **R17 reference-core/shared-axle/camera-rider/reference-feel overrides**, and **MR-01..MR-06 mechanical core rewrite** are present in `main` at repository level. MR-01..MR-06 are closed at source/contract/build level and the mechanical core is **READY FOR HUMAN ACCEPTANCE**; live Roblox solver/visual/human evidence remains **HUMAN STUDIO PENDING**.

Current R17/MR-06 invariants:
- R16.3B stroke origin remains: after cleanup the **first cleaned point** becomes authoritative `(0,0)` by translation only; wide `1.75:1` semantic DrawInputRect remains isotropic by height.
- `CanonicalLegShape` is the single canonical shape builder. `DrawingController` uses it for prediction, submits raw semantic points, and renders server-authoritative accepted points; `LegShapeService` is the thin server authority layer and recomputes the same canonical pipeline.
- `RacerRuntime` owns racer lifecycle/version/reshape orchestration. `LegPairAssembly` is the current mechanical owner: one **shared axle**, one `AxleRoot`, one `AxleJoint`, **one motor**, and two persistent rigid side `LegAssembly` owners.
- The rigid Left/Right copies use the same ShapeSpec and a fixed opposed relation, `RightPhaseOffsetDegrees = 180`; both rotate with the same shared motor direction/speed. There is no second side actuator and no runtime phase-chasing correction.
- Instant redraw preserves the existing pair, side owners, `AxleRoot`/`AxleJoint`, motor and current rotational phase. Only side geometry is replaced, then grows **hub-to-tip** on that stable axle through the bounded rapid reshape; BodyCollider CFrame and linear/angular velocity are not reset. No compatibility-hub, staged-pair, retiring-pair or whole-pair handoff path remains in the current mechanical core.
- Production `RaceCameraController`/`CameraMath` are active M0 owners under R17. Normal follow uses a **stable two-axis dead-zone** anchor before smoothing. Hold-RMB yaw is **full 360°**, pitch remains bounded, rendered orbit/return are smoothed, and body rotation is not camera authority.
- Production `RiderPresentationController` is active as a normalized nonphysical human rider presentation owner under R17. E03 later extends/accepts the same owner for 8-player readability; it does not introduce a duplicate rider system.
- R17.6 compares **body density**, **leg density**, **motor speed**, and optional **body friction** only on temporary Studio racers. **Production tuning remains unchanged** until human Studio evidence is reviewed; `HUMAN BODY FEEL CHOICE PENDING`.
- R17.7 retains the canonical reference-course matrix. `R17FINAL` remains an explicit one-click ordered Studio evidence route, while normal Roblox Studio `Play` uses committed **`G0`** as the fast manual CORE loop and skips automatic B03–B16/R17 startup evidence. No CI result may fabricate human acceptance.
- Studio Gate A — **HUMAN STUDIO PENDING**. Studio Gate B — **HUMAN STUDIO PENDING**. Studio Gate C — **HUMAN STUDIO PENDING**. B17/G0 remains **HUMAN_GATE PENDING**.

**Rule:** only one gameplay feature may be ACTIVE at a time. `SESSION.md` owns the evidence cursor; `25` owns implementation order. No C01 or later work may start without the required M0 human evidence and recorded B17/G0 PASS or an explicit Product Owner gate decision.

The 2026-09-10 Camera/Rider decision remains the original contract lock, but its old D09/E03-only implementation timing is superseded by the 2026-09-11 R17 Product Owner overrides. D09/E03 remain later multiplayer/readability extension-and-acceptance tasks for the already-existing `RaceCameraController` and `RiderPresentationController`; they are not duplicate implementations. The 2026-09-12 phase/default decisions supersede the intermediate 0°/R17FINAL-default interpretation without changing this scope. The 2026-09-13 MR-01..MR-06 rewrite supersedes the old duplicated/staged mechanical implementation details without expanding WHAT/WHY scope.

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
- CLOSED / MR-01..MR-06 MECHANICAL CORE REWRITE — one canonical builder, persistent pair/axle/joint/side owners, direct hub-to-tip redraw path; repository/static/build closure is GREEN and status is **READY FOR HUMAN ACCEPTANCE**; human G0 remains pending.
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
