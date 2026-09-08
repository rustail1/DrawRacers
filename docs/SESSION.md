# SESSION.md — CURRENT STATE

Date: 2026-09-09  
Documentation version: **v1.3.4 EXECUTION CONSISTENCY FREEZE**

## Product state
The specification remains closed for production. No new WHAT/WHY scope was introduced by the night CORE implementation run.

Locked product direction remains: 8-player live physics drawing race; player controls the drawn physical leg shape; no competitive power monetization; progression/meta stays out of M0 until the ordered gates allow it.

## Accepted implementation evidence
The repository-recorded human/Studio acceptance remains unchanged:
- A01 — Git/Rojo baseline — ACCEPTED.
- A02 — minimal shared/server/client roots — ACCEPTED.
- A03 — reproducible M0 test scene — ACCEPTED.
- A04 — deployment/config skeleton + Studio roots — ACCEPTED.
- B01 — pointer abstraction — ACCEPTED.
- B02 — local stroke preview — ACCEPTED.

Later B03–B15 implementation/tests exist in `main`, but implementation/CI alone does **not** promote those tasks to ACCEPTED where their task DoD requires local/Studio evidence.

## Current implementation/evidence cursor
**B15 — Five obstacle lab final geometry — IMPLEMENTED / STUDIO PASS PENDING.**

Sequence authority: `25_IMPLEMENTATION_SEQUENCE.md` places B15 after B14 and before B16. Acceptance authority: `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` requires Flat/Steps/Wall/Gap/Tunnel canonical defaults and traversal by intended legal shapes. Exact geometry owners used for this task: `60_TRACKPIECE_PARAMETER_CATALOG.md` and `67_LEVEL_BUILD_ASSEMBLY_RELEASE_PLAYBOOK.md`.

### Pending evidence carried forward
B12 SubmitStroke/StrokeResult, B13 Atomic redraw, and B14 abuse/stress remain Studio-pending. The night-autopilot override allows bounded CORE implementation to continue before the hard G0 gate, but it does not mark any pending task ACCEPTED.

### B15 TDD / implementation evidence
RED evidence:
- `e4d20f517d815d8a7ad5d62d8d0dec4ead2e1c08` — added the B15 canonical obstacle contract first;
- GitHub Actions `Contract Verify` run `34288872680` failed as intended: **44 passed, 2 failed**, specifically because canonical `StartX` defaults and `ObstacleLab` geometry did not yet exist;
- `a0eedf5eaa0b3282ebc6484b8770b6ddc6d31e1d` added the Studio-spec wiring contract before the Studio spec existed; its verification also failed as intended.

GREEN implementation commits:
- `56b928d0054215283751f0728ecd4d246a58c019` — declares the five canonical B15 piece defaults in `M0SceneConfig`;
- `c31b57994a58dcdb2bd44bd46cf1076ac759b1cb` — replaces the old continuous flat lab floor with collision geometry for the canonical FlatShort / SmallSteps / SingleWallLow / GapSmall / LowTunnelWide sequence plus 10-stud recovery floors;
- `2d9bed74e5eb0c82ceea295e3c7630b87688e4f2` — adds exact Studio geometry assertions;
- `1cda4a461c06f7cfe2cf92caad3335e357829abf` — wires the B15 Studio geometry spec into the existing Studio bootstrap;
- `d9badbc4c70b7c12cbe35897423e6e0f32461178` — makes the fifth canonical step assertion explicit.

Geometry implemented from `60` defaults:
- FlatShort: 18 studs, top Y=0;
- SmallSteps: length 28, H=1.5, D=4.0, gap=1.0, five discrete raised blocks over a baseline floor;
- SingleWallLow: length 20, H=2.6, thickness=2.0, centered wall over a baseline floor;
- GapSmall: length 24, centered 3.2-stud opening with 10.4-stud approach and landing and **no hidden collidable floor across the gap**;
- LowTunnelWide: length 28, 16-stud collision ceiling with 4.25-stud bottom clearance;
- lane collision width remains 8 studs and the existing lab spawn remains at body-center Y=3.

Fresh automated evidence on B15 code head `d9badbc4c70b7c12cbe35897423e6e0f32461178`:
- GitHub Actions `Contract Verify` run `34289171053`: SUCCESS;
- workflow command `python verify.py`: **47 passed, 0 failed**.

### B15 evidence still required before ACCEPTED
Roblox Studio/Rojo physics evidence is not available to the automation and must not be fabricated. Required local evidence remains:
- sync/build current `main` in the normal Rojo workflow;
- Studio Play prints `[DrawRacers][B15] obstacle lab geometry tests PASS` with no DrawRacers red runtime errors;
- visually confirm canonical Flat / discrete Steps / centered Wall / truly open Gap / low Tunnel collision layout;
- traverse all five obstacle representatives using the intended legal-shape set required by the B15 DoD; geometry-test PASS alone does not prove physical traversability or feel.

## Night-autopilot override
The Product Owner explicitly authorized bounded CORE implementation to continue while earlier Studio evidence is pending, provided no documentation hard human gate is crossed. Therefore the next implementation task may proceed to **B16 — Debug physics/tuning panel** while B12–B15 Studio evidence remains pending. This override does not mark those tasks ACCEPTED.

## Next permitted task
**B16 — Debug physics/tuning panel.** Scope and owner docs must be taken from its exact `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` row before any change. Do not pull B17/G0 evidence, multiplayer/meta/economy/shop, or any post-G0 work forward.

After B16, the next ordered item is **B17/G0 HUMAN GATE**. B17 is a hard stop: no C01 or later phase may start until recorded G0 PASS or an explicit Product Owner scope decision after allowed rework.
