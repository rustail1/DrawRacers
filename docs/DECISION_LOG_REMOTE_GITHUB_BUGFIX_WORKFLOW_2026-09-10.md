# DECISION LOG — REMOTE GITHUB BUGFIX WORKFLOW — 2026-09-10

Status: **APPROVED PROCESS DECISION**  
Scope: development workflow only; no gameplay/runtime behavior change.

## Context

DrawRacers is developed with the repository as the canonical source and Rojo as the bridge into Roblox Studio. The current practical executor model is not a local Codex-only flow: ChatGPT reads and changes `rustail1/DrawRacers` directly in GitHub, the user pulls the approved `main` head to `C:\Dev\DrawRacers`, Rojo syncs the filesystem project into Roblox Studio, and the user performs human Play/Studio acceptance.

A recurring failure mode of vague requests such as `fix this bug` is premature implementation: an agent may patch the visible symptom, widen the diff, perform unrelated refactor, or damage an architecture boundary before proving the root cause.

The user observed that fixes are materially safer when the agent first produces an explicit investigation/plan describing root cause, files to touch, files not to touch, expected output and verification.

## Decision

Adopt a mandatory **plan-first bugfix workflow** for DrawRacers.

### Repository execution profile
- Repository: `rustail1/DrawRacers`.
- Branch: `main` only.
- No branches/PRs unless the Product Owner explicitly changes this policy.
- ChatGPT may act as remote GitHub executor after explicit approval of the implementation plan.
- Remote GitHub execution cannot claim knowledge of the user's uncommitted local worktree.
- One task has one active executor; do not concurrently implement the same task from remote GitHub and a local coding agent.
- Rojo-managed filesystem source remains canonical; Roblox Studio is the runtime/human acceptance environment, not a competing source tree.

### Task classification
Every requested change is first classified as `BUGFIX`, `FEATURE`, `CONTRACT_CHANGE`, `TUNING`, `DOC_ONLY`, or `REVIEW`.

A desired behavior that conflicts with current Source of Truth is not patched as a BUGFIX. It becomes a CONTRACT_CHANGE: update/approve the design contract before runtime implementation.

### BUGFIX lifecycle

```text
user evidence
-> INVESTIGATE / PLAN ONLY
-> root cause + blast radius + exact scope + RED/test plan + Studio acceptance plan
-> user approval
-> re-check main HEAD
-> RED (when meaningful)
-> confirm correct failure
-> minimal GREEN
-> targeted/full regression
-> Rojo/build/CI evidence
-> diff audit
-> direct main commit
-> /review (read-only)
-> user git pull + Rojo + Roblox Studio
-> /acceptance
```

Default BUGFIX mode is read-only. Repository changes require explicit plan approval using the standard phrase:

```text
ДЕЛАЙ ПО УТВЕРЖДЁННОМУ ПЛАНУ.
```

After approval, the plan is a scope contract. If implementation needs an unapproved file/system/public contract/architecture boundary, implementation stops and requests a plan amendment.

### Review
`/review` is read-only and checks the actual diff against the approved plan, established root cause, Source of Truth, architecture/public contracts and verification evidence. Review never silently edits the repository.

### Human acceptance
Automated checks and a clean console do not promote Roblox physics feel, camera framing, visual readability, touch UX, Studio Gate A/B/C, B17/G0 or any other explicitly human gate to PASS. The correct state after repository GREEN is `READY FOR HUMAN ACCEPTANCE` until the user supplies Studio evidence.

## New process owners
- `AGENTS.md` — repository entry/router and hard execution rules.
- `docs/AGENTS.md` — detailed AI/developer policy and Source of Truth routing.
- `docs/BUGFIX_PROTOCOL.md` — mandatory investigate/plan/implement bugfix protocol.
- `docs/REVIEW_PROTOCOL.md` — mandatory read-only post-fix review protocol.
- `docs/AI_WORKFLOW_QUICKSTART.md` — human copy/paste prompts and GitHub -> PC -> Rojo -> Studio instructions.
- `docs/26_HANDOFF_MAP.md` — process routing plus feature-owner routing.

## Non-decisions / unchanged contracts

This decision does **not**:
- change R16 gameplay/physics/pivot/camera contracts;
- mark any Studio gate PASS;
- change `default.project.json` or Rojo mapping;
- change network/DataStore/gameplay architecture;
- authorize unrelated refactor;
- replace specialized owner specs.

Current R16 Studio Gate A/B/C and B17/G0 human acceptance status remain exactly as recorded by their existing owners.

## Rationale

The workflow adds a deliberate boundary between diagnosis and implementation. It makes the root cause and blast radius reviewable before repository writes, preserves existing architecture by default, and matches the actual development topology in which ChatGPT changes remote GitHub while the user is the only authority for local Roblox Studio evidence.
