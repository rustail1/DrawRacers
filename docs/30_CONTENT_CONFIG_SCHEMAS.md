# 30 — CONTENT & CONFIG SCHEMAS
Статус: **DATA CONTRACT v1.3.4**. Контент расширяется данными; новый track/cosmetic/event не должен требовать новый service. Exact launch TrackPiece/TrackDefinition values = `60`; economy/soft price values = `61`; launch catalog/art IDs = `62`.

## TrackPieceDefinition
```lua
{
  Id = "SmallSteps",
  Version = 1,
  Length = 28,
  Difficulty = 1,
  PrimaryRequirementTag = "LONG_REACH",
  Tags = {"LONG_REACH","HOOK_CLIMB"},
  ForbiddenAdjacentTags = {"PUNISH_LARGE_HARD"},
  StartMarker = "Start",
  EndMarker = "End",
  CheckpointSocket = nil,
  RecoverySocket = "Recovery",
  VariantParams = {StepHeight={Min=1.2,Max=1.8}, StepDepth={Min=3.5,Max=4.5}}
}
```

## TrackDefinition — canonical authoring schema
```lua
{
  Id = "T07_BIG_TO_SMALL",
  Version = 1,
  Theme = "TOY_WORKSHOP",
  Pieces = {
    {Id="FlatShort", Params=nil, VariantSeed=nil},
    {Id="SmallSteps", Params={StepHeight=1.6}, VariantSeed=nil},
    {Id="LowTunnelWide", Params={Clearance=4.2}, VariantSeed=nil},
    {Id="FlatShort", Params=nil, VariantSeed=nil},
    {Id="FinishSprint", Params={Length=34}, VariantSeed=nil},
  },
  DifficultyTier = 2,
  ExpectedRedraws = {Min=2, Max=4},
  Tags = {"EARLY", "CLIMB_CLEARANCE"},
  Enabled = true,
}
```
`TrackService` resolves this authoring definition once per heat into the immutable `ResolvedTrackSnapshot` described in `22`. All lanes use the same resolved snapshot.

## CosmeticDefinition
```lua
{
  Id="Body_Stripes_01", Category="Body", Rarity="Common",
  AssetKey="Body_Stripes_01", SoftPrice=350, RobuxSku=nil,
  Unlock={Type="Shop"}, PhysicsProfile="STANDARD", Enabled=true
}
```
`PhysicsProfile` для player-facing cosmetics всегда `STANDARD`.

## CosmeticCollectionDefinition
```lua
{
  Id="NEON_RUSH",
  DisplayNameKey="COLLECTION_NEON_RUSH",
  ItemIds={"Body_NeonGrid_01","Ink_Spectrum_01","Trail_Pixel_01","Finish_NeonBurst_01"},
  Enabled=true,
}
```
Every referenced item must exist in the canonical cosmetic catalog; a collection is presentation/grouping, not a second ownership store.

## MonetizationSkuDefinition
```lua
{
  Key="STARTER_STYLE_PASS_A",
  ProductType="Pass", -- Pass | DeveloperProduct
  PlatformId=0,        -- required nonzero in STAGING/PROD environment config
  GrantKey="STARTER_STYLE_A",
  Enabled=false,
}
```
Platform IDs are deployment data, not product-design questions. DEV may use disabled/test mappings; STAGING/PROD validation fails closed when an enabled SKU has an invalid/missing PlatformId or mismatched ProductType.

## OfferDefinition
```lua
{
  Id="StarterStyle_A",
  EligibilityPolicy="PAID_STYLE_ELIGIBLE", -- exact rule owned by 45
  ProductType="Pass",
  SkuKey="STARTER_STYLE_PASS_A",
  Contents={"Body_StickerBomb_01","Ink_Lime_01","Finish_Spark_01"},
  ExperimentKey="starter_offer_v1",
  Enabled=true,
}
```
The config cannot weaken the eligibility floor in `45`; it may only further restrict/segment an already eligible player.

## BotProfile
Exact launch values/policy = `75`.
```lua
{ Id="EASY",   ReactionDelay=1.00, MistakeRate=0.20, PaceScale=0.92, ShapePolicy="TAG_LOOKUP_V1" }
{ Id="MEDIUM", ReactionDelay=0.70, MistakeRate=0.12, PaceScale=1.00, ShapePolicy="TAG_LOOKUP_V1" }
{ Id="HARD",   ReactionDelay=0.50, MistakeRate=0.06, PaceScale=1.05, ShapePolicy="TAG_LOOKUP_V1" }
```
Bot profile never changes dynamically after GO. PaceScale is think-time only, never physics.


## RaceQueueConfig
```lua
{
  TargetHeatSlots = 8,
  MinimumHumanCountBeforeHeat = 1,
  HeatAssemblyTimeout = 8.0,
  FTUEAssemblyTimeout = 2.0,
  PrepCountdown = 3.0,
  HardHeatTimeout = 90.0,
  FinishGraceWindow = 15.0,
  ResultsInputGuard = 0.75,
  ResultsMinimumDisplay = 3.5,
  KillPlaneMargin = 12.0,
  BotsEnabledProduction = true,
  AutoRequeueEnabled = false,
}
```
Numeric defaults mirror `16`; lifecycle semantics are `74`; bot fill is `40/75`.

