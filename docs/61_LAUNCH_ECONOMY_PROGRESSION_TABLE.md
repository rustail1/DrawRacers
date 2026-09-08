# 61 — LAUNCH ECONOMY, MASTERY & ACCESS TABLE
Статус: **LAUNCH ECONOMY NUMERIC CONTRACT v1.3.4**.

This file owns exact **starting** reward values, soft prices, mastery gains, access thresholds and launch Robux price hypotheses. They are implementation defaults, not claims about optimal live economy. Changes follow analytics/Decision Log rules in `10/16/49/55`. `06` owns the design meaning of Coins/Collection/Status/Access; `44` owns server reward/status behavior; `45/56/71` own purchase primitives/grant safety.

## 1. Coin reward table — valid finish/public heat
A valid reward is granted once per authoritative result. Public heats use the table below. The **first successful FTUE T06 finish uses the same placement row** plus applicable one-time bonuses; FTUE DNF is explicitly excluded by §2.

| Result | Coins |
|---|---:|
| 1st | 120 |
| 2nd | 100 |
| 3rd | 85 |
| 4th | 75 |
| 5th | 65 |
| 6th | 60 |
| 7th | 55 |
| 8th | 50 |
| Valid DNF with minimum participation | 25 |
| AFK/invalid participation | 0 |

One-time bonuses:
- first ever valid heat completion: **+100 Coins**;
- first ever win: **+100 Coins**;
- first clear of each TrackId: **+25 Coins**;
- FTUE completion: **Ink_Sky_01 cosmetic entitlement**; no duplicate Coin conversion.

No daily login reward is required at launch.

## 2. DNF reward rules
**EntryFTUEPlace/T06 DNF always grants 0 persistent Coins and 0 MP, does not consume FirstHeatBonus, does not grant FirstTrackClear, does not set Tutorial.Completed, and does not mutate FTUE ownership flags.** T06 simply repeats. This prevents retry farming and makes the first persistent FTUE mutation occur only on authoritative finish.

A **public RacePlace** DNF receives 25 Coins only if all are true:
- race was server-authoritative and reached `RACING`;
- player passed at least the first ordered checkpoint OR achieved >=25% resolved track progress;
- player did not remain AFK for more than half of active heat time;
- reward grant for this heat/player has not already been committed.

## 3. Mastery Points (MP)
Mastery is non-spendable progression/status. It never changes physics.

| Event | MP |
|---|---:|
| Valid finish | +5 |
| Podium (1st–3rd) | +2 extra |
| Win | +2 extra |
| First clear of TrackId | +3 extra |
| Valid DNF | +0 |
| Bot result | excluded from human profile |

Example first-time win on a new track: `5 + 2 + 2 + 3 = 12 MP`.

## 4. Launch access tiers
Public matchmaking does **not** split players into separate queues by mastery. RaceService selects a track tier that every current human in the heat is eligible to play, using the **minimum unlocked access tier among humans**; bots never lower the tier.

| Access tier | Requirement | Eligible pool |
|---|---:|---|
| INTRO | `Tutorial.Completed=false` with safe profile | `FTUE_MAIN` = T06 only until first finish |
| EARLY | FTUE complete, 0–39 MP | `PUBLIC_EARLY` |
| STANDARD | >=40 MP | `PUBLIC_STANDARD` |
| ADVANCED | >=120 MP | `PUBLIC_ADVANCED` |

Exact launch pool definitions/weights:
- `PUBLIC_EARLY`: T06 weight `0.50`; T07–T10 weight `1.00` each.
- `PUBLIC_STANDARD`: T06 weight `0.50`; T07–T16 weight `1.00` each.
- `PUBLIC_ADVANCED`: T11–T20 weight `1.00` each.

Selection after all humans are ADVANCED: first choose source pool `30% PUBLIC_STANDARD / 70% PUBLIC_ADVANCED`, then weighted-random inside that source pool. For mixed tiers, use the highest single pool allowed by the lowest human tier (EARLY or STANDARD); do not blend above that player’s access.

Immediate-repeat rule: if the resolved eligible candidate set has >1 TrackId, remove the immediately previous public TrackId on that server before renormalizing weights. Server owns RNG/selection; selected TrackId/ResolvedTrackSnapshot is identical for all racers. LiveOps `76` may multiply featured weights but never bypass access.

A human who joins during an active heat spectates and participates next heat per `41`; access is evaluated at heat assembly freeze.

## 5. Visible status milestones
These are presentation titles only; they do not alter matchmaking or physics.

| Title key | Requirement |
|---|---|
| ROOKIE | default |
| ROLLER | 40 MP |
| ADAPTER | 120 MP |
| SHAPE SMITH | 300 MP |
| TRACK HACKER | 600 MP |
| DRAW MASTER | 1000 MP |

Additional visible counters: Wins, Podiums, Races Finished, Mastery Points. Seasonal rank remains later scope.

## 6. Launch soft-currency cosmetic prices
Exact item art/content is owned by `62`.

### Bodies
| ItemId | Coins |
|---|---:|
| Body_Default_01 | 0 / default |
| Body_Stripes_01 | 350 |
| Body_Checker_01 | 650 |
| Body_StickerBomb_01 | Pass-only |
| Body_NeonGrid_01 | Pass-only |
| Body_CrownPlate_01 | Pass-only |

### Inks
| ItemId | Coins |
|---|---:|
| Ink_Graphite_01 | 0 / default |
| Ink_Sky_01 | FTUE reward |
| Ink_Coral_01 | 300 |
| Ink_Lime_01 | Starter Pass-only |
| Ink_Spectrum_01 | Themed Pass-only |

