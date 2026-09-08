# 76 — FIRST 30 DAYS LIVEOPS CONTENT BUFFER
Статус: **LAUNCH + 30-DAY CONFIG-READY CONTENT PLAN v1.3.4**.

Цель: выполнить правило `09` о месяце готового контента без необходимости придумывать первую LiveOps-программу после релиза. Это starting schedule; production data may reorder/disable entries through the measurement/rollback contract. Ни один event ниже не меняет racer physics или fair placement.

## 1. General rules
- LiveOps starts only after launch stability checks pass.
- All events are configuration combinations of existing tracks/objectives/rewards/messages/themes; no new gameplay code.
- Coin multipliers modify post-race soft reward only, never speed/physics/checkpoint placement.
- If an event hurts FTUE, stability, retention guardrails or economy, disable/rollback through config immediately.
- New players still complete canonical T06 FTUE before public event rotation.

## 2. Launch baseline — Day 0–6
`Id = LAUNCH_STANDARD_01`
- public pool: canonical access pools from `61`;
- multiplier: `1.00 Coins`;
- objective: none during Day 0–6; baseline deliberately avoids extra objective/reward pressure so launch metrics establish the canonical game/economy;
- theme follows TrackDefinition;
- purpose: establish clean baseline metrics before adding modifiers.

## 3. Week 2 — Day 7–13: CLIMB WEEK
`Id = CLIMB_WEEK_01`
- eligible featured TrackIds: `T04,T10,T13,T16,T20` subject to player access tier;
- featured selection weight ×`1.50` inside otherwise canonical eligible pool; inaccessible track is ignored, never force-unlocked;
- Coin reward multiplier `1.10` after base race reward/bonuses;
- objective `FINISH_5_FEATURED` → `100 Coins` one-time event objective reward;
- message: `CLIMB WEEK — DRAW FOR THE WALLS`;
- visual overlay: existing TOY/NEON theme only, no new collision art.

## 4. Week 3 — Day 14–20: GAP WEEK
`Id = GAP_WEEK_01`
- featured TrackIds: `T08,T09,T13,T17,T19` subject to access;
- featured weight ×`1.50`;
- Coin multiplier `1.10`;
- objective `FINISH_5_FEATURED` → `100 Coins` once;
- message: `GAP WEEK — REACH FURTHER`.

## 5. Week 4 — Day 21–27: COMPACT WEEK
`Id = COMPACT_WEEK_01`
- featured TrackIds: `T05,T07,T10,T14,T16` subject to access;
- featured weight ×`1.50`;
- Coin multiplier `1.10`;
- objective `FINISH_5_FEATURED` → `100 Coins` once;
- message: `COMPACT WEEK — GO SMALL`.

## 6. Day 28–30: NEON RUSH
`Id = NEON_RUSH_01`
- featured tracks `T11–T20` only for players whose common access pool allows them; lower-tier heats continue their normal pool;
- within ADVANCED selection, featured weight ×`1.25`;
- Coin multiplier `1.15`;
- contextual showcase may feature existing `NEON_STYLE_PASS_A` after normal `45` eligibility; no fake sale/discount/countdown;
- no exclusive paid gameplay reward;
- message: `NEON RUSH — MASTER THE MIX`.

## 7. Canonical config representation
Do **not** create a second event schema here. Every row below instantiates `30.LiveEventDefinition` exactly: `Id`, `Version`, `StartAtUTC`, `EndAtUTC`, `RuleModifierSetId`, `FeaturedTrackWeights`, `CoinRewardMultiplier`, `ObjectiveSetId`, `RewardTableId`, `CosmeticCollectionId`, `VisualThemeOverride`, `MessageKey`, `LeaderboardMode`, `OfferShowcaseSkuKey`, `Enabled`.

`StartAtUTC/EndAtUTC` are the only unresolved deployment values and are entered through the release calendar when PROD launch time is known. The source schedule remains relative Day N; no developer invents an alternate event window.

## 8. Objective persistence — required, not optional
H05 is incomplete until event objectives are implemented. Each enabled objective uses an `ObjectiveSetDefinition` + `RewardTableDefinition` from `30`; progress is server-verified from existing authoritative race events and stored in versioned LiveEvent profile data.

Objective progress/reward uses the **same authoritative race `GrantId`** and idempotent `31.ApplyRaceGrant` mutation as the finish that caused progress. Restart/rejoin/retry cannot count or grant twice. If an event objective system is unavailable or fails STAGING acceptance, that event remains `Enabled=false`; the release operator does **not** silently strip the objective or substitute a different reward.

Exact launch objective rows:
- `LAUNCH_STANDARD_01`: `ObjectiveSetId=nil`, `RewardTableId=nil`.
- `CLIMB_WEEK_01`: `ObjectiveSetId=CLIMB_WEEK_OBJECTIVES_01`; one `RACE_FINISH` objective `FINISH_5_FEATURED`, Target=5, TrackIds=`T04,T10,T13,T16,T20`; `RewardTableId=CLIMB_WEEK_REWARDS_01` grants `100 Coins` once.
- `GAP_WEEK_01`: `ObjectiveSetId=GAP_WEEK_OBJECTIVES_01`; `FINISH_5_FEATURED`, Target=5, TrackIds=`T08,T09,T13,T17,T19`; `RewardTableId=GAP_WEEK_REWARDS_01` grants `100 Coins` once.
- `COMPACT_WEEK_01`: `ObjectiveSetId=COMPACT_WEEK_OBJECTIVES_01`; `FINISH_5_FEATURED`, Target=5, TrackIds=`T05,T07,T10,T14,T16`; `RewardTableId=COMPACT_WEEK_REWARDS_01` grants `100 Coins` once.
- `NEON_RUSH_01`: `ObjectiveSetId=nil`, `RewardTableId=nil`.

Progress and completion rewards are applied through the authoritative race `GrantId` transaction in `31/44`; no separate client objective-claim remote exists.

## 9. Measurement contract per event
Before activation record:
- baseline period and cohort;
- primary metric: voluntary rematch/heat participation among eligible returning players;
- guardrails: early exit, D1/D7 where sample supports it, session crashes/performance, Coin source inflation, payer conversion without offer pressure;
- event exposure flag/ID on analytics;
- keep/iterate/rollback date.

Events are not proof of retention; they are controlled reusable changes.

## 10. Content buffer acceptance
PASS for release planning when baseline + all four post-launch configs can be instantiated in STAGING from data only, messages/localization keys exist, objective progress/reward is idempotent through `31`, featured pools respect access/fairness, and disabling any event restores canonical `61` pools/economy without a code deploy.
