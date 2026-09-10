# BUGFIX PROTOCOL — ROBLOX / ROJO / REMOTE GITHUB

Status: **MANDATORY PROCESS CONTRACT**  
Applies to: implementation defects where current runtime behavior violates the current Source of Truth.  
Default executor profile for DrawRacers: **ChatGPT works against remote GitHub `main`; user pulls to PC, Rojo syncs filesystem source into Roblox Studio, user performs human acceptance.**

This protocol prevents symptom patches, scope creep, speculative fixes, and architecture damage during local bug repair.

---

## 0. TASK CLASSIFICATION GATE

Before treating anything as a BUGFIX, classify the request as exactly one of:

- `BUGFIX` — current implementation violates the current Source of Truth.
- `FEATURE` — new approved behavior inside the current product/architecture contracts.
- `CONTRACT_CHANGE` — desired behavior conflicts with the current Source of Truth or changes WHAT/WHY.
- `TUNING` — empirical value adjustment without changing the meaning/ownership contract.
- `DOC_ONLY` — documentation/process change with no runtime behavior change.
- `REVIEW` — read-only audit of an already implemented change.

If current code correctly follows the current Source of Truth but the user wants different behavior, **STOP BUGFIX**. Report `CLASSIFICATION: CONTRACT_CHANGE`, name the affected owner docs/Decision Log, and do not patch production code around the old contract.

---

# MODE 1 — INVESTIGATE / PLAN

**Default mode for every BUGFIX. No repository writes.**

Allowed:
- read repository files;
- inspect current `main`, commits, history, diffs and CI evidence;
- read `AGENTS.md`, `docs/ARCHITECTURE_MAP.md`, Source of Truth and exact owner docs;
- inspect `default.project.json` and Rojo mapping;
- inspect related code/tests/configs;
- perform safe read-only reasoning/checks.

Forbidden in PLAN ONLY:
- modify/create/delete repository files;
- commit/push;
- reset/revert unrelated work;
- change architecture;
- alter a test merely to manufacture GREEN.

## 1. REPOSITORY STATE

For the default remote GitHub executor, report:

```text
EXECUTION: REMOTE_GITHUB
BRANCH: main
REMOTE_HEAD: <sha>
LOCAL_WORKTREE: UNKNOWN TO REMOTE EXECUTOR
ROJO_PROJECT: default.project.json
```

Do not claim the user's `C:\Dev\DrawRacers` worktree is clean unless the user supplies local `git status` evidence. Existing local user changes are protected.

Read `default.project.json` and identify which filesystem roots are Rojo-managed. For current DrawRacers the canonical mapping includes:
- `src/shared` -> `ReplicatedStorage.Shared`;
- `src/server` -> `ServerScriptService`;
- `src/client` -> `StarterPlayer.StarterPlayerScripts`;
- declared GUI/runtime folders from the project file.

Filesystem/Rojo-managed source is authoritative. Do not create a competing manual Script/LocalScript/ModuleScript in Studio to bypass the repository.

## 1A. PROJECT CONTEXT / ARCHITECTURE MAP ROUTING

Before tracing the bug, read `docs/ARCHITECTURE_MAP.md` and use it only to choose the smallest likely **current implemented** subsystem.

Mandatory routing rules:
1. Start from the map's symptom/system row and select the smallest likely owner cluster, normally 2–5 files/systems plus direct dependencies.
2. Read the **current GitHub code** for that cluster before making any root-cause claim.
3. Read the exact Source-of-Truth owner docs routed by `docs/26_HANDOFF_MAP.md`.
4. Expand into another subsystem only when evidence shows the flow crosses that boundary or the first hypothesis cannot explain the observation.
5. Do not perform a full repository rescan merely by default; record the concrete reason if a broad scan becomes necessary.
6. `ARCHITECTURE_MAP.md` is a navigation cache, not proof. If current code conflicts with it, current code and current Source-of-Truth owners take priority.
7. If a row is stale, report exactly what is stale. Update the map only if architecture/navigation materially changed; a local bugfix that keeps the same owners should not churn the map.
8. Do not treat target/future owners from `docs/21_SYSTEM_CLASS_ARCHITECTURE.md` as already implemented. Verify that a file/system actually exists in current `main` before routing a fix through it.

The purpose is **less context, not less rigor**: map first, then current code, then evidence.

## 2. BUG CONTRACT

Restate only supported facts:

```text
FACT:
<what happens now>

EXPECTED:
<what should happen according to current Source of Truth>

REPRODUCTION:
<exact user steps>

EVIDENCE:
<Output / stack trace / screenshot / video / measured observation>

CONSTRAINTS:
<explicit constraints, if any>
```

Do not invent missing observations. Separate user-observed facts from hypotheses.

## 3. REPRODUCTION AND EVIDENCE

Report:

```text
REPRODUCIBLE:
yes / no / cannot be reproduced remotely

OBSERVED EVIDENCE:
<facts confirmed by code, Git history, logs, tests, or supplied evidence>

UNKNOWN:
<facts not yet established>
```

