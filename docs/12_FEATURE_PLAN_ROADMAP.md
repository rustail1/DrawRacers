# 12 — PRODUCTION ROADMAP — IMPLEMENTATION SEQUENCE v1.3.4

## Gate philosophy
Product WHAT/WHY зафиксирован. Каждый milestone закрывает **acceptance objective** зависимого слоя. Не строить верхний слой поверх неисправной/непринятой реализации нижнего.

## M0 — Physics Lab
**Acceptance objective:** draw→physical shape works and passes Core Lab DoD + `55` G0.

Scope:
- cube;
- DrawCanvas;
- stroke processing;
- physical leg assembly;
- two-leg motor locomotion;
- stabilization/lane lock;
- atomic redraw;
- 5 canonical obstacles;
- debug/tuning tools.

No multiplayer service, shop, meta or LiveOps.

## M0.5 — Adaptation Track
**Acceptance objective:** authored grammar creates intended trade-offs and passes `55` G1; universal-shape dominance is a content/physics defect.

Scope:
- one 30–45s mixed test track;
- 3 strong shape requirement transitions;
- observation logging/playtest sheet.

## M1 — 2-Player Rival Slice
**Acceptance objective:** locked rival layer passes `55` G2 plus network/fairness QA.

Scope:
- 2 isolated lanes;
- same TrackDefinition;
- authoritative race state/checkpoints/finish;
- rival shape visibility;
- simple placement/progress HUD;
- fast rematch.

No shop/season.

## M2 — 8-Player Product Vertical Slice
**Acceptance objective:** target 8-player heat passes `55` G3 + `57` M2 device/performance thresholds.

Scope:
- private STAGING two-place environment provisioned via `64/70`;
- 8 lanes;
- first 10 authored tracks T01–T10 from `60/67`;
- FTUE;
- lineup/results/podium;
- fast requeue;
- basic Coins using `61`;
- vertical-slice subset of the exact `62` catalog;
- save/equip + atomic Coin catalog purchase via `71`;
- semantic audio/VFX/haptics and Settings/accessibility/safety controls;
- analytics baseline;
- target-mobile performance pass.

## M3 — Alpha Product Loop
**Acceptance objective:** full session/meta/persist loop works, required Bot Fill is implemented before public cold-start release, and `55` G4/G5 are recorded before paid offers.

Scope:
- complete T01–T20 authored TrackDefinitions and both visual themes (`60/62`);
- mastery/status/access road using `61`;
- garage/collection matching `59/62`;
- first-session ownership pacing;
- **Bot Fill required before public cold-start release**; implementation follows `40_BOT_FILL_SPEC.md`;
- social presentation polish;
- admin/observability; save fault matrix; content registry/provenance binding (`34/31/69/70`).

## M4 — Monetization & Soft Launch
Only after core/session value exists and G5 passes:
- `56` Developer Product receipt/idempotency path where applicable;
- three exact launch Pass SKUs + contextual Starter Style offer from `61/62`; Pass reconciliation = `71`;
- cosmetic price tests after sample;
- discovery icon/thumbnail tests using `55` G6;
- funnel/economy analytics;
- LiveOps config infrastructure;
- content buffer;
- final launch UI/content/economy freeze checks (`59–62`), platform/asset binding (`64/70`), final transaction tests (`56/71`).

## M5 — Live Product
- course rotations;
- themed collections;
- tournament/season only if retention supports it;
- ongoing measurement contracts;
- scale investment based on data.

## Priority implementation order
1. A01–A04 repo/Rojo/Studio/deployment skeleton (`23/64/65/70`).
2. Stroke input/preview.
3. Clean/simplify/resample.
4. Physical leg assembly.
5. Hinge locomotion.
6. Body stabilization/lane lock.
7. Atomic redraw.
8. Five obstacle lab.
9. Mixed adaptation track.
10. TrackPiece contract/builder + exact assembly workflow `67`.
11. Race/checkpoint/finish authority.
12. 2-player network/social test.
13. Camera/HUD/rematch.
14. STAGING two-place provisioning (`64/70`).
15. 8-player scale/readability.
16. PlayerDataService + exact-once RewardService.
17. AnalyticsAdapter baseline before FTUE measurement.
18. Canonical BotRacerController foundation for controlled FTUE fill.
19. Confirmed Results + CosmeticService dependencies.
20. FTUE/routing using all accepted dependencies, then Garage/audio/settings.
21. Complete T01–T20 + both themes (`60/67/62/69`).
22. Mastery/status/access using `61`.
23. Extend canonical bot controller into required public Bot Fill + G4/G5.
24. Observability/save-fault/content-registry passes.
25. Exact launch Passes + Pass reconciliation `71` + DP receipt safety `56`.
26. Discovery A/B/C + G6.
27. LiveOps configs/G7.
28. PROD provisioning/ID binding (`64/70`).
29. QA/performance/rollback drill.
30. Final execution-consistency release audit `78`.
31. Public enable + first-hour/day monitoring.

## Stop points
Do not proceed if a gate fails. **Fix/retest the current implementation first.** Product scope is not implicitly reopened by a failed test; any WHAT/WHY change requires explicit owner decision + Decision Log + Feature List update.

## AI task rule
One task = one observable behavior with expected result → minimal change → Studio test → human acceptance. Never hand AI “build the whole game”.


## v1.3.4 exact-contract routing
- Core freehand coordinate/pivot/collider construction: `73`.
- Heat timeout/DNF/requeue/spectator semantics: `74`.
- Production bot difficulty/shape policy: `75`.
- H05 first-30-day LiveOps buffer: `76`.
- Final documentation/build audit: `78`.
