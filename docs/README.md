# DRAW RACERS — Roblox Development Bible

Статус: **v1.3.4 ZERO-QUESTION PRODUCTION FREEZE — START-TO-PUBLIC-RELEASE EXECUTION READY**  
Дата: 2026-09-03  
Primary public title: **Draw Racers**; release clearance/fallback rule — `48/62`.

## What this package guarantees — and what it cannot
This package is designed so a programmer/Codex/UI implementer/level designer/artist/release operator can follow one owner path from an empty repository through **public enable and first-live monitoring** without inventing missing WHAT/WHY, UI composition, Studio instance structure, level assembly workflow, launch obstacle dimensions, launch economy values, catalog transaction rules, platform provisioning rules, deployment IDs or launch content identity.

It does **not** guarantee a hit, retention, PTR, payer conversion or revenue. Reference success validates a high-level pattern; our build still has empirical gates in `55`, performance gates in `57`, discovery tests in `38/62`, and live analytics in `10/46`.

## Locked product
**8-player live physics drawing race.** The player draws one continuous shape; it becomes two real rotating physical legs/wheels. The racer moves automatically from physical contact. The player reads the next obstacle, redraws while moving, compares rival solutions and tries to overtake. Fast rematch is part of the product.

Non-negotiable:
1. Drawing is the main control; no gas/jump/manual steering.
2. Drawn geometry is real collision geometry, not a hidden “shape class”.
3. Redraw works during Racing and swaps atomically.
4. Final heat target = 8; 2-player is integration/testing only.
5. Same resolved track/physics baseline for all racers.
6. Racers never physically collide with each other.
7. Rivals are visible and socially informative.
8. Zero paid physics power.
9. Meta = Collection + Status + Access, not stat power.
10. Public release includes required bot fill for underfilled heats.
11. Clean-room original expression; no copied competitor code/assets/UI/levels/audio/branding.
12. One fact → one owner document.

## Exact owner map
| Domain | Owner |
|---|---|
| Product/audience/core promise | `00`, `01`, `02`, reference boundary `51/54` |
| Drawing/physical legs/redraw | `03`, global defaults `16`, **exact screen→pivot→collider mapping `73`** |
| Level grammar | `04`, authoring `42`, **exact TrackPiece dimensions + T01–T20 `60`**, build/release workflow **`67`** |
| Multiplayer/race/bots/place routing | `05`, `40`, **lifecycle/timeouts/requeue `74`**, bot policy **`75`**, server lifecycle **`41`**, setup/config `23/30` |
| Meta/Coins/status/access | `06`, `44`, **exact launch values `61`** |
| Monetization | `07`, `19`, `45`, DP receipt `56`, Coin+Pass transaction contract **`71`**, exact SKUs `61/62`, IDs `70` |
| FTUE/camera/UI behavior | `08`, `29` |
| **Exact UI layout/wireframes/copy** | **`59`**, exact child hierarchy/bindings **`68`** |
| LiveOps/content scale | `09`, schemas `30`, **first 30-day ready buffer `76`** |
| Analytics/events | `10`, exact event dictionary `46` |
| Roblox architecture/network | `11`, `21`, `22`, setup `23`, **exact Studio instances/properties `65`** |
| QA/DoD/performance | `15`, `24`, `33`, `57` |
| **Exact launch art/content/public identity** | **`62`**, production workflow **`69`**, ID registry **`70`** |
| Save/migration/session lease/exact-once grants/security | `31`, `32`, receipt `56` |
| Ops/release/rollback | `34`, `35`, `48`, **platform provisioning `64`**, **deployment registry `70`** |
| Localization/accessibility/safety | `37`, `39`, exact layout checks `59` |
| Implementation order | `25`, full route `52`, **per-task acceptance `66`**, current item `SESSION` |
| Scope | `FEATURE_LIST` |
| Final completeness audit | **`78_FINAL_EXECUTION_CONSISTENCY_AUDIT_v1.3.4.md`** |

## Working route from zero to release
`A01 repo/Rojo → A02 shared roots → A03 M0 scene → A04 deploy/instance skeleton → B01/B02 DrawCanvas → stroke math → physical leg → hinge → two legs → stabilization/lane → authoritative stroke → atomic redraw → canonical obstacle lab → G0 → adaptation/G1 → 2-player network/social/G2 → 8-player scale/readability → STAGING provisioning → PlayerDataService → RewardService → AnalyticsAdapter → canonical FTUE BotRacerController foundation → confirmed Results → CosmeticService → EntryFTUEPlace→T06→RacePlace routing → Garage/presentation → G3 → T01–T20 + public Bot Fill + G4/G5 → exact launch Passes → discovery G6 → LiveOps foundation/G7 → final UI/content/economy/IP/performance checks → PROD provisioning/ID bind → audit 78 → public enable → first-hour/day monitoring.`

The exact sequence is `25_IMPLEMENTATION_SEQUENCE.md`; never skip ahead because a later system is easier.

## v1.3.4 zero-question closure additions
The extra pass closed implementation questions that were still technically “HOW”, but could still cause a programmer/agent to ask for design-like guidance:
- `64` fixes DEV/STAGING/PROD experience provisioning, two-place release outcomes, policy/preflight and publish order;
- `65` fixes exact Studio runtime/template Instance names, properties, tags and collision matrix;
- `66` fixes output + acceptance/stop condition for every task A01→I08;
- `67` fixes the exact level workflow from one TrackPiece blockout through 8-lane themed release;
- `68` fixes exact UI child hierarchy, controller ownership, focus/input and state binding;
- `69` fixes art/audio/VFX/content production states and acceptance workflow;
- `70` is the only owner for generated Universe/Place/Pass/Product/Asset IDs and environment binding;
- `71` fixes atomic Coin cosmetic purchase and one-time Pass entitlement reconciliation;
- `73` fixes exact DrawCanvas coordinate/pivot/scale → physical collider construction and shape lifetime;
- `74` fixes exact arrival/assembly/PREP/finish grace/DNF/Results/requeue/spectator lifecycle;
- `75` fixes deterministic launch bot difficulty, legal shape presets, lookahead, timing and mistake behavior;
- `76` freezes the first 30 days of config-ready LiveOps content and objective/reward rules;
- `78` is the current final audit.

## AI/programmer rule
Before every task read: `FEATURE_LIST → SESSION → 50 → 26 row → 66 task row → owner docs`. Then:
`reconnaissance → smallest observable implementation → automated check → Studio test → edge/regression → human acceptance → log → next item`.

AI may decide HOW inside owner contracts. It may not silently invent/change player verbs, layout hierarchy, launch track dimensions, economy meaning, catalog identity, fairness, persistence schema or scope.

## History
Historical audits/changelogs are **not included in the production handoff ZIP**. They are kept only in the separate history archive. Codex/programmers should ingest only files listed in `manifest.json.current_documents`.

## Current revision record
See `CHANGELOG_v1.3.4.md` for the execution-consistency freeze delta.
