# FEATURE LIST — SCOPE SOURCE OF TRUTH v1.4.2

Statuses: `BACKLOG | ACTIVE | ACCEPTED | CUT | LATER`

**Current milestone:** M0 — Physics Lab  
**Current gameplay feature:** Authoritative draw → physical locomotion → redraw → canonical obstacle lab → debug/tuning pipeline, implementation items **B03–B16**.  
**Current implementation integrity:** bounded CORE/pre-G0 repair **R01–R12**, runtime/evidence closure **R14.1–R14.11**, planar correction **R15/R15.1**, R16 Stage A **R16.1–R16.4**, Stage B **R16.5–R16.7**, and Stage C **R16.8–R16.10** are implemented in `main` at repository level. **R16.8–R16.10 are IMPLEMENTED/AUTOMATED GREEN**, while live Roblox solver/visual evidence remains **HUMAN STUDIO PENDING**. Studio Gate A and Studio Gate B were not retroactively passed; the Product Owner explicitly authorized bounded Stage-C implementation before the next Roblox Studio launch.  
**Current R16 contract:** X/Y translation remains physical, Z translation remains mechanically lane-locked, and body rotation about world X/Y/Z is upright constrained; specifically **rotation about world Z: locked/corrected**. R16.2 owns hub offsets in `PhysicsConfig.LegGeometry`. R16.3A converts cleaned input to a **centered authoritative shape** by bounds translation only (no resize/mirror/rotation), and one ShapeSpec is duplicated to both legs; R16.4 retains the 180° twin-leg phase contract. Stage B adds solver measurement; Stage C adds repeated moving redraw verification, reference-side presentation, Wall evidence, and the aggregate canonical `R16C` harness without changing obstacle geometry.  
**Historical evidence retained:** pre-R06 **66 passed, 0 failed**; R09 repair **80 passed, 0 failed**; final R10–R12 code head `e2bedd34696bb99da43878c19d7984c9134c8bef` / run `34363706915` verified **88 passed, 0 failed**. Final R14 code/tooling head `8a6a05a31427346d2a1437820ffa759f21fca90c` / run `34387618626` verified **120 passed, 0 failed** plus successful **Rojo build**. The first R15 force-based implementation passed automation but failed real Studio with `laneDeviation 5.199`. R15.1 mechanical-plane production head `be44304bf00391e05c7d7750609730a7368ebc87` / run `34394991926` verified **125 passed, 0 failed** plus successful **Rojo build**. Stage-A repository head `81c7d84c542160f07fc4fe986df89e5aa69f8f73` / run `34448666472` verified **142 passed, 0 failed**. Stage-B implementation head `2197882e4c641e7c1d17a6dfc538f23fd1a521e6` / run `34451426807` verified **145 passed, 0 failed** plus Rokit and **Rojo build PASS**. Final R16.10 code head `3838a994f5b5164b64f3cdee934e5bc84f7be7a4` / run `34454820796` verified **149 passed, 0 failed**, Rokit install PASS and **Rojo build PASS**.  
**Current gate:** **R16 Stage C — Studio Gate C — HUMAN STUDIO PENDING**; **Studio Gate A — HUMAN STUDIO PENDING** and **Studio Gate B — HUMAN STUDIO PENDING** also remain pending because implementation progression was explicitly overridden for implementation, not acceptance. Historical B17/G0 remains the downstream **HUMAN_GATE** after R16 Studio evidence; implementation/CI/Rojo build alone do not promote B03–B16 to ACCEPTED.  
**Acceptance note:** A01–A04 and B01–B02 remain recorded ACCEPTED.  
**Rule:** only one gameplay feature may be ACTIVE at a time. `SESSION.md` owns the evidence cursor; `25` owns implementation order. No C01 or later work may start without ordered R16 Studio evidence and recorded B17/G0 PASS or an explicit Product Owner gate decision.

## Bootstrap — required before M0
- ACCEPTED — A01 Git/Rojo baseline
- ACCEPTED — A02 shared/server/client roots
- ACCEPTED — A03 M0 scene
- ACCEPTED — A04 deployment registry + exact Studio root contract (`64/65/70`)