A remote GitHub executor often cannot reproduce Roblox solver/camera/touch/visual bugs directly. That is not permission to guess. If one minimal Studio observation would distinguish competing causes, stop and request exactly that observation.

## 4. TECHNICAL RECONNAISSANCE

Trace the failing scenario end to end:

```text
ENTRY POINT
-> event/function/controller/service that starts the scenario

DATA / STATE FLOW
-> how state/input moves through the current owners

DEPENDENCIES
-> exact modules/configs/remotes/runtime objects involved

FAILURE POINT
-> first point where actual behavior diverges from expected behavior
```

Inspect only relevant current owners, including when applicable:
- Script / LocalScript / ModuleScript;
- configs and shared types;
- RemoteEvent / RemoteFunction and client/server boundary;
- Player / Character / respawn lifecycle;
- UI creation/reset lifecycle;
- DataStore/persistence ownership;
- collision/physics ownership;
- Rojo mapping/sync ownership;
- a similar working scenario already present in this project;
- recent commits that could explain a regression.

Reuse existing owners first. Do not create a new Manager/Service/Controller/Event/Storage/abstraction when an existing owner already has the responsibility.

## 5. ROOT CAUSE

Return:

```text
OBSERVED BUG:
...

PROVEN FACTS:
...

CHAIN:
A
-> B
-> C
-> incorrect state D

ROOT CAUSE:
...

CONFIDENCE:
high / medium / insufficient

WHY:
...

ALTERNATIVE HYPOTHESES:
<only if still genuinely possible>
```

If confidence is insufficient, **do not propose a production fix as established fact**. Propose one minimal experiment that can confirm or falsify the leading hypothesis.

## 6. BLAST RADIUS

Report:

```text
TOUCH:
path/module -> why it must change

DEPENDENCIES TO VERIFY:
system -> why it may be affected

DO NOT TOUCH:
paths/systems that must remain unchanged

PUBLIC CONTRACTS TO PRESERVE:
interfaces/events/data formats/module APIs/gameplay rules
```

Explicitly flag elevated blast radius if the change touches:
- shared framework/architecture;
- client/server network contract;
- DataStore/schema/migration;
- common UI framework;
- Character lifecycle;
- public ModuleScript API;
- Rojo project mapping;
- collision matrix or physics ownership;
- gameplay rules/balance.

## 7. MINIMAL FIX PLAN

Propose **one primary fix** for the established root cause. Do not redesign the system to present multiple elegant alternatives unless the current architecture truly cannot support a local repair.

For every step state:

```text
STEP N
CHANGE: what changes
WHY: why this addresses the root cause
FILE/OWNER: exact path/module
INVARIANT PRESERVED: what existing behavior/contract remains unchanged
EXPECTED RESULT: observable result after the step
VERIFY: exact test/check
```

Forbidden without separate justification:
- unrelated refactor;
- architecture cleanup unrelated to the defect;
- public API rename;
- gameplay rule change;
- balance change;
- neighboring-system change;
- legacy deletion;
- new dependency;
- bundling another bugfix.

If a local fix is not sufficient and an architecture boundary must change, **STOP**. Explain the required boundary change and blast radius and wait for explicit approval as a plan amendment or CONTRACT_CHANGE.

## 8. PLAN IS A SCOPE CONTRACT

The final plan must contain:

```text
BASE_SHA: <remote main sha used for analysis>
FILES TO CHANGE:
- exact/path
...

FILES/AREAS NOT TO CHANGE:
- exact path/owner or system
...
```

After the user approves implementation, these files and boundaries become the implementation scope contract.

If implementation later requires:
- a new production file not in the plan;
- another Service/Controller/Manager;
- another Source-of-Truth owner;
- a public API/network/schema change not approved;
- a gameplay/balance change;
- a Rojo mapping change;
- a file explicitly listed under DO NOT TOUCH;

then **STOP** and request a plan amendment. Do not silently expand scope.

## 9. TEST PLAN BEFORE CHANGE

Define the smallest meaningful verification set.

```text
REGRESSION RED:
How to demonstrate the existing defect before the fix.

TARGETED GREEN:
How to demonstrate the intended repaired behavior.

EDGE CASES:
Only defect-related edge cases.

REGRESSION:
Existing scenarios that must remain green.
```

### RED QUALITY GATE

Before production change, a RED test must:
1. fail because of the observed contract violation, not a typo/path/environment problem;
2. be expected to turn GREEN from the proposed root-cause fix;
3. prefer observable behavior/invariant over private implementation detail;
4. not weaken an existing assertion just to permit the new code.

If a meaningful automated RED is impractical for Roblox physics, camera, touch UX, visual readability, animation feel, or other human-observable behavior, **do not create a fake static test merely to satisfy TDD wording**. Define an exact `MANUAL RED`/Studio reproduction and keep automated tests focused on the parts that can be proved deterministically.

## 10. ROBLOX STUDIO ACCEPTANCE PLAN

