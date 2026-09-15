# 25 — IMPLEMENTATION SEQUENCE

Статус: **ORDER OF OPERATIONS v1.6.0 CORE V3**

Этот файл отвечает: **что писать первым, вторым и дальше**, чтобы каждая система появлялась только когда её зависимость уже доказана.

Current sequence owner for M0 is `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md` + `SESSION.md`. Old R17/CR2/CR3 implementation ordering is removed.

---

# PHASE A — PROJECT BOOTSTRAP

### A01 Local folder + Rojo baseline
Output: exact local project folder/archive syncs reproducibly through Rojo/Studio. Git is not required in the current workflow.

### A02 Minimal shared structure
Output: `Shared/Types`, `Shared/Config`, server/client bootstrap without speculative future services.

### A03 M0 test scene foundation
Output: runtime roots, flat lane/debug spawn and later obstacle authoring anchors exist. **Core V3 Flat modes must not start obstacle geometry before Flat PASS.**

### A04 Deployment/config skeleton
Create exact DEV/STAGING/PROD deployment registry files from `64/70`; no fake numeric IDs. Apply exact Studio root/instance contract `65`.

Gate: clean reproducible local baseline; missing external IDs fail closed rather than being guessed.

---

# PHASE B — M0 CORE V3 FLAT PHYSICS

### B01 InputController pointer abstraction
Dependency: A02. UI input rectangle/layout must use `59`.

### B02 DrawingController local preview
Dependency: B01.

### B03 StrokeTypes + StrokeMath Dedupe/Clamp
Dependency: B02.

### B04 CanonicalLegShape / GeometryMath mapping
Dependency: B03. Exact first-cleaned-point translation anchor and collider mapping = `73`. Do not resize/mirror/reverse the accepted stroke.

### B05 Stroke math automated tests
Dependency: B04.

### B06 RacerTemplate + thin RacerRuntime
Dependency: A03. `RacerRuntime` delegates current leg mechanics to Core V3; it must not reconnect legacy locomotion owners.

### B07 Core V3 SharedAxle
Dependency: B06. Exactly one `AxleRoot`, one `HingeConstraint`, one motor owner; LEFT -Z, RIGHT +Z at fixed 180°. Hinge stays structurally enabled.

### B08 Core V3 LegGeometry
Dependency: B04+B07. Same authoritative XY ShapeSpec on both sides; visual preview nonphysical; physical segments use `canCollide` plan and leg traction material.

### B09 Core V3 clearance + transactional redraw
Dependency: B08. `EMPTY/PREVIEW/WAIT_CLEAR/ACTIVE`; bounded +Y-only clearance; pair collision activation atomic; accepted shape/version commits only after real ACTIVE; failure is fail-closed.

### B10 Core V3 2.5D lane/upright owner — CURRENT NEXT TASK
Dependency: B07+B09. Lock only Z translation to lane plane and stabilize BodyCollider upright. Preserve X/Y translation and shared axle rotation. No normal +X/+Y mover.

### B11 Authoritative LegShapeService
Dependency: B04+B09. Client never authors world geometry; reject zero-drive-collider shapes; mechanical pending is exception-safe.

### B12 SubmitStroke / StrokeResult contract
Dependency: B11. Exact bounded remote contract; stale/rate/malformed requests fail closed.

### B13 Transactional accepted-UI result
Dependency: B12. Client accepted drawing follows final server mechanical commit; mechanical failure clears stale accepted state when old physical shape was invalidated.

### B14 Core V3 automated suite C01–C07
Dependency: B07–B13. `COREV3_TEST` must run all seven current specs. C07 is the flat locomotion regression.

### B15 Human Core V3 Flat Gate
Dependency: B10+B14. `COREV3` mode: ROUND from rest -> SMALL_ROUND -> LONG -> HOOK -> ASYMMETRIC -> 20 moving redraws. Prove natural +X locomotion, lane lock/upright stability and no hidden horizontal helper.

### B16 Core V3 observability/tuning panel
Dependency: B14. DEV/Studio only; show state, hinge count, motor state, contact, relative rotation, clearance, helper detection and acceptance evidence without becoming physics authority.

### B17 Flat-gate record / post-Flat handoff
Dependency: B15+B16. Record PASS or bounded rework/escalation. Only after human Flat PASS may obstacle work and legacy locomotion-file cleanup resume.

---

# PHASE C — M0.5 ADAPTATION ACCEPTANCE

### C01 TrackPiece authoring contract minimal
Use schema `30`, authoring rules `42`, and numeric defaults/ranges `60`.

