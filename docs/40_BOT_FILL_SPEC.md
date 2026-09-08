# 40 — BOT / FILL RACER SPEC
Статус: **COLD-START PRODUCT CONTRACT v1.3.4**.

## Purpose
Bots exist only so a low-CCU server still produces a readable competitive heat. They are not the long-term fantasy and never pretend to be real users.

## Rules
- Target heat = 8 slots. Humans have priority.
- At public-release heat assembly timeout, remaining empty slots **are filled** with clearly marked bots up to the configured target heat. Development/staging may disable fill explicitly for tests.
- Canonical defaults live in `16`: `TargetHeatSlots=8`, `MinimumHumanCountBeforeHeat=1`, public `HeatAssemblyTimeout=8s`, EntryFTUE `FTUEAssemblyTimeout=2s`, `BotsEnabledProduction=true`. Runtime config schema: `30`.
- A bot uses the same physical racer template and same legal ShapeSpec bounds.
- Bot exact canonical presets, RequirementTag mapping, lookahead and mistake behavior are `75_BOT_SHAPE_POLICY_BEHAVIOR_CATALOG.md`; preset coordinates are `73`.
- Bot EASY/MEDIUM/HARD profile is fixed at heat start per `75`; no hidden rubber-band teleport or impossible speed.
- Bots do not earn persistent rewards, appear in global player leaderboards, make purchases or create analytics as human users.
- New human replaces a bot only between heats.

## Difficulty
Exact starting mix/profile sequence is `75`. Goal is credible competition without guaranteeing player wins; tuning comes from real finish distributions, never placement-driven dynamic cheating.

## Technical owner
`BotRacerController` is server-side policy feeding legal shape intents to existing `LegShapeService`; it does not duplicate Racer/Physics systems.


## Bot presentation
Every bot display marker uses prefix `BOT` plus racer number, e.g. `BOT #4`; no fake human display name/avatar. Results row also carries a `BOT` chip. Exact marker placement follows `59`.

FTUE uses the same fair BotRacerController/shape bounds but the shorter assembly timeout; no special hidden bot physics or rubber-band is permitted.


## Single implementation path
`25/66` E07 creates the canonical BotRacerController/shape-decision path for controlled EntryFTUE fill. F05 only enables/extends that same path for public 8-slot cold-start assembly. A second FTUE-only bot physics/controller implementation is forbidden.
