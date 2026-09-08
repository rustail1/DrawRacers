# AGENTS.md — RULES FOR CHATGPT / CODEX / CLAUDE

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation stage only. Product power is never sold.

## Role split
Human/vision owner owns **WHAT and WHY**. AI proposes/implements **HOW** inside approved constraints.

## Mandatory start of every task
1. Read `FEATURE_LIST.md` and confirm feature is in scope. **Do not load `_HISTORY/` for normal implementation.**
2. Use `26_HANDOFF_MAP.md` to select only the relevant specialized spec(s).
3. For architecture/network tasks read `21_SYSTEM_CLASS_ARCHITECTURE.md` and/or `22_NETWORK_DATA_CONTRACTS.md`.
4. Read relevant Decision Log + `SESSION.md`.
5. Inspect existing Roblox project/code/DataModel before changing anything.
6. Reuse existing services/modules first; do not create `NewWhateverManager` before proving need.
7. Follow the task lifecycle in `20_HOW_TO_DEVELOP_THE_GAME.md`.

## Design-freeze rule
There are no known open WHAT/WHY questions required for implementation. Empirical outcomes are not treated as “already proven”; use `55` for bounded test/rework/escalation. If a test fails, route to the owner spec and rework/tune implementation. Do not invent a new mechanic or reopen product identity unless the human explicitly approves a Decision Log + Feature List scope change.

## Task size
One task = one observable behavior that can be separately implemented and tested. Break giant requests into minimal vertical steps.

## Implementation loop
`Expected result → technical reconnaissance → minimal change → run/test → report → human acceptance → next step`.

## Source of truth
- Scope: `FEATURE_LIST.md`
- Product: Project Bible/specialized specs
- Global physics/race/camera numbers: `16`; UI geometry: `59`; level geometry/content: `60`; economy/progression/prices: `61`; performance thresholds: `57`
- Canonical persistent profile: `31_SAVE_DATA_MIGRATION_RECOVERY.md`
- Empirical gate protocol: `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md`
- Developer Product receipt semantics: `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`
- Release performance/device PASS: `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`
- Launch art/content/public identity: `62`
- Exact DrawCanvas→pivot→collider mapping: `73`
- Exact heat lifecycle/timeouts/requeue: `74`
- Exact bot shape/difficulty policy: `75`
- First 30-day LiveOps buffer: `76`
- Current final documentation audit: `78`
- Current state/exact task: `SESSION.md`
- Why a choice exists: Decision Log

Never silently duplicate/change facts across files.

## Core invariants
- Draw is locomotion.
- Real collider geometry matters.
- Redraw during race.
- Same fair physics for everyone.
- No paid competitive power.
- Other racers non-colliding.
- Server validates finish/rewards/stroke bounds.
- Track content data-driven.

## Testing
AI may automate math/invariants/errors. Human must test feel/UX/camera/physics in Roblox Studio. Clean console is not sufficient.

After shared-system change run regression on old scenarios.

## Completion report
At task end state:
- files changed;
- behavior implemented;
- tests run/results;
- known edge cases;
- deviations from spec;
- what felt fragile/bad in implementation;
- next smallest step.

Update `SESSION.md` after accepted changes.


## Architecture lock
Do not invent new top-level Service/Controller families that overlap owners defined in `21_SYSTEM_CLASS_ARCHITECTURE.md` without a Decision Log. Circular project-module dependencies are forbidden. `Bootstrap.server.lua` / `Bootstrap.client.lua` are composition roots; lower-level modules do not reach back into orchestration services.


## v1.3.4 mandatory execution context
For any implementation task, after FEATURE_LIST/SESSION/HANDOFF read the exact task row in `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`. Use `65` for Studio objects/collision, `68` for UI hierarchy, `70` for generated platform IDs. Never invent numeric Roblox IDs. Coin catalog/Pass grant logic must use `71`. Core geometry uses `73`; race lifecycle uses `74`; bot behavior uses `75`; H05 uses `76`. Final release uses `78`.


## Hard execution dependency v1.3.4
A01→A02→A03→A04 is mandatory. In M2, `E04 PlayerDataService → E05 RewardService → E06 AnalyticsAdapter → E07 canonical BotRacerController → E08 confirmed Results → E09 CosmeticService → E10 FTUE/routing` is mandatory. Do not stub a temporary save/reward/bot system to jump ahead. Production handoff contains no `_HISTORY`; use only manifest current documents.
