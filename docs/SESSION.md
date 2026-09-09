# SESSION.md — CURRENT STATE

Date: 2026-09-09  
Documentation version: **v1.3.4 EXECUTION CONSISTENCY FREEZE**

## Product state
The product specification remains closed. CORE/pre-G0 repair **R01–R09** is a bounded implementation-integrity pass inside the already-approved B03–B16/B17 scope; it introduces **no new WHAT/WHY** gameplay scope.

Locked direction remains: 8-player live physics drawing race; one continuous player stroke controls two real rotating physical legs; no competitive power monetization; progression/meta remains outside M0 until the ordered gates allow it.

## Accepted implementation evidence
Repository-recorded human/Studio acceptance remains unchanged:
- A01 — Git/Rojo baseline — ACCEPTED.
- A02 — minimal shared/server/client roots — ACCEPTED.
- A03 — reproducible M0 test scene — ACCEPTED.
- A04 — deployment/config skeleton + Studio roots — ACCEPTED.
- B01 — pointer abstraction — ACCEPTED.
- B02 — local stroke preview — ACCEPTED.

B03–B16 code and regression specs exist in `main`, but they are **not promoted to ACCEPTED** merely because automated checks are green. Required Studio/physics/human evidence is still pending.

## CORE/pre-G0 integrity repair R01–R09
- **R01 Geometry Authority** — `GeometryMath` is the single pure owner of normalized-shape → mapped-points/segment-plan construction; server ShapeSpec carries that plan into `LegAssembly`. The visible wide DrawCanvas contains a square semantic DrawInputRect.
- **R02 Drawing/Network Correctness** — visual preview sampling is decoupled from bounded semantic payload sampling; obvious too-short strokes are rejected locally; accepted-result ordering follows server truth.
- **R03 Physics Contract** — complete semantic collision groups/matrix, 25° free-tilt stabilization window with no forward propulsion, M0 lab under `Workspace.Runtime.Tracks`, and tunnel geometry relative to `Lane.TopY`.
- **R04 Debug Correctness** — collider count reads real `Segments` folders, cleaned-point telemetry comes from accepted ShapeSpec, stuck telemetry uses the documented 2.5 s +X progress window, and debug targeting prefers explicit `DebugTarget` then a human racer.
- **R05 Studio/G0 Integration** — Studio uses exactly one selectable interactive harness. Default mode is `G0`; the Studio-only `M0HumanHarness` injects a temporary Player→RacerRuntime resolver into existing `StrokeRemoteTransport`. It does not implement D05 `RacerService`.
- **R06 Documentation Consistency** — repository status/docs were reconciled to the B17/G0 hard stop without claiming Studio acceptance.
- **R07 Core Review Fixes** — exact B12 outer payload validation and abuse work-ordering, complete B16 raw/physics/motor telemetry and environment gating, plus semantic DrawInputRect ownership were tightened.
- **R08 Final Core Closure** — touch layout changes only between strokes; the normal Roblox Character is isolated from G0 physics before racer spawn; server enforces `MinUsefulLegExtent = 0.7`; anti-stall is bounded, actual-contact based, canonical-tag based and visible as `antiStallActive`.
- **R09 Pre-G0 Consistency Review — CLOSED at implementation/regression level** — accepted preview state is semantic rather than layout-pixel state; exact doc-59 touch ValidationToast/DrawHint tokens reflow with DrawCanvas; obstacle `RequirementTag` overrides recovery assist; spawned racers discard the empty template-only `RuntimeAttachments` helper after moving its attachments onto `BodyCollider`. The three R09 findings are no longer open code items; they remain in B17 Studio smoke only as runtime verification points.

Decision records: `DECISION_LOG_CORE_AUDIT_REPAIR_2026-09-09.md` and `DECISION_LOG_PRE_G0_REVIEW_R07_R09_2026-09-09.md`.

