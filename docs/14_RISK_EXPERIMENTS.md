# 14 — RISK REGISTER & EMPIRICAL PRODUCT GATES — v1.3.4

> The game design is locked; the **outcome of our implementation is not pre-proven**. `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` defines samples, pass criteria, max rework cycles and escalation so a failed test never becomes an open-ended argument.

## R1 — Shapes do not meaningfully differ
Class: implementation/physics gate. Impact: blocks M0.
Experiment: round/line/hook/compact/asymmetric shapes across flat/stairs/gap/tunnel/wave.
Failure: same shape dominates or outcomes feel random. Gate: `55` G0.

## R2 — Redraw becomes busywork
Class: interaction/pacing gate. Impact: high.
Experiment: 30–45s mixed track designed for 2–4 meaningful redraws.
Failure: spam, avoidance or redraw perceived as interruption. Gate: `55` G1.

## R3 — Universal shape bypasses obstacle grammar
Class: level-grammar gate. Impact: blocks M0.5.
Experiment: canonical shape suite on mixed track.
Failure: one trivial shape clears nearly all requirement families at competitive pace. Gate: `55` G1.

## R4 — Real multiplayer adds little
Class: **empirical product outcome gate**, not merely a technical risk.
The project still ships toward an 8-player target, but the rival presentation must create measurable pressure/learning/comedy instead of noise. Gate: `55` G2.

## R5 — 8 racers create unreadable noise
Class: presentation/performance gate. Impact: blocks M2.
Experiment: progressive 2→4→8 test on target aspect ratios/devices. Gate: `55` G3 + `57`.

## R6 — Network/server physics feel bad
Class: implementation/platform gate. Impact: blocks M1/M2.
Experiment: Server Authority with target device/network cases; fallback only after measurement + Decision Log. Gate: `55` G3 + `57`.

## R7 — Session ends after novelty
Class: **empirical product outcome gate**. Reference games do not prove our rematch/session retention. Gate: `55` G4.

## R8 — Cosmetics do not create desire
Class: **empirical product outcome gate**. Fair cosmetic monetization is locked, but desire/conversion is measured in our build. Gate: `55` G5.

## R9 — Marketability is weak
Class: **empirical product outcome gate**. The core has market precedent; our title/icon/thumbnail/PTR do not. Gate: `55` G6 and `54`.

## R10 — Small team cannot sustain content
Class: production scalability gate.
Experiment: create new track/theme/collection through data/config after infrastructure. Gate: `55` G7.

## Acceptance order
1. G0 physical leg causality.
2. G1 adaptation / anti-universal-shape.
3. G2 2-player social value.
4. G3 8-player readability/network/performance.
5. G4 repeat session behavior.
6. G5 free cosmetic/status desire.
7. G6 discovery creative.
8. Monetization experiments.
9. G7 LiveOps/content scalability.

## Design-status rule
- **DESIGN LOCKED:** drawing locomotion, 8-player target, fair physics, meta pillars and non-P2W monetization are the chosen product.
- **EMPIRICAL PRODUCT GATES OPEN:** R4/R7/R8/R9 are outcomes that only our build/players can establish.
- **FAILED GATE:** rework the owner layer for up to the iteration budget in `55`. After that, Product Owner records `CONTINUE / SCOPE CHANGE / PIVOT / STOP`.
- A gate never silently invents a new mechanic or changes product identity.
