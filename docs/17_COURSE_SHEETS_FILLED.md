# 17 — COURSE SHEETS FILLED FOR THIS PROJECT

> PRODUCT LOCK v1.3.4: final target is an 8-player live drawing race; 2-player is only an implementation stage. Product power is never sold.

Этот файл показывает, как наша игра проходит методологию L1–L5. Он не заменяет специализированные specs.

# L1 IDEA SHEET — заполненная фиксация
## 1. Для кого
Зафиксированная primary audience target: Roblox players 9–13, для которых дизайн делает ставку на короткие obby/physics challenges, мгновенный визуальный результат, соревнование и самовыражение.

Им важно: быстро понять действие, сразу увидеть физический эффект, сравнить себя с другими и показать свой стиль.

Игра должна позволять: одним жестом создавать locomotion, немедленно видеть его последствия и соревноваться с видимыми rivals.

## 2. Спрос
Roblox demand signal: Draw & Slide, Draw Wheels to Escape, Wheel Drawing Obby, Draw Obby показывают большой исторический/актуальный интерес к drawing→physics/obstacle формату.

External signal: Draw Climber — крупный мобильный functional reference; Roblox drawing/physics demand подтверждается отдельными market signals. Финальный продукт не позиционируется как clone.

Референсы не гарантируют метрики именно нашей 8-player реализации или конкретного visual branding. Эти outcomes измеряются после реализации, но WHAT/WHY продукта уже зафиксирован.

## 3. Negative space
Игроки уже получают drawing obbies/vehicles. Зафиксированная адаптация/дифференциация: **видимые чужие формы и real-time placement** являются постоянной частью core решения. Это project decision, а не утверждение о гарантированном retention effect.

## 4. Главный глагол
Главный: **рисовать locomotion shape**.

Связка: читать трассу → рисовать → наблюдать физический результат → сравнивать темп → redraw → финишировать → получать visible progression → снова гонка.

## 5. Первые пять минут
См. `08_FTUE_UI_CAMERA.md` и `01_PRODUCT_IDEA_MARKET.md`. Core должен быть понятен и весел до меты.

## 6. Почему Roblox
1 player = physics puzzle/time trial. 2 = pressure + copying/learning. 5–8 = social spectacle/placement/overtakes. 20 racers in one heat признаны плохим fit по читаемости; проект сознательно ограничивает heat.

## 7. Team fit
Главная новая технологическая задача — динамическая физическая shape + networked fair physics. Всё остальное (UI, race state, DataStore, cosmetics) стандартнее. Поэтому cheapest implementation path начинается с M0 Physics Lab.

## 8. Самый дешёвый acceptance path
Сначала принимаем реализацию фундаментальной причинности: shape physics даёт контролируемые различия, а obstacle grammar не допускает universal-shape dominance.
Проверка: cube + draw + legs + 5 obstacles, без магазина/8-player service. Если не проходит — исправляем физику/контент до DoD, а не переизобретаем продукт.

# L3 GAME LOOPS — заполненная фиксация
## Core
read → draw → move → compare → redraw → finish.

## Session
join → несколько быстрых heats → meaningful unlock/equip → ещё heat → exit with next goal.

## Meta
mastery unlocks harder course pools/status; cosmetics attach to expression after races. Meta не даёт power.

## Persist
owned cosmetics, mastery/course access, status, wins/podiums, settings/season state.

## Long path
освоить permanent course tiers + visible mastery/collections; seasons extend path.

## Depth map
5m: basic shapes. 20m: combinations. Day2: moving/clearance/gap families. Week: compound sequences. Month: rotations/mastery challenges using same verbs.

# L4 MONETIZATION SHEET — заполненная фиксация
## Кто
Игрок, который уже закончил несколько heats и пользовался Garage/cosmetics.

## Чего хочет
Быть визуально заметнее/собрать стиль/показать статус.

## Как понял ценность
Видит собственный racer и cosmetics rivals в lineup/race/podium; уже экипировал бесплатный item.

## Потребность
Хочет конкретный locked style/complete collection. Бесплатный опыт не ухудшается искусственно.

## Trigger
Contextual preview/garage interaction после подтверждения ценности, не первые секунды.

## Изменение
До: стандартный/имеющийся стиль. После: немедленно новый визуальный identity в racer + next lineup/podium.

## Primitive
Pass для permanent cosmetic/convenience; Developer Product для cosmetic currency/repeat packs; rewarded video only after eligibility and in natural breaks; subscription post-PMF.

## Price
Единственный numeric source: `16_BALANCE_TUNING.md`; проверяется experiment.

## Fair play
Платёж не меняет physics/win probability at equal skill.

## Post-purchase
Immediate preview/equip + VFX/audio + display next race.

## Repeat
Новые честные collections/themes/status desires.

## Measurement
offer funnel, purchase grant/equip, repeat rate + retention/fairness guardrails.

# L5 LIVEOPS SHEET — заполненная фиксация
## Success direction
Healthy live game = core funnel не течёт, players rematch/return, track content можно производить конфигами, cosmetics имеют organic use, updates измеряются.

## Signal order
1. Наблюдение/сообщество.
2. Статистика масштаба.
3. Рынок/конкуренты.
4. Экспертная интерпретация.

## Primary pre-launch funnel focus
First 60–180 seconds: draw→physics, первый redraw, finish, rematch. Это заранее выбранный измеряемый участок, не незакрытый дизайн-вопрос.

## Analytics map
Core, FTUE, race finish/stuck/redraw, economy, monetization. Events and decisions in `10_ANALYTICS_TEST_PLAN.md`.

## Expandable surfaces
TrackDefinitions, TrackPieces parameters, cosmetic definitions, mastery milestones, course rotations, event rewards/themes.

## Event constructor
Defined in `09_LIVEOPS.md`.

## Suitable formats
Seasonal course tournaments, themed collection/course rotations, community completion/time goals.

## Calendar
Six-month direction in `09_LIVEOPS.md`; exact shipping remains data-driven.

# FINAL COURSE SYSTEM SPINE
Аудитория
→ хочет мгновенную физическую причинность + соревнование + самовыражение
→ обещание: нарисуй wheels/legs и обгони rivals
→ core: read→draw→move→compare→redraw→finish
→ meta: mastery/course access + cosmetics/status
→ persist: collection/mastery/status
→ monetization: cosmetic state change after value understood
→ release: analytics pre-wired
→ signals: FTUE/core/economy/community
→ hypothesis
→ config-first update
→ measurement contract
→ keep/iterate/rollback.

## Remaining empirical variables — NOT design questions
Все WHAT/WHY решения закрыты. В Play Mode/soft launch остаются только измеряемые параметры исполнения:
1. точные motor/friction/stabilization constants;
2. max safe collider complexity on target mobile;
3. camera framing/FOV/look-ahead for 8 racers;
4. redraw cadence/race/intermission timing;
5. cosmetic catalog/offer conversion and collection pacing;
6. Server Authority performance of our exact assembly;
7. discovery creative PTR;
8. retention/revenue baselines.

Эти данные настраиваются в пределах owner specs/configs. Они не дают AI права менять core, multiplayer identity, fair-play contract, meta pillars или monetization strategy без Decision Log.