### Trails
| ItemId | Coins |
|---|---:|
| Trail_None | 0 / default |
| Trail_SpeedLines_01 | 700 |
| Trail_Dots_01 | 900 |
| Trail_Pixel_01 | Themed Pass-only |
| Trail_Stars_01 | Premium Pass-only |

### Finish FX
| ItemId | Coins |
|---|---:|
| Finish_Pop_01 | 0 / default |
| Finish_Confetti_01 | 1000 |
| Finish_Spark_01 | Starter Pass-only |
| Finish_NeonBurst_01 | Themed Pass-only |
| Finish_CrownBurst_01 | Premium Pass-only |

## 7. Economy pacing starting expectation
- A new player receives visible customization immediately after FTUE (`Ink_Sky_01`).
- If the first successful FTUE finish is 8th, its exact minimum Coin grant is `50 placement + 100 first valid completion + 25 first T06 clear = 175`; one additional 8th-place public finish yields 225 total. One more average public race approaches the 300–350 first soft-cosmetic range.
- First soft-price target is 300–350 Coins; expected engaged first session can buy one item without paying.
- Winning accelerates collection modestly, but does not gate it.
- No soft item is consumed on equip; purchases are permanent profile ownership.

## 8. Launch Robux SKU price hypotheses
The platform listing/price is deployment data and must match runtime Marketplace data. Starting price targets:

| SkuKey | Primitive | Price hypothesis | Grant |
|---|---|---:|---|
| STARTER_STYLE_PASS_A | Pass | 59 Robux | Body_StickerBomb_01 + Ink_Lime_01 + Finish_Spark_01 |
| NEON_STYLE_PASS_A | Pass | 149 Robux | Body_NeonGrid_01 + Ink_Spectrum_01 + Trail_Pixel_01 + Finish_NeonBurst_01 |
| PREMIUM_PRESENTATION_PASS_A | Pass | 299 Robux | Body_CrownPlate_01 + Trail_Stars_01 + Finish_CrownBurst_01 |
| COINS_450_DP | Developer Product | 49 Robux | 450 Coins |
| COINS_1100_DP | Developer Product | 99 Robux | 1100 Coins |
| COINS_2500_DP | Developer Product | 199 Robux | 2500 Coins |

Coin Developer Products start **disabled**. They may be enabled only after the soft economy and cosmetic engagement satisfy `45` eligibility plus `55` G5 and a Product Owner Decision Log confirms they do not harm fair play/collection pacing. Receipt grants use `56` exactly.

## 9. Offer ordering
After canonical eligibility:
1. Starter Style Pass is the first contextual paid offer.
2. Neon Style Pass may appear after player has opened Garage at least twice OR owns any non-default cosmetic beyond FTUE reward.
3. Premium Presentation Pass may appear only after >=10 completed heats or ownership of another paid Pass.
4. Coin packs, if enabled, are shown in Garage/soft-shop only when player is actively viewing a Coin-priced item they cannot afford; never interrupt Results/Race.

## 10. Economy config keys
Implementation should map values into one authoritative EconomyConfig table with these keys:
- `PlacementCoins[1..8]`
- `ValidDnfCoins`
- `FirstHeatBonusCoins`
- `FirstWinBonusCoins`
- `FirstTrackClearCoins`
- `MasteryFinish`, `MasteryPodium`, `MasteryWin`, `MasteryFirstClear`
- `AccessThresholdStandard`, `AccessThresholdAdvanced`
- `SoftPrices[ItemId]`
- SKU deployment mappings from `30`.

Changing exact numbers is tuning. Changing what Coins can buy, adding power, making Mastery spendable, or changing queue fairness is a product change requiring owner-doc update.


## 11. First-player routing
With a safely loaded profile and `Tutorial.Completed=false`, the player remains/is routed to **EntryFTUEPlace** and only the controlled `FTUE_MAIN` T06 heat is eligible. Remaining slots fill after the 2s FTUE assembly timeout. On first authoritative T06 finish, server commits the placement Coin row + applicable first-valid-completion/first-T06-clear bonuses + MP finish/first-clear values, together with Tutorial completion + FTUE Ink_Sky grant/equip in one canonical PlayerDataService mutation before routing the player to RacePlace. **FTUE DNF commits no persistent reward/progression and consumes no one-time bonus; T06 repeats in EntryFTUEPlace.** GuestSafe may practice but does not persist completion/rewards; after profile safety restores, routing follows the real Tutorial flag. Exact lifecycle = `41`.

## 12. Starting offer-frequency / cooldown defaults
These are launch hypotheses so implementation does not guess:
- Starter Style: first compact Results offer at the first Results screen after canonical eligibility becomes true; after dismissal, suppress for **3 completed heats** and at least **10 minutes**; maximum **2 Starter impressions per session**; never show again after ownership.
- Neon Style: never auto-modal from Results; show a recommended card in Garage after its eligibility rule; maximum **1 highlighted impression per session**; normal catalog browsing remains available.
- Premium Presentation: Garage/catalog only; no automatic Results card; maximum **1 highlighted impression per session**.
- Any purchase-prompt cancel/fail suppresses the same SKU for **10 minutes**; purchase pending blocks duplicate prompt for that SKU.
- GuestSafe: zero paid impressions/prompts.

Tuning may reduce frequency. Increasing above these caps requires monetization experiment/guardrail review; eligibility floor from `45` cannot be weakened by tuning.
