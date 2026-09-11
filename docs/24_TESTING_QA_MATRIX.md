# 24 — TESTING & QA MATRIX

Статус: **ACCEPTANCE CONTRACT v1.3.5 / R17 OVERRIDE**

Чистая Console не означает готовую игру. Этот файл определяет, что именно проверять по уровням системы.

R17 mechanical/presentation override supersedes the old independent-leg motor assumption. Current M0 evidence uses one shared `LegPairAssembly`, one `AxleJoint` motor, two rigid side assemblies with structural 180° offset, plus the R17 production camera owner. Human Studio gates remain **HUMAN STUDIO PENDING** until real Studio evidence is supplied.

---

# 1. M0 core physics matrix

## Stroke input
- Mouse drag draws continuous preview.
- Touch drag draws without page/camera conflict.
- Pointer leaving canvas clamps/cancels according to spec without error.
- Tiny invalid stroke keeps previous shape.
- Very noisy stroke is simplified to bounded complexity.
- Self-intersection does not crash/build unbounded geometry.

## Shape build
- One accepted stroke builds two rigid physical side shapes mounted to one shared `LegPairAssembly` axle.
- Exactly one `AxleJoint` HingeConstraint/motor drives the pair; individual `LegAssembly` sides own no motor.
- Right side remains structurally offset by `RightPhaseOffsetDegrees = 180`; there is no runtime phase-chasing controller.
- Segment count stays within config cap.
- No per-segment motors.
- Segments form rigid assemblies under the shared axle.
- No explosive overlap at hub/body on canonical shapes.

## Locomotion
Canonical manual shape suite:
- round/loop;
- long bar/arc;
- hook/L-like;
- compact short form;
- weird/star/zigzag.

Check:
- flat movement exists;
- at least two shapes show clearly different useful behavior;
- compact shape passes clearance where oversized form struggles;
- hook/long form beats compact on climb/reach case;
- **R16.1 upright-body acceptance:** normal angular deviation <= 1.0 degree;
- strong-contact disturbance <= 3.0 degrees;
- after disturbance, return to <= 1.0 degree within 0.25 s;
- X/Y translation remains physical/free while orientation correction is active;
- orientation correction must not add forward propulsion or vertical lift.

## Redraw
- Old legs remain while drawing.
- Accepted release swaps the whole shared leg pair atomically.
- Invalid release keeps old shape.
- Body position/velocity not hard reset.
- One axle phase is preserved across redraw; left/right do not keep independent motor phases.
- After a successful redraw exactly one `AxleRoot` and two side leg models remain; no `*_Retiring` Instances leak.
- Redraw while leg touching obstacle does not explode or teleport.
- Repeated redraw stress test leaves no accumulating abandoned Instances.

## R17 reference-fidelity regression
- **R17.9 camera:** RMB/free-look yaw target is full 360° (no ±40° clamp); rendered yaw/pitch/follow remain smoothed; pitch remains bounded; release returns smoothly to canonical framing. Touch camera gesture ownership is accepted only from world-space starts outside DrawCanvas/active UI.
- **R17.10 shared axle:** production locomotion owns one `LegPairAssembly`, one `AxleRoot`, one `AxleJoint`, one motor, and two rigid side `LegAssembly` children.
- **R17.11 structural anti-phase:** no `PhaseLockToleranceDegrees`, `PhaseLockRecoveryTime`, `PhaseLockMaxRelativeCorrection`, `_StepLegPhaseSync`, or second motor sign exists in production. Right side is structurally 180° from left.
- **R17.12 mounting/collision:** side socket uses the canonical cube-surface offset (`LegSocketZAbs = 1.5`) and keeps presentation parts nonphysical; no hidden body/inner-hub overlap regression.
- **R17.14 atomic redraw:** redraw stages/replaces one shared pair, preserves one axle phase, keeps BodyCollider CFrame/linear/angular velocity intact, leaves exactly one axle root, and rolls back the complete replacement on build/commit/enable failure.
- These automated/Studio-evidence contracts do **not** promote camera feel, body feel, rider pose/readability or B17/G0 to PASS; those remain **HUMAN STUDIO PENDING** / human-gated.

---

# 2. M0.5 level grammar matrix

Mixed track must show:
- minimum multiple requirement transitions per spec;
- no universal trivial shape competitive across all sections;
- obstacle requirement visible before unavoidable failure;
- recovery space after hard section;
- human tester redraws for a reason they can verbalize.

