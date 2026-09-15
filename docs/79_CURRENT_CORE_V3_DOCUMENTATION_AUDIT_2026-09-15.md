# 79 — CURRENT CORE V3 DOCUMENTATION AUDIT — 2026-09-15

Status: **PASS — DOCUMENTATION CASCADE CLEANUP**

This audit replaces obsolete v1.3.4/R15–R17 mechanical handoff context for current implementation work.

## Current mechanical authority
1. `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`
2. `03_CORE_MECHANICS_SPEC.md`
3. `11_TECH_DESIGN_ROBLOX.md`
4. `16_BALANCE_TUNING.md`
5. `21_SYSTEM_CLASS_ARCHITECTURE.md`
6. `24_TESTING_QA_MATRIX.md`
7. `73_SHAPE_COORDINATE_PIVOT_COLLIDER_SPEC.md`
8. `superpowers/specs/2026-09-15-core-v3-flat-physics-design.md`
9. `superpowers/plans/2026-09-15-core-v3-flat-physics-current-plan.md`
10. `SESSION.md`

## Current locked Core V3 facts
- one shared axle;
- exactly one physical HingeConstraint / one motor owner;
- LEFT -Z / RIGHT +Z / fixed 180° relation;
- hinge remains structurally enabled; motor OFF uses `ActuatorType.None`;
- normal +X locomotion comes only from leg/Track physical reaction;
- redraw is `PREVIEW -> WAIT_CLEAR -> ACTIVE`, fail-closed and commits accepted state only after ACTIVE;
- C01–C07 are the current automated Studio suite;
- human Flat Gate precedes obstacle work;
- approved next architecture repair is 2.5D Z lane-plane lock + upright orientation stabilization with X/Y physical and no forward helper;
- current execution is local folder/archive + Rojo/Studio, with Git/GitHub disabled unless explicitly re-enabled.

## Removed from active production context
- CR2 current source;
- CR3 current source;
- twin-pivot/twin-drive mechanical design;
- old MR/core-rewrite plans and specs;
- superseded R15/R16/R17 mechanical drive/lane decision logs;
- old remote-GitHub workflow decision;
- obsolete Studio-core iteration decision;
- obsolete v1.3.4 final audit/changelog;
- obsolete early camera/rider sequence-only override.

## Retained supporting decisions
A small number of older dated decision records remain only because current non-Core-V3 owners/tests still depend on them:
- camera/rider presentation contract;
- R16.3B first-cleaned-point stroke-origin reference parity;
- `DECISION_LOG_TEMPLATE.md`.

They do not override `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md` for locomotion mechanics.

## Code-scope audit
This cleanup is documentation/process only. `src/`, `tests/`, Rojo mapping, configs and assets must remain byte-identical to the supplied baseline.


## Known non-documentation debt
The root `verify.py` suite currently reports legacy failures because many Python tests still encode superseded CR2/R17 internals. This documentation cleanup intentionally does not edit/delete tests or runtime code. Current Core V3 mechanical automation is C01–C07; stale Python-contract migration is a separate bounded task and must not resurrect obsolete mechanics.

## Current unresolved human gate
Core V3 flat Roblox physics remains:

`AUTOMATED PASS / HUMAN PHYSICS PENDING`

Documentation consistency does not promote runtime physics to PASS.
