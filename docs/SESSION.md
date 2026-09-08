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

Later B03–B14 implementation/tests exist in `main`, but implementation/CI alone does **not** promote those tasks to ACCEPTED where their task DoD requires local/Studio evidence.

## Current implementation/evidence cursor
**B14 — Invalid/stress redraw suite — IMPLEMENTED / STUDIO PASS PENDING.**

Sequence authority: `25_IMPLEMENTATION_SEQUENCE.md` places B14 after B13 and before B15. Acceptance authority: `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` requires spam/malformed/stale/large payloads to fail safely without leaked parts, server crash, or removal of the current valid shape. Owners: `24/32`.

### Pending evidence carried forward
B12 SubmitStroke/StrokeResult and B13 Atomic redraw remain Studio-pending. The night-autopilot override allows bounded CORE implementation to continue before the hard G0 gate, but it does not mark any pending task ACCEPTED.

### B14 implementation evidence
Commits:
- `00ea23d0b87e24bcb44dd16cc1429b90f43e85e3` — B14 Studio abuse/stress behavior spec;
- `9f79fc2c5a34f94e7ff40565c56ffd4c463d9766` — Studio bootstrap wiring;
- `c330918bc80f5c667310d2240bfb36cdce92cee4` — static B14 contract guards.

Coverage added:
- valid accepted shape is seeded before abuse cases;
- valid cooldown spam must return `RATE_LIMITED` and preserve the accepted shape;
- stale duplicate sequence must return `STALE_SEQUENCE` and preserve the accepted shape;
- malformed point structure, non-finite points, `MaxRawPoints+1`, and canonical bounded payload larger than `MaxStrokePayloadBytes` are rejected without geometry mutation;
- 40 repeated legal redraws assert exactly two surviving leg models, bounded physical part count, monotonic `ShapeVersion`, and no retiring-model leaks;
- 50-request burst spam asserts no extra models/parts and no version mutation;
- static contract guard verifies validation/payload/rate gates occur before `ValidateAndBuild`.

Fresh automated evidence on B14 head `c330918bc80f5c667310d2240bfb36cdce92cee4`:
- GitHub Actions `Contract Verify` run `34284052971`: SUCCESS;
- `python verify.py`: **44 passed, 0 failed**.

### B14 evidence still required before ACCEPTED
Roblox Studio/Rojo evidence is not available to the automation and must not be fabricated. Required local evidence remains:
- sync/build current `main` in the normal Rojo workflow;
- Studio Play prints `[DrawRacers][B14] redraw abuse/stress tests PASS`;
- no DrawRacers red runtime error;
- no visible orphan/retiring leg geometry after the stress suite.

## Night-autopilot override
The Product Owner explicitly authorized bounded CORE implementation to continue while earlier Studio evidence is pending, provided no documentation hard human gate is crossed. Therefore the next implementation task may proceed to **B15 — Five obstacle lab final geometry** while B12–B14 Studio evidence remains pending. This override does not mark those tasks ACCEPTED.

## Next permitted task
**B15 — Five obstacle lab final geometry.** Required owners: `60_LEVEL_CONTENT_PRODUCTION_SPEC.md` and `67_LEVEL_ASSEMBLY_AND_VALIDATION.md`. Scope is only the canonical Flat/Steps/Wall/Gap/Tunnel M0 lab geometry/defaults and their intended legal-shape traversal acceptance. Do not pull B16 tuning UI, multiplayer/meta/economy/shop, or any post-G0 work forward.

After B15, ordered M0 work remains B16 → **B17/G0 HUMAN GATE**. B17 is a hard stop: no C01 or later phase may start until recorded G0 PASS or an explicit Product Owner scope decision after allowed rework.
