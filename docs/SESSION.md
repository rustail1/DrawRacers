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

Later B03–B13 implementation exists in `main`, but implementation/CI alone does **not** promote those tasks to ACCEPTED where their task DoD requires local/Studio evidence.

## Current implementation/evidence cursor
**B13 — Atomic redraw — IMPLEMENTED / STUDIO PASS PENDING.**

Sequence authority: `25_IMPLEMENTATION_SEQUENCE.md` places B13 after B12 and before B14. Acceptance authority: `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` requires old legs to remain while a replacement is drawing/building, then a valid pair swap with no body teleport or velocity reset. Owners: `03/28`.

### B12 pending evidence carried forward
B12 SubmitStroke/StrokeResult is implemented. GitHub static regression was green before B13, but B12 still requires its Roblox Studio acceptance line and no DrawRacers runtime errors before it may be recorded ACCEPTED.

### B13 implementation evidence
Code commit: `f8ba153f9216de22f026b3b80be191d71d725353` (`feat: implement B13 atomic redraw`).

Implementation:
- `LegAssembly` supports detached staged construction; staged assemblies do not replace or enter Workspace until `Commit()`.
- `RacerRuntime:ApplyShape` captures current left/right rotation phase, builds both replacement legs off-Workspace, and leaves the working pair untouched if either staged build fails.
- after both replacements are ready, the old pair is renamed to retiring names, both new legs are committed in one no-yield server section, requested motor state is restored, then the retired pair is destroyed;
- redraw code does not write BodyCollider `CFrame`, `PivotTo`, `AssemblyLinearVelocity`, or `AssemblyAngularVelocity`;
- a forced second-leg build failure is covered by the B13 Studio spec and must preserve old legs, ShapeVersion, body transform and velocities;
- successful redraw is covered for exactly two surviving leg models, old-pair cleanup and non-default rotation-phase preservation.

Fresh automated evidence on the code commit:
- GitHub Actions `Contract Verify` run `34283480699`: SUCCESS;
- `python verify.py`: **42 passed, 0 failed**;
- B13 static contract tests: PASS.

### B13 evidence still required before ACCEPTED
Roblox Studio/Rojo evidence is not available to the automation and must not be fabricated. Required human gate remains:
- sync/build current `main` in the normal local Rojo workflow;
- Studio Play prints `[DrawRacers][B13] atomic redraw tests PASS`;
- no DrawRacers red runtime error;
- visual/physics confirmation that the working legs remain while a redraw is pending and that a successful redraw does not visibly teleport or zero racer motion.

## Night-autopilot override
The Product Owner explicitly authorized bounded CORE implementation to continue while earlier Studio evidence is pending, provided no documentation hard human gate is crossed. Therefore the next implementation task may proceed to **B14 — invalid/stress redraw suite** even though B12/B13 remain Studio-pending. This override does not mark either task ACCEPTED.

## Next permitted task
**B14 — Invalid/stress redraw suite.** Required owners: `24_TESTING_QA_MATRIX.md` and `32_SECURITY_THREAT_MODEL.md`. Scope is abuse/stress of the existing redraw/network path only. It must not pull B15 geometry, B16 tuning UI, multiplayer/meta/economy/shop, or any post-G0 work forward.

After B14, ordered M0 work remains B15 → B16 → **B17/G0 HUMAN GATE**. B17 is a hard stop: no C01 or later phase may start until recorded G0 PASS or an explicit Product Owner scope decision after allowed rework.
