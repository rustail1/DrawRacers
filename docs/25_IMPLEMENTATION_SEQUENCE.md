# 25 — IMPLEMENTATION SEQUENCE

Статус: **ORDER OF OPERATIONS v1.4.0 R17**

Этот файл отвечает: **что писать первым, вторым и дальше**, чтобы каждая система появлялась только когда её зависимость уже доказана.

Current sequence override: `DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md`. R17 reference-core work is authorized before B17 acceptance. `RaceCameraController`/`CameraMath` and provisional `RiderPresentationController` are already current M0 presentation owners under R17; D09/E03 later extend these same owners for multiplayer/readability rather than introducing duplicates. `RacerService` remains D05.

---

# PHASE A — PROJECT BOOTSTRAP

### A01 Repository + Rojo baseline
Output: пустой проект синхронизируется VS Code ↔ Studio.

### A02 Minimal shared structure
Output: `Shared/Types`, `Shared/Config`, server/client bootstrap без будущих пустых сервисов.

### A03 M0 test scene
Output: lane, flat floor, debug spawn, five obstacle blockout anchors.

### A04 Deployment/config skeleton
Create exact DEV/STAGING/PROD deployment registry files from `64/70`; no fake numeric IDs. Apply exact Studio root/instance contract `65`.

Gate: clean reproducible baseline committed; missing external IDs fail closed rather than being guessed.

---

# PHASE B — M0 PHYSICS LAB

### B01 InputController pointer abstraction
Dependency: A02. UI input rectangle/layout must use `59`, not an improvised canvas.

### B02 DrawingController local preview
Dependency: B01.

### B03 StrokeTypes + StrokeMath Dedupe/Clamp
Dependency: B02.

### B04 StrokeMath Simplify/Resample/Normalize
Dependency: B03. Exact DrawCanvas-center pivot/scale mapping = `73`.

### B05 Stroke math automated tests
Dependency: B04.

### B06 Racer template + RacerRuntime minimal
Dependency: A03.

### B07 LegAssembly one-leg constructor
Dependency: B04+B06. Segment construction/local frame = `73/65`.

### B08 One hinge motor flat test
Dependency: B07.

### B09 Left/right legs + phase
Dependency: B08. Hub offsets/axis/sign/duplication = `73`; numeric phase magnitude = `16`.

### B10 Racer stabilization/lane lock
Dependency: B09.

### B11 Authoritative LegShapeService wrapper
Dependency: B04+B09.

### B12 SubmitStroke/StrokeResult minimal remote contract
Dependency: B11.

### B13 Atomic redraw
Dependency: B12.

### B14 Invalid/stress redraw suite
Dependency: B13.

### B15 Five obstacle lab final geometry
Dependency: B10+B13. Start from exact canonical geometry/defaults in `60` for Flat/Steps/Wall/Gap/Tunnel representatives.

### B16 Debug tuning panel
Dependency: B15.

## R17 — REFERENCE-CORE PARITY OVERRIDE BEFORE B17

R17 is the current Product Owner override. It does not promote earlier human gates; it orders additional core evidence/fixes before B17 can be accepted.

### R17.0 Contract reconcile
Record the R17 decision and reconcile current implementation ownership. Camera/rider may exist during M0 under R17; first-point mechanical origin remains current until R17.3 evidence and an explicit R17.4 decision.

### R17.1 Desktop camera input
Use the existing `RaceCameraController`; do not create another camera owner. Hold RMB over world space with Local Racer present -> bounded orbit, mouse capture, exact mouse-state restoration, automatic smooth return. LMB remains DrawCanvas input. Touch ownership remains unchanged.

### R17.2 Rider mount/pose
Use the existing `RiderPresentationController`; no second rider manager. Establish deterministic nonphysical jockey/rodeo mount and Studio scale/readability evidence.

### R17.3 Mechanical-origin experiment
Studio-only comparison of current first-point, bounds-center and deterministic geometry/reference-center candidates using identical canonical shapes/resets. Do not alter production origin or network schema during the experiment.

### R17.4 Mechanical-origin migration
Only after R17.3 human evidence, record one explicit Product Owner origin decision and migrate the server-owned authoritative geometry consistently if the current first-point origin loses the comparison.

### R17.5 Live phase-lock acceptance
Prove actual 180-degree anti-phase stability under real hinges/contact/redraw, not only commanded motor correction. Preserve same locomotion sign and configured average motor speed.

### R17.6 Body feel A/B
Tune in isolation: density first, then friction, then collider size only if belly contact remains the proven limiter. Keep motor `-8 / 35000 / 120` unchanged during these sweeps. Record body/belly contact, leg contact, air time, distance, speed and stuck time.

### R17.7 Reference course pass
Canonical shape matrix across unchanged Flat/Steps/Wall/Gap/Tunnel plus live redraw. Require meaningful shape niches and no universal winner.

### R17.8 Final core human gate
Consolidated server regression + R16/R17 Studio/reference-feel acceptance. Only supplied human evidence may close this gate.

### B17 M0 human test + tuning log
Run `55` G0 only after ordered R17 work reaches R17.8 or Product Owner records another explicit gate decision. B17 remains HUMAN_GATE PENDING until recorded evidence is PASS.

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
Extend the existing R17 production camera owner to Local Racer + look-ahead + visible rival. Do not create a second camera/controller. Start camera constants from `16` and respect `59` DrawCanvas exclusion zone.

Preserve the production camera contract from R17 and `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md`:
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
Use exact presentation owners `08/59/68`; no persistence dependency yet. Extend the existing R17/D09 camera and R17 rider owners to the real 8-player readability case; do not create second systems.

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
