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

Later B03–B16 implementation/tests exist in `main`, but implementation/CI alone does **not** promote those tasks to ACCEPTED where their task DoD requires local/Studio evidence.

## Current implementation/evidence cursor
**B16 — Debug physics/tuning panel — IMPLEMENTED / STUDIO PASS PENDING.**

Sequence authority: `25_IMPLEMENTATION_SEQUENCE.md` places B16 after B15 and immediately before B17/G0. Acceptance authority: `66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md` requires the debug/tuning surface to display the required physics/shape/lane/checkpoint metrics and to be DEV/STAGING only. Owner docs used: `23_PROJECT_SETUP_TOOLCHAIN.md` and `34_DEBUG_ADMIN_OBSERVABILITY.md`.

### Pending evidence carried forward
B12 SubmitStroke/StrokeResult, B13 Atomic redraw, B14 abuse/stress, and B15 obstacle traversal remain Studio-pending. The Product Owner night override allowed bounded CORE implementation through B16, but it does not mark any pending task ACCEPTED.

### B16 TDD / implementation evidence
RED evidence:
- `9e80914ea3863961c7fabba92632f56e784be09b` — added the B16 static contract before implementation;
- GitHub Actions `Contract Verify` run `34293523453` failed as intended because `DebugTuningPanel.lua` and `DebugTelemetry.lua` did not exist yet.

GREEN implementation commits:
- `27bf2058d60d098fa62852779251fc6a059155bb` — server-side debug telemetry sampler;
- `7f69e7907b71b73115f1961637c8753add94b861` — DEV/STAGING client tuning panel;
- `23a756ffb6da0ce27364868e5121fcbb2758c864` — client bootstrap wiring;
- `bdf5c6e9fb2c40985ab515c60c3d6ba4acf742f6` — server telemetry bootstrap wiring;
- `93a2f7b49d29a02e38b91a97a98540e60bbec6d6` — Studio telemetry behavior spec;
- `a151f13cfff756772d6fc285ea4be7aab5a7e3cf` — Studio spec bootstrap wiring.

Implemented debug surface:
- visible only in Studio or when `game:GetAttribute("DrawRacersEnvironment")` is `DEV`/`STAGING`;
- not added to the normal player HUD hierarchy;
- displays shapeVersion, simplified point count, collider segment count, body speed, motor angular velocity target, stuck state, lane deviation, checkpoint, and progress;
- server publishes replicated debug attributes at a bounded 5 Hz sample rate;
- checkpoint/progress read existing runtime attributes and therefore remain 0 until the later race/checkpoint system owns real values; B16 does not invent that later system.

Fresh automated evidence on B16 code head `a151f13cfff756772d6fc285ea4be7aab5a7e3cf`:
- GitHub Actions `Contract Verify` run `34293651190`: SUCCESS;
- workflow command `python verify.py`: **51 passed, 0 failed**.

### B16 evidence still required before ACCEPTED
Roblox Studio/Rojo evidence is not available to the automation and must not be fabricated. Required local evidence remains:
- sync/build current `main` in the normal Rojo workflow;
- Studio Play prints `[DrawRacers][B16] debug tuning panel tests PASS` with no DrawRacers red runtime errors;
- confirm the panel is visible in Studio/DEV-STAGING context and the displayed physics metrics update while the racer moves/redraws;
- confirm no player-facing debug panel appears in PROD context.

## HARD STOP — B17 / G0 HUMAN_GATE
The next ordered task is **B17 — G0 human gate**. This task requires recorded human/Studio evidence according to `15/55` and cannot be passed by CI or automation. No C01, M0.5, multiplayer, meta, economy, shop, or any post-G0 implementation may begin until G0 is explicitly recorded PASS or the Product Owner authorizes bounded rework/scope change.

## Next permitted task
**B17 — G0 HUMAN_GATE only.** No implementation task beyond this gate is currently permitted.
