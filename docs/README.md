# DRAW RACERS — DEVELOPMENT BIBLE INDEX

Status: **CURRENT CORE V3 DEVELOPMENT PACKAGE — 2026-09-15**

## Current mechanical Source of Truth
Read first for any current locomotion/redraw/physics task:
1. `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`
2. `SESSION.md`
3. `FEATURE_LIST.md`
4. `ARCHITECTURE_MAP.md`
5. relevant owner docs (`03`, `11`, `16`, `21`, `24`, `73`)

Old CR2/CR3/twin-drive/R15-R17 mechanical implementation documents have been removed from the working package. Do not recreate them as active context.

## Product
DrawRacers is an original Roblox 2.5D drawing race inspired by the observable high-level Draw Climber mechanic: one continuous drawing becomes real locomotion geometry. Final product target remains an 8-player live race; current development is still M0 Core V3 Flat Physics.

Non-negotiable product invariants:
- drawing is the main control;
- drawn geometry is real locomotion geometry;
- redraw works during the race;
- no paid competitive physics power;
- racers do not physically push each other;
- server validates competitive outcomes;
- track/content remains data-driven.

## Current Core V3
- one shared axle;
- one HingeConstraint/motor owner;
- Left -Z / Right +Z at fixed 180°;
- movement only from legs contacting Track;
- redraw PREVIEW -> WAIT_CLEAR -> ACTIVE, fail-closed;
- C01–C07;
- Flat Gate before obstacles;
- approved next repair: Z lane-plane lock + upright orientation stabilization with X/Y physical and no forward helper.

## Current workflow
Local folder/archive only. Git/GitHub is currently disabled. See `AI_WORKFLOW_QUICKSTART.md`.

## Domain owner map
| Domain | Owner |
|---|---|
| Product/audience/core promise | `00`, `01`, `02` |
| Current Core V3 locomotion/redraw | `CURRENT_CORE_V3_SOURCE_OF_TRUTH`, `03`, `11`, `16`, `21`, `73` |
| Current Core V3 tests/gate | `24`, `SESSION`, C01–C07 |
| Level grammar/content | `04`, `42`, `60`, `67` |
| Multiplayer/race/bots | `05`, `40`, `41`, `74`, `75` |
| Meta/economy | `06`, `44`, `61` |
| Monetization | `07`, `19`, `45`, `56`, `71` |
| UI/camera/FTUE | `08`, `29`, `59`, `68` |
| LiveOps/analytics | `09`, `10`, `46`, `76` |
| Persistence/security | `31`, `32` |
| Release/ops | `34`, `35`, `48`, `57`, `64`, `70` |
| Implementation order | `25`, `52`, `66`, `SESSION` |
| Current documentation audit | `79_CURRENT_CORE_V3_DOCUMENTATION_AUDIT_2026-09-15.md` |

## Gate rule
Current status is **HUMAN PHYSICS PENDING**. M0.5 and later product systems stay blocked until the Core V3 Flat Gate is human-accepted or the Product Owner explicitly changes the gate.
