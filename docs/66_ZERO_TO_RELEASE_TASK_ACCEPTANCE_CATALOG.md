# 66 — ZERO-TO-RELEASE TASK ACCEPTANCE CATALOG
Статус: **PROGRAMMER / CODEX EXECUTION CONTRACT v1.3.4**.

Цель: `25` fixes order; this file fixes the **minimum observable output and acceptance for every implementation task**. The implementer does not ask “what counts as done?” — they read the row, owner docs, implement the smallest end-to-end slice, test it, then move on.

## Global rule for every task
Before edit: `FEATURE_LIST → SESSION → 50 → 26 → this row → owner docs → relevant code`. After edit: automated checks → Studio test → regression → human acceptance where visual/feel → update SESSION. No later task starts while current ACTIVE task is not accepted.

## Phase A — bootstrap
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| A01 | Git repo + Rojo baseline | `23` | clean repo, `rojo serve/build` path works, Studio sync round-trip, first commit |
| A02 | Shared/config/type + server/client bootstrap roots | `21/23/65` | exact root tree exists; boot no errors; no empty future services |
| A03 | M0 test scene | `16/60/65` | flat lane + canonical obstacle anchors + debug spawn reproducible from clean sync |
| A04 | deployment/config skeleton | `64/70` | DEV/STAGING/PROD config files exist with no fake IDs; missing IDs fail closed |

## Phase B — M0 physics lab
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| B01 | pointer abstraction | `03/59/68` | mouse/touch produce same start/move/end/cancel semantic stream; no camera pointer conflict |
| B02 | local stroke preview | `03/59/68` | one continuous preview, exact DrawCanvas hit rect, cancel leaves current accepted shape |
| B03 | dedupe/clamp | `03/16` | deterministic unit tests; NaN/Inf/out-of-bounds rejected or clamped per contract |
| B04 | simplify/resample/pivot-map | `03/16/73` | same input → same normalized output; caps obeyed; useful shape not collapsed below minimum |
| B05 | stroke math tests | `24` | canonical, tiny, duplicate, self-cross, max-point, malformed cases PASS |
| B06 | RacerTemplate/RacerRuntime | `16/21/65` | exact instance tree, 3×3×3 collider, no Humanoid, spawn/despawn clean |
| B07 | one LegAssembly | `03/16/21/65/73` | normalized ShapeSpec becomes exact bounded physical segment chain around canonical hub/pivot |
| B08 | one hinge motor | `16` | flat movement exists, motor values from defaults, no hidden +X propulsion except allowed anti-stall |
| B09 | two legs + phase | `03/16/65/73` | exact same-XY duplicated left/right build at canonical hubs, +Z hinge axis/sign correct, phase offset starts correctly, one accepted shape controls both |
| B10 | stabilization/lane | `16/65` | R16.1: X/Y translation remains physical, Z translation remains lane-locked, and BodyCollider stays upright about world X/Y/Z within current tolerance; no extra forward race power |
| B11 | authoritative LegShapeService | `03/21/22` | client cannot create world geometry; server validates and owns ShapeSpec/build |
| B12 | SubmitStroke/StrokeResult | `21/22` | exact remote payload, stale/rate/malformed rejection, no generic RPC |
| B13 | atomic redraw | `03/28` | old legs remain while drawing/building; valid swap occurs atomically without teleport/reset velocity |
| B14 | redraw abuse/stress | `24/32` | spam/malformed/stale/large payload cannot leak parts, crash, or remove valid current shape |
| B15 | five-obstacle lab | `60/67` | flat/steps/wall/gap/tunnel use canonical defaults and are traversable by intended legal shapes |
| B16 | debug/tuning panel | `23/34` | displays required physics/shape/lane/checkpoint metrics; DEV/STAGING only |
| B17 | G0 human gate | `15/55` | recorded G0 PASS or bounded rework/escalation; no silent pass |

## Phase C — adaptation
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| C01 | TrackPiece data/validator | `30/42/60/65/67` | all required fields/Start/End/attributes/collision groups validated |
| C02 | mixed 30–45s track | `04/60/67` | requirement transitions force meaningful shape tradeoffs and recovery remains fair |
| C03 | universal-shape protocol | `03/55` | canonical shapes run under same conditions; results captured |
| C04 | G1 adaptation gate | `55` | voluntary meaningful redraw + no universal normal solution according to gate |

