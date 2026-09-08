# 44 — STATUS, RANK & REWARD SPEC
Статус: **PROGRESSION CONTRACT v1.3.4**.

## Race reward order
Server validates result → RewardService computes one complete delta + server `GrantId` → PlayerDataService applies the exact-once `31` race-grant transaction → Analytics logs the **committed** delta → Results shows that delta.

## Soft reward inputs
Placement, finish vs DNF, participation floor, first-ever heat bonus, first-ever win bonus and first-clear TrackId bonus. Exact launch amounts are in `61_LAUNCH_ECONOMY_PROGRESSION_TABLE.md` and mirrored into authoritative EconomyConfig; no second numeric table is created.

## Status
Wins, Podiums, RacesFinished and MasteryPoints/titles are visible accomplishments. They never alter racer physics.

## Rank
Competitive rank/season is later scope. When enabled, rating algorithm is server-only, bots excluded, abandoned races handled explicitly, and matchmaking does not promise skill-based pairing until enough population exists. Enabling it requires an explicit scope/LiveOps decision, not a silent implementation addition.

## Mastery
Mastery is long-term evidence of play: races/achievements/track challenges → cosmetic/status unlocks. Avoid stat upgrades.

## Anti-farm
Rewards require a valid heat with minimum progress/participation. Repeated AFK/instant DNF cannot outperform normal play.


## Launch status/access
Exact MP gains, visible titles and public track access thresholds are `61`; exact pool membership is `60`.


## Reward presentation safety
Placement can be announced after authoritative finish, but numeric Coins/Mastery/status deltas are presented as earned only after canonical grant/profile mutation commits. FINISHING/RESULTS pending/GuestSafe copy is `74/59`.


## LiveOps objective rewards
Launch LiveOps objectives in `76` are server-verifiable `RACE_FINISH` counters from `30`. Their progress and one-time Coin completion reward are folded into the same idempotent `31.ApplyRaceGrant` transaction as the authoritative heat result, so retrying a heat grant cannot double-count or double-pay an event objective. No separate client claim endpoint exists.


## FTUE reward boundary
EntryFTUE T06 DNF is not a persistent reward result: 0 Coins, 0 MP, no first-completion/track-clear flags. Only the first authoritative T06 finish can commit Tutorial/Ink/reward state, exactly as `31/61`.
