# 33 — PERFORMANCE BUDGETS
Статус: **ENGINE BUDGET v1.3.4**. These are project budgets, not Roblox platform limits. Exact release device classes and PASS/FAIL thresholds live in `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`.

## Targets
- Mid-range mobile design target: 60 FPS.
- Supported low-end reference device: must satisfy `57` low-mobile p95 frame-time gate.
- Server: investigate sustained frame degradation; release threshold is `57`.
- No monotonic memory growth across 30 consecutive heats.
- Join-to-control target/limit is `57`, measured on a cold client and published STAGING.

## Dynamic physics budget
- 1 Body + 2 hubs per racer.
- physics collider target: 8–12 active segments per leg; hard cap from `PhysicsConfig`; current absolute default cap 14/leg.
- 8 racers worst case should stay roughly <=200–220 dynamic collision parts before track dynamics.
- visual stroke may be smoother without creating more physics colliders.

## Allocation rule
Pool/reuse leg segments per racer where practical. Redraw must not create/destroy unbounded instance trees. Completed-stroke rebuild only; no per-pointer physics rebuild.

## Networking
- client sends completed gesture, not every pointer move;
- max payload bounded;
- replicate semantic state/physics, not per-frame reliable CFrames;
- local preview is immediate; authoritative accept/reject latency must meet `57`.

## Profiling gates
M0: redraw spike. M1: two clients + latency/physics. M2: eight clients + worst shapes + 30-heat soak. Pre-release: real/equivalent reference devices + client/server MicroProfiler + published Performance Dashboard.

## Release blocker rule
Any P0/P1, target-device threshold failure, sustained server frame failure, material join failure, or positive memory leak slope blocks release until fixed or explicitly removed from supported scope by Product Owner decision.
