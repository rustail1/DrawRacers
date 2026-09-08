# 41 — MATCHMAKING & SERVER LIFECYCLE
Статус: **SESSION / PLACE ORCHESTRATION CONTRACT v1.3.4**.

## Launch topology
The experience has exactly two places (`23/30`):
- **`EntryFTUEPlace` is the Roblox start place.** It exists to remove public-heat waiting from the first experience.
- **`RacePlace` is the continuous public-race place.** It runs normal 8-slot heats for onboarded players.

This is one experience and one product, not two game modes. Both places use the same canonical systems/profile/content. `PlaceMode` only changes orchestration.

## Common profile readiness
1. `PlayerDataService` starts canonical profile load (`31`).
2. Until load resolves, persistent economy/equip/purchases are disabled.
3. Safe load yields the authoritative `Tutorial.Completed` value.
4. GuestSafe permits non-persistent practice only; no paid offers, no persistent grants/equips, no retroactive rewards.
5. `PlaceRouterService` makes routing decisions server-side after the state above is known.

## EntryFTUEPlace — exact flow
### Safely loaded, `Tutorial.Completed=false`
Player remains in EntryFTUEPlace and enters the controlled `FTUE_MAIN = T06_STEPS_TO_SPEED` queue.
- Target slots = 8.
- Ready first-time humans have priority.
- `FTUEAssemblyTimeout = 2s` from the first ready human, then remaining slots are filled by fair bots from `40`.
- Only T06 is selectable. No Garage/Store/paid offers before authoritative finish.
- DNF/fail → Results may show retry, then next eligible heat remains T06.
- First authoritative finish → apply normal valid-race reward plus one-time `Tutorial.Completed=true` + `Ink_Sky_01` grant/auto-equip through canonical profile mutations (`31/61`) → show FTUE Results → server routes player to `RacePlace`.
- If teleport to RacePlace fails, keep the committed profile state, show `CONNECTING TO RACES…`, retry with bounded backoff; do not grant again. User may manually retry.

### Safely loaded, `Tutorial.Completed=true`
Do not put the player into FTUE roster. Route to `RacePlace` immediately.

### GuestSafe
The player may run T06 as **practice** with all persistence/paid UI disabled. Once safe load recovers:
- if `Tutorial.Completed=false`, remain in/enter the next T06 FTUE heat;
- if `Tutorial.Completed=true`, route to RacePlace at the next safe non-racing transition.
GuestSafe completion is never backfilled.

## RacePlace — exact flow
### Safely loaded, `Tutorial.Completed=true`
On arrival only, state receives one automatic initial queue intent per `74`. If a public heat is already active, the player observes/spectates with `YOU'RE IN NEXT RACE` and joins next assembly; there is no mid-heat insertion. After participating in a heat, subsequent public heats require explicit `RACE AGAIN`.

### Safely loaded, `Tutorial.Completed=false`
Player is **not** inserted into a public roster. `PlaceRouterService` routes them to `EntryFTUEPlace`. This covers direct joins, stale links and edge cases.

### GuestSafe
May observe or participate in public practice according to current roster capacity, but cannot persist rewards/equips/tutorial/purchases. Once profile safety restores, route according to the real Tutorial flag at the next safe transition.

## Public RacePlace heat assembly
- Capacity = `TargetHeatSlots` from `16/30` (default 8).
- Ready humans always take priority.
- Start immediately when 8 human slots are filled.
- Otherwise, after `HeatAssemblyTimeout = 8s` with at least one ready human, fill remaining slots with bots and lock roster.
- In PROD `BotsEnabledProduction=true` is mandatory. DEV/STAGING may disable only for explicit tests.
- Build one canonical `TrackDefinition`, resolve one immutable `ResolvedTrackSnapshot` through `TrackService/22`, and apply the same snapshot to every lane. Launch geometry is exact/no random variant; HeatSeed semantics are `22`.
- Track pool/access selection is `61`; bots never lower the human pool tier.

## Between heats
Safely loaded players may Garage/equip/requeue without leaving RacePlace. No lobby teleport loop. Exact Results guard, queue intent, server-ready delay, `LEAVE QUEUE`, spectator behavior and finish timeouts are `74`. Launch has no auto-requeue setting. Paid offers obey `45/61`.

## Disconnect / rejoin
Mid-heat disconnect = DNF; no bot takeover mid-heat. A normal rejoin starts at EntryFTUEPlace because that is the experience start place; after profile load, completed players are routed back to RacePlace. No reward rollback.

## Parties/friends
Roblox-native join/friend entry is supported, but dedicated party/server affinity is later scope. FTUE correctness takes priority over preserving a direct first-timer join into a friend’s RacePlace: first-timers complete T06, then return to public racing.

## Planned update / drain
RacePlace stops new public heat creation and drains current heat according to `35`. EntryFTUEPlace stops starting new FTUE heats, finishes safe active FTUE heats, commits completed tutorials, then routes or shows update status. Both places must run compatible schema/config versions during rollout.


## Deployment binding
Actual EntryFTUEPlace/RacePlace provisioning is `64`; environment PlaceIds live only in `70`. Lifecycle logic never hard-codes numeric PlaceIds.


## Implementation dependency
The two-place FTUE route is enabled only after `25/66` E04 PlayerDataService, E05 RewardService, E06 AnalyticsAdapter, E07 canonical BotRacerController, E08 confirmed Results and E09 CosmeticService are ACCEPTED. Routing code must not create temporary save/reward/bot substitutes.
