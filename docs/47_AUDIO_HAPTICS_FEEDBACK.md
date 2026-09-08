# 47 — AUDIO, HAPTICS & FEEDBACK
Статус: **JUICE CONTRACT v1.3.4**.

Gameplay emits semantic presentation events. `AudioController` resolves asset/pool; gameplay code never hardcodes SoundIds. Audio assets themselves must be original/licensed, produced/accepted through `69`, and bound only through semantic AssetIds in `70`.

## 1. Exact launch semantic keys
| Key | Direction | Length / repetition |
|---|---|---|
| `SFX_UI_Navigate` | soft dry click/tick | <120 ms |
| `SFX_UI_PrimaryCTA` | brighter two-note click | <180 ms |
| `SFX_Draw_Loop` | quiet pencil/marker texture following local stroke | loop while drawing; max -18 dB under core impacts |
| `SFX_Draw_Accept` | short elastic snap + ink pop | 180–260 ms |
| `SFX_Draw_Reject` | muted paper/buzzer tick, non-punitive | 160–240 ms |
| `SFX_Leg_Contact_Soft` | rubber/plastic tap pool, 4 variants | per-contact cooldown 90 ms |
| `SFX_Leg_Impact_Hard` | chunky low-mid thump pool, 3 variants | cooldown 180 ms |
| `SFX_Checkpoint` | subtle upward ping | <=300 ms |
| `SFX_Placement_Up` | very short positive rise | <=250 ms; no spam more than once/0.7s |
| `SFX_Stuck_Hint` | soft attention knock | <=350 ms, once per stuck episode |
| `SFX_Countdown` | three same ticks + brighter GO | one per beat |
| `SFX_Finish_Local` | placement sting | 0.7–1.1s |
| `SFX_Coins` | 2–4 light coin ticks | <=500 ms total |
| `SFX_Cosmetic_Equip` | cloth/plastic sparkle snap | <=350 ms |
| `SFX_Purchase_Celebrate` | short premium reveal sting | 0.8–1.2s |
| `SFX_Podium` | compact victory flourish | <=1.5s |

Music: exactly two launch loops, one per theme (`MUS_ToyWorkshop`, `MUS_NeonFactory`), 90–140 BPM upbeat playful electronic/percussive; seamless loop 60–120s. Results/podium may layer a sting but must not restart the full loop every heat.

## 2. Mix priority
`local core action > local state feedback > UI > rivals > music > ambient`.
- Local contact/shape feedback is 4–6 dB louder than equivalent rival cue.
- Rival repetitive leg impacts are distance/LOD culled; never mix all 8 racers at full level.
- Podium/purchase FX cannot mask next-race countdown.
- No sustained high-frequency hiss in draw loop; mobile speaker legibility matters.

## 3. Haptic launch pattern
Haptics are presentation-only and fail silently on unsupported devices.
- Draw accept: one light pulse ~35 ms.
- Draw reject: one light pulse ~20 ms, no harsh repeated vibration.
- Hard impact: medium pulse ~45 ms, cooldown >=250 ms.
- Finish local: medium pulse ~70 ms.
- Purchase celebration: light-medium-light pattern over <=300 ms.
- Reduce Motion also disables nonessential haptics; if a separate Haptics toggle is added, default On where platform permits.

## 4. Feedback rules
- Audio reinforces state; it never substitutes for required visual info.
- SFX/music settings apply immediately.
- Repeated physics contacts use variant pools/randomized pitch only inside a narrow ±3% range to avoid machine-gun repetition.
- No audio cue claims reward/purchase success before server/platform confirmation.
- GuestSafe disables purchase celebration because no purchase may complete in that state.

## 5. Acceptance
On `57` reference devices, 8-racer heat must remain intelligible: local draw/finish/countdown cues are distinguishable, no clipping/distortion from rival pile-up, and disabling Music/SFX takes effect within one interaction frame/update.