Gate fail examples:
- one long bar wins everything;
- tester redraws only because UI tells them, not because geometry suggests it;
- best strategy is spam redraw continuously;
- physics result feels random rather than understandable.

---

# 3. M1 network/race matrix

Use Start Server + 2 Players.

## Race state
- both clients receive same countdown/start;
- client cannot start/finish race locally;
- leave during countdown handled;
- leave during racing handled;
- finish once only;
- timeout resolves race;
- rematch creates clean new runtime state.

## Track fairness
- both lanes use same TrackDefinition/parameters;
- checkpoints align logically;
- no lane gets different obstacle dimensions;
- racer collision isolation works.

## Stroke security
Send malformed payload tests:
- non-table;
- NaN/inf if representable;
- too many points;
- out-of-bounds points;
- spam rate;
- stale sequence;
- submit outside RACING/allowed state.

Expected: rejected safely; no unbounded Instances; no server error.

## Finish security
- direct teleport to finish without checkpoints rejected/no reward;
- out-of-order checkpoint rejected;
- duplicate finish gives one result/reward;
- server time determines order.

## Server Authority/physics
- test normal latency;
- simulated higher latency where possible;
- observe misprediction/rubber-band;
- confirm no client speed/position authority is required for victory.

Decision: GO / tune / documented fallback.

---

# 4. M2 8-player matrix

## Readability
- local racer unmistakable;
- next obstacle readable;
- rivals visible enough for social comparison;
- rival geometry does not obscure local obstacle read;
- placement/progress understandable.

## Performance
Worst-case:
- 8 racers;
- max allowed collider segments;
- repeated redraws;
- dynamic obstacle track;
- full UI/VFX baseline.

Collect:
- client FPS/frame time on target devices;
- server physics/load indicators;
- memory growth over repeated heats;
- network/misprediction symptoms.

Hard release/M2 thresholds and the supported reference device matrix are owned by `57_RELEASE_PERFORMANCE_DEVICE_MATRIX.md`. This file describes scenarios; `57` decides PASS/FAIL.

## Repeated heat soak
Run many heats without restart:
- no orphan racers;
- no orphan leg parts;
- no TrackRuntime leak;
- remotes not connected multiple times;
- placement reset;
- results reset;
- memory stable enough.

---

# 5. FTUE QA

First 60 seconds must demonstrate:
1. player sees/understands drawing area;
2. draws once;
3. racer visibly moves because of shape;
4. reaches a situation that motivates redraw;
5. successfully redraws or receives progressive hint;
6. finishes/understands goal;
7. sees immediate next-race reason.

Test no-text comprehension where possible before adding more tutorial copy.

---

# 6. Data QA

Published/private environment as required.

- first join profile created;
- rejoin restores profile;
- equip persists;
- race reward persists;
- write failure does not duplicate/grant corrupt state;
- profile migration old→new schema tested before schema rollout;
- leave/shutdown save path exercised;
- no client can set wallet directly.

---

# 7. Cosmetic fairness QA

Every cosmetic type:
- visual change visible;
- collider geometry unchanged;
- body gameplay bounds unchanged;
- motor parameters unchanged;
- camera target unchanged;
- no visibility exploit that hides obstacle/racer unfairly.

---

# 8. Monetization QA

Before live offer:
- execute all `56_PURCHASE_RECEIPT_GRANT_CONTRACT.md` retry/duplicate/crash-path cases;
- entitlement/receipt grant idempotent;
- purchase success produces immediate visible result;
- failure/cancel grants nothing;
- no paid item changes competitive physics;
- reconnect after purchase preserves item;
- UI does not claim false scarcity/discount.

---

# 9. Analytics QA

Roblox analytics events are server-side/published-game constrained where applicable.

Verify:
- event names/fields match `10_ANALYTICS_TEST_PLAN.md`;
- no high-cardinality user ids in custom field dimensions;
- at most intended custom fields used;
- funnel step order meaningful;
- economy sources/sinks balanced semantically;
- event fire counts checked via debug instrumentation before relying on dashboard delay.

---

# 10. Regression suites by shared change

If changed `StrokeMath` → rerun all canonical shapes + invalid payload suite.

If changed `LegPairAssembly/LegAssembly/physics` → rerun shared-axle invariants + five obstacle lab + redraw + respawn.

If changed `RaceCameraController/CameraMath` → rerun R17.9 yaw/pitch/smoothing/input-ownership automated checks plus human Studio camera-feel pass.

If changed `RaceService` → rerun start/leave/finish/timeout/rematch.

If changed `TrackBuilder` → rerun first authored tracks + lane equality validator.

