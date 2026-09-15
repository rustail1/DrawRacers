# Core V3 Flat Physics Current Plan

Status: **CURRENT EXECUTION PLAN — LOCAL FILE WORKFLOW**

## Goal
Close the Core V3 Flat Gate before returning to obstacle work.

## Task 1 — 2.5D lane constraint
- add/activate one dedicated Core V3 lane-plane owner;
- lock only Z translation;
- preserve X/Y physical freedom;
- no +X helper.

Acceptance: racer cannot drift off the lane plane during ROUND contact.

## Task 2 — upright body stabilization
- add bounded orientation-only stabilization;
- do not constrain shared axle rotation;
- do not provide forward/vertical translation.

Acceptance: cube does not fall sideways or tumble uncontrollably while legs remain physically authoritative.

## Task 3 — automated regression
Run `COREV3_TEST` and require C01–C07.

Do not weaken C07 to get GREEN. If real physics cannot be proven automatically, preserve the deterministic invariants and leave the human gate pending.

## Task 4 — human ROUND gate
Mode `COREV3`:
1. start from rest;
2. draw one ROUND;
3. wait at least 5 seconds;
4. confirm lane lock/upright behavior;
5. confirm leg contact + relative axle/body rotation;
6. confirm +X motion without horizontal helper.

## Task 5 — shape suite + moving redraw
Only after ROUND passes:
- SMALL_ROUND;
- LONG;
- HOOK;
- ASYMMETRIC;
- 20 redraws while moving.

## Stop rule
If three sequential physical fixes in the same subsystem fail, stop changing coefficients and revisit the architecture/root cause.

## Explicitly out of scope until Flat PASS
- walls/steps/gaps/tunnels;
- AntiStall;
- obstacle recovery;
- multiplayer/meta/economy/shop;
- legacy CR2/CR3/R17 leg runtime;
- Git/GitHub workflow.
