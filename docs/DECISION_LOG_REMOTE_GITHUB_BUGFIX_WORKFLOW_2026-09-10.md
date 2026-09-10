# DECISION LOG — REMOTE GITHUB BUGFIX WORKFLOW — 2026-09-10

Status: **APPROVED PROCESS DECISION**  
Scope: development workflow only; no gameplay/runtime behavior change.

## Context

DrawRacers is developed with the repository as the canonical source and Rojo as the bridge into Roblox Studio. The current practical executor model is not a local Codex-only flow: ChatGPT reads and changes `rustail1/DrawRacers` directly in GitHub, the user pulls the approved `main` head to `C:\Dev\DrawRacers`, Rojo syncs the filesystem project into Roblox Studio, and the user performs human Play/Studio acceptance.

A recurring failure mode of vague requests such as `fix this bug` is premature implementation: an agent may patch the visible symptom, widen the diff, perform unrelated refactor, or damage an architecture boundary before proving the root cause.

The user observed that fixes are materially safer when the agent first produces an explicit investigation/plan describing root cause, files to touch, files not to touch, expected output and verification.

A second inefficiency is repeatedly rediscovering the entire repository for every small bug. The repository already has detailed target architecture and owner specs, but those documents intentionally include future systems that are not yet implemented. A compact map of the **current implemented runtime** can reduce context and search cost if it is treated only as navigation and never as proof.

## Decision

Adopt a mandatory **plan-first bugfix workflow** for DrawRacers and a non-authoritative **current architecture navigation cache**.

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

### Current architecture navigation cache
`docs/ARCHITECTURE_MAP.md` records the current implemented code topology, current M0/R16 owners, immediate dependencies, common symptom routing and protected public boundaries.

It is explicitly **not Source of Truth**. The precedence is:

```text
current GitHub main code + current Source-of-Truth owner docs
> ARCHITECTURE_MAP navigation cache
```

For a bug investigation, the executor starts from the smallest likely cluster in the map, reads the current code for that cluster and its immediate dependencies, and expands only when evidence crosses a boundary. A repository-wide rescan is not the default.

If the map disagrees with current code, the map is stale. The executor reports the stale row and uses current code/current owner docs. The map is refreshed only when architecture/navigation materially changes; ordinary local bugfixes do not churn it.

Target/future systems documented in `21_SYSTEM_CLASS_ARCHITECTURE.md` are not assumed to exist. The map distinguishes currently implemented M0/R16 owners from future target modules.

### BUGFIX lifecycle

```text
user evidence
-> ARCHITECTURE_MAP navigation
-> current code + exact owner-doc verification
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

## Process owners
- `AGENTS.md` — repository entry/router and hard execution rules.
- `docs/AGENTS.md` — detailed AI/developer policy and Source of Truth routing.
- `docs/ARCHITECTURE_MAP.md` — non-authoritative current implemented-runtime navigation cache.
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
- replace specialized owner specs;
- make `ARCHITECTURE_MAP.md` authoritative over current code or Source of Truth.

Current R16 Studio Gate A/B/C and B17/G0 human acceptance status remain exactly as recorded by their existing owners.

## Rationale

The workflow adds a deliberate boundary between diagnosis and implementation. The architecture map adds a second boundary between **navigation** and **evidence**: it lets the executor find the likely owner quickly without pretending cached architecture knowledge proves current behavior. Together they make root cause and blast radius reviewable before repository writes, preserve existing architecture by default, reduce unnecessary context loading, and match the actual topology in which ChatGPT changes remote GitHub while the user is the only authority for local Roblox Studio evidence.
