# Current Architecture Navigation Map Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. This is a documentation/process-only change; no runtime or Rojo mapping changes are authorized.

**Goal:** Add a compact current-runtime architecture/navigation map so future DrawRacers bug investigations can start from the smallest relevant subsystem instead of repeatedly scanning the whole repository.

**Architecture:** Keep existing Source-of-Truth ownership unchanged. `docs/ARCHITECTURE_MAP.md` is a non-authoritative navigation cache derived from current `main` code and links back to existing owner docs; `AGENTS.md` and the bugfix/quickstart workflow route investigations through it before opening current implementation files.

**Tech Stack:** GitHub `main`, Markdown process docs, Roblox/Luau source inspection, Rojo `default.project.json`, GitHub Actions Contract Verify.

**Spec:** User-approved DOC_ONLY architecture-audit request plus `docs/DECISION_LOG_REMOTE_GITHUB_BUGFIX_WORKFLOW_2026-09-10.md`.

## Global Constraints

- Repository is `rustail1/DrawRacers`; branch is `main` only.
- Documentation/navigation only: do not modify Lua runtime, tests, configs, `default.project.json`, physics, UI behavior, or Studio gate state.
- `docs/ARCHITECTURE_MAP.md` is navigation only; current code + current Source-of-Truth owners outrank it.
- Preserve `R16 PRE-STUDIO CLOSURE P0–P6` and all Studio/HUMAN pending statuses.
- Do not duplicate the target architecture contract in doc `21`, network contract in `22`, or feature routing in `26`.
- Full repository verification must still pass after documentation changes.

---

### Task 1: Audit current implemented runtime topology

**Files:**
- Read: `default.project.json`
- Read: `src/client/**`
- Read: `src/server/**` current M0/R16 owners
- Read: `src/shared/**` current M0/R16 owners
- Read: `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`
- Read: `docs/26_HANDOFF_MAP.md`
- Read: `docs/SOURCE_MAP.md`

**Interfaces:**
- Consumes: current remote HEAD and current Source-of-Truth routing.
- Produces: verified current-owner inventory and dependency flows for the map.

- [x] Confirm current remote `main` HEAD before audit.
- [x] Inspect Rojo mapping and current filesystem roots.
- [x] Inspect current client input/drawing/bootstrap/presentation owners.
- [x] Inspect current server stroke authority/racer physics/obstacle/debug owners.
- [x] Inspect shared config/math/type owners.
- [x] Compare current implementation against target doc `21` and explicitly separate implemented M0/R16 modules from future target modules.

### Task 2: Create the navigation cache

**Files:**
- Create: `docs/ARCHITECTURE_MAP.md`

**Interfaces:**
- Consumes: Task 1 verified topology.
- Produces: a current-code navigation cache used only to choose what to inspect next.

- [x] Record audit date and runtime base HEAD.
- [x] State precedence: current code + Source of Truth > map.
- [x] Record Rojo bridge and current M0/R16 dependency graph.
- [x] Map actual client/server/shared owners and immediate dependencies.
- [x] Add symptom-to-first-files routing for common bug classes.
- [x] Add protected boundary surfaces and map refresh triggers.
- [x] Explicitly mark future target services/controllers as not currently implemented.

### Task 3: Route future bugfixes through the map

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/BUGFIX_PROTOCOL.md`
- Modify: `docs/AI_WORKFLOW_QUICKSTART.md`
- Modify: `docs/DECISION_LOG_REMOTE_GITHUB_BUGFIX_WORKFLOW_2026-09-10.md`

**Interfaces:**
- Consumes: `docs/ARCHITECTURE_MAP.md`.
- Produces: mandatory map-first/minimal-context investigation workflow without making the map authoritative.

- [x] Add the map to mandatory task navigation in root `AGENTS.md`.
- [x] Require BUGFIX investigation to select the smallest likely system cluster from the map, then verify current code and immediate dependencies.
- [x] Forbid repository-wide rescans without a concrete reason.
- [x] Require reporting a stale map rather than trusting it over current code.
- [x] Update the copy/paste bug prompt so the user does not have to repeat these rules manually.
- [x] Record the navigation-cache decision in the existing workflow Decision Log.

### Task 4: Self-review and verify

**Files:**
- Verify only; no runtime file changes.

**Interfaces:**
- Consumes: final documentation diff.
- Produces: verified DOC_ONLY handoff.

- [x] Check that no Lua/config/test/Rojo mapping file is in the diff.
- [x] Check the map does not claim future target modules are already implemented.
- [x] Check existing R16 human gate language is untouched.
- [x] Run fresh `Contract Verify`; require `python verify.py`, Rokit/toolchain, and Rojo build to pass.
- [x] Compare final head against the task base and confirm scope is documentation/navigation only.
