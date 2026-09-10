# AGENTS.md — RULES FOR CHATGPT / CODEX / CLAUDE

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation stage only. Product power is never sold.

## Role split
Human/vision owner owns **WHAT and WHY**. AI proposes/implements **HOW** inside approved constraints.

The current preferred execution topology for this repository is:

```text
ChatGPT remote GitHub executor
-> rustail1/DrawRacers main
-> user git pull on PC
-> Rojo
-> Roblox Studio
-> human evidence
```

The generic local Codex/Claude workflow described elsewhere remains compatible, but it is not required. A remote GitHub executor cannot inspect the user's uncommitted local worktree and must not claim that it can.

## Mandatory task classification
Before any change, classify the request as exactly one of:
- `BUGFIX` — current implementation violates current Source of Truth;
- `FEATURE` — new approved behavior inside current contracts;
- `CONTRACT_CHANGE` — desired behavior conflicts with current Source of Truth or changes WHAT/WHY;
- `TUNING` — empirical value change without changing ownership/meaning;
- `DOC_ONLY` — documentation/process-only change;
- `REVIEW` — read-only audit.

Mandatory routing:
- `BUGFIX` -> `BUGFIX_PROTOCOL.md`.
- `REVIEW` / `/review` -> `REVIEW_PROTOCOL.md` and **no writes**.
- `CONTRACT_CHANGE` -> affected owner spec + Decision Log first; runtime code only after the new contract/plan is approved.
- Human copy/paste workflow and local commands -> `AI_WORKFLOW_QUICKSTART.md`.

If current code correctly implements current Source of Truth but the user wants different behavior, do not call it a bug and do not patch around the current spec.

## Mandatory start of every task
1. Read `FEATURE_LIST.md` and confirm feature is in scope. **Do not load `_HISTORY/` for normal implementation.**
2. Read `SESSION.md` for the exact current cursor and human-gate status.
3. Use `26_HANDOFF_MAP.md` to select only the relevant specialized spec(s).
4. For catalog implementation tasks read the exact row in `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`.
5. For architecture/network tasks read `21_SYSTEM_CLASS_ARCHITECTURE.md` and/or `22_NETWORK_DATA_CONTRACTS.md`.
6. Read relevant Decision Log and relevant existing code.
7. Inspect current remote `main` HEAD before planning/writing.
8. Inspect the existing Roblox/Rojo owner before creating anything new.

## Repository execution policy
- Repository: `rustail1/DrawRacers`.
- Working branch: **`main` only**; no branches/PRs unless the Product Owner explicitly changes policy.
- After an approved implementation plan, ChatGPT acting through GitHub may commit the bounded change directly to `main`.
- PLAN ONLY does not authorize any repository write.
- One Task ID has one active executor. Do not concurrently implement the same task in remote GitHub and a local coding agent.
- Remote GitHub state is not proof that `C:\Dev\DrawRacers` has no local edits. Existing local user changes are protected.
- Filesystem/Rojo-managed scripts are canonical. Roblox Studio is for runtime/human validation, not manual competing copies of source scripts.

## BUGFIX lifecycle
Every BUGFIX defaults to **INVESTIGATE / PLAN ONLY** and must follow `BUGFIX_PROTOCOL.md`.

Required high-level lifecycle:

```text
evidence
-> technical reconnaissance
-> root cause
-> blast radius
-> exact FILES TO CHANGE / DO NOT TOUCH
-> RED/test plan + Studio acceptance plan
-> STOP / wait for approval
-> re-check main HEAD
-> RED when meaningful
-> confirm correct failure
-> minimal GREEN
-> regression/full verification
-> diff audit
-> direct-main commit
-> /review
-> human Roblox Studio acceptance
```

Standard implementation approval phrase:

```text
ДЕЛАЙ ПО УТВЕРЖДЁННОМУ ПЛАНУ.
```

Once approved, the plan is a scope contract. If implementation requires a file/system/public API/schema/gameplay/balance/Rojo/architecture change outside the plan, STOP and request a plan amendment.

Do not stack speculative fixes. If the root-cause hypothesis is disproved, return to investigation with the new evidence.

## Design-freeze rule
There are no known open WHAT/WHY questions required for implementation. Empirical outcomes are not treated as “already proven”; use `55` for bounded test/rework/escalation. If a test fails, route to the owner spec and rework/tune implementation. Do not invent a new mechanic or reopen product identity unless the human explicitly approves a Decision Log + Feature List scope change.

If observed desired behavior contradicts current Source of Truth, classify it as `CONTRACT_CHANGE`; update/approve the relevant owner/Decision Log before runtime implementation.

## Task size
One task = one observable behavior that can be separately implemented and tested. Break giant requests into minimal vertical steps.

For a bugfix, the approved plan determines the blast radius. Do not turn a local repair into architecture cleanup.