## M0 — Physics Lab
- ACCEPTED — DrawCanvas input + stroke preview (`59` layout; B01+B02)
- ACTIVE / IMPLEMENTED — B03–B16 core locomotion/redraw/obstacle/debug pipeline.
- ACTIVE / REPAIR COMPLETE, STUDIO EVIDENCE PENDING — R01–R08 implementation-integrity repair series.
- CLOSED / IMPLEMENTATION-REGRESSION — R09–R12 pre-G0 findings; retained in B17 only as runtime verification points.
- CLOSED / IMPLEMENTATION-REGRESSION-CI-DOCS — R14.1–R14.11 pre-G0 runtime/tooling/evidence closure; Studio checkpoints remain HUMAN PENDING.
- CLOSED / SUPERSEDED ORIENTATION DETAIL — R15.1 hard 2.5D lane-plane correction remains the Z-lock foundation; its free-world-Z orientation detail is superseded by R16.1.
- **ACTIVE / R16 Stage A / R16.1–R16.4 IMPLEMENTED-AUTOMATED GREEN; Studio Gate A — HUMAN STUDIO PENDING** — upright body, canonical hubs, R16.3A centered authoritative shape, and 180° twin-leg phase.
- **ACTIVE / R16 Stage B / R16.5–R16.7 IMPLEMENTED/AUTOMATED GREEN; Studio Gate B — HUMAN STUDIO PENDING** — single-owner leg material config and ROUND flat measurement, solver-owned Y evidence on Steps/Gap, full canonical reference-shape registry and comparative matrix.
- **ACTIVE / R16 Stage C / R16.8–R16.10 IMPLEMENTED/AUTOMATED GREEN; Studio Gate C — HUMAN STUDIO PENDING** — 10 moving redraws, reference-side G0 presentation, observer hiding, Wall evidence, and aggregate `R16C` canonical pass harness. Product Owner authorized Stage-C implementation before the next Studio run; this is not a Studio PASS.
- BACKLOG / HUMAN_GATE — B17/G0; **hard stop before M0.5** and still required after R16 completion.

### R01–R12 implementation-integrity record
- **R01** — one `GeometryMath` plan owner + authoritative ShapeSpec→LegAssembly path; square semantic drawing surface prevents aspect-ratio physics distortion.
- **R02** — bounded semantic sampling independent of input event rate; local minimum validation; server-truth accepted-result ordering.
- **R03** — full collision matrix, no forward propulsion from stabilization, canonical runtime track root, TopY-relative tunnel geometry. Its older orientation detail is superseded by R16.1 upright-body parity.
- **R04** — real collider/simplified-point telemetry, progress-window stuck semantics, deterministic debug target selection.
- **R05** — one selectable Studio interactive harness; default `G0`; Studio-only injected Player→RacerRuntime mapping uses existing stroke transport and does not implement D05 RacerService.
- **R06** — status/README/decision evidence reconciled to the G0 hard stop without promoting Studio acceptance.
- **R07** — strict B12 outer payload validation/rate work-ordering; complete B16 raw/physics/motor telemetry and DEV/STAGING gating; square semantic surface ownership tightened.
- **R08** — touch layout switches only between strokes; normal Roblox Character isolated before G0 racer spawn; server minimum useful extent `0.7`; bounded actual-contact anti-stall on canonical flat/recovery semantics with `antiStallActive` telemetry.
- **R09 — CLOSED** — accepted preview stores semantic coordinates so responsive changes cannot distort it; exact touch ValidationToast/DrawHint tokens from `59`; obstacle RequirementTag overrides recovery assist; spawned racer removes empty template-only `RuntimeAttachments` after attachment transfer.
- **R10 — CLOSED** — accepted preview thickness follows active pointer only during drawing and the current layout otherwise; `EmptyGhost` stays hidden after first pointer-down; `ValidationToast` is mutually exclusive with `DrawHint` and auto-hides within 2.0 s; unsupported LastInputType values cannot force desktop layout.
- **R11 — CLOSED** — hybrid LastInputType changes do not overwrite live-stroke layout intent; live preview points/Frames stay bounded by the existing stroke budget via compaction.
- **R12 — CLOSED** — long/noisy semantic strokes compact at the cap instead of freezing so later geometry still contributes; G0 Character respawn isolation does not re-enable retired Character collision/query/touch.

