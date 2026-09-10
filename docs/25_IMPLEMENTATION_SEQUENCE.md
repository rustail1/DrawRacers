# 25 — IMPLEMENTATION SEQUENCE

Статус: **ORDER OF OPERATIONS v1.3.4**

Этот файл отвечает: **что писать первым, вторым и дальше**, чтобы каждая система появлялась только когда её зависимость уже доказана.

Camera/rider contract amendment: `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md` defines future D09/E03 presentation behavior but does **not** move either task earlier or alter the current M0/R16/B17 gate.

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

### B17 M0 human test + tuning log
Run `55` G0. Do not proceed until the recorded gate is PASS or Product Owner records an explicit scope decision after the allowed rework cycles.

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

### D09 RaceCameraController
Local racer + look-ahead + visible rival. Start camera constants from `16` and respect `59` DrawCanvas exclusion zone.

Implement the production camera contract from `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md`:
- introduce pure `CameraMath` only for deterministic frame-rate-independent smoothing/dead-zone/orbit math;
- active-race target follows Local Racer position without inheriting BodyCollider rotation/roll;
- use stable smoothed target + vertical dead-zone/damping from `16`;
- desktop free-look = hold RMB with bounded yaw/pitch; release returns automatically to canonical side view;
- touch orbit can start only from world space outside DrawCanvas/active UI and never steals an active drawing pointer;
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

### E03 Full 8-player readability camera/HUD pass
Use exact presentation owners `08/59/68`; no persistence dependency yet.

Extend the already-implemented D09 camera to the real 8-player readability case; do not create a second camera system. Introduce `RiderPresentationController` here, and only here, for human-racer mini-avatar presentation:
- cube shell remains the canonical racer body from `62`;
- rider is a separate standardized/normalized presentation-only visual keyed by server-authored `OwnerUserId`;
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

---

# PHASE H — LIVEOPS FOUNDATION

### H01 Config-driven course rotation
### H02 Cosmetic collection configs
### H03 Event modifier schema
### H04 Measurement contract workflow
### H05 Content buffer
Instantiate and validate the exact first-30-day configs/objectives/rewards from `76` using `30/31/44/60/61/62/69`; no new mechanic required. Event objective progress/reward rides the existing authoritative race GrantId transaction.
### H06 Tournament/season only if retention/social data justify

Procedural/endless generator remains later unless authored-track production becomes a proven bottleneck.

---

# Strict dependency rule

Never pull a task from a later phase just because it is easy/fun.

Examples:
- no DataStore before racer core needs persist;
- no Shop before cosmetic/status value exists;
- no procedural generator before authored level grammar is validated;
- no 8-player service before the 2-player rival slice passes acceptance;
- no seasons before session/return loop shows signal;
- the camera/rider Contract Lock does not authorize `CameraMath`, `RaceCameraController` or `RiderPresentationController` before D09/E03 respectively.


# PHASE I — FINAL PUBLIC RELEASE FREEZE

### I01 UI screenshot matrix
Pass all `59` desktop/touch reference layouts.

### I02 Content manifest completion
All `60` T01–T20, both `62` themes, 20 produced cosmetics, audio/VFX checklist and discovery pack exist and validate through `67/69/70`.

### I03 Economy/progression config verification
Runtime values match `61`; grants/save/anti-farm tests pass.

### I04 Name/IP/platform policy clearance
`39/48/62/64` title/safety/maturity/provenance rules PASS.

### I05 PROD provisioning + deployment ID binding
Provision/bind exact two-place PROD + all SKU/assets through `64/70`; private production smoke test before public enable.

### I06 QA/performance/rollback drill
Run `24/35/57`; known-good compatible two-place rollback pair recorded.

### I07 Final zero-question production audit
Run `78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md`; release only on PASS.

### I08 Public enable + first-hour/day monitoring
Enable public access/discovery only after I07. Monitor `35` P0/P1, funnel, server performance and purchase errors.
