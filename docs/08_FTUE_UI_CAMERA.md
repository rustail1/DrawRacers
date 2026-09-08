# 08 — FTUE, UX, UI & CAMERA — v1.3.4

## FTUE objective
Первые 60 секунд доказывают настоящую игру: **я рисую physical shape → она двигает cube → obstacle показывает ограничение → redraw меняет результат → я соревнуюсь и хочу ещё race**.

## First 60 seconds choreography
### 0–8s
A normal first join lands in **EntryFTUEPlace** (`23/41`). After safe profile load with `Tutorial.Completed=false`, player stays there and enters **T06_STEPS_TO_SPEED** (`60`) immediately; remaining slots fill after the dedicated 2s FTUE assembly window. There is no wait for an unrelated public heat to finish. Player sees cube, track, DrawCanvas. Prompt uses canonical `59` copy `DRAW YOUR WHEELS`.

### 8–20s
First valid stroke applies. Racer начинает физически двигаться. Strong immediate feedback.

### 20–35s
Obstacle делает initial shape заметно менее эффективной. Если redraw не происходит — timed non-modal canvas hint.

### 35–50s
Redraw создаёт видимый recovery/overcome/overtake moment.

### 50–60s+
First authoritative T06 finish → server atomically commits the exact FTUE finish reward set from `61`, sets Tutorial.Completed, grants/auto-equips `Ink_Sky_01` once (`31/61`) → Results shows only the confirmed reward/next goal → player is routed to RacePlace and the next public heat uses the normal EARLY pool. **FTUE DNF grants 0 persistent Coins, 0 MP and no first-completion/first-clear bonus; it simply repeats T06 in EntryFTUEPlace.**

Секунды = tuning hypothesis, не source fact.

## Drawing input
- Mobile-first lower-screen canvas.
- One stroke; release = apply.
- No Apply/Rotate/Delete buttons in normal flow.
- Old functional shape remains active while new one is being drawn.
- New stroke preview immediate and local.
- Server validation cannot make normal drawing feel like long confirmation.

## HUD
Active race contains only necessary information:
- placement `3/8`;
- progress strip/finish direction;
- DrawCanvas;
- minimal contextual hint;
- no visible race timer at launch; hard timeout remains internal/server-side. Moving obstacle timing is read from world motion, not a HUD countdown.

No permanent shop/daily popups over race view.

## Camera product requirement
`Scriptable` side/3/4 follow + look-ahead.

Must simultaneously support:
1. local racer readability;
2. 1–2 upcoming decisions;
3. perception of nearby rivals;
4. visible overtakes without camera chaos.

Exact FOV/offset: `16_BALANCE_TUNING.md`.

## Rival readability
Do not force all 8 full-size bodies to overlap in view. Nearby racers can be physically visible; distant racers may use progress strip/markers/simplified visuals.

## Fast rematch UX
After finish:
- placement/reward celebration concise;
- Next Race button immediately obvious;
- FTUE completion grants `Ink_Sky_01`; it is auto-equipped once after the authoritative grant so the player sees an immediate ownership change. Garage remains optional and never blocks requeue;
- no forced trip through garage/shop.

## Accessibility basics
- not color-only feedback;
- high-contrast draw line;
- UI safe areas/mobile scale;
- reduce intense shake option;
- capped cosmetic VFX during active race;
- localization-friendly short copy.

## UX acceptance questions
- First-time player moves within ~20 sec?
- Redraw understandable without paragraph tutorial?
- Hand/finger does not hide critical upcoming obstacle?
- Player knows who is ahead?
- Other racers add interest, not noise?
- Results create “one more race” instead of menu fatigue?


## Exact UI/layout owner
All launch placements, sizes, safe areas, responsive modes and canonical source copy are `59_UI_LAYOUT_WIREFRAME_SPEC.md`.


## Place-transition UX
- New player does not see a lobby between join and T06.
- Returning player may briefly see canonical loading state in EntryFTUEPlace, then `CONNECTING TO RACES…` during server routing to RacePlace.
- Teleport status is non-modal only while safe; no purchase/shop can appear during routing.
- The FTUE 60-second choreography clock begins when the player is in drawable T06 state; separate join→drawable performance is enforced by `57`.
