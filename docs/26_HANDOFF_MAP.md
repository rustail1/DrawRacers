# 26 — SYSTEM HANDOFF MAP

Статус: **AI/DEVELOPER NAVIGATION v1.3.5**

Use this file before every task so AI/developer reads the smallest correct owner set. Exact current item still comes from `SESSION.md`; order comes from `25_IMPLEMENTATION_SEQUENCE.md`.

## Process routing before feature routing

Classify the task before selecting feature owners:

| Task type | Read first | Execution rule |
|---|---|---|
| BUGFIX | `AGENTS.md`, `BUGFIX_PROTOCOL.md`, `SESSION.md`, this handoff row, exact current owner specs/code | default PLAN ONLY; prove root cause/blast radius; no write until approved plan; then bounded RED→GREEN |
| REVIEW / `/review` | `REVIEW_PROTOCOL.md`, approved plan, actual base→head diff, affected owners | read-only; no repository writes |
| CONTRACT_CHANGE | `AGENTS.md`, current owner spec, Decision Log, relevant code | current code is not patched around old spec; approve new contract before implementation |
| FEATURE | `AGENTS.md`, `FEATURE_LIST.md`, `SESSION.md`, exact `66` row, this map, owner specs | technical reconnaissance → minimal implementation plan → implementation/acceptance |
| TUNING | numeric owner (`16/57/59/60/61` as applicable), evidence/gate owner `55`, `SESSION.md` | one value family at a time; measured evidence; no hidden contract change |
| DOC_ONLY | exact process/status owners | no runtime scope change; preserve gameplay/human-gate status unless explicitly part of the task |

Human copy/paste prompts and the remote GitHub → PC → Rojo → Studio handoff are in `AI_WORKFLOW_QUICKSTART.md`.

## Feature/system owner routing

| Feature/system | Read first | Main code owner | Primary acceptance/test |
|---|---|---|---|
| Drawing input | `03`, `16`, exact mapping `73`, network `22`, exact UI `59/68` | InputController + DrawingController | mouse/touch preview; B01/B02 |
| Stroke math | `03`, `16`, pivot/scale `73` | StrokeMath | pure tests + canonical strokes |
| Leg geometry | `03`, `11`, `21`, exact instances `65`, collider construction `73` | LegAssembly + LegShapeService | shape→bounded real collider |
| Hinge locomotion | `03`, `16`, `55` G0 | LegAssembly/RacerRuntime | flat + canonical shapes + G0 |
| Stabilization/lane | `03`, `16` | RacerRuntime | bounce allowed, lane drift controlled |
| Redraw | `03`, `22`, `55` | DrawingController + LegShapeService + RacerRuntime | atomic swap/contact stress |
| Obstacles / TrackPiece | `04`, `30`, `42`, **`60/65/67`** | TrackPiece assets/config | exact authoring + canonical trade-offs + G1 |
| TrackBuilder / resolved track | `04`, `30`, `21`, `22` | TrackService/TrackRuntime | same resolved snapshot all lanes |
| Race state | `05`, `21`, `22`, `28`, exact lifecycle/timeouts `74` | RaceService/RaceRuntime | phase/leave/timeout/rematch |
| Checkpoints/finish | `05`, `22`, `32` | ProgressValidationService | teleport/out-of-order rejection |
| 2-player rival | `05`, `08`, `29`, `55` G2 | existing race + camera/HUD | G2 crossover + fairness |
| Camera | `08`, `16`, `29`, **`59` exclusion/layout** | RaceCameraController | obstacle+rival readability |
| HUD/results | `08`, `05`, `29`, **`59/68`**, requeue timing `74` | HUD/ResultsController | exact hierarchy/layout + placement/rematch clarity |
| 8-player scaling | `05`, `24`, `55` G3, `57` | existing systems | full heat + device/perf PASS |
| FTUE | `08`, **`59`**, `61`, KPI plan `10`, events `46`, `55` | existing core + HUD | first-minute funnel + G4 inputs |
| Coins/rewards | `06`, **`61`**, `31`, `44`, analytics `10/46` | RewardService + PlayerDataService | grant once/save/economy event |
| Cosmetics | `06`, `43`, **`61/62/69/70/71`**, `44`, `55` G5 | CosmeticService | visual-only fairness + purchase/equip + free desire |
| Place/FTUE routing | `23`, `30`, `41`, platform `64/70`, `57` | PlaceRouterService + RaceService | new/returning/direct-edge/teleport retry matrix |
| Persistent data | **`31`**, architecture `21`, QA `24` | PlayerDataService | canonical schema/save/rejoin/migration |
| Save recovery/migrations | `31`, `24`, ops `35` | PlayerDataService | version/load/write/recovery tests |
| Monetization strategy/catalog | `07`, `19`, `45`, `61/62`, platform IDs `64/70`, Pass contract `71` | MonetizationService | contextual offer + confirmed entitlement + theatre |
| Developer Product receipts | **`56`**, `31`, `45`, `32` | MonetizationService + PlayerDataService | duplicate/retry/crash-path tests |
| Analytics/KPIs | `10`; **exact events `46`** | AnalyticsAdapter | published server events/funnel correctness |
| Bot fill | `40`, values `16`, shape/policy `73/75`, schema `30`, lifecycle `41/74` | BotRacerController + existing services | underfilled heat fairness |
| Security pass | `32`, `22`, `24` | all server boundaries | exploit suite |
| Performance pass | `33`, `24`, **`57`** | existing systems | 8-player soak + required device matrix |
| LiveOps/content scale | `09`, `30`, `42`, launch surfaces `60/62/67/69`, first-30-day buffer `76`, `55` G7 | configs + existing services | new content without new architecture |
| Discovery creative | `38`, evidence `54`, **`62` first A/B/C**, `55` G6, analytics `46` | product/creative + AnalyticsAdapter | comprehension + downstream guardrails |
| Release | `35`, `34`, `48`, `57`, `59–62`, platform `64/70`, task catalog `66`, current audit **`78`** | ops/process | staging/prod smoke + rollback + device PASS |
| Player safety | `39`, `37` | presentation/settings | abuse/readability/accessibility check |

Every task also reads `FEATURE_LIST.md`, `AGENTS.md`, `SESSION.md` and the relevant Decision Log. Do not read `_HISTORY/` for normal implementation. Historical changelogs and superseded audits are provenance only, never current owner specs.

Additional exact-owner shortcuts:
- UI placement/wireframe → `59`;
- TrackPiece dimensions + T01–T20 → `60`;
- Coins/MP/access/soft prices/Robux hypotheses → `61`;
- public title/art palette/themes/catalog/launch asset manifest → `62`;
- platform provisioning/release settings → `64`;
- exact Studio Instance/property/collision tree → `65`;
- per-task Done/stop criteria → `66`;
- level build workflow → `67`;
- UI child hierarchy/controller binding → `68`;
- art/audio/content production workflow → `69`;
- generated Place/Product/Asset ID registry → `70`;
- Coin catalog + Pass entitlement transaction rules → `71`;
- DrawCanvas→pivot→collider exact mapping → `73`;
- heat lifecycle/timeouts/DNF/requeue/spectator → `74`;
- bot preset/difficulty/decision policy → `75`;
- first 30-day LiveOps configs/objectives → `76`;
- current final audit → `78`.
