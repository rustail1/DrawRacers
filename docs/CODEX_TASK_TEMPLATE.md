# CODEX TASK TEMPLATE

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation/integration stage only. Product power is never sold.

## Context to read
- `FEATURE_LIST.md`
- `SESSION.md`
- relevant row in `26_HANDOFF_MAP.md`
- [specialized owner spec]
- [decision log if one exists]
- never load `_HISTORY/` unless the task is provenance/audit

## Feature
[one observable behavior]

## WHY
[problem/desired player behavior]

## Expected result / acceptance
1. ...
2. ...
3. ...

## Invariants
[List only relevant project invariants.]

## First step — reconnaissance only
Before editing, inspect the existing project and report:
- relevant scripts/modules/services;
- existing test/debug tools;
- existing architecture to reuse;
- minimal implementation path.
Do not create a parallel subsystem if an existing one can be extended.

## Implementation rule
Make the smallest change that closes one end-to-end path. Do not implement future features preemptively.

## Test
- happy path;
- edge cases;
- regression if shared code touched;
- Studio/Play Mode instructions for human acceptance.

## Completion report
Files changed, tests/results, deviations, fragile areas, next step. Update SESSION only after acceptance.


If task touches UI/layout, include `59`; launch level dimensions/tracks → `60`; economy/progression/prices → `61`; launch art/content/identity → `62`. Do not invent alternate defaults.


## No-guess rules v1.3.4
- Studio object names/properties: `65`.
- UI child hierarchy/focus/binding: `68`.
- Track assembly: `67`.
- Platform/Asset IDs: `70`; never invent placeholders.
- Coin catalog purchase / Pass entitlement: `71`.
- DrawCanvas coordinate/pivot/collider mapping: `73`.
- Heat/requeue/timeout/DNF/spectator lifecycle: `74`.
- Bot shapes/difficulty/decision policy: `75`.
- Day 0–30 LiveOps buffer: `76`.
