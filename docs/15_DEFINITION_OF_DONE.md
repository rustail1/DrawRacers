# 15 — DEFINITION OF DONE

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation stage only. Product power is never sold. Passing DoD means the implementation matches the locked design; it is not a promise of commercial success.

## Acceptance protocol
Human/empirical statements in this DoD are accepted only through the fixed sample/method/pass/max-iteration rules in `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md`. Performance statements use `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`; monetization receipts use `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md`.

## Core Lab DoD
- [ ] Mouse and touch strokes create valid preview.
- [ ] Server/local lab processing caps geometry safely.
- [ ] Shape creates real collision geometry, not only visuals.
- [ ] Two legs rotate via bounded motor.
- [ ] At least 4 canonical shapes show visibly different behavior.
- [ ] Redraw swaps without resetting racer progress.
- [ ] Flat/step/wall/gap/tunnel test obstacles each expose different trade-off.
- [ ] No common trivial shape dominates all 5 in human tests.
- [ ] No severe physics explosion from self-intersections within allowed bounds.
- [ ] `55` G0 is recorded PASS before M0.5.

## Adaptation Acceptance DoD
- [ ] Mixed track lasts roughly within target race window after tuning.
- [ ] Track contains at least 3 meaningful geometry requirement transitions.
- [ ] Testers voluntarily redraw for understandable gameplay reasons.
- [ ] Typical successful play does not depend on redraw spam.
- [ ] No trivial universal shape stays competitively dominant across the mixed route.
- [ ] `55` G1 is recorded PASS before multiplayer work; scope change requires separate owner Decision Log.

## 2-Player Rival Slice DoD
- [ ] Both players see same TrackDefinition.
- [ ] Race start is synchronized enough for fairness.
- [ ] Racers cannot collide/grief.
- [ ] Checkpoints must be passed in order.
- [ ] Server determines finish/placement/reward.
- [ ] Rematch works without server reset bugs.
- [ ] Player can observe rival solution without losing sight of own obstacle.
- [ ] `55` G2 is recorded PASS before 8-player scale-up.

## 8-Player Product Slice DoD
- [ ] 8 racers complete repeated heats without systemic desync.
- [ ] Target mobile frame/latency profile acceptable from measured test, not assumption.
- [ ] Camera/HUD readable with 8.
- [ ] Finish order stable under near-simultaneous finishes and matches `74` deterministic `FinishAcceptedAt → FinishSequence → SlotIndex` ordering; client time cannot affect placement.
- [ ] Leaver does not break heat.
- [ ] Track build deterministic across lanes.
- [ ] `57` performance release contract passes for the M2 stage.
- [ ] `55` G3 is recorded PASS.

## FTUE DoD
- [ ] Player applies first shape quickly without paragraph tutorial.
- [ ] Player experiences first redraw need in first minute-ish flow.
- [ ] Funnel logs server-side steps.
- [ ] Hint triggers only after diagnosed need.
- [ ] Next-race CTA returns to core quickly.

## Session/Product DoD
- [ ] Results do not block immediate requeue.
- [ ] Players can complete repeated heats without forced garage/shop detours.
- [ ] Playtest records races/session and finish→next-race behavior.
- [ ] Other racers add visible pressure/learning/comedy rather than only background presence.
- [ ] Cosmetic/status presentation is visible enough to be noticed without obscuring race readability.
- [ ] `55` G4/G5 are executed before monetization soft launch.

## Meta DoD
- [ ] Coins have visible fair sinks.
- [ ] Cosmetic equip persists.
- [ ] Mastery unlock does not change race physics advantage.
- [ ] Player sees next horizon.

## Monetization DoD
- [ ] Offer follows demonstrated cosmetic value.
- [ ] No product changes competitive physics.
- [ ] Purchase grant idempotent/persistent and passes `56` duplicate/retry/crash-path tests.
- [ ] Post-purchase immediately shows/equips value.
- [ ] Offer/purchase funnel measurable.

## LiveOps DoD
- [ ] New TrackDefinition requires no code.
- [ ] New cosmetic definition mostly data/assets.
- [ ] Event config changes course/reward/theme without new architecture.
- [ ] Every update has measurement contract.

## AI Task DoD
- [ ] Feature existed in Feature List.
- [ ] WHAT/WHY spec read.
- [ ] Technical reconnaissance done before new subsystem.
- [ ] Minimal step implemented.
- [ ] Happy path tested.
- [ ] Edge cases tested.
- [ ] Regression checked when shared code changed.
- [ ] Human visually/physically accepted in Studio.
- [ ] Decision Log/SESSION updated.


## UI / launch-content DoD v1.3.4
- [ ] Race/Results/Garage/Store/Settings match `59` hierarchy, anchors, responsive rules and source copy.
- [ ] All five `59` screenshot/device layouts have no overlap/clipping/input occlusion.
- [ ] T01–T20 are built from `60`; variant values are inside allowed ranges and validate.
- [ ] Runtime reward/mastery/access/soft prices match `61` starting config or documented accepted tuning.
- [ ] All required `62` launch art/content assets exist; cosmetics preserve STANDARD physics.
- [ ] Public title passes `48`, or the first cleared fallback from `62` is used.
