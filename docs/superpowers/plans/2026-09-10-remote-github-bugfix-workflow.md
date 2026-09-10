# Remote GitHub Bugfix Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the repository itself enforce a plan-first bugfix workflow for ChatGPT working directly on GitHub `main`, with the user validating pulled changes through Rojo and Roblox Studio.

**Architecture:** Keep `AGENTS.md` files short as routing/policy entry points. Put detailed behavior in focused process documents: `BUGFIX_PROTOCOL.md` for investigate/plan/implement, `REVIEW_PROTOCOL.md` for read-only post-fix audit, and `AI_WORKFLOW_QUICKSTART.md` for copy/paste user prompts and local PowerShell handoff. Record the process decision without changing gameplay/runtime contracts.

**Tech Stack:** GitHub `main`, Git, Rojo, Roblox Studio, repository Markdown, GitHub Actions Contract Verify.

**Spec:** User-approved workflow in chat on 2026-09-10 plus `AGENTS.md`, `docs/AGENTS.md`, `docs/20_HOW_TO_DEVELOP_THE_GAME.md`, and `default.project.json`.

## Global Constraints

- Repository is `rustail1/DrawRacers`.
- Work directly on `main`; no branches or PRs.
- Remote ChatGPT/GitHub executor cannot claim knowledge of the user's local uncommitted worktree.
- Filesystem/Rojo-managed source remains canonical; Studio is a validation surface, not a competing source tree.
- BUGFIX defaults to PLAN ONLY and no repository write until the user approves the plan.
- After approval, the plan is a scope contract; scope expansion requires STOP and plan amendment.
- Automated checks cannot promote physics/camera/UI/visual/feel human gates to PASS.
- This change is process/documentation only; do not modify runtime/gameplay files or current R16 gate status.

---

### Task 1: Route tasks from repository AGENTS files

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/AGENTS.md`

- [ ] Preserve current Source of Truth and architecture rules.
- [ ] Add explicit task classification: BUGFIX / FEATURE / CONTRACT_CHANGE / TUNING / DOC_ONLY / REVIEW.
- [ ] Route BUGFIX to `docs/BUGFIX_PROTOCOL.md` and REVIEW to `docs/REVIEW_PROTOCOL.md`.
- [ ] Record direct-`main` remote execution and local-worktree visibility boundary.
- [ ] Record the approval gate and human Studio acceptance rule.

### Task 2: Add the detailed bugfix protocol

**Files:**
- Create: `docs/BUGFIX_PROTOCOL.md`

- [ ] Define INVESTIGATE / PLAN as the default read-only phase.
- [ ] Require remote HEAD, evidence, end-to-end state flow, root cause, blast radius, minimal fix plan, RED quality gate, and Studio acceptance plan.
- [ ] Require STOP when current code matches Source of Truth but requested behavior is a CONTRACT_CHANGE.
- [ ] Define IMPLEMENT only after `ДЕЛАЙ ПО УТВЕРЖДЁННОМУ ПЛАНУ.`.
- [ ] Require re-check of `main`, minimal GREEN, regression, full verification, diff audit, fresh CI, and `READY FOR HUMAN ACCEPTANCE` status.

### Task 3: Add read-only review protocol

**Files:**
- Create: `docs/REVIEW_PROTOCOL.md`

- [ ] Define `/review` as read-only.
- [ ] Compare approved plan/base SHA to current fix diff.
- [ ] Check root-cause coverage, scope creep, unnecessary refactor, architecture/public contracts, tests, and remaining human gates.
- [ ] Never modify files during review.

### Task 4: Add user quickstart and universal prompts

**Files:**
- Create: `docs/AI_WORKFLOW_QUICKSTART.md`

- [ ] Document `GitHub main -> git pull -> Rojo -> Roblox Studio -> evidence -> review/acceptance` topology.
- [ ] Give the user one universal PLAN ONLY prompt that asks the executor to classify the task.
- [ ] Give exact approval, `/review`, `/acceptance`, and CONTRACT_CHANGE prompt templates.
- [ ] Give safe local PowerShell commands, including checking `git status --short` before pull.

### Task 5: Wire process navigation and record the decision

**Files:**
- Modify: `docs/26_HANDOFF_MAP.md`
- Modify: `docs/SESSION.md`
- Create: `docs/DECISION_LOG_REMOTE_GITHUB_BUGFIX_WORKFLOW_2026-09-10.md`

- [ ] Add process routing before feature-specific handoff rows.
- [ ] Record that the workflow is active without changing R16 gameplay/gate state.
- [ ] Record rationale, remote/local boundary, direct-main policy, approval gate, review, and human acceptance.

### Task 6: Verify and audit

- [ ] Confirm changed paths are documentation/process only.
- [ ] Confirm `default.project.json` remains untouched and Rojo mapping is unchanged.
- [ ] Confirm current Studio Gate A/B/C and B17/G0 statuses are unchanged.
- [ ] Push one atomic documentation commit to `main`.
- [ ] Inspect fresh GitHub Actions Contract Verify result; report any failure instead of declaring completion.