Before implementation, define the exact final handoff the user will run after pulling the finished GitHub change:

```text
1. local command / Studio action
EXPECTED: exact observation

2. ...
EXPECTED: ...

OUTPUT:
required lines and errors/warnings that must not occur

REGRESSION:
neighboring manual scenarios to repeat
```

Automated checks never substitute for required human acceptance of physics feel, camera framing, touch UX, visual readability, or B17/G0/Studio gates.

## 11. PLAN SUMMARY AND STOP

End MODE 1 with:

```text
CLASSIFICATION: BUGFIX
BASE_SHA: ...
ROOT CAUSE: ...
FIX: ...
FILES TO CHANGE: ...
ARCHITECTURE CHANGE: NO / YES
RISK: low / medium / high + reason
AUTOMATED CHECKS: ...
MANUAL STUDIO CHECK: ...
STATUS: PLAN READY — WAITING FOR APPROVAL
```

Then stop. **Do not change the repository.**

Standard approval phrase:

```text
ДЕЛАЙ ПО УТВЕРЖДЁННОМУ ПЛАНУ.
```

---

# MODE 2 — IMPLEMENT

MODE 2 starts only after explicit user approval of the plan.

## 12. PRE-WRITE RECHECK

Before any write:
1. re-fetch remote GitHub `main` HEAD;
2. compare it with `BASE_SHA`;
3. if unchanged, continue;
4. if changed, inspect the intervening diff;
5. if the approved plan may be stale or overlaps changed owners, **STOP** and report the conflict;
6. never overwrite protected user/local changes by assumption.

## 13. RED -> GREEN

If the plan includes an automated regression:
1. add/run the smallest regression proving the current bug;
2. confirm the failure is the expected RED;
3. only then make the minimal production change;
4. run the targeted test to GREEN.

If the plan uses a manual RED because automation is inappropriate, preserve the exact human reproduction for final acceptance and run all deterministic automated invariants available around the changed owner.

If the root-cause hypothesis proves wrong during implementation, **STOP**. Do not stack a second speculative fix. Return to INVESTIGATE with the new evidence.

## 14. IMPLEMENTATION RULES

- Change only approved scope.
- Reuse current architecture/owners.
- No unrelated refactor.
- No silent contract/balance change.
- No manual competing Studio script for a Rojo-managed file.
- Do not weaken tests to make production code pass.
- Preserve public contracts unless the plan explicitly approved a change.

If several attempted fixes start crossing unrelated subsystems, stop and classify the problem as a possible architecture/contract issue.

## 15. VERIFICATION

Run/obtain the checks approved by the plan. For the current repository baseline, repository-complete verification normally includes:

```text
python verify.py
rokit install --no-trust-check
rojo build default.project.json -o <temporary rbxlx path>
```

For remote GitHub execution, a fresh `Contract Verify` GitHub Actions run may be the execution evidence for these commands when its job log proves the exact checks completed successfully.

Also:
- inspect warnings/errors relevant to the change;
- inspect the final diff against `BASE_SHA`/approved scope;
- confirm no accidental files changed;
- confirm Source of Truth remains consistent.

Unexpected verification failure triggers systematic debugging. Do not alter expectations simply to recover GREEN.

## 16. GIT POLICY FOR DRAWRACERS

Current project policy:
- repository: `rustail1/DrawRacers`;
- branch: **`main` only**;
- no branch/PR flow for this project unless the Product Owner explicitly changes policy;
- after an approved implementation plan, the remote GitHub executor may commit/push the bounded fix directly to `main`;
- implementation should remain reviewable and limited to the approved task.

A PLAN ONLY request never authorizes writes.

## 17. IMPLEMENTATION REPORT

Return:

```text
ROOT CAUSE:
...

CHANGED:
path -> change -> why

DIFF SCOPE:
...

NOT CHANGED:
...

TESTS:
check -> result

CI / ROJO:
...

WARNINGS / ERRORS:
...

REMAINING RISKS:
...

ROBLOX STUDIO ACCEPTANCE:
exact local pull/Rojo/Studio steps

EXPECTED RESULT:
...

STATUS:
READY FOR HUMAN ACCEPTANCE
```

Do not say the bug is finally fixed when its acceptance requires a human Studio check that has not yet happened.

---

# MODE 3 — HUMAN ACCEPTANCE

The user pulls the accepted remote head to the PC, runs Rojo, starts the required Roblox Studio scenario, and returns Output/screenshots/video/measurements.

Only supplied human evidence can close a human gate. If evidence fails, reopen a bounded BUGFIX investigation from the failed observation; do not automatically broaden the previous plan.

Recommended local safety handoff before pull:

```powershell
cd C:\Dev\DrawRacers
git status --short
```

If output is non-empty, preserve those local changes and resolve/snapshot them before pulling. If clean:

```powershell
git pull --ff-only origin main
rojo serve default.project.json
```

Then connect the Rojo plugin in Roblox Studio and perform the exact acceptance steps from the implementation report.