## Phase D — 2-player integration
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| D01 | two identical lanes | `05/30/60/67` | geometry hash/definition equal except lane Z offset |
| D02 | RaceTypes/RacePhase | `21/22` | explicit state enum; invalid transitions rejected |
| D03 | RaceRuntime | `21` | one heat owns runtime-only race state; cleanup leaves no old racers/track |
| D04 | RaceService state loop | `05/21/28/74` | arrival/assembly/prep/countdown/racing/finishing/results lifecycle and exact timeouts observable/deterministic |
| D05 | RacerService mapping | `21/65` | correct player↔slot↔lane; leave/despawn clean |
| D06 | progress/checkpoints/finish | `05/22/28/60` | ordered server validation; client cannot self-finish/skip checkpoint |
| D07 | server authority harness | `11/27/64` | current supported authority mode tested in STAGING/local equivalent; fallback documented only if required |
| D08 | network abuse suite | `22/24/32` | malformed/rate/stale requests fail closed, normal latency path still playable |
| D09 | camera | `08/16/59` | local racer + next obstacle + rival visible; touch exclusion zone respected |
| D10 | race HUD | `29/59/68` | placement/progress/countdown exact hierarchy/layout, no authoritative calculations client-side |
| D11 | results + requeue | `29/59/68/74` | exact 0.75s input guard/3.5s server-ready rule, one-tap repeat, duplicate request safe, no menu wall |
| D12 | G2 social/network gate | `55/57` | rival adds pressure/learning/comedy per gate; fairness/latency guardrails PASS |

## Phase E — 8-player vertical slice
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| E00 | STAGING two-place provisioning | `64/70` | EntryFTUEPlace + RacePlace IDs resolved in STAGING; routing config valid |
| E01 | 8 lanes/roster | `05/16/65` | slots 1–8, isolated collision, equal track, no visual/physics cross-push |
| E02 | T01–T10 | `60/67` | exact definitions reconstruct from clean data; per-track acceptance PASS |
| E03 | 8-player readability | `08/59/62/68` | local obstacle remains readable with 7 rivals; progress strip/shape detail modes work |
| E04 | PlayerDataService | `21/31` | safe load/lease/migrate/GuestSafe/transfer/release matrix PASS before persistent FTUE/reward path |
| E05 | RewardService + race/FTUE grant | `21/31/44/61` | one result → one atomic GrantId mutation; FTUE finish reward exact-once; FTUE DNF = 0 persistent Coins/MP/bonuses |
| E06 | analytics baseline | `10/46` | FTUE/core/economy events exist before funnel acceptance; authoritative confirmed points only; bots excluded from human funnels |
| E07 | canonical BotRacerController + FTUE fill foundation | `05/22/40/73/75` | same legal production bot controller builds legal shapes; EntryFTUE 2s fill works; no hidden physics/rubber-band/rewards/human analytics |
| E08 | confirmed Results/podium/requeue | `29/59/61/62/68/74` | exact reward rows/next goal/CTA states, deterministic finish/DNF path, no unconfirmed reward display, no premature paid offer |
| E09 | cosmetic definitions/service | `31/43/61/62/71` | ownership/equip/source rules enforce standard physics; FTUE Ink renders and authoritative auto-equip/rejoin state works |
| E10 | two-place FTUE/routing | `08/10/23/31/41/46/59/61/64/70/74` | only after E04–E09: new safe profile T06→atomic commit→confirmed Results→RacePlace; analytics + return/direct/teleport retry/failure matrix PASS |
| E11 | Garage + Coin catalog purchase | `59/61/62/68/71` | browse/preview/buy/equip exact; atomic Coin purchase/no double charge |
| E12 | audio/VFX/haptic feedback | `47/62/68/69/70` | semantic cues resolve by key, local priority readable, Reduce Motion behavior works |
| E13 | Settings/accessibility/safety UI | `37/39/59/68` | launch settings apply; rival shape FULL/REDUCED/HIDDEN path tested |
| E14 | 8-player perf/security/transfer gate | `24/32/33/55/57` | G3 + M2 device/30-heat soak + transfer + abuse/fault P0/P1 PASS |