## Implementation loop
Normal feature/tuning loop:

`Expected result -> technical reconnaissance -> minimal change -> run/test -> report -> human acceptance -> next step`.

BUGFIX uses the stricter `BUGFIX_PROTOCOL.md` lifecycle above.

## Source of truth
- Scope: `FEATURE_LIST.md`
- Product: Project Bible/specialized specs
- Global physics/race/camera numbers: `16`; UI geometry: `59`; level geometry/content: `60`; economy/progression/prices: `61`; performance thresholds: `57`
- Canonical persistent profile: `31_SAVE_DATA_MIGRATION_RECOVERY.md`
- Empirical gate protocol: `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md`
- Developer Product receipt semantics: `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`
- Release performance/device PASS: `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`
- Launch art/content/public identity: `62`
- Exact DrawCanvas->pivot->collider mapping: `73`
- Exact heat lifecycle/timeouts/requeue: `74`
- Exact bot shape/difficulty policy: `75`
- First 30-day LiveOps buffer: `76`
- Current final documentation audit: `78`
- Current state/exact task: `SESSION.md`
- Why a choice exists: Decision Log
- Bugfix execution: `BUGFIX_PROTOCOL.md`
- Post-fix read-only audit: `REVIEW_PROTOCOL.md`
- Human operator prompts and Git/Rojo handoff: `AI_WORKFLOW_QUICKSTART.md`

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

## Architecture lock
Do not invent new top-level Service/Controller families that overlap owners defined in `21_SYSTEM_CLASS_ARCHITECTURE.md` without a Decision Log. Circular project-module dependencies are forbidden. `Bootstrap.server.lua` / `Bootstrap.client.lua` are composition roots; lower-level modules do not reach back into orchestration services.

A local bugfix must reuse the existing natural owner unless the approved plan explicitly proves an architecture-boundary change is necessary.

## Testing
AI may automate math/invariants/errors. Human must test feel/UX/camera/physics in Roblox Studio. Clean console is not sufficient.

For implementation defects, use meaningful TDD:
`RED -> confirm correct FAIL -> minimal GREEN -> targeted regression -> required full verification`.

Do not create a meaningless static test merely to claim RED for physics/camera/UI/visual feel that genuinely needs Roblox Studio observation. In those cases define an exact manual RED and automate only deterministic invariants around it.

After shared-system change run regression on old scenarios.

Unexpected failure requires root-cause/systematic debugging before another production fix. Never weaken an expectation solely to obtain GREEN.

## Remote verification and Rojo
`default.project.json` owns the current Rojo mapping. The remote executor should inspect it when sync/mapping is relevant and must not change it as collateral damage.

For repository-complete changes, use the checks required by the current plan/task. The current Contract Verify path includes repository verification plus pinned toolchain/Rojo build evidence. Fresh CI must belong to the actual fix head when it is used as completion evidence.

The user performs the local handoff:

```powershell
cd C:\Dev\DrawRacers
git status --short
```

If clean:

```powershell
git pull --ff-only origin main
rojo serve default.project.json
```

If `git status --short` is non-empty, do not assume those local edits are disposable.

## Human acceptance
Automated checks can establish `AUTOMATED GREEN`; they cannot establish a required Studio/human PASS.

For physics feel, camera framing, touch UX, visual readability and explicit Studio/HUMAN gates, the correct post-implementation status is:

`READY FOR HUMAN ACCEPTANCE`

until the user returns the required Roblox Studio Output/screenshots/video/measurements.

`/review` is code/process review only and does not substitute for `/acceptance` or a Studio gate.

## Completion report
At task end state:
- files changed;
- behavior implemented;
- tests run/results;
- known edge cases;
- deviations from spec;
- what felt fragile/bad in implementation;
- next smallest step;
- exact local pull/Rojo/Studio acceptance steps when human evidence is required.

Update `SESSION.md` after accepted changes where the current-state cursor/process needs to be recorded.

## v1.3.4 mandatory execution context
For any catalog implementation task, after FEATURE_LIST/SESSION/HANDOFF read the exact task row in `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`. Use `65` for Studio objects/collision, `68` for UI hierarchy, `70` for generated platform IDs. Never invent numeric Roblox IDs. Coin catalog/Pass grant logic must use `71`. Core geometry uses `73`; race lifecycle uses `74`; bot behavior uses `75`; H05 uses `76`. Final release uses `78`.

## Hard execution dependency v1.3.4
A01->A02->A03->A04 is the historical bootstrap dependency. In M2, `E04 PlayerDataService -> E05 RewardService -> E06 AnalyticsAdapter -> E07 canonical BotRacerController -> E08 confirmed Results -> E09 CosmeticService -> E10 FTUE/routing` is mandatory. Do not stub a temporary save/reward/bot system to jump ahead. Production handoff contains no `_HISTORY`; use only manifest current documents.
