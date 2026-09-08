# 10 — ANALYTICS, ACCEPTANCE & TEST PLAN — v1.3.4

## Principle
Log only events that support decisions. Analytics begins before launch.

## Main product funnel
`impression/PTR → join → track ready → first draw → first movement → first redraw → first obstacle success → first finish → results → second race started → 3rd race started → session milestone → D1 return → cosmetic interaction → payer funnel`.

## FTUE events
The canonical event names and fields live **only** in `46_ANALYTICS_EVENT_DICTIONARY.md`. This file owns the questions/funnel logic. FTUE concept sequence: race started → first accepted stroke → first movement → first redraw → key obstacle cleared → finish → next heat. Analyze delta times and device/experiment/player segments within current platform limits.

## Core events
Parameterize rather than create one event per obstacle. Exact names/fields are `46`; required concepts are accepted stroke, rejected stroke, stuck, checkpoint, finish, respawn, results/rematch and bot-filled heat. Useful dimensions must remain bounded and comply with current platform field limits.

## Product health measurements
### M1 — Shape differentiation
Look at redraw distribution + mixed track completion. Red flag: large share succeeds with initial universal shape.

### M2 — Redraw quality
Look at redraw frequency, stuck sequence, quit timing, device deltas, playtest feedback.

### M3 — Multiplayer contribution
Compare solo/bot/2-player/8-player cohorts or controlled playtests on rematch, session depth and qualitative behavior. Presence alone is not proof.

### M4 — Fast repeat
Key behavioral metrics:
- finish→next-race conversion;
- races per session;
- time to second race;
- session length distribution;
- early quit after loss vs win.

### M5 — Visible status/cosmetic interaction
- garage open after seeing other styles;
- cosmetic preview/equip;
- ownership change in first session;
- cosmetic exposure→interaction.

## Implementation acceptance gates
Exact human sample/pass/rework rules are `55_EMPIRICAL_PRODUCT_GATE_PROTOCOL.md`; exact performance thresholds are `57`. The summaries below explain **why** each gate exists.

### Physics Lab gate
Most observed testers can intentionally create at least 3 distinct useful locomotion behaviors without developer intervention.

### Core Adaptation gate
Mixed track causes voluntary meaningful redraw; one-shape dominance is not observed as normal solution.

### 2-player Rival gate
Real rival is readable; pressure/learning/comedy cues are visible without damaging control of the local racer; networking/placement/rematch remain correct.

### 8-player Product gate
Readability + mobile FPS + networking + finish correctness remain acceptable, and social spectacle increases rather than destroys clarity.

### Session gate
Results/CTA allow multiple immediate rematches without forced meta screens. Exact behavioral baseline is measured in soft launch and used for tuning, not for reopening the core design by default.

### Monetization gate
Before price optimization, cosmetic presentation is fully usable/visible and the free ownership/equip loop is complete. Conversion and willingness-to-pay are measured outcomes, not missing design decisions.

## Economy events
Sources: heat completion, placement, milestones/events.  
Sinks: cosmetic Coins purchases.  
Monitor wallet distribution, source/sink balance, time-to-first ownership.

## Monetization funnel
Canonical exact event names are owned by `46`. Conceptually measure: eligibility → offer exposure → prompt → authoritative grant → equip/use → next race with purchased value.

## Experiments priority
1. Camera framing/readability.
2. FTUE hint timing.
3. DrawCanvas mobile size.
4. Race duration/obstacle density.
5. Results duration/Next Race prominence.
6. Cosmetic presentation visibility.
7. First offer timing/price only after core/session gate.

## Guardrails
Any engagement/revenue experiment must not worsen:
- race completion;
- perceived fairness;
- input latency;
- mobile FPS/errors;
- FTUE completion;
- free-player progression;
- rematch behavior.

## Retention targets
No universal D1/D7 number is invented as a source fact. `55` G4 fixes the sample/decision procedure: soft launch establishes our baseline and uses current Creator Analytics benchmark/peer context when available; later tuning/LiveOps targets are explicit experiment hypotheses. Commercial performance is measured, never guaranteed by documentation.