## Phase F — alpha product loop
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| F01 | T11–T20 + themes | `60/62/67/69` | all 20 release-track rows PASS, both theme kits no physics changes |
| F02 | mastery/status/access | `06/44/61` | exact MP/titles/pools; lowest-human eligibility rule; no power stats |
| F03 | full launch collection | `43/61/62/69/70` | 20 produced assets + null state bound, preview/equip/rejoin verified |
| F04 | session pacing | `02/06/08/55` | G4 voluntary rematch/session criteria PASS, no mandatory shop/daily wall |
| F05 | production Bot Fill | `40/41/16/73/75` | extends E07 same controller; timeout fills to 8; deterministic profile/preset decisions; same legal shapes/physics; no rewards/analytics pollution |
| F06 | free expression desire gate | `55` | G5 PASS before paid offer code/creative is enabled |
| F07 | admin/observability | `34` | required metrics/flags/diagnostics, no player-accessible admin path |
| F08 | save fault/migration/handoff regression | `31/24` | timeout/crash/lease/teleport/duplicate GrantId/GuestSafe matrix PASS |
| F09 | content registry/provenance bind | `36/48/69/70` | required assets have owner/source/hash/license/IDs and no raw IDs in gameplay |

## Phase G — monetization/soft launch
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| G01 | MonetizationService + DP receipt path | `45/56/70` | duplicate/retry/crash Product receipts exact-once; disabled Coin DPs cannot prompt |
| G02 | three Passes + contextual offers | `45/61/62/70/71` | eligibility/frequency exact, ownership reconciles on load/prompt, no client-authority grant |
| G03 | post-purchase theatre | `07/45/59/62` | celebration after confirmed state; item immediately preview/equip capable |
| G04 | monetization analytics | `10/46` | OfferSeen→Opened→Prompted→Succeeded/Failed→Equipped chain consistent |
| G05 | discovery A/B/C | `38/54/55/62/64` | G6 recorded; creative promise matches actual first minute |

## Phase H — LiveOps foundation
| ID | Build | Required owners | Acceptance / stop condition |
|---|---|---|---|
| H01 | course rotation config | `09/30/60` | change pool/rotation without service code edit |
| H02 | cosmetic collection config | `09/30/43` | new collection data-driven, no physics owner change |
| H03 | event modifier schema | `09/30` | only fair allowed modifiers; invalid power modifier fails validation |
| H04 | measurement contract workflow | `09/10/46` | each live change has metric/guardrail/segment/method/rollback before enable |
| H05 | content buffer | `09/30/31/44/61/69/76` | baseline + Day 7–30 configs instantiate data-only; featured finish objectives/rewards are exact-once; disable restores canonical baseline |
| H06 | season/tournament | `09` | remains disabled unless retention/social evidence explicitly unlocks scope |

## Phase I — final release freeze
| ID | Build/check | Required owners | Acceptance / stop condition |
|---|---|---|---|
| I01 | UI screenshot matrix | `59/68` | all reference resolutions/states PASS |
| I02 | content manifest | `62/67/69/70` | all tracks/themes/cosmetics/audio/VFX/discovery rows RELEASE_VERIFIED |
| I03 | economy/progression verification | `61/71` | runtime config equals approved launch values or logged tuning decision |
| I04 | name/IP/safety/platform policy | `39/48/62/64` | clearance/maturity/provenance PASS |
| I05 | PROD provisioning + ID binding | `35/64/70` | both places + SKU/assets + namespaces resolved; private PROD smoke PASS |
| I06 | QA/performance/deploy rollback drill | `24/35/57` | no P0/P1, rollback pair known-good, 30-heat/device matrix PASS |
| I07 | final documentation/build audit | `78` | EXECUTION-CONSISTENCY audit PASS; manifest/static/dependency checks PASS |
| I08 | public enable | `35/64` | only now enable public access/discovery; monitor first hour/day |

## Completion definition
“Game built” means I08 completed, not “core works”. Any implementation ambiguity affecting player-visible WHAT/WHY routes back to its owner doc before code continues. Any HOW choice inside contracts belongs to the implementer and does not block production.
