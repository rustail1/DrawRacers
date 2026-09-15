# AGENTS.md — Draw Racers repository entry point

This root file routes AI/developer work to the production handoff in `docs/`. It does not replace specialized owner specs.

## Current execution profile
- **Local-file / local-folder workflow only.** Git/GitHub/branches/commits/PRs are not part of the current development loop unless the Product Owner explicitly re-enables them.
- The local project folder/archive supplied for the session is the execution baseline.
- Work in a separate copy/overlay when possible; do not overwrite the user's only source copy without an explicit request.
- Filesystem/Rojo-managed scripts remain canonical source. Roblox Studio provides live runtime/human evidence.
- One Task ID has one active executor.

## Mandatory task start
1. Read `docs/AGENTS.md`.
2. Read `docs/DEVELOPMENT_PRINCIPLES.md` for mandatory module-boundary, local-fix vs `MODULE_REWRITE`, testing, lifecycle, client/server, and performance rules.
3. Read `docs/FEATURE_LIST.md` and `docs/SESSION.md`.
4. Read `docs/ARCHITECTURE_MAP.md` as a **navigation cache only**. Use it to choose the smallest likely current subsystem; then verify the actual current code. If code disagrees with the map, current code + Source-of-Truth owner wins.
5. Read `docs/26_HANDOFF_MAP.md` for the relevant owner specs.
6. Read the exact current task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` when the task belongs to the release catalog.
7. Read only the owner specs named by that task row/handoff plus relevant existing code and immediate dependencies.
8. Confirm the exact local baseline folder/archive before planning or writing.

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
- User copy/paste commands and local-file/Rojo/Studio handoff -> `docs/AI_WORKFLOW_QUICKSTART.md`.

`MODULE_REWRITE` is not a new task classification. It is the mandatory implementation strategy from `docs/DEVELOPMENT_PRINCIPLES.md` when investigation proves the selected owner is structurally unhealthy. If WHAT/WHY or an approved external contract changes, the task is still `CONTRACT_CHANGE` first.

## BUGFIX approval gate
Default BUGFIX mode is **INVESTIGATE / PLAN ONLY** unless the user explicitly asks to execute an already-approved plan.

After approval, the plan is a scope contract. If implementation requires an unapproved file, owner, public API/network/schema change, gameplay/balance change, Rojo mapping change, or architecture boundary, **STOP and request a plan amendment**.

## Hard rules
- Work only on the current task; do not jump ahead.
- Do not load or recreate old `_HISTORY` documentation in normal implementation context.
- Do not invent numeric Roblox Place/Product/Pass/Asset IDs.
- Do not create duplicate top-level Service/Controller families that conflict with `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`.
- Protect the supplied local baseline. Do not assume another copy on the PC has identical edits.
- `docs/ARCHITECTURE_MAP.md` is never proof of current behavior; re-read the current code before establishing root cause.
- If investigation proves the architecture map stale, report the stale row. Update it only when architecture/navigation materially changed, not for every local implementation edit.
- For implementation bugs: establish root cause before production change; do not stack speculative fixes.
- A local patch is allowed only while the selected module boundary is healthy under `docs/DEVELOPMENT_PRINCIPLES.md`. If root cause is structural (duplicate owner/pipeline, obsolete compatibility path, wrong module responsibility/API, repeated interacting patches), **STOP the local patch path and plan a coherent `MODULE_REWRITE`**. Do not add another compatibility branch to avoid the rewrite.
- TDD when meaningful: RED -> confirm correct FAIL -> minimal GREEN -> regression -> fresh verification.
- For Roblox physics/camera/UI/visual/feel where a meaningful automated RED is not possible, define exact Studio/manual reproduction instead of writing a fake static test.
- Unexpected verification failure triggers systematic debugging; do not weaken expectations to recover GREEN.

## Human acceptance
Human Studio acceptance is required for physics feel, camera, touch UX, visual readability, and every task/gate whose owner requires human evidence.

Local automated tests and Rojo build may prove `AUTOMATED GREEN`, but they cannot promote a required human gate to PASS. After implementation/review, use `READY FOR HUMAN ACCEPTANCE` until the user supplies the required Roblox Studio evidence.

## Current bootstrap dependency
`A01 -> A02 -> A03 -> A04 -> B01` remains the historical mandatory bootstrap dependency. Current work must still follow the active cursor in `docs/SESSION.md`; do not restart completed bootstrap work.
