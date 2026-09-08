# 74 — RACE LIFECYCLE, TIMEOUT & REQUEUE DEFAULTS
Статус: **EXACT HEAT LIFECYCLE CONTRACT v1.3.4**.

Цель: один owner для спорных таймингов и переходов `arrival → queue → heat → finish → results → requeue/spectate`, чтобы RaceService, UI и matchmaking не интерпретировали их по-разному. Numeric starting defaults mirror into `16/RaceConfig`; this file owns semantics.

## 1. Arrival queue rule
### EntryFTUEPlace
Eligible first-timer is automatically queued for T06 after safe profile load. FTUE retry remains automatic until first authoritative finish unless the player leaves the experience.

### RacePlace
A safely loaded `Tutorial.Completed=true` human receives **one automatic initial queue intent on arrival**. If a heat is active, player spectates with `YOU'RE IN NEXT RACE`; if assembly is open, player may join that next roster.

After the player has participated in a public heat, future heats require explicit `RACE AGAIN`. There is **no launch auto-requeue setting**.

## 2. Public assembly clock
- Target slots: 8.
- Assembly starts/clock starts when first actually-ready human exists for the next heat.
- If 8 humans become ready before timeout, roster locks immediately.
- Otherwise after `HeatAssemblyTimeout=8.0s`, fill remaining slots with bots and lock.
- A clicked requeue intent from Results becomes `ReadyForNextHeat` only after that Results has been visible for `ResultsMinimumDisplay=3.5s` for that player.
- Server never waits for a player who did not requeue.

## 3. PREP / GO
- `PREP_COUNTDOWN = 3.0s`.
- DrawCanvas accepts input throughout PREP/countdown.
- No accepted shape at GO = stationary racer + draw hint; no StarterShape/default wheel.
- Heat elapsed timer starts at authoritative GO.

## 4. Hard timeout and finish grace
Starting defaults:
- `HardHeatTimeout = 90.0s` from GO.
- First valid human/bot finish starts `FinishGraceWindow = 15.0s`.
- Grace sweep allowed `12–20s`; hard timeout is always the outer cap.
- Effective heat end = earliest of `all active racers resolved`, `firstFinishTime + FinishGraceWindow`, `GO + HardHeatTimeout`.
- If nobody finishes before hard timeout, all unresolved racers are DNF.

DNF ordering is deterministic:
1. highest ordered checkpoint reached;
2. greatest clamped progress inside current checkpoint segment;
3. earlier time reaching that exact progress bucket if still tied;
4. stable racer slot index final tie-break.

## 4.1 Deterministic valid-finish ordering
For every accepted valid finish, server authority records two server-only values inside the heat:
1. `FinishAcceptedAt` — server monotonic acceptance time used for ordering/telemetry; client timestamps never participate;
2. `FinishSequence` — an integer incremented exactly once in the same serialized finish-accept path.

Valid finish placement sort is **`FinishAcceptedAt ASC → FinishSequence ASC → SlotIndex ASC`**. `FinishSequence` resolves finishes that land on the same observable server time/tick; `SlotIndex` is the final defensive tie-break. Once a racer receives a valid placement it is immutable for that heat. Duplicate/retransmitted finish touches cannot allocate a second sequence or change placement.

## 5. Kill plane
Each resolved TrackSnapshot exposes one `KillPlaneY`:
`KillPlaneY = MinTopOrCollisionYOfResolvedGameplayGeometry - 12.0 studs`.
For a baseline-only track this is `-12.0` when floor top is Y=0.

Crossing body center below KillPlaneY triggers recovery to last safe checkpoint. Decorative/non-collidable geometry is excluded from the minimum. Moving gameplay platform extrema are included in the resolved minimum.

## 6. FINISHING and reward commit
- authoritative placement may be shown immediately after valid finish;
- FINISHING presentation default = `2.0s`;
- reward value MUST NOT be displayed as granted until canonical race grant commit succeeds;
- while grant unresolved show `CALCULATING REWARDS…` or no numeric delta;
- GuestSafe displays `PROGRESS UNAVAILABLE` / `NO PROGRESS SAVED`, never a fake Coin delta;
- Results reward row uses committed profile delta only.

## 7. RESULTS and requeue
Starting defaults:
- `ResultsMinimumDisplay = 3.5s` before player can become server-ready for the next heat;
- `RACE AGAIN` is visible immediately but disabled for first `0.75s` to prevent accidental carry-over taps;
- after 0.75s click sets `RequeueIntent=true` and button becomes `QUEUED`;
- actual `ReadyForNextHeat=true` occurs when 3.5s minimum display has elapsed;
- opening Garage after queue intent does not cancel it;
- explicit `LEAVE QUEUE` cancels before roster lock;
- closing Garage returns to Results/queue context;
- no click = not queued, and server is not blocked.

If roster locks while queued player is in Garage, Garage remains open until server enters PREP, then closes with `RACE STARTING` transition; pending equip already committed before roster lock is reflected next heat.

## 8. Spectator behavior for late join
Launch spectator mode is automatic and non-interactive:
- DrawCanvas hidden;
- local PlacementChip hidden;
- ProgressStrip remains in spectator form;
- banner `YOU'RE IN NEXT RACE` if initial queue intent is active;
- camera follows current race leader with the same wide look-ahead principles as RaceCamera;
- leader switch occurs only when new leader is stable for >=`0.50s`, or immediately on authoritative finish/checkpoint ordering change that resolves first place;
- no manual spectator target cycling at launch.

After current heat ends, queued late joiner transitions normally into next assembly/roster.

## 9. Leave/disconnect
- voluntary leave/disconnect during RACING = DNF and no placement bonus;
- no mid-heat bot replacement;
- disconnect while only queued removes that ready slot; if assembly later reaches timeout, bot can fill it;
- rejoin follows normal EntryFTUEPlace routing and one-time arrival queue rules after safe load.

## 10. Reward idempotency
Race reward mutation uses a server-generated unique `GrantId` per player/heat grant and canonical idempotency path in `31/44`; do not key exactly-once behavior only by a client-visible raceId.

## 11. Acceptance
PASS when RaceService, ResultsController, GarageController, spectator UI and Bot Fill all follow the same rules above under: 1 human, 8 humans, late join, no requeue click, requeue+Garage, disconnect during assembly, first finish grace, nobody finishes, GuestSafe and controlled shutdown.
