# 18 — TRELLO-READY BACKLOG

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is an implementation/integration stage only. Product power is never sold.

Use each heading as a card. Acceptance criteria are observable results. Do not pull later milestone cards early.

# LIST: M0 — PHYSICS LAB

## M0-01 DrawCanvas capture
**WHY:** implement and accept primary input on mouse/touch.  
**Sequence mapping:** M0-01 = `25` B01 + B02. Empty-repo bootstrap A01–A03 happens before it.  
**Depends:** A01–A03 accepted.  
**Acceptance:** pointer drag produces continuous local stroke preview; release emits bounded point list; cancel/outside handling does not error.

## M0-02 Stroke processing
**WHY:** raw finger noise cannot become hundreds of physics parts.  
**Depends:** M0-01.  
**Acceptance:** dedupe/simplify/resample deterministic enough for test inputs; limits from tuning; unit tests for tiny/duplicate/self-intersecting strokes.

## M0-03 One physical leg builder
**WHY:** close draw→collision chain.  
**Depends:** M0-02.  
**Acceptance:** normalized stroke builds bounded welded collider assembly attached to hub; no per-segment motors.

## M0-04 Hinge locomotion flat test
**WHY:** implement and accept geometry-driven body locomotion.  
**Depends:** M0-03.  
**Acceptance:** motor rotates leg; multiple shapes create measurable movement; no uncontrolled solver explosion in canonical cases.

## M0-05 Two legs + phase
**WHY:** reach target locomotion structure.  
**Depends:** M0-04.  
**Acceptance:** same stroke builds two legs; phase/direction correct; body moves forward consistently.

## M0-06 Stabilization + lane lock
**WHY:** keep 2.5D readable without killing physical bounce.  
**Depends:** M0-05.  
**Acceptance:** racer returns toward upright/lane center; can still tilt/jump on contacts.

## M0-07 Atomic redraw
**WHY:** redraw is core, not optional polish.  
**Depends:** M0-05.  
**Acceptance:** old legs continue during drawing; valid release swaps without reset/teleport; invalid stroke keeps old legs.

## M0-08 Five obstacle lab
**WHY:** test shape trade-offs.  
**Depends:** M0-06/07.  
**Acceptance:** flat, step/wall, gap, tunnel, uneven section; different shapes demonstrably better/worse; universal shape issue documented.

## M0-09 Core human test
**WHY:** accept the M0 implementation layer before moving to M0.5; failure uses bounded REWORK/ESCALATE from `55`.  
**Depends:** M0-08.  
**Acceptance:** execute `55` G0; record PASS/REWORK/ESCALATE and rework-cycle count. Product CUT/pivot only via Product Owner escalation after the defined budget.


# LIST: M0.5 — ADAPTATION PROOF

## M0.5-01 Mixed adaptation track
**WHY:** enforce/accept track grammar that creates decisions rather than one universal wheel.  
**Depends:** M0-08/09.  
**Acceptance:** 30–45s track contains at least 3 requirement transitions; multiple canonical shapes show different strengths; no single trivial shape remains competitively dominant across the whole route.

## M0.5-02 Adaptation human test
**WHY:** determine whether redraw is meaningful rather than busywork.  
**Depends:** M0.5-01.  
**Acceptance:** execute `55` G1; PASS required before networking, otherwise bounded REWORK/ESCALATE.

# LIST: M1 — 2-PLAYER SOCIAL PROOF

## M1-01 TrackPiece contract + builder
Acceptance: pieces connect by markers/pivots; bad piece fails validation; same definition can build two lanes.

## M1-02 Race state machine
Acceptance: waiting/countdown/racing/finished/results transitions deterministic; no client can force state.

## M1-03 Server stroke validation
Acceptance: rate/payload/bounds/state checks; malformed request cannot spawn unlimited parts.

## M1-04 Checkpoints + finish authority
Acceptance: out-of-order finish invalid; placement timestamps server-side; reward only once.

## M1-05 Collision isolation
Acceptance: racers see each other but cannot push/collide; track contacts remain correct.

## M1-06 2-player camera/HUD
Acceptance: local racer + future obstacle + rival readable; placement/progress correct.

## M1-07 Rematch
Acceptance: two players complete repeated heats without stale legs/track/state.

## M1-08 Network + social-value playtest
Acceptance: network cases logged and `55` G2 executed; PASS before 8-player scale-up.

