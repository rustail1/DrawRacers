# FEATURE DECISION LOG

Feature: M0 CORE architecture integrity repair (R01–R05)  
Date: 2026-09-09  
Owner: Product Owner / engineering handoff

## Problem / WHY
A read-only audit after B16 found implementation inconsistencies that could make the M0 core behave differently from its existing contracts even though static milestone tests were green: duplicated physical-geometry calculation, DrawCanvas aspect distortion, event-rate-dependent stroke payload density, accepted-preview/server-state desync under overlapping submissions, incomplete collision registration, over-tight body stabilization, incorrect debug metrics, multiple simultaneous Studio movement harnesses, and no real human SubmitStroke→racer binding for the G0 Studio gate.

This repair is reliability work inside already-approved M0 scope. It adds **no new WHAT/WHY** player verb, progression, race mode, economy, monetization or post-G0 system.

## Scope gate
Present inside the ACTIVE M0 core pipeline in `FEATURE_LIST.md`. Repair is bounded to B03–B16 implementation integrity and preparation for B17/G0. It must stop before C01.

## Decision / WHAT
Observable behavior after the repair:

- **R01:** one `GeometryMath` path owns normalized shape → mapped points → physical segment plan; the accepted server ShapeSpec is the plan used by runtime leg construction. The wide visual DrawCanvas contains a **square semantic DrawInputRect** so equal screen X/Y distances remain equal semantic/physical distances.
- **R02:** visual stroke preview may sample every input event, but network semantics use bounded movement-threshold samples. The client does not submit obviously too-short strokes. A matching accepted server result newer than the last accepted sequence becomes the accepted preview even if a newer request is pending or later rejected.
- **R03:** the semantic collision matrix includes Track/RacerBody/RacerLeg/RacerGhostVisual/Decoration/Trigger; stabilization permits the documented transient tilt window without +X propulsion; M0 generated geometry lives below canonical Runtime.Tracks and remains relative to Lane.TopY.
- **R04:** debug telemetry reads actual accepted shape/leg state; stuck means insufficient +X progress over the documented window; debug selection prefers explicit `DebugTarget`, then a human racer.
- **R05:** Studio runs exactly one interactive harness selected by config. Default is G0. The G0 harness uses the existing stroke transport with a Studio-only injected Player→RacerRuntime resolver. **D05 RacerService** remains a later task and is not implemented early.

## Alternatives considered
1. Keep duplicated geometry calculation in `LegShapeService` and `LegAssembly`, then add equality assertions. Rejected: two owners can drift and violate the authoritative ShapeSpec boundary.
2. Keep rectangular semantic normalization and compensate with anisotropic world scaling. Rejected: it makes the same drawn geometry depend on UI aspect ratio and weakens shape→physics readability.
3. Implement production D05 RacerService before G0 just to bind player remotes. Rejected: violates implementation order and pulls M1 architecture into M0.
4. Keep B08/B09/B10 harnesses running simultaneously and visually inspect the intended racer. Rejected: creates ambiguous physical/debug evidence at the human gate.

## Why chosen
The repair keeps one owner per fact, preserves the existing server-authority boundary, minimizes pre-G0 architecture, and makes the Studio G0 run represent the actual drawing/network/physical-redraw path instead of a synthetic movement demo.

## Constraints / invariants
- No new gameplay verb or competitive advantage.
- No hidden forward propulsion.
- No client-authored world geometry or ShapeVersion.
- No early RaceService/RacerService/reward/checkpoint implementation.
- B17/G0 remains a human gate; automation cannot promote it.
- Later race/meta/economy scope remains untouched.

## Numbers
No new product tuning table is created here. Runtime values continue to be owned by `16_BALANCE_TUNING.md` / the corresponding Config modules. The repair only binds implementation to existing values such as stroke sampling thresholds, the transient tilt boundary, and the documented stuck-progress window.

## Acceptance criteria
- [x] R01 regression added before production repair and observed RED→GREEN.
- [x] R02 regression added before production repair and observed RED→GREEN.
- [x] R03 regression added before production repair and observed RED→GREEN.
- [x] R04 regression added before production repair and observed RED→GREEN.
- [x] R05 regression added before production repair and observed RED→GREEN.
- [x] Full pre-R06 automated suite: **66 passed, 0 failed**.
- [ ] Current Rojo build/sync verified locally after the complete repair.
- [ ] Studio B03–B16 specs run with no DrawRacers red runtime error.
- [ ] Real G0 drawing creates authoritative physical legs and locomotion.
- [ ] Redraw on the moving G0 racer preserves physical continuity.
- [ ] B17 empirical human gate recorded separately according to `55`.

## Measurement
For repair correctness: contract-suite failures, Studio runtime errors, accepted ShapeVersion/segment telemetry, actual +X progress, and G0 human-gate observations. This repair does not invent a new product KPI.

## Result after implementation
R01–R05 implementation is in `main`. GitHub Actions run `34336175789` executed `python verify.py` with **66 passed, 0 failed**. **Studio evidence pending**; therefore B03–B16 acceptance and B17/G0 are not silently promoted.

## Follow-up / rollback condition
If current Studio reveals shape distortion, network/preview desync, nonphysical redraw, bad telemetry, or G0 harness contamination, rework the bounded failing R-item before G0. Do not bypass B17 or begin C01 to work around an M0 failure.
