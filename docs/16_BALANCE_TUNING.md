# 16 — GLOBAL PHYSICS / RACE / CAMERA DEFAULTS v1.6.0 CORE V3

> Values here are **project starting defaults / tuning hypotheses**, not hidden values from Draw Climber. The implementer starts with the exact `Default` value and may sweep only inside the stated range during acceptance. Domain-specific numeric content lives in `59` UI, `60` TrackPieces, `61` economy/progression and `57` performance.

Current mechanical authority is `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`. Legacy R17/CR2/CR3 tuning passages are superseded where they conflict. Human Core V3 physics remains pending.

## 1. Racer / collision defaults
| Parameter | Default | Initial sweep / hard note |
|---|---:|---|
| Body collider size | 3×3×3 studs | current body baseline; change only after proven contact/mass evidence |
| Lane center spacing | 12 studs | 10–14 |
| Max leg extent from hub | 4.5 studs | 4.0–4.8; never player-paid |
| Min useful leg extent | 0.7 studs | 0.6–0.9 |
| Physical leg segment thickness | 0.45 studs | .38–.55 |
| Physics point target after resample | 12 | 9–15 |
| Max collider segments per leg | 14 | hard cap launch |
| Visual segments per leg | 24 | 20–30 presentation only |
| Left/right local phase difference | **180° opposed** | fixed Core V3 structural relation |
| Shared axle local X/Y | `0, 0` | fixed at BodyCollider center; not a tuning value |
| Side mount Z | `body.Size.Z/2 + 0.45` | Core V3 `SideOutset`; left negative, right positive |
| Inner hub no-collision radius | 0.65 studs | .55–.80 |

Starting Core V3 physical properties:
- Body: density `0.25`, friction `0.0`, elasticity `0.04`.
- Leg physical segments: density `0.60`, friction `1.0`, elasticity `0.02`, but geometry Parts are massless so the dedicated AxleRoot carries stable driven inertia.
- AxleRoot: cubic size `1.50`, density `0.50`, friction `0.0`, elasticity `0.0`.
- Physical leg thickness `0.54`; visual thickness `0.78`; max 14 segments.
- Cosmetics never alter physical properties.

Do not tune mass/torque/friction together. Change one proven limiter at a time after Studio evidence.

## 2. Stroke processing defaults
| Parameter | Default | Sweep / cap |
|---|---:|---|
| Raw sample min movement in semantic canvas units | 0.010 | .008–.016 |
| Max raw points submitted | 96 | hard cap |
| Minimum raw points before cleanup | 3 | fixed |
| Dedupe distance | 0.012 | .008–.020 |
| RDP epsilon | 0.022 | .015–.035 |
| Resample target points | 12 | 9–15 |
| Max cleaned points | 15 | hard cap |
| Minimum cleaned polyline length | 0.18 semantic units | .14–.22 |
| Raw semantic half-width | **1.75** | fixed R16.3B input contract |
| Raw semantic half-height | **1.0** | fixed R16.3B input contract |
| Stroke submit cooldown | 0.20 s | .15–.30; abuse/rate protection, not gameplay power |
| Max stroke payload bytes | 4096 | hard validation cap |

Rules: one continuous stroke per submit; invalid/tiny/stale submit leaves the current accepted shape intact; self-intersection remains legal. **Current production origin remains R16.3B/`73`:** normalization is isotropic using half the visible wide DrawInputRect height as one semantic unit, raw points are clamped to X `±1.75` and Y `±1.0`, and after cleanup the authoritative shape is translated so its **first cleaned point** becomes `(0,0)`. This translation never resizes, rotates or mirrors the shape; the bounds midpoint is not required to be the hub.

The first-cleaned-point origin remains current. Any future origin change requires an explicit contract change.

## 3. Motor defaults
`SharedAxle` owns the single Core V3 motor. Angular velocity is extent-aware: target tip speed divided by usable drive radius, clamped to the configured angular range. There is no per-side motor tuning family.

| Parameter | Default | Initial sweep |
|---|---:|---|
| Rotation sign / target | sign `-1`; target tip speed `15` | angular magnitude clamps `1.5..8.0 rad/s` |
| MotorMaxTorque | 35,000 | 20,000–60,000 after actual mass profiling |
| MotorMaxAcceleration | 120 rad/s² | 80–180 |

Acceptance meaning matters more than numeric scale: intended SmallSteps/WallLow must be solvable by suitable legal shapes; WallHigh must not be brute-forced by every compact/round shape.

Motor tuning is allowed only after evidence proves the motor remains the limiter. Any future sweep changes the single `SharedAxle/DriveJoint` owner and must never invent a second actuator.

## 4. Planar lane/body stabilization defaults
Approved Core V3 contract:
- X translation free;
- Y translation free;
- Z locked to lane plane;
- body stabilized upright;
- shared axle rotation remains free.

