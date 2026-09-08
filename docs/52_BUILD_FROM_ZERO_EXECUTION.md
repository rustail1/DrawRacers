# 52 — BUILD-FROM-ZERO EXECUTION CONTRACT
Статус: **IMPLEMENTATION ROUTE v1.3.4**.

Цель: разработчик/Codex должен иметь однозначный маршрут от пустого репозитория до public release, не придумывая игровые правила. Этот файл **не дублирует specs** — он маршрутизирует работу по существующим owner documents.

## Rule 0 — before any code
Read in order: `README` → `FEATURE_LIST` → `SESSION` → `50_COMPLETENESS_MATRIX` → relevant row in `26_HANDOFF_MAP` → exact task row in `66`. Do not load `_HISTORY/` unless investigating provenance. Product/reference boundary: `51`; market evidence: `54`; empirical gates: `55`.

## Phase 1 — bootstrap
Execute `25` A01–A04 using `23_PROJECT_SETUP_TOOLCHAIN`, exact Studio contract `65`, and deployment skeleton `64/70`. Acceptance: repository/Rojo/Studio mapping works, required collision groups/config roots/test scene exist.

## Phase 2 — M0 core physics
Execute `25` B01–B17. Owners: `03`, exact coordinate/pivot/collider mapping `73`, `11`, `21`, `22`, tuning `16`, DrawCanvas layout `59`, QA `24`. Output: draw→real physical legs→bounded locomotion→atomic redraw→five obstacle lab. Exact runtime Instances/collision = `65`; UI input hierarchy = `68`. Must pass `15` Core Lab DoD **and `55` G0** before M0.5.

## Phase 3 — M0.5 track grammar
Execute `25` C01–C04. Owners: `04`, `30`, `42`, exact launch geometry/tracks `60`. Output: mixed track, requirement transitions, no normal universal-shape bypass. Exact assembly/release workflow = `67`. Run `55` G1. Failed acceptance = bounded rework TrackPiece/physics/tuning, then explicit escalation, not silent new game design.

## Phase 4 — M1 networked rival slice
Execute `25` D01–D12. Owners: `05`, exact heat/requeue/timeouts `74`, `21`, `22`, `28`, `41`. Output: two clients, authoritative race/checkpoints/finish, isolated lanes, readable rival, fast requeue. Pass `55` G2 before scale-up.

## Phase 5 — M2 target 8-player slice
Execute `25` E-series and remaining M2 tasks **in ID order; E04 PlayerDataService → E05 RewardService → E06 AnalyticsAdapter → E07 canonical bot foundation → E08 confirmed Results → E09 CosmeticService are hard dependencies of E10 FTUE routing and may not be deferred or reimplemented ad hoc.** Owners: `05`, `08`, `29`, exact UI `59`, exact T01–T10 `60`, economy `61`, content `62`, `33`, `46`. Before FTUE routing provision STAGING via `64/70`. Output: 8 racers, authored pool, FTUE, results, save/equip, atomic Coin catalog purchase (`71`), Coins/cosmetics, semantic audio/feedback (`47/68`), analytics. Pass `55` G3 and `57` M2 performance thresholds.

## Phase 6 — M3 complete product/session/meta
Owners: `06`, `43`, `44`, `31`, `41`. Build mastery/status/access, garage/collection, sufficient authored course pool, session pacing. Keep all race physics fair and identical. Run `55` G4 and G5 before paid-offer work.

## Phase 7 — production completeness before public launch
Mandatory even if not glamorous:
- Bot Fill for underfilled heats: `40`, exact bot profile/shape policy `75`;
- save migrations/recovery: `31`;
- security/threat pass: `32`;
- performance budgets/8-player soak: `33` + `24`;
- observability/admin: `34`;
- platform provisioning/release settings: `64`;
- exact environment/Place/Product/Asset ID binding: `70`;
- release/rollback: `35`;
- asset provenance/naming: `36` + required launch asset manifest `62` + production workflow `69` + ID registry `70`;
- localization/accessibility: `37` + UI screenshot matrix `59`;
- discovery creative pack: `38` + exact first pack `62`;
- drawing safety/moderation: `39`;
- IP clean-room/name clearance: `48` + ordered title rule `62`;
- empirical gate records: `55`;
- Developer Product receipt/idempotency: `56`;
- release performance/device matrix: `57`.

## Phase 8 — M4 monetization + soft launch
Owners: `07`, `19`, `45`, `46`; exact initial prices/grants `61`, exact items/presentation `62`; empirical changes `49`. First offers are contextual cosmetic/status value only after `55` G5 confirms visible free expression value. No competitive power. Developer Product granting must implement `56` exactly; Pass entitlement and Coin catalog mutations must implement `71` exactly.

## Phase 9 — LiveOps/release
Owners: `09`, `30`, objective persistence `31/44`, `35`, `46`, concrete first-30-day buffer `76`. Regular content should be TrackDefinitions/TrackPieces/cosmetics/rewards/event config, not new architecture. Each change uses a measurement contract and can be rolled back.

## Per-task mandatory loop
`scope check → relevant owner spec → reconnaissance → smallest observable change → automated checks → Studio playtest → edge/regression → human acceptance → Decision Log if decision changed → SESSION update → next task`.

## What the implementer may decide without asking the vision owner
HOW choices inside existing owners: local function names, private helper decomposition, data-structure choice, internal algorithm, test utility implementation, optimization technique — provided contracts/invariants remain unchanged.

## What the implementer may NOT decide silently
- add/remove player actions;
- change 8-player target;
- add gas/jump/steering;
- replace real drawn collision with cosmetic presets;
- add racer collision/combat;
- sell physics advantage;
- change persist pillars;
- make public free-form drawing sharing;
- add new top-level overlapping Service/Controller owner;
- change save/network schemas incompatibly without migration/version decision.

These require explicit owner decision + Decision Log + owner doc + Feature List change.

## Final release criterion
The game is release-candidate when exact UI (`59`), launch tracks (`60`), economy/progression (`61`) and launch art/content (`62`) are implemented and accepted, and every `Production completeness` item in `FEATURE_LIST` is `ACCEPTED`, `55` required pre-release gates are recorded, `56` receipt tests pass if Developer Products are enabled, `57` device/performance matrix passes, `35/48` release/IP checks pass, and no P0/P1 issue remains. `78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md` must remain PASS. Commercial KPIs remain live measurements, not promises.


## Two-place launch topology
By M2 FTUE acceptance the experience must use the final topology, not a temporary lobby assumption: EntryFTUEPlace is the start place; safe newcomers run T06 there; completed profiles route to RacePlace; first authoritative FTUE finish persists before routing. Exact contract = `23/30/41`, measured by `57`.


## Final zero-question release rule
Public enable is `25` I08 only after `78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md` PASS. A missing generated Roblox ID is resolved through `64/70`, not guessed. A missing observable WHAT/WHY decision stops implementation; a private HOW choice inside `21/22/65/68` belongs to the implementer.