### R14.1–R14.11 pre-G0 runtime/evidence closure record
- **R14.1 Shape parity — CLOSED code/contract** — accepted preview uses server-authoritative accepted points; B12 Studio spec compares result geometry to current ShapeSpec.
- **R14.2 G0 presentation — CLOSED code/contract** — Studio-only non-physical camera/proxy harness, with no early `RaceCameraController` implementation.
- **R14.3 Studio gate runner — CLOSED code/contract** — aggregated spec failures drive `TESTING/BLOCKED/READY`; injected fail→BLOCKED→restore→READY observation remains HUMAN PENDING in Studio.
- **R14.4 Collision Default — CLOSED code/contract** — Default collision semantics cannot push RacerBody/RacerLeg; Studio physics observation remains HUMAN PENDING.
- **R14.5 Network pending/failure — CLOSED code/contract** — count/time bounded pending strokes, late trusted accepts supported, server exceptions contained.
- **R14.6 Recovery — CLOSED code/contract** — kill-Y recovery resets the same RacerRuntime to canonical spawn and preserves authoritative ShapeSpec/ShapeVersion; gap/fall Studio observation remains HUMAN PENDING.
- **R14.7 Atomic commit rollback — CLOSED regression** — injected partial-commit and post-commit enable failures restore prior accepted legs and remove staged/retiring state.
- **R14.8 Validation UX — CLOSED code/contract** — geometry errors map to `DRAW A DIFFERENT SHAPE`; transport/technical failures map to `TRY AGAIN`; final Studio visual/timing acceptance remains HUMAN PENDING.
- **R14.9 CI Rojo build — CLOSED CI** — GitHub Actions installs the pinned toolchain and executes a real Rojo build after contract checks.
- **R14.10 Types/RemoteNames — CLOSED code/contract** — shared StrokeTypes are consumed on active network/ShapeSpec runtime boundaries; active remote consumers and B12 Studio coverage use shared RemoteNames.
- **R14.11 Docs/evidence reconciliation — CLOSED repository** — root/status/decision docs retain final code/tooling head `8a6a05a31427346d2a1437820ffa759f21fca90c`, run `34387618626`, **120 passed, 0 failed**, successful **Rojo build**, while preserving **Studio checkpoints: HUMAN PENDING** and **B17/G0 HUMAN_GATE**.

### R15/R15.1 hard 2.5D planar racer physics — historical foundation
- **R15.1 — IMPLEMENTED/AUTOMATED GREEN; HUMAN STUDIO PENDING** — X/Y remain the physical gameplay plane and Z translation is mechanically locked to lane center by `PlaneConstraint`.
- First R15 human Studio attempt **FAILED** despite `13 PASS / 0 FAIL` and READY: live debug reached `laneDeviation 5.199` and the racer visibly travelled sideways. The old B10 was property-heavy/anchored and did not exercise real lateral solver behavior.
- Owner remains `RacerStabilizer`; no `AlignPosition`, no side walls, no new movement service, no normal-operation CFrame/PivotTo correction, and no stabilizer +X propulsion.
- Starting diagnostics/tuning: `LaneNormalError = 0.03`, `LaneHardBound = 0.08`, `OrientationResponsiveness = 40`, `OrientationMaxTorque = 60000`, `OrientationMaxAngularVelocity = 30`.
- R15.1 RED: `8574b918988b8e26551140f2e0d3005caded8fe8`, run `34394769781`, **123 passed, 2 failed**. Automated production evidence: `be44304bf00391e05c7d7750609730a7368ebc87`, run `34394991926`, **125 passed, 0 failed**, successful **Rojo build**.
- Historical `PrimaryAxisParallel` / free-world-Z body rotation is explicitly superseded by R16.1 and is not the current orientation contract.

### R16 Stage A — reference mechanical parity
- **R16.1 Upright Body** — `AlignOrientation` uses `AllAxes` with identity attachment basis; X/Y remain physically free, Z remains plane-locked; rotation about world X: locked/corrected; rotation about world Y: locked/corrected; **rotation about world Z: locked/corrected**.
- **R16.2 Hub Position** — `HubOffsetX = 0.0`, `HubOffsetY = -0.35`, `HubOffsetZAbs = 1.62` live only in `PhysicsConfig.LegGeometry`; Runtime consumes them symmetrically.
- **R16.3 / R16.3A Pivot + Reference Shape Centering** — one accepted stroke becomes one ShapeSpec and exactly two same-XY legs. The server translates cleaned bounds center to `(0,0)` without resizing, mirroring or rotating; `StrokeResult.acceptedPoints` and physical geometry use the same **centered authoritative shape**. Raw position of an otherwise identical drawing inside DrawInputRect no longer changes the leg; drawn size still does.
- **R16.4 Twin-leg Phase** — same motor locomotion direction, initial right-minus-left phase `180° ±1°`, and redraw preserves live per-side phase.
- Stage-A repository evidence: head `81c7d84c542160f07fc4fe986df89e5aa69f8f73`, run `34448666472`, **142 passed, 0 failed**, successful Rokit install and **Rojo build**.
- **Mandatory Studio Gate A — HUMAN STUDIO PENDING.** Product Owner later authorized Stage B and Stage C implementation without retroactively marking this gate PASS.

