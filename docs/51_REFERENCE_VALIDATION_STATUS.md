# 51 — REFERENCE VALIDATION STATUS & COPY BOUNDARY
Статус: **PRODUCT EVIDENCE / DESIGN-FREEZE CONTRACT v1.3.4**.

Этот файл отвечает на один вопрос: **что мы считаем достаточным основанием для locked design, а что всё равно измеряется уже в нашей реализации?**

## 1. Reference-validated design basis
На основе материалов из `SOURCE_MAP.md` и dated evidence table `54_MARKET_EVIDENCE_SNAPSHOT.md` проект считает достаточным precedent для следующих высокоуровневых решений:
- drawing is functional input, not decoration;
- drawn geometry can drive/alter physical locomotion;
- obstacle geometry can create reasons to change shape;
- short drawing/physics/obby loops are understandable market patterns;
- race/relative progress is a familiar competitive wrapper;
- visible cosmetics/status can be legitimate non-P2W value in a fair competitive game.

Этого достаточно, чтобы **не держать эти пункты открытыми как дизайнерские вопросы**.

## 2. Project decisions — our adaptation
Следующее не “найдено внутри референса”; это зафиксированная архитектура нашей игры:
- up to 8 racers per heat;
- parallel equivalent lanes;
- no direct gas/jump/steering;
- two rotating drawn legs/wheels;
- redraw during movement;
- no racer-vs-racer physical collisions;
- server-authoritative race/checkpoint/reward validation;
- fast rematch;
- collection + status + access meta;
- cosmetics/status monetization with zero paid physics power;
- Bot Fill required before public cold-start release;
- authored TrackPiece grammar first, procedural later;
- config-driven LiveOps surfaces.

These are WHAT/WHY locks. AI/programmers implement them; they do not replace them with “better ideas” without an explicit Decision Log.

## 3. Empirical outcomes — measured after implementation
References cannot honestly guarantee the exact values below for our Roblox build:
- FPS/latency/jitter of our physical assembly;
- PTR of our title/icon/thumbnail;
- FTUE completion;
- races per session / finish→rematch;
- D1/D7;
- cosmetic interaction/conversion/repeat spend;
- exact price elasticity;
- exact track/camera/physics tuning.

These are **not design gaps**. Owners/defaults/procedures live in `16`, `24`, `33`, `46`, `49`; empirical product outcome gates and stop/rework rules live in `55`; performance PASS/FAIL lives in `57`.

## 4. Commercial claim rule
The documentation may say “reference-proven pattern”, “market precedent” or “design locked from successful references”. It must **not** say “hit guaranteed”, “retention proven for our build” or invent competitor/internal metrics that are not in `SOURCE_MAP`. A successful reference lowers design uncertainty; it does not eliminate execution/discovery risk.

## 5. Clean-room boundary
Allowed to study/adapt: high-level rules, causal loop, public observable behavior, broad genre conventions.

Must be original/cleared: source code, models, textures, exact levels/creative arrangement, UI expression, audio/music, branding/name/logo, copy, proprietary data, store/marketing creatives. Full release contract: `48_IP_CLEANROOM_RELEASE_CHECK.md`.

## 6. Decision consequence
Current rule:
- do not ask “should the game be drawing locomotion?” — locked;
- do not ask “should final target be 8-player?” — locked;
- do not ask “should monetization sell power?” — no, locked;
- do ask/measure “what FOV works?”, “what torque feels right?”, “what price converts?”, “what is our actual D1?” — tuning/data only.