# LIST: M2 — 8 PLAYER VERTICAL SLICE

## M2-01 Scale lanes to target heat
Acceptance: full heat loads/races/finishes repeatedly.

## M2-02 Authored track pool
Acceptance: T01–T10 are authored exactly from `60`, validate, and expose per-track metric IDs.

## M2-03 FTUE
Acceptance: first draw/movement/redraw/finish/Ink_Sky grant/rematch flow uses `08/59/61` and is measurable.

## M2-04 Results/podium/requeue
Acceptance: placement readable; quick next race; finished racers cannot interfere.

## M2-05 Data profile
Acceptance: canonical `31` profile, `61` Coins/MP values and equip state save/recover safely.

## M2-06 Cosmetics system
Acceptance: first required subset of `62` catalog exists and cosmetic visual definitions never change canonical collider/physics.

## M2-07 Economy
Acceptance: runtime rewards/prices match `61`, sources/sinks log correctly, FTUE Ink_Sky grant is once-only and first-session soft unlock pacing is possible.

## M2-08 Analytics
Acceptance: FTUE/core/economy events emitted server-side with controlled fields.

## M2-09 Mobile performance + 8-player gate
Acceptance: `57` M2 matrix + `55` G3 PASS; bottlenecks fixed or gate remains REWORK.

# LIST: M3 — ALPHA PRODUCT / PUBLIC-LAUNCH CONTENT

## M3-01 Complete T01–T20 + both themes
Acceptance: every TrackDefinition in `60` validates, both `62` themes exist, and no collision/decor mismatch changes geometry.

## M3-02 Mastery/status/access
Acceptance: MP gains, titles and pool eligibility match `61`; mixed-tier humans use the lowest common eligible pool without separate queues.

## M3-03 Garage final + launch catalog
Acceptance: `59` Garage wireframe, all 20 produced `62` cosmetics + Trail_None, and `61` prices/sources are represented with correct server-confirmed equip states.

## M3-04 Required cold-start Bot Fill
Acceptance: `40` behavior/defaults, clearly marked bots, same legal physics, no bot persistent rewards/leaderboards.

## M3-05 Session/free-value gates
Acceptance: execute G4 and G5 with records before paid offers.

# LIST: M4 — MONETIZATION / SOFT LAUNCH

## M4-01 Three launch Pass SKUs
Acceptance: exact Starter/Neon/Premium grants and initial price hypotheses match `61/62`; Pass entitlement reconciliation passes `71`; platform IDs come only from `70` and validate in STAGING/PROD.

## M4-02 Contextual Starter offer + theatre
Acceptance: eligibility from `45`, layout from `59`, confirmed entitlement before equip/celebration.

## M4-03 Receipt contract
Acceptance: if Coin Developer Products are enabled, every retry/crash/duplicate path in `56` passes; otherwise SKU definitions remain disabled.

## M4-04 Discovery A/B/C + G6
Acceptance: first three creatives match `62`, downstream funnel instrumentation exists, G6 recorded.

# LIST: M5 — RELEASE / LIVEOPS FOUNDATION

## M5-01 Config rotations + event constructor
Acceptance: regular course/cosmetic/event content can be assembled through `30` without new gameplay architecture.

## M5-02 Final production checks
Acceptance: `35/48/57/59/60/61/62/64/67/68/69/70/71` pass and no P0/P1 remains.

## M5-02A PROD platform provisioning
Acceptance: exact two-place PROD, registry, 3 Pass IDs, 3 disabled-or-enabled Developer Product IDs, asset IDs and namespaces resolve through `64/70`; private PROD smoke passes before public enable.

## M5-03 Final documentation/spec drift audit
Acceptance: `78` stays PASS against implemented release candidate or differences are documented/approved before shipping.

Post-release/data-dependent cards: season/tournament, party/friends, private-server features, rewarded video, subscription, procedural/endless.

Listed cards become ACTIVE through normal Feature List status changes. A Decision Log is required only when WHAT/WHY/scope/architecture changes, not merely to execute already-approved scope.


### v1.3.4 exact-contract addendum
For implementation cards: core geometry must cite `73`; race lifecycle/requeue cards cite `74`; Bot Fill cites `75`; one-month LiveOps buffer card cites `76`; final release audit card cites `78`. These are owner routes, not additional gameplay scope.