### R16 Stage B — reference feel/evidence implementation
- **R16.5 Motor / Grip / Mass — IMPLEMENTED/AUTOMATED GREEN, Studio Gate B — HUMAN STUDIO PENDING** — `PhysicsConfig.PhysicalMaterials.LegSegment` owns the existing leg material values; `R16B` measures ROUND flat speed after `2 s` settle over `3 s`, requiring `4–7 studs/s`, motors enabled and no anti-stall. No production motor/torque/grip numbers were blindly changed to force a target.
- **R16.6 Vertical Physics — IMPLEMENTED/AUTOMATED GREEN, Studio Gate B — HUMAN STUDIO PENDING** — normal locomotion remains solver-owned in Y; Stage-B harness measures HOOK rise on SmallSteps and SMALL_ROUND fall in GapSmall. No scripted Y locomotion was added.
- **R16.7 Reference Shape Matrix — IMPLEMENTED/AUTOMATED GREEN, Studio Gate B — HUMAN STUDIO PENDING** — executable `ROUND_01`, `LONG_BAR_01`, `SMALL_ROUND_01`, `HOOK_01`, `ASYM_01`, `SUBOPTIMAL_01` run from reset through exact comparative rules for flat/steps/gap/tunnel, including `SuboptimalWorseRatio=0.20` and `noUniversalWinner`.
- Stage-B repository evidence: head `2197882e4c641e7c1d17a6dfc538f23fd1a521e6`, run `34451426807`, **145 passed, 0 failed**, successful Rokit install and **Rojo build PASS**.
- **Studio Gate B — HUMAN STUDIO PENDING.** CI does not prove real speed, vertical contact behavior or niche differentiation. Product Owner explicitly authorized Stage C implementation before the next Studio run; that override is implementation-only.

### R16 Stage C — redraw/presentation/canonical pass implementation
**R16 Stage C implementation authorized by Product Owner on 2026-09-10.** The explicit decision was to finish **R16.8–R16.10** before launching Roblox Studio again. Studio Gate A, Studio Gate B and Studio Gate C remain **HUMAN STUDIO PENDING**.
- **R16.8 Moving Redraw Parity — IMPLEMENTED/AUTOMATED GREEN** — 10 moving redraws assert ShapeVersion progression, exactly two active leg models, no retiring leaks, no commit-time body CFrame/velocity reset, and live per-side phase preservation within `5°`.
- **R16.9 Reference Camera / Observer Isolation — IMPLEMENTED/AUTOMATED GREEN** — Studio presentation uses the approved side-oriented camera constants; observer Character parts are hidden and restored; presentation proxy remains non-physical.
- **R16.10 Canonical Final Harness — IMPLEMENTED/AUTOMATED GREEN** — selectable `R16C` reuses Stage-B evidence, verifies unchanged Flat/Steps/Wall/Gap/Tunnel presence, adds Wall HOOK/LONG_BAR evidence and 10 Heartbeat-spaced live redraws through `LegShapeService`. Stage C does not create or mutate obstacle Parts.
- Final R16.10 code evidence: head `3838a994f5b5164b64f3cdee934e5bc84f7be7a4`, run `34454820796`, **149 passed, 0 failed**, Rokit install PASS, **Rojo build PASS**.
- **Studio Gate C — HUMAN STUDIO PENDING.** Run `R16C` once after this implementation batch, then return to default `G0` for the human reference-feel check. Automation is not Studio acceptance.
- **R16.11 must not freeze before Studio Gate C is recorded.** R16.11 may only reconcile final live evidence/tuning/status after the combined Studio pass; it must not turn pending gates into PASS based on CI.

Repository audit conclusion at this gate: no new top-level gameplay service/controller family is justified. CI includes Rojo buildability but does not replace Studio/external-tester G0 evidence.

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
- BACKLOG — Fast rematch
- BACKLOG — Network/security tests + G2

## M2 — 8-Player Product Vertical Slice
- BACKLOG — 8 lane scaling
- BACKLOG — STAGING two-place provisioning (`64/70`)
- BACKLOG — First 10 authored tracks T01–T10 from `60/67`
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
**Repository closure status: AUTOMATED GREEN target; Studio acceptance remains pending.**

P0–P6 record the bounded pre-Studio repair sequence: P0 plan/contract reconciliation; P1 real elapsed B10 recovery timing; P2 isolated flat benchmark; P3 real below-kill-Y recovery evidence; P4 shared full six-shape matrix with winner-set intersection; P5 Wall suitable-success plus SUBOPTIMAL negative-control proof with dedicated WallContactTimeout preserved; P6 repository status/decision reconciliation and final CI/toolchain verification.

**Studio Gate A — HUMAN STUDIO PENDING**  
**Studio Gate B — HUMAN STUDIO PENDING**  
**Studio Gate C — HUMAN STUDIO PENDING**  
**B17/G0 — HUMAN_GATE PENDING**

`AUTOMATED GREEN` is repository/CI evidence only and never marks any Studio or external human gate PASS.
