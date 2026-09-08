# 16 — GLOBAL PHYSICS / RACE / CAMERA DEFAULTS v1.3.4

> Values here are **project starting defaults / tuning hypotheses**, not hidden values from Draw Climber. The implementer starts with the exact `Default` value and may sweep only inside the stated range during acceptance. Domain-specific numeric content lives in `59` UI, `60` TrackPieces, `61` economy/progression and `57` performance.

## 1. Racer / collision defaults
| Parameter | Default | Initial sweep / hard note |
|---|---:|---|
| Body collider size | 3×3×3 studs | fixed product baseline |
| Lane center spacing | 12 studs | 10–14 |
| Max leg extent from hub | 4.5 studs | 4.0–4.8; never player-paid |
| Min useful leg extent | 0.7 studs | 0.6–0.9 |
| Physical leg segment thickness | 0.45 studs | .38–.55 |
| Physics point target after resample | 12 | 9–15 |
| Max collider segments per leg | 14 | hard cap launch |
| Visual segments per leg | 24 | 20–30 presentation only |
| Left/right phase offset | 180° | 160–200° |
| Inner hub no-collision radius | 0.65 studs | .55–.80 |

Starting physical properties:
- Body density `1.0`, friction `0.45`, elasticity `0.05`.
- Leg collision segment friction `1.0`, elasticity `0.02`; visual-only stroke has no collision.
- Hub is non-collidable. Inner leg segments inside hub exclusion are non-collidable.
- Do not alter body/leg physical properties by cosmetic ID.

## 2. Stroke processing defaults
| Parameter | Default | Sweep / cap |
|---|---:|---|
| Raw sample min movement in normalized canvas | 0.010 | .008–.016 |
| Max raw points submitted | 96 | hard cap |
| Minimum raw points before cleanup | 3 | fixed |
| Dedupe distance | 0.012 | .008–.020 |
| RDP epsilon | 0.022 | .015–.035 |
| Resample target points | 12 | 9–15 |
| Max cleaned points | 15 | hard cap |
| Minimum cleaned polyline length | 0.18 normalized units | .14–.22 |
| Normalized coordinate bounds | [-1,1] each axis | fixed |
| Stroke submit cooldown | 0.20 s | .15–.30; abuse/rate protection, not gameplay power |
| Max stroke payload bytes | 4096 | hard validation cap |

Rules: one continuous stroke per submit; invalid/tiny/stale submit leaves the current accepted shape intact; self-intersection remains legal.

## 3. Motor defaults
Use one motorized hinge per leg as `11` describes.

| Parameter | Default | Initial sweep |
|---|---:|---|
| AngularVelocity | **-8.0 rad/s** | magnitude 7.0–9.0; axis/sign semantics fixed by `73` |
| MotorMaxTorque | 35,000 | 20,000–60,000 after actual mass profiling |
| MotorMaxAcceleration | 120 rad/s² | 80–180 |

Acceptance meaning matters more than numeric scale: intended SmallSteps/WallLow must be solvable by suitable legal shapes; WallHigh must not be brute-forced by every compact/round shape.

## 4. Lane and body stabilization defaults
Observable contract: X forward, Y physical vertical, Z stays near lane center, body may bounce/tilt but not drift or spin forever.

Start targets for whichever constraint/force implementation `21` chooses:
- lane center target Z error `0`;
- soft correction begins at `|Z error| > 0.15 stud`;
- normal allowed error <=`0.35 stud`; hard safety bound `0.75 stud` before server recovery/debug flag;
- orientation target keeps racer forward axis +X and up axis near +Y;
- orientation correction responsiveness start `8`; sweep `5–12` if using Roblox responsiveness-style constraint;
- stabilizer must allow at least ±25° transient pitch/roll without instantly snapping flat;
- no stabilizer may add intentional +X race speed.

## 5. Anti-stall assist
Default = **enabled only on flat/recovery surfaces**, never on obstacle pieces that test geometry.
- activation: grounded/contacting flat tag AND forward speed <0.35 studs/s for 0.60s after valid shape exists;
- assist target: max +X acceleration equivalent `2.0 studs/s²` for at most 0.75s;
- immediately disable on obstacle RequirementTag, airborne state, or forward speed >=1.0 studs/s;
- assist cannot cross gap/wall/checkpoint by itself and is included in G0 diagnostics.

