# DEVELOPMENT_PRINCIPLES.md — Draw Racers Engineering Constitution

Status: **MANDATORY ENGINEERING PROCESS CONTRACT**  
Applies to: all Draw Racers runtime, shared modules, client/server code, tests, refactors, module rewrites, and AI-assisted development.

This document defines **how the codebase is allowed to evolve**. Product behavior remains owned by the current Source-of-Truth product/spec documents. If this document conflicts with an approved product contract, the product contract wins and this engineering document must be updated deliberately rather than worked around in code.

## 1. Source basis and adaptation

These principles are adapted for Draw Racers from the Roblox development practices emphasized in the project reference books:

- Nathan Tucker, *Make Your Own Roblox Games: A Step-by-Step Guide* — plan and organize the project, keep related objects structured, use reusable/OOP-style organization where it helps, monitor performance, profile, test on different devices, and treat player experience/playtesting as part of development.
- Tomas Gonzalez Dominguez, *Mastering Scripting in Roblox Studio* — use descriptive local code, small focused functions, modules for reusable logic, explicit event handling, resource cleanup, frequent testing, unit tests where meaningful, and repeated playtesting.
- Zander Brumbaugh, *Coding Roblox Games Made Easy* — build larger Roblox backends modularly, separate main functionalities into modules, test systems throughout development, use explicit client/server communication, and keep verification of authoritative gameplay actions on the server.

The books are guidance, not executable Source of Truth. Draw Racers keeps modern project-specific choices such as Luau strictness, Rojo-managed filesystem source, explicit module ownership, existing RemoteNames/types, and the approved architecture specs. We adopt the **principles**, not every literal code idiom shown in a book example.

## 2. Core architecture rules

### 2.1 One module = one responsibility

Every production module must have one responsibility that can be written in one clear sentence.

A module should answer:
- What does it own?
- What inputs does it accept?
- What outputs/state does it expose?
- What direct dependencies does it require?
- What is explicitly outside its responsibility?

If those answers require several unrelated responsibilities, the boundary is unhealthy.

### 2.2 One fact = one owner

A gameplay rule, geometry transform, state transition, tuning value, or validation rule has one canonical owner.

Consumers call/read that owner. They do not copy the algorithm and keep a second version in sync.

Examples:
- shared deterministic shape math has one owner;
- server authority has one owner;
- tuning numbers live in the approved config owner;
- UI presentation does not become a second gameplay authority.

### 2.3 One gameplay pipeline

Do not keep parallel production pipelines for the same behavior.

Forbidden as a steady state:
- old + new redraw paths;
- client cleanup math + different server cleanup math;
- two services that both believe they own the same state;
- compatibility path that silently becomes permanent;
- legacy fallback that bypasses the current authoritative path.

A staged migration may temporarily need compatibility code only when the approved plan names:
1. why it is required;
2. its exact consumers;
3. the removal checkpoint;
4. the test proving it can be deleted.

If no removal checkpoint exists, do not add the compatibility path.

### 2.4 Small public API, private implementation

Expose only operations consumers genuinely need. Internal construction order, helper functions, temporary state, and implementation details stay private.

Tests and callers should depend on module behavior/invariants, not accidental private field names or line-level implementation details.

### 2.5 Explicit dependency direction

Composition roots (`Bootstrap.server.lua`, `Bootstrap.client.lua`, or another explicitly approved composition owner) wire systems together.

Lower-level modules do not reach upward into orchestration owners. Circular project-module dependencies are forbidden.

Prefer dependency flow from orchestration -> focused modules -> pure/shared utilities, never a cycle.

### 2.6 Pure shared math where parity matters

When client prediction/presentation and server authority need the same deterministic transformation, put that transformation in one pure shared module.

Pure math modules must not depend on Workspace, Players, Instances, RemoteEvents, UI, or mutable world state unless their contract explicitly requires it.

The server still recomputes authoritative results from untrusted client input.

## 3. Roblox client/server authority

Client responsibilities normally include:
- input collection;
- local prediction;
- presentation/UI/camera;
- sending the smallest approved semantic request.

Server responsibilities normally include:
- validating the request envelope and values;
- rate/sequence/security checks;
- authoritative gameplay state;
- authoritative rewards/results;
- recomputing gameplay-critical results rather than trusting client-authored world state.

RemoteEvents/RemoteFunctions are boundaries, not shared authority. Keep payload contracts explicit and bounded.