Preferred next implementation: PlaneConstraint for Z + bounded AlignOrientation/equivalent torque-only upright correction. Numeric responsiveness/torque are **TUNING PENDING** and must be chosen only after live Studio evidence; do not silently reuse obsolete R16 values as proven defaults.

Rules:
- no AlignPosition/VectorForce/LinearVelocity that adds normal +X locomotion;
- no scripted +Y lift except the bounded redraw clearance owner;
- no per-frame CFrame/PivotTo correction;
- the lane/orientation owner must not suppress shared axle rotation.

Core V3 redraw starting hypotheses:
- preview duration = `0.10 s`;
- hop target vertical velocity = `20 studs/s`;
- maximum added hop velocity = `24 studs/s`;
- from rest at default gravity, the hop is about `1.02 studs` high;
- `MaxLift = 4.0 studs` and soft-lift target velocity = `5.0 studs/s` remain unchanged.

The hop values are bounded starting hypotheses. Visual timing/feel remains **HUMAN PHYSICS PENDING**.

## 5. Anti-stall assist
**Core V3 Flat Gate default = DISABLED.**

Do not use AntiStall or another +X helper to make the Flat Gate pass. Any future recovery/assist system is a later feature after natural leg-driven locomotion is proven and must never become the normal movement source.

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
- Core V3 out-of-bounds trigger: `BodyCollider.Position.Y < -12 studs`; rearm only above `-8 studs`.
- Core V3 fall recovery returns the same racer to its saved spawn/lane with zeroed velocities and its accepted pair preserved; this is separate from the later stuck/obstacle policy below.
- Progress sample window: 2.5 s.
- “Meaningful horizontal progress” threshold: +0.35 studs over that window.
- First contextual redraw hint: after 2.5 s below threshold.
- Recovery eligibility: 6.0 s continuous below threshold, unless player is clearly airborne on a moving obstacle; max delay 7.0 s.
- Respawn: last safe checkpoint, body center Y +3.0 studs, canonical upright body orientation, retain accepted shape/shared pair relation.
- Recovery input freeze/penalty: 1.25 s.
- Finish timer continues during recovery.

## 9. Camera starting values
| Parameter | Default | Sweep / rule |
|---|---:|---|
| FOV | 60° | 55–65° |
| Local racer horizontal screen anchor | 0.38 from left | .35–.40 |
| Look-ahead | 11 studs | 8–14 |
| Camera height above lane floor | 10 studs | 8–12 |
| Side/Z distance | 23 studs | 18–28 |
| Position damping time | 0.16 s | .10–.24 |
| Look target damping time | 0.12 s | .08–.20 |
| Vertical dead-zone | **0.50 stud** | .30–.80 |
| Vertical damping time | **0.22 s** | .16–.30 |
| Free-look yaw target | **full 360° / wrapped, no artificial limit** | current camera contract; tune sensitivity/damping, not yaw wall |
| Free-look pitch limit | **±70°** | current `ORBIT_PITCH_LIMIT = 70`; any reduction requires human feel evidence |
| Orbit input damping time | **0.08 s** | current production smoothing |
| Free-look return time | **0.40 s** | .30–.55 |
| Max gameplay camera shake | 0.12 stud / 0.6° | Reduce Motion = 0 |

Camera behavior is governed by the current camera/rider presentation contract (`08`, `21`, `59`, `DECISION_LOG_CAMERA_RIDER_PRESENTATION_2026-09-10.md`):
- production `RaceCameraController`/`CameraMath` are active M0 owners; D09 later extends this same owner to the 2-player/rival readability case rather than introducing a second camera;
- the active-race camera follows a smoothed target derived from the **Local Racer world position**, not from the racer's rotational CFrame; racer roll/pitch/yaw never becomes camera roll/orientation authority;
- smoothing must be frame-rate independent; X can converge with the normal position damping while Y uses the vertical dead-zone and vertical damping above so small solver bounce does not shake the view and meaningful climbs/falls remain visible;
- desktop free-look is **hold RMB**; yaw target supports **full 360°** rotation and rendered yaw/pitch remain smoothed; pitch is clamped to ±70°;
- current camera contract requires reliable mouse capture/restoration and allows eligible RMB camera ownership even when CoreScripts set `gameProcessed`, while focused text/project UI/DrawCanvas still block the camera;
- release automatically returns to canonical side framing using `Free-look return time`; LMB remains drawing input and is not a camera toggle;
- touch free-look may start only from world space outside DrawCanvas and active UI; a touch that starts in DrawInputRect remains drawing-owned until end/cancel;
- ordinary racer physics does not create implicit camera shake. `Max gameplay camera shake` applies only to deliberate presentation effects and becomes zero under Reduce Motion;
- other racers may be visible but do not become the active-race target automatically. Spectator target policy remains owned by `74`.

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

The existence of a sweep range does not leave implementation undefined: **always start from Default**. Core V3 tuning must follow the ordered isolation rules above and may not mix origin, mass/friction/collider and motor changes in one evidence step.