If changed `PlayerDataService` → rerun save/rejoin/migration/reward/equip.

If changed cosmetics → rerun fair collider comparison.

If changed remotes/security → rerun malformed/spam/out-of-state requests.

---

# 11. Human playtest protocol
Sample sizes, pass criteria, maximum rework cycles and escalation are **not chosen ad hoc**. Use `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md` for G0–G7. The record below is attached to that gate run.

# 12. Human playtest record template

For each core test record:
```text
Build/version:
Device:
Track:
Shape(s):
What player expected:
What happened:
Was cause understandable?:
Where player voluntarily redrew?:
Where player felt physics random?:
Camera issue?:
Would they immediately race again?:
Bug vs tuning vs design issue:
Decision:
```


# v1.3.4 exact-contract regression suite

## UI layout (`59`)
- 1920×1080 desktop, 1366×768 desktop, 2532×1170 touch, 2400×1080 wide touch, low-end `57` device.
- Assert no HUD/DrawCanvas overlap with system inset; primary CTA visible; draw hit rect matches visual rect; modal Z-order correct.
- GuestSafe disables persistent/economy/purchase actions without hiding race access.

## Level content (`60`)
- Validate all 24 piece IDs, hard ranges, Start/End markers, recovery sockets where required, T01–T20 references.
- Build all lanes from the same ResolvedTrackSnapshot; compare transforms within tolerance.
- Run canonical shape suite on every piece default and min/max variants before PROD enable.

## Economy/progression (`61`)
- Placement 1–8, DNF valid/invalid, first-ever completion, first-ever win, first TrackId clear all grant exactly once.
- Mastery/access threshold transitions at 40/120 MP; mixed-tier heat uses lowest human eligible pool.
- Every soft cosmetic uses exact price/source; Pass-only item cannot be Coin-bought; disabled Coin DP cannot prompt.

## Launch catalog/art (`62`)
- All 20 produced cosmetic assets + Trail_None IDs resolve.
- Every visual shell fits canonical body envelope and has no gameplay collision.
- Both themes preserve identical TrackPiece collision snapshots.
- Discovery A/B/C capture contains only project-owned build assets.


## FTUE place routing matrix — release required
- new safe profile → EntryFTUEPlace T06 within gate → finish → tutorial/Ink_Sky exactly once → RacePlace;
- new safe profile → DNF → repeats T06, no tutorial completion;
- completed safe profile → EntryFTUEPlace → RacePlace, no FTUE roster;
- direct RacePlace + Tutorial false → EntryFTUEPlace, never public roster;
- teleport fails after FTUE reward commit → retry routing, no duplicate reward/grant;
- GuestSafe → no paid/persistent mutation; safety recovers false → T06; safety recovers true → RacePlace;
- rollout with compatible mixed server versions → no profile corruption.


## Persistence concurrency / lease matrix — release required
- duplicate `ApplyRaceGrant` with identical GrantId → one reward/status/tutorial mutation only;
- two distinct GrantIds → both apply exactly once;
- UpdateAsync timeout after commit → reconciliation sees GrantId and does not double grant;
- ProcessReceipt duplicate/retry → `56` exactly once;
- source server BeginTransfer → destination token takeover → any late source write is rejected by lease;
- TeleportInitFailed before takeover → source clears transfer marker and remains writable;
- expired/mismatched transfer token → cannot take active lease;
- stale lease >90s → new server can recover profile;
- non-stale foreign lease → GuestSafe/read-only, no forced overwrite;
- rapid settings/equip → coalesced persistence, final accepted state survives rejoin;
- mixed EntryFTUE/RacePlace transfer after FTUE finish → tutorial/Ink_Sky/race reward are committed once before route.


## v1.3.4 transaction/platform regression matrix
### Coin catalog (`71`)
- enough Coins; insufficient Coins; already-owned item; duplicate requestId/double click; stale client price; write timeout/uncertain outcome; GuestSafe; rejoin persistence; no negative Coins.
### Pass entitlement (`71`)
- already owned before join; purchase during session; cancel; ownership query timeout; rejoin after prompt before celebration; wrong environment PassId; no double grant.
### Deployment (`64/70`)
- DEV/STAGING/PROD namespaces isolated; current PlaceId resolves to correct mode; missing/unknown enabled SKU fails closed; Entry/Race IDs not swapped; disabled Coin DPs cannot prompt.
### UI/Studio contracts (`65/68`)
- exact collision isolation; no rogue unversioned Studio object dependency; no input focus leak between DrawCanvas/modal/camera.