## 6. Race defaults
| Parameter | Default | Notes |
|---|---:|---|
| TargetHeatSlots | 8 | fixed product target |
| 2-player integration stage | 2 | not final mode identity |
| Target standard race duration | 30–45 s | T01–T05 FTUE may be shorter |
| Expected meaningful redraws | 2–4 | T20 allows 3–5 initial sweep |
| Strong redraw need interval | 10 s nominal | acceptable 8–15 s |
| PREP/countdown | 3.0 s | DrawCanvas available during prep |
| FINISHING presentation | 2.0 s | then Results |
| Results CTA input guard | 0.75 s | button visible immediately, disabled during guard |
| Results minimum display before server-ready | 3.5 s | exact semantics `74`; click may set intent after 0.75s |
| FinishGraceWindow | 15.0 s | sweep 12–20; capped by hard timeout |
| Default hard heat timeout | 90 s | outer cap; per-track override only by Decision Log/gate |
| KillPlane vertical margin | 12.0 studs | below minimum resolved gameplay collision Y, semantics `74` |
| HeatAssemblyTimeout | 8.0 s | public RacePlace, from first ready human |
| FTUEAssemblyTimeout | 2.0 s | EntryFTUEPlace; minimize first-action wait |
| MinimumHumanCountBeforeHeat | 1 | PROD cold-start |
| BotsEnabledProduction | true | required pre-public launch |

## 7. Bot defaults
| Parameter | Default | Sweep |
|---|---:|---|
| BotReactionDelay | 0.70 s | .45–1.1 |
| BotMistakeRate | 0.12 | .05–.22 |
| BotPaceScale | 1.00 | .90–1.05 |

No dynamic rubber-band after heat start. Table is the MEDIUM baseline; exact EASY/MEDIUM/HARD profiles, profile assignment and shape policy are `75`. Bots use same legal shape bounds/physics and never persistent rewards/leaderboards/purchases.

## 8. Stuck / recovery
- Progress sample window: 2.5 s.
- “Meaningful horizontal progress” threshold: +0.35 studs over that window.
- First contextual redraw hint: after 2.5 s below threshold.
- Recovery eligibility: 6.0 s continuous below threshold, unless player is clearly airborne on a moving obstacle; max delay 7.0 s.
- Respawn: last safe checkpoint, body center Y +3.0 studs, zero roll/pitch, retain accepted shape.
- Recovery input freeze/penalty: 1.25 s.
- Finish timer continues during recovery.

## 9. Camera starting values
| Parameter | Default | Sweep |
|---|---:|---|
| FOV | 60° | 55–65° |
| Local racer horizontal screen anchor | 0.38 from left | .35–.40 |
| Look-ahead | 11 studs | 8–14 |
| Camera height above lane floor | 10 studs | 8–12 |
| Side/Z distance | 23 studs | 18–28 |
| Position damping time | 0.16 s | .10–.24 |
| Look target damping time | 0.12 s | .08–.20 |
| Max gameplay camera shake | 0.12 stud / 0.6° | Reduce Motion = 0 |

Exact HUD/DrawCanvas composition is `59`, and camera must frame the next obstacle above the DrawCanvas exclusion zone on every device in `57`.

## 10. Session targets
- No mandatory meta interruption between heats.
- Engaged first-session hypothesis: voluntary chain capable of ~10–15 minutes.
- No artificial waiting/ad wall to hit time target.
- Results/garage can be exited to requeue with one primary action.

## 11. Economy / monetization numeric ownership
Do **not** invent Coin rewards/prices from the old range notes. Exact initial launch economy is `61_LAUNCH_ECONOMY_PROGRESSION_TABLE.md`; exact launch item identities are `62`. Price optimization remains empirical after G5.

## 12. Tuning protocol
Every changed constant records:
- owner key/file;
- old/new value;
- build/track/device/network context;
- test sample/gate;
- observed improvement and guardrail regression;
- ACCEPT / REVERT / CONTINUE SWEEP;
- Decision Log if the change alters product meaning rather than only a numeric value.

The existence of a sweep range does not leave implementation undefined: **always start from Default**.