### C02 Mixed 30–45s track
Use a `60` T06–T10 style composition; at least distinct speed/reach/climb/clearance transitions.

### C03 Universal-shape comparison protocol
Canonical shapes on same track.

### C04 Human adaptation test
Run `55` G1. PASS is required before M1.

---

# PHASE D — M1 2-PLAYER RIVAL SLICE

### D01 Expand TrackService + TrackRuntime
Build two identical lanes from same TrackDefinition.

### D02 RaceTypes/RacePhase
Strict enum/state representation.

### D03 RaceRuntime
One heat state container.

### D04 RaceService waiting/countdown/racing/results
No rewards yet beyond debug result. Exact lifecycle/assembly/PREP/finish-grace/DNF semantics = `74`.

### D05 RacerService player mapping/spawn
Two players assigned isolated lanes. Human racer spawn becomes the server-authoritative source of the replicated `OwnerUserId` presentation identifier from `65`; bots never impersonate a human owner id.

### D06 ProgressValidationService/checkpoint tracker
Ordered checkpoints + finish.

### D07 Server Authority configuration/test harness
Enable current Workspace server authority setting for test place; document behavior.

### D08 Malformed stroke/race remote tests
Security before broader scale.

### D09 RaceCameraController — 2-player extension/acceptance
Extend the existing production camera owner to Local Racer + look-ahead + visible rival. Do not create a second camera/controller. Start camera constants from `16` and respect `59` DrawCanvas exclusion zone.

Preserve the current production camera contract and `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md`:
- deterministic frame-rate-independent `CameraMath` remains the pure math owner;
- active-race target follows Local Racer position without inheriting BodyCollider rotation/roll;
- stable smoothed target + vertical dead-zone/damping from `16`;
- desktop free-look = hold RMB with bounded yaw/pitch, cursor capture/restoration, and automatic return;
- touch orbit starts only from world space outside DrawCanvas/active UI and never steals an active drawing pointer;
- no camera orientation Remote/event authority;
- verify base side view, nearby-rival and upcoming-obstacle readability in Roblox Studio.

### D10 HUDController progress/placement
Presentation only; exact placement/size/copy = `59`.

### D11 ResultsController + fast requeue
Repeated heats. Exact Results guard/requeue/spectator semantics = `74`.

### D12 2-player latency/fairness + social-value test
Run `55` G2 and relevant network cases from `57`. PASS is required before 8-player scale-up.

---

# PHASE E — M2 8-PLAYER VERTICAL SLICE

### E00 STAGING two-place provisioning
Provision private/unlisted STAGING `EntryFTUEPlace` + `RacePlace`, bind generated IDs through `64/70`, verify environment isolation before profile/routing work.

### E01 Lane scale 2→8
No new core mechanics.

### E02 T01–T10 authored TrackDefinitions
Build exact first ten definitions from `60`; do not invent alternate launch blockouts.

### E03 Full 8-player readability camera/HUD/rider pass
Use exact presentation owners `08/59/68`; no persistence dependency yet. Extend the existing camera/rider owners to the real 8-player readability case; do not create second systems.

Rider acceptance at E03:
- cube shell remains the canonical racer body from `62`;
- rider remains a separate standardized/normalized presentation-only visual keyed by server-authored `OwnerUserId`;
- starting normalized target scale `0.65`, with Studio comparison `0.55 / 0.65 / 0.75` and a hard readability envelope/fallback for oversized appearances;
- rider pose is the approved jockey/frog-rider seated pose; first implementation does not require bob/lean animation;
- rider never changes racer/leg physics, collision, mass, camera authority, checkpoints/finish, rewards or Draw Racers cosmetic ownership;
- bots retain explicit `BOT #N` identity and do not imitate human avatar riders;
- pass 2-player and 8-player visual/readability evidence before E03 is accepted.

### E04 PlayerDataService profile lifecycle
Implement `31` safe load, lease, schema migration, GuestSafe, cross-place transfer token/handoff and release behavior. This must exist before any FTUE completion or persistent reward can be accepted.

### E05 RewardService + Coins/MP grant path
Server-validated race result → exact starting reward/mastery table from `61` → one atomic `GrantId` mutation through `31`. Implement FTUE completion grant semantics and explicit FTUE-DNF no-reward semantics.

### E06 AnalyticsAdapter baseline
Implement authoritative FTUE/core/economy event dictionary from `10/46` now, **before FTUE acceptance**, so the mandatory FTUE funnel can be observed rather than retrofitted. Bots are excluded from human KPI funnels.