## 4. Healthy local fix vs full module rewrite

**Do not rewrite every module for every typo.** A small local fix is correct when the module boundary is healthy.

### 4.1 Local fix is allowed when all are true

- the root cause is inside one existing natural owner;
- the owner's one-sentence responsibility remains correct;
- the current public API still expresses the desired architecture;
- there is one production path for the behavior;
- the fix does not require another compatibility/fallback path;
- no neighboring owner must learn private details of the module;
- existing tests can express the repaired behavior as a contract/invariant.

Then use the normal BUGFIX protocol and make the smallest proven repair.

### 4.2 MODULE_REWRITE escalation is required when investigation proves one or more structural failures

Escalate instead of stacking another patch when:
- the module owns multiple unrelated responsibilities;
- the same transformation/rule exists in multiple modules;
- old/new implementations run in parallel;
- a new compatibility branch would preserve an obsolete internal design;
- the public API itself represents the wrong architecture;
- callers depend on private/transitional state;
- repeated fixes interact because old state machines/paths remain alive;
- a correct change requires deleting an obsolete lifecycle rather than adding another condition;
- tests mainly protect legacy implementation details instead of desired behavior;
- the root cause repeatedly crosses the same broken module boundary.

`MODULE_REWRITE` is an **implementation strategy**, not a new product-task classification. The task is still BUGFIX/FEATURE/TUNING/etc. If WHAT/WHY or an approved external product contract changes, use `CONTRACT_CHANGE` first.

### 4.3 Meaning of "rewrite the whole module"

A module rewrite means the selected module is re-derived from its approved contract as one coherent implementation.

It does **not** mean blindly deleting correct behavior. Before implementation, classify existing behavior/API as:
- `KEEP` — still part of the desired contract;
- `CHANGE` — contract/API remains needed but implementation or shape must change;
- `DELETE` — legacy/transitional behavior no longer belongs.

Direct consumers may be migrated atomically in the same rewrite stage when required. Do not keep a fake legacy wrapper merely to satisfy stale tests.

## 5. Mandatory MODULE_REWRITE workflow

For every approved module rewrite:

1. **Fresh local baseline** — re-read the exact supplied folder/archive before planning and again before writing; do not assume another local copy is identical.
2. **Read the owner** — selected module, owner spec, direct consumers, direct dependencies, and relevant tests only.
3. **State responsibility** — one sentence describing what the rewritten module owns.
4. **Define boundary** — exact inputs, outputs, owned state, dependencies, and explicit non-responsibilities.
5. **Classify API/behavior** — `KEEP / CHANGE / DELETE`.
6. **Define invariants** — player-visible and architectural behavior that must remain true.
7. **RED first where meaningful** — write/replace tests for the desired module contract; confirm the RED fails for the right reason.
8. **Replace coherently** — implement the module as the target design, not as another layer over the old internals.
9. **Migrate direct consumers atomically** — only consumers approved by the plan.
10. **Delete legacy path** — remove obsolete branches/helpers/transitional state in the same rewrite stage once no approved consumer uses them.
11. **Focused GREEN** — module/contract tests.
12. **Current-contract verification** — run the task-specific current tests/checks. For Core V3 Flat work, the authoritative automated Studio suite is C01–C07; do not force legacy CR2/R17 Python contracts to pass by restoring obsolete architecture.
13. **Rojo build** — pinned/current project build must succeed.
14. **Fresh artifact evidence** — every automated/build result used as completion evidence must belong to the exact edited artifact. CI is optional and only relevant if the Product Owner later re-enables that workflow.
15. **Diff/self-review** — confirm scope, ownership, dead code, duplicate pipelines, API leakage, and accidental neighboring changes.
16. **Human Studio evidence when required** — physics, feel, camera, touch UX, visual readability, and other human gates remain pending until actual Roblox Studio evidence exists.

A rewrite stage is not GREEN merely because CI was made green. It is GREEN only when the intended boundary is simpler and the obsolete path is gone.

## 6. Testing principles

### 6.0 Current legacy Python-suite warning

The current local package still contains historical Python contract tests under `tests/` and `verify.py`. Many encode superseded CR2/R17 implementation details (twin-drive/staged-pair/old redraw contracts). They are retained for now because test migration/deletion is a separate non-documentation task.

