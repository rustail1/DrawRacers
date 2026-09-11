# 16 — GLOBAL PHYSICS / RACE / CAMERA DEFAULTS v1.4.1 R17

> Values here are **project starting defaults / tuning hypotheses**, not hidden values from Draw Climber. The implementer starts with the exact `Default` value and may sweep only inside the stated range during acceptance. Domain-specific numeric content lives in `59` UI, `60` TrackPieces, `61` economy/progression and `57` performance.

R17 sequence/authority override: `DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md` plus `DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md`. Human-video evidence on 2026-09-12 further corrects the side relation to **co-phase 0°** while preserving the one shared axle/one motor architecture. Human Studio gates remain pending.

## 1. Racer / collision defaults
| Parameter | Default | Initial sweep / hard note |
|---|---:|---|
| Body collider size | 3×3×3 studs | current production baseline; R17.6 may compare 3.0 / 2.8 / 2.6 only after density+friction evidence |
| Lane center spacing | 12 studs | 10–14 |
| Max leg extent from hub | 4.5 studs | 4.0–4.8; never player-paid |
| Min useful leg extent | 0.7 studs | 0.6–0.9 |
| Physical leg segment thickness | 0.45 studs | .38–.55 |
| Physics point target after resample | 12 | 9–15 |
| Max collider segments per leg | 14 | hard cap launch |
| Visual segments per leg | 24 | 20–30 presentation only |
| Left/right local phase difference | **0° (co-phase)** | fixed current R17 reference relation; live-solver acceptance is R17.5 |
| Side socket Z magnitude | 1.5 studs | `LegSocketZAbs`; structural shared-axle mount |
| Inner hub no-collision radius | 0.65 studs | .55–.80 |

Starting physical properties:
- Body density `1.0`, friction `0.45`, elasticity `0.05`.
- Leg collision segment friction `1.0`, elasticity `0.02`; visual-only stroke has no collision.
- Shared `AxleRoot` and side `LegRoot` roots are non-collidable. Inner leg segments inside hub exclusion are non-collidable.
- Do not alter body/leg physical properties by cosmetic ID.
- **R17.6 isolation rule:** first compare body density `1.00 / 0.60 / 0.40`; then compare body friction `0.45 / 0.25 / 0.10` using the selected density; compare body collider `3.0 / 2.8 / 2.6` only if measured belly contact remains the proven limiter. Do not change these families simultaneously.

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

R17.3 is authorized to compare first-point, bounds-center and deterministic geometry/reference-center origins in a Studio-only evidence experiment. That experiment does **not** change production origin. Only an explicit R17.4 decision after human evidence may supersede the current first-point rule.

## 3. Motor defaults
`LegPairAssembly` owns **one shared axle and one motor** for both rigid side assemblies. There is no per-side motor tuning family and no phase-chasing correction loop. Both depth-separated side copies are **co-phase**: `RightPhaseOffsetDegrees = 0` relative to Left.

| Parameter | Default | Initial sweep |
|---|---:|---|
| AngularVelocity | **-8.0 rad/s** | magnitude 7.0–9.0; shared +Z axis/sign semantics fixed by `73` |
| MotorMaxTorque | 35,000 | 20,000–60,000 after actual mass profiling |
| MotorMaxAcceleration | 120 rad/s² | 80–180 |

Acceptance meaning matters more than numeric scale: intended SmallSteps/WallLow must be solvable by suitable legal shapes; WallHigh must not be brute-forced by every compact/round shape.

**R17.6 guard:** motor values remain `-8 / 35000 / 120` during the body density/friction/collider isolation sweeps. Motor tuning is allowed only after mass/contact evidence proves it is still the limiting variable. Any future motor sweep changes the single `AxleJoint` owner; it must never invent a second left/right actuator.

## 4. Planar lane/body stabilization defaults
Observable contract: racer locomotion is 2.5D. X/Y are the physical gameplay plane; Z translation is locked to the racer's lane center. Under the **R16.1 upright-body contract**, rotation about world X/Y/Z is locked/corrected while X/Y translation remains physically free.

Canonical R16.1 starting defaults:
- `LaneNormalError = 0.03`
- `LaneHardBound = 0.08`
- `OrientationResponsiveness = 40`
- `OrientationMaxTorque = 60000`
- `OrientationMaxAngularVelocity = 30`

Rules:
- `RacerStabilizer` uses a mechanical `PlaneConstraint` between the racer body attachment and an anchored, invisible, non-collidable lane-plane reference at the canonical lane-center Z.
- The plane constraint owns only the forbidden out-of-plane Z translation. X/Y translation remains physical gameplay and receives no stabilizer propulsion.
- `LaneNormalError = 0.03` and `LaneHardBound = 0.08` are diagnostic tolerances, not permitted lateral gameplay freedom; any unexplained excursion above `0.08` is failed Studio evidence.
- Upright orientation correction uses `AlignOrientation` with `AlignType.AllAxes` and an identity attachment basis so all body axes recover to canonical upright orientation.
- Normal body angular deviation target is `<=1.0°`; a strong-contact disturbance may transiently reach `<=3.0°` and must recover to `<=1.0°` within `0.25 s`.
- Orientation correction may apply corrective torque only; it must not add intentional +X propulsion or scripted +Y lift.
- No invisible side walls, no normal-operation per-Heartbeat CFrame/PivotTo projection, and no stabilizer may add intentional +X race speed.
- R16.1 supersedes the R15 free-world-Z rotation contract. R15 remains historical evidence for the mechanical plane lock only, not current body-rotation semantics.
- Finite-force `AlignPosition` lane correction and its force/responsiveness/velocity tuning are not part of the planar contract.

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
| Free-look yaw target | **full 360° / wrapped, no artificial limit** | R17.9 fixed behavior; tune sensitivity/damping, not yaw wall |
| Free-look pitch limit | **±70°** | current `ORBIT_PITCH_LIMIT = 70`; any reduction requires human feel evidence |
| Orbit input damping time | **0.08 s** | current production smoothing |
| Free-look return time | **0.40 s** | .30–.55 |
| Max gameplay camera shake | 0.12 stud / 0.6° | Reduce Motion = 0 |

Camera behavior is governed by `DECISION_LOG_R17_REFERENCE_CORE_OVERRIDE_2026-09-11.md`, `DECISION_LOG_R17_SHARED_AXLE_CAMERA_FIDELITY_2026-09-11.md` and the original camera/rider presentation contract:
- production `RaceCameraController`/`CameraMath` are active M0 owners under R17; D09 later extends this same owner to the 2-player/rival readability case rather than introducing a second camera;
- the active-race camera follows a smoothed target derived from the **Local Racer world position**, not from the racer's rotational CFrame; racer roll/pitch/yaw never becomes camera roll/orientation authority;
- smoothing must be frame-rate independent; X can converge with the normal position damping while Y uses the vertical dead-zone and vertical damping above so small solver bounce does not shake the view and meaningful climbs/falls remain visible;
- desktop free-look is **hold RMB**; yaw target supports **full 360°** rotation and rendered yaw/pitch remain smoothed; pitch is clamped to ±70°;
- R17.1 requires reliable mouse capture/restoration and allows eligible RMB camera ownership even when CoreScripts set `gameProcessed`, while focused text/project UI/DrawCanvas still block the camera;
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

The existence of a sweep range does not leave implementation undefined: **always start from Default**. R17 tuning must follow the ordered isolation rules above and may not mix origin, mass/friction/collider and motor changes in one evidence step.
