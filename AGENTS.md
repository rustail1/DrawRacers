# AGENTS.md — Draw Racers repository entry point

This root file routes AI/developer work to the production handoff in `docs/`. It does not replace specialized owner specs.

## Repository execution profile
- Repository: `rustail1/DrawRacers`.
- Working branch: **`main` only**. No branches/PRs unless the Product Owner explicitly changes policy.
- Primary remote workflow: ChatGPT may read/plan/implement directly against GitHub `main`; the user then pulls that head to the PC, Rojo syncs filesystem source into Roblox Studio, and the user performs human acceptance.
- A remote GitHub executor can see remote repository state but **cannot claim knowledge of the user's local uncommitted worktree**.
- One Task ID has one active executor. Do not concurrently implement the same task from remote GitHub and a local coding agent.
- Filesystem/Rojo-managed scripts are canonical source. Do not create competing manual copies in Roblox Studio.

## Mandatory task start
1. Read `docs/AGENTS.md`.
2. Read `docs/FEATURE_LIST.md` and `docs/SESSION.md`.
3. Read `docs/ARCHITECTURE_MAP.md` as a **navigation cache only**. Use it to choose the smallest likely current subsystem; then verify the actual current code. If code disagrees with the map, current code + Source-of-Truth owner wins.
4. Read `docs/26_HANDOFF_MAP.md` for the relevant owner specs.
5. Read the exact current task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` when the task belongs to the release catalog.
6. Read only the owner specs named by that task row/handoff plus relevant existing code and immediate dependencies.
7. Inspect current remote `main` HEAD before planning or writing.

Do not rescan the entire repository for every bug merely because it exists. Start from `ARCHITECTURE_MAP.md`, inspect the smallest relevant current owner cluster, and expand only when evidence crosses a boundary or the map is stale.

## Mandatory task classification
Before changing anything, classify the request as exactly one of:
- `BUGFIX` — implementation violates current Source of Truth;
- `FEATURE` — new approved behavior inside current product/architecture contracts;
- `CONTRACT_CHANGE` — desired behavior conflicts with current Source of Truth or changes WHAT/WHY;
- `TUNING` — empirical value change without changing ownership/meaning;
- `DOC_ONLY` — documentation/process-only change;
- `REVIEW` — read-only audit of an already implemented change.

Routing:
- `BUGFIX` -> **must follow `docs/BUGFIX_PROTOCOL.md`**.
- `REVIEW` or `/review` -> **must follow `docs/REVIEW_PROTOCOL.md` and make no writes**.
- `CONTRACT_CHANGE` -> update/approve the affected owner spec + Decision Log before runtime implementation; do not patch around an old contract.
- User copy/paste commands and local Git/Rojo/Studio handoff -> `docs/AI_WORKFLOW_QUICKSTART.md`.

## BUGFIX approval gate
Default BUGFIX mode is **INVESTIGATE / PLAN ONLY**.

Do not write to GitHub until the user explicitly approves the plan, normally with:

```text
ДЕЛАЙ ПО УТВЕРЖДЁННОМУ ПЛАНУ.
```

After approval, the plan is a scope contract. If implementation requires an unapproved file, owner, public API/network/schema change, gameplay/balance change, Rojo mapping change, or architecture boundary, **STOP and request a plan amendment** instead of silently expanding scope.

## Hard rules
- Work only on the current task; do not jump ahead.
- Do not load or recreate old `_HISTORY` documentation in normal implementation context.
- Do not invent numeric Roblox Place/Product/Pass/Asset IDs.
- Do not create duplicate top-level Service/Controller families that conflict with `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`.
- Protect existing user/local changes; remote GitHub state is not proof that the PC worktree is clean.
- `docs/ARCHITECTURE_MAP.md` is never proof of current behavior; re-read the current code before establishing root cause.
- If investigation proves the architecture map stale, report the stale row. Update it only when architecture/navigation materially changed, not for every local implementation edit.
- For implementation bugs: establish root cause before production change; do not stack speculative fixes.
- TDD when meaningful: RED -> confirm correct FAIL -> minimal GREEN -> regression -> fresh verification.
- For Roblox physics/camera/UI/visual/feel where a meaningful automated RED is not possible, define exact Studio/manual reproduction instead of writing a fake static test.
- Unexpected verification failure triggers systematic debugging; do not weaken expectations to recover GREEN.

## Human acceptance
Human Studio acceptance is required for physics feel, camera, touch UX, visual readability, and every task/gate whose owner requires human evidence.

Repository tests, CI, Rokit and Rojo build may prove `AUTOMATED GREEN`, but they cannot promote a required human gate to PASS. After implementation/review, use `READY FOR HUMAN ACCEPTANCE` until the user supplies the required Roblox Studio evidence.

## Current bootstrap dependency
`A01 -> A02 -> A03 -> A04 -> B01` remains the historical mandatory bootstrap dependency. Current work must still follow the active cursor in `docs/SESSION.md`; do not restart completed bootstrap work.