## TrackPoolDefinition
Exact launch weights are `61`.
```lua
{
  Id="PUBLIC_EARLY",
  Entries={
    {TrackId="T06_STEPS_TO_SPEED",Weight=0.50},
    {TrackId="T07_BIG_TO_SMALL",Weight=1.00},
    {TrackId="T08_SPEED_TO_REACH",Weight=1.00},
    {TrackId="T09_REACH_TO_SPEED",Weight=1.00},
    {TrackId="T10_HOOK_TO_COMPACT",Weight=1.00},
  },
  PreventImmediateRepeat=true, Enabled=true,
}
```
`PUBLIC_STANDARD`/`PUBLIC_ADVANCED` populate exactly from `61`; TrackService removes last TrackId when >1 candidate then renormalizes.

## RewardTableDefinition
```lua
{
  Id="WEEKEND_REWARD_A",
  Entries={
    {RewardKey="Coins", AmountKey="EVENT_BASE_COINS"},
    {RewardKey="Cosmetic", ItemId="Ink_Coral_01", Condition="MILESTONE_FINAL"},
  },
  Enabled=true,
}
```
Actual launch numeric reward values resolve from the `61` economy table into Economy/Event Config; no client authors an amount.

## ObjectiveSetDefinition
```lua
{
  Id="CLIMB_WEEK_OBJECTIVES_01",
  Version=1,
  Objectives={
    {
      Id="FINISH_5_FEATURED",
      Type="RACE_FINISH",
      Target=5,
      TrackIds={"T04","T10","T13","T16","T20"}, -- nil means any authoritative finished track
      RequireHuman=true,
    },
  },
  Enabled=true,
}
```
Launch objective type is `RACE_FINISH` only. `TrackIds=nil` means any authoritative finish; a non-empty TrackIds list counts only those tracks. DNF does not increment. Bots never increment human objective progress. New objective types require a schema/Decision Log update rather than ad-hoc callback code.

## RotationDefinition
```lua
{
  Id="PUBLIC_ROTATION_A",
  Entries={
    {TrackPoolId="EARLY_PUBLIC_A", Weight=1},
    {TrackPoolId="WEEKEND_A", Weight=1, RequiresEventId="Weekend_InkRush"},
  },
  Enabled=true,
}
```

## RuleModifierSetDefinition
```lua
{
  Id="STANDARD_FAIR",
  TrackRuleOverrides={},
  PhysicsOverrides=nil, -- physics power overrides are forbidden in standard public competition
  Enabled=true,
}
```
At launch `STANDARD_FAIR` is the only public competitive modifier set. Any later non-standard rule family requires an explicit product/LiveOps Decision Log and clear mode segregation.

## LiveEventDefinition — canonical event schema
The first 30-day concrete event buffer is `76`. This section is the only field-name/schema owner.
```lua
{
  Id="CLIMB_WEEK_01",
  Version=1,
  StartAtUTC=0, -- deployment timestamp, resolved when calendar is known
  EndAtUTC=0,
  RuleModifierSetId="STANDARD_FAIR",
  FeaturedTrackWeights={ T04=1.50, T10=1.50 },
  CoinRewardMultiplier=1.10,
  ObjectiveSetId="CLIMB_WEEK_OBJECTIVES_01",
  RewardTableId="CLIMB_WEEK_REWARDS_01",
  CosmeticCollectionId=nil,
  VisualThemeOverride=nil, -- nil = TrackDefinition theme
  MessageKey="EVENT_CLIMB_WEEK",
  LeaderboardMode="STANDARD",
  OfferShowcaseSkuKey=nil,
  Enabled=false,
}
```
All referenced IDs must resolve at boot. Unknown references fail closed. `StartAtUTC/EndAtUTC` are deployment data, never fabricated design dates. Standard public competitive events may not modify physics power/fairness or bypass access. Field aliases such as `EventId`, `StartAt`, `EndAt` are forbidden in runtime config.

## Config rules
- уникальные IDs;
- schema version обязателен для persisted/remote significant data;
- unknown IDs fail closed;
- production configs валидируются при boot;
- runtime numbers живут в Config modules, не в UI/code duplicates.


## Launch config population rule
The schemas above do not authorize placeholder content. Before public launch:
- all 24 TrackPiece definitions and T01–T20 TrackDefinitions are populated from `60`;
- all 20 produced cosmetic items + `Trail_None` are populated from `62`, with soft prices from `61`;
- three Pass SKU definitions use the exact grant sets in `61/62`;
- disabled Coin Developer Product definitions may exist with `Enabled=false` until G5/Decision Log;
- missing referenced ID or duplicate catalog ID fails content validation in STAGING/PROD.
