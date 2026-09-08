# 49 — OPEN ITEMS: EMPIRICAL TUNING / LIVE OUTCOMES ONLY
Статус: **FINAL PRODUCTION FREEZE v1.3.4**.

Nothing in this file is an undefined implementation choice. Every tunable has a concrete starting value in an owner document; every product outcome has a measurement/escalation procedure. If an implementer asks “what value do I start with?”, the answer must already exist in `16`, `57`, `59`, `60` or `61`.

## Runtime / physics tuning
Start from exact defaults in `16`:
- hinge velocity/torque/acceleration;
- physical properties;
- stabilization/lane correction;
- collider/point limits;
- simplify/resample thresholds;
- anti-stall and stuck/recovery thresholds.

## Presentation tuning
Start from `16/59/62/47`:
- camera FOV/distance/look-ahead/damping;
- exact HUD/DrawCanvas anchors/sizes;
- rival LOD/opacity;
- VFX/audio/haptics intensity;
- hint/results timing.

Layout composition is **not** open-ended: `59` is the current accepted wireframe. Tuning may adjust values only after screenshot/playtest evidence and must not silently redesign hierarchy.

## Race / level tuning
Start from `16/60`:
- race/finish/results/hard timeout;
- T01–T20 TrackPiece dimensions and ranges;
- obstacle spacing/recovery pads;
- redraw cadence;
- moving obstacle periods;
- bot reaction/mistake/pace.

A TrackPiece can be tuned inside `60` launch ranges. Changing its primary geometry question/tag/topology is a design/content change, not numeric tuning.

## Economy / monetization tuning
Start from exact values in `61`:
- placement/DNF/first-time Coin rewards;
- Mastery gains/access thresholds;
- soft cosmetic prices;
- three Pass price hypotheses;
- disabled Coin-pack amount/price hypotheses;
- offer ordering/frequency after eligibility.

Paid-offer eligibility floor remains locked by `45`; Coin Developer Products remain disabled until their explicit gate/enable decision. Price optimization is empirical, not a missing design answer.

## Art/content iteration
Start from `62` exactly:
- public title candidate/fallback order;
- palette/theme identity;
- 20 produced launch cosmetics + Trail_None;
- two world themes;
- discovery A/B/C pack;
- launch asset checklist.

Artist execution details remain HOW. Changing catalog/theme/title order or required launch asset list is a Product Owner/content decision.

## Empirical product outcomes
R4/R7/R8/R9 remain measured through `55` G2/G4/G5/G6. Reference precedent does not pre-prove our social value, retention, cosmetic desire or PTR.

## Live metrics — measured, never invented
- PTR/acquisition quality;
- FTUE completion/delta times;
- races/session and finish→requeue;
- D1/D7 and session baselines;
- cosmetic interaction/conversion/repeat spend;
- FPS/latency/join/memory/error rates on `57` matrix.

## Procedure
1. Start from canonical owner value.
2. Change through config/content data/debug tooling, not scattered literals.
3. Record old/new + build/device/track/sample.
4. Run relevant `15` DoD + `24` QA + `55` gate + `57` performance + `59` screenshot matrix when applicable.
5. ACCEPT / REWORK / ROLLBACK.
6. Any new mechanic, scope, hierarchy, economy meaning or fairness change requires Decision Log + owner update + Feature List update.

All non-empirical questions resolve through `50_COMPLETENESS_MATRIX.md`.