## Automated evidence
Historical evidence is intentionally retained:
- R01–R05 code/test head: GitHub Actions `Contract Verify` run `34336175789` → **66 passed, 0 failed**.
- R06 repository status reconciliation: commit `1269336b6754a7f9ea3172a1b99cddfe8fa276f7`, run `34337310421` → **68 passed, 0 failed**.
- R08 closure head: commit `3a0a32ce90f2cfcd2f37e3be430758dacc86d6d3`, run `34349254516` → **77 passed, 0 failed**.
- R09 RED: commit `35c4df76dd4d663e4785bcb295fda357b8c48ef9`, run `34351760319` → **77 passed, 3 failed**, exposing all three newly recorded gaps.
- R09 bounded repair: commit `3d414556677577af6b07ff253b97041c0eb59c30`, run `34352130204` → **80 passed, 0 failed**; the three R09 implementation findings are formally CLOSED.

The current GitHub workflow is intentionally described accurately: it runs `python verify.py` contract/static checks. It does **not** execute Roblox Studio physics, touch interaction, or external-player acceptance, and therefore cannot satisfy B17/G0 by itself.

## Current implementation/evidence cursor
**B17 — G0 HUMAN_GATE — Studio PASS PENDING.**

The repository remains intentionally stopped at the M0 human gate. `StudioHarnessConfig.Mode` defaults to `G0`, so a local Studio Play session can exercise the real M0 path:

`DrawInputRect → DrawingController → SubmitStroke → StrokeRemoteTransport → LegShapeService → authoritative ShapeSpec → atomic physical legs → locomotion → redraw`.

### Studio evidence still required
Verify current `main` locally before any B03–B16 implementation is promoted:
- `git pull --ff-only`, `python verify.py`, and normal Rojo build/sync complete without project errors;
- Studio Play runs B03–B16 specs with no red DrawRacers runtime error;
- `[DrawRacers][B16] debug tuning panel tests PASS` appears;
- `[DrawRacers][G0] human harness ready` appears;
- only one interactive G0 racer/harness remains after synchronous specs;
- the normal Roblox Character is observer-only and cannot push/block the racer;
- drawing creates server-accepted physical legs and movement;
- redraw while moving changes the accepted physical shape without teleporting/resetting body state;
- a sub-0.7 useful leg extent is rejected and leaves the old accepted shape intact;
- accepted preview remains semantically stable across layout changes between strokes;
- touch layout uses the doc-59 DrawCanvas/ValidationToast/DrawHint positions and never reflows in-progress drawing;
- debug `simplifiedPoints`, `physicsPoints` and `colliderSegments` report real nonzero values after a valid shape;
- `antiStallActive` is bounded on flat/recovery contact and immediately false on obstacle/unknown collidable/airborne cases;
- M0 lab exists under `Workspace.Runtime.Tracks`, not as a second top-level gameplay root.

### Empirical G0 still required
After the local technical smoke, `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` still owns product acceptance: **6 unique external testers** and every fixed G0 criterion must PASS. A local developer playtest is useful evidence but is not the six-tester empirical gate.

## Audit notes / remaining risk
The R09 repository pass found no reason to introduce a new top-level service, manager, race system, or data owner. Current M0 layering remains aligned with `21`: Bootstrap is composition root; `LegShapeService` owns authoritative shape processing; `RacerRuntime` owns body/legs/stabilizer/anti-stall lifetime; `StrokeRemoteTransport` remains transport-only; no early D05 `RacerService` exists.

The three R09 implementation findings are CLOSED. The remaining gate risk is runtime evidence, not an open known code defect from those findings.

One infrastructure limitation remains deliberately **not disguised as a pass**: CI is primarily static Python contract verification and does not compile/run Luau or Studio physics. The immediate mitigation at B17 is the required local `rojo build`/Studio gate. Adding broader CI toolchain coverage may be considered as a later bounded tooling task, but it does not replace the human G0 test and is not a reason to start C01 early.

## HARD STOP
**B17/G0 remains a HUMAN_GATE.** No C01, M0.5, multiplayer, meta, economy, shop, or later implementation may begin until G0 is explicitly recorded PASS or the Product Owner records a bounded rework/scope decision allowed by the gate protocol.

## Next permitted task
**B17 — G0 HUMAN_GATE only.**