### E07 Canonical BotRacerController foundation + FTUE assembly
Implement the **same production BotRacerController family** defined by `40/75`, legal ShapeSpec path `73`, and server authority path `05/22`, but initially enable only the controlled EntryFTUE 2s assembly behavior. No hidden FTUE physics/rubber-band. Public cold-start fill remains F05 configuration/integration work, not a second bot system.

### E08 Results/podium/requeue confirmed-state UX
Upgrade the D11 Results path to exact `59/68` hierarchy and `74` timings. Bind placement/reward/next-goal only from confirmed server result/grant state. This must exist before FTUE acceptance because first FTUE finish includes a Results reward/next-goal state.

### E09 Cosmetic definitions + CosmeticService
Load exact catalog IDs/art manifest `62`; implement ownership/equip validation with no physics impact. `Ink_Sky_01` must render and auto-equip correctly from an authoritative FTUE grant before the FTUE funnel can pass.

### E10 Two-place FTUE funnel + routing
Enable the final funnel only after E04–E09 are ACCEPTED. Publish/configure EntryFTUEPlace as start place and RacePlace as public heat place (`23/30/41`). Implement safe-profile routing, 2s canonical bot assembly, T06 first draw→movement→redraw→finish→atomic reward/tutorial/Ink_Sky commit→confirmed Results→RacePlace, returning-player EntryFTUEPlace→RacePlace redirect, direct RacePlace first-timer→EntryFTUEPlace redirect, funnel analytics, and teleport retry/idempotency. UI = `08/59`; economy/profile = `31/61`; lifecycle = `74`; performance = `57`.

### E11 Garage / Coin catalog purchase / equip UI
Exact layout/copy = `59/68`; catalog = `62`; price/source states = `61`. Coin purchase and ownership mutation use `71` atomically; equip remains server validated.

### E12 Audio/VFX/haptic semantic presentation
Implement `AudioController` + `FeedbackController` from `21/47/68`; bind only semantic keys through `69/70`.

### E13 Settings/accessibility/safety presentation
Implement exact Settings/rival-shape-detail/Reduce Motion behavior from `37/39/59/68`.

### E14 Performance/soak/security pass
8 racers worst-case shapes plus EntryFTUE→RacePlace transfer. Execute `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md` M2 thresholds, `24/32` abuse/fault cases and `55` G3.

Gate: G3 PASS + no P0/P1 + required device matrix PASS.

---

# PHASE F — M3 ALPHA PRODUCT LOOP

### F01 Complete launch track pool T01–T20 + themes
Data/content from `60/62`, not new code families.

### F02 Mastery/status/access
Implement exact MP gains/titles/access tiers from `61`; returns player into race core.

### F03 Collection presentation
Complete all 20 produced launch cosmetics + Trail_None and exact Garage presentation `59/62`.

### F04 Session pacing polish
No menu wall between races. Run `55` G4 before monetization.

### F05 Required public cold-start Bot Fill
Extend the already-accepted E07 canonical BotRacerController into public cold-start assembly using `40_BOT_FILL_SPEC.md`, exact difficulty/shape/decision policy `75`, and defaults/config routing from `16/30`. Humans have priority during assembly; on timeout remaining slots are filled with fair bots. Do not create a second bot implementation. DEV/STAGING may disable only for explicit tests.

### F06 Free cosmetic/status desire gate
Expose free collection/status value and run `55` G5 before paid offers.

### F07 Admin/observability implementation
Implement `34` feature flags/diagnostics/admin restrictions required for safe release.

### F08 Save/migration/handoff fault matrix
Run `31/24` lease, migration, GuestSafe, transfer, duplicate GrantId and crash/retry cases.

### F09 Content registry/provenance binding
Bind accepted assets through `36/48/69/70`; no raw platform IDs in gameplay code.

Gate: G4/G5 recorded; Bot Fill implementation accepted before public cold-start release.

---

# PHASE G — M4 MONETIZATION / SOFT LAUNCH

### G01 MonetizationService platform integration
Implement and test `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md` before any repeatable Developer Product goes live.

### G02 Exact launch Pass catalog + first contextual style offer
Implement the three Pass grants/prices/ordering from `61/62`; Starter first after eligibility. Pass entitlement reconciliation is exactly `71`; generated PassIds come from `70`.

### G03 Purchase post-theatre
Immediate equip/visible expression using `59/62` presentation; never before confirmed entitlement.

### G04 Price/offer analytics
Price is hypothesis.

### G05 Discovery asset experiments
Produce exact first A/B/C creatives from `62`, use evidence boundary `54`, run `55` G6; promise must match the actual first minute.

No competitive power.