For current Core V3 mechanics:
- do **not** treat a failing legacy Python contract as authority over `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`;
- do **not** restore deleted legacy architecture just to make those tests green;
- current mechanical automation is C01–C07 in Roblox Studio;
- migrate/retire stale Python contracts in a dedicated post-approval task.


### 6.1 Test contracts, not history

Prefer tests for:
- deterministic input -> output;
- state transition/invariant;
- authoritative ownership;
- lifecycle cleanup;
- identity that is intentionally persistent;
- bounded payload/rate/security behavior;
- absence of forbidden duplicate authority;
- regressions observed by the player.

Static source-text tests are acceptable for deliberate architecture constraints, generated-tree/Rojo contracts, forbidden dependencies, or other properties that are genuinely static. They should not force an obsolete implementation to survive a rewrite.

If a test checks an implementation detail that the approved architecture intentionally removes, replace the test with one that protects the current behavior/invariant.

Never weaken an expectation only to obtain GREEN.

### 6.2 Human evidence is real evidence

Automated tests cannot establish Roblox physics feel, contact quality, camera feel, touch usability, visual readability, or animation feel when those depend on the live engine/player perception.

For those properties:
- define exact Studio reproduction/acceptance;
- automate surrounding deterministic invariants;
- report `READY FOR HUMAN ACCEPTANCE` until the user supplies evidence.

## 7. Lifecycle and event discipline

Prefer events/signals to unnecessary polling when an event naturally represents the state change.

Every module that creates connections, tasks, transient Instances, or other resources must own their cleanup. Destruction/recovery must be idempotent where the lifecycle can call it more than once.

Avoid hidden global mutable state. State should live in the module/object that owns its lifecycle or in an explicitly approved shared state owner.

## 8. Data and tuning discipline

Separate behavior from data/configuration when values are meant to be tuned, balanced, environment-specific, or reused.

Do not scatter magic gameplay numbers through runtime code. Use the established config/owner document for the value.

Do not introduce a new generic Manager/Service/Controller just to hold a few constants or helpers. A new owner must represent a real responsibility.

## 9. Performance is part of architecture

Roblox performance is not a final polish step.

For runtime systems:
- avoid unnecessary Parts/Models/Instances;
- avoid unnecessary work in high-frequency events;
- clean up connections/resources;
- prefer simple collision/presentation structures that satisfy the mechanic;
- cache/reuse only where it has a clear ownership/performance benefit;
- use profiling/Studio measurements when optimizing rather than guessing;
- verify important paths on representative device/performance targets before release.

Do not sacrifice correctness or module clarity for speculative micro-optimization.

## 10. AI-assisted development context rule

Do not re-read the whole repository for every change.

Normal context expansion order:

`task -> current owner spec -> architecture map route -> selected module -> direct consumers/dependencies -> evidence-driven expansion`

`ARCHITECTURE_MAP.md` is navigation only. Current code + current Source of Truth prove behavior.

Expand across a module boundary only when evidence shows the root cause/data flow crosses it. This keeps AI context smaller without lowering rigor.

## 11. Documentation and Source-of-Truth discipline

Do not silently duplicate the same fact in several documents.

- Product WHAT/WHY belongs in product/owner specs and Decision Logs.
- Engineering HOW rules belong here.
- Current execution cursor/evidence belongs in `SESSION.md`.
- Navigation belongs in `ARCHITECTURE_MAP.md` / handoff docs.
- Task-specific rewrite design belongs in its approved design/plan.

When architecture materially changes, update the navigation/owner docs that actually became stale. Do not churn unrelated historical documentation.

## 12. Current Draw Racers Core V3 application

The current mechanical authority is `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md` and the current design is `docs/superpowers/specs/2026-09-15-core-v3-flat-physics-design.md`.

Current owner chain:

`DrawingController -> LegShapeService -> RacerRuntime -> CoreV3/LegCoreController -> SharedAxle + LegGeometry + LegClearanceController`

Legacy CR2/CR3/R17/MR leg implementation modules are not compatibility targets. Do not reconnect them to avoid fixing Core V3. The next approved architecture repair is a dedicated 2.5D lane/orientation owner that constrains Z/upright only and never supplies normal +X locomotion.

## 13. Definition of a healthy module

A module is healthy when a developer/AI can answer, without reading unrelated systems:

- what it owns;
- what it does not own;
- how to call it;
- what state persists across its lifetime;
- what cleans it up;
- what invariants its tests protect.

Changing its internals should not require consumers to understand those internals.

That is the target structure for Draw Racers.