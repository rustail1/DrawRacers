# Studio Core Iteration Default — 2026-09-12

Status: **APPROVED PRODUCT OWNER CONTRACT CHANGE / HUMAN STUDIO PENDING**

## Decision

During active M0 core feel/visual iteration, a normal Roblox Studio `Play` must enter the interactive human core immediately instead of automatically spending startup time on the B03–B16 Studio regression suite and the R17FINAL evidence matrix.

The committed default Studio harness returns to `G0` as the manual core loop. In this default mode:

- `M0TestScene` still builds so the canonical obstacle lab is available;
- `M0HumanHarness` starts directly after the scene build;
- B03–B16 Studio regression specs are **not** auto-run at startup;
- no `TESTS RUNNING` banner is shown for the normal G0 core session;
- production camera, rider presentation, drawing, redraw, physics and obstacle interaction remain active for direct human iteration.

## Explicit evidence modes remain available

Automated/evidence infrastructure is retained in the repository. `B08`, `B09`, `B10`, `R16B`, `R16C`, `R16FINAL` and `R17FINAL` remain selectable diagnostic/evidence modes. When one of those modes is explicitly selected, the existing startup regression boundary still runs before the selected harness.

GitHub `Contract Verify`, `python verify.py`, Rokit and Rojo build checks remain unchanged. This decision removes automatic Studio evidence from the **ordinary manual Play loop**; it does not delete regression coverage.

## Scope / non-changes

This is a development-flow contract change only. It does not change:

- draw/ShapeSpec/network authority;
- shared-axle/co-phase locomotion semantics;
- camera behavior;
- rider presentation behavior;
- production physics tuning;
- obstacle geometry;
- Rojo mapping;
- any HUMAN_GATE result.

The current goal after this decision is repeated short human iterations on the live core: draw -> physical legs -> locomotion -> redraw -> obstacles -> camera/rider. Automated evidence is invoked intentionally when needed rather than blocking every manual run.

## Gate state

All previously pending Studio/human gates remain pending. Switching the default development loop to direct G0 does not fabricate PASS for Studio Gate A/B/C or B17/G0.
