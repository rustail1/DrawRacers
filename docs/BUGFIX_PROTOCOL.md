# BUGFIX PROTOCOL — ROBLOX / ROJO / LOCAL FILE WORKFLOW

Status: **CURRENT MANDATORY BUGFIX CONTRACT — 2026-09-15**

Current execution profile: exact local folder/archive -> bounded edit in separate copy/overlay -> automated/static checks -> Rojo/Studio -> human evidence. Git/GitHub is disabled unless explicitly re-enabled.

## 1. Default mode
A new bugfix starts **INVESTIGATE / PLAN ONLY** unless the user explicitly orders execution of an already-approved plan.

Do not change production code before the root cause is established.

## 2. Required evidence
Record:
- FACT: what happens;
- EXPECTED: what should happen;
- REPRODUCTION: exact actions;
- EVIDENCE: Output/video/screenshot/measurement;
- BASELINE: exact local folder/archive used.

For Core V3 mechanical bugs also read `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`, `SESSION.md` and `ARCHITECTURE_MAP.md` first.

## 3. Technical reconnaissance
Read only the smallest likely owner cluster and direct dependencies. Current code + current Source of Truth beat stale navigation/history.

For Core V3 locomotion start with:
- `RacerRuntime.lua`;
- `Runtime/CoreV3/*`;
- `LegShapeService.lua`;
- drawing/result path;
- C01–C07;
- `CoreV3FlatHarness.lua`.

Do not begin from legacy CR2/CR3/R17 leg modules.

## 4. Root cause before fix
Trace the failing chain backward. For multi-component problems collect evidence at each boundary. State one hypothesis and the evidence that supports it.

No speculative fix stacking. One variable at a time.

If three sequential fixes in the same subsystem fail, STOP and revisit the architecture before a fourth attempt.

## 5. Plan contract
Before implementation identify:
- ROOT CAUSE;
- FILES TO CHANGE;
- DO NOT TOUCH;
- RED/test plan;
- Studio acceptance plan;
- rollback/failure behavior.

If implementation requires unapproved scope, stop and amend the plan.

## 6. TDD / verification
When meaningful:
`RED -> confirm expected failure -> minimal GREEN -> targeted regression -> full required verification`.

Do not invent fake static RED tests for Roblox physics/camera/visual feel. For live-engine behavior define an exact manual RED and automate only deterministic invariants.

For Core V3 changes run the relevant C01–C07 contracts. Do not weaken C07 simply to get GREEN.

## 7. Physics rule
Automation cannot prove feel/contact/solver behavior. If Studio has not been run, report:
`AUTOMATED PASS / HUMAN PHYSICS PENDING`.

## 8. Local artifact handoff
Keep the source baseline intact when possible. Produce:
- overlay/replacement files if useful;
- full replacement archive for a clean handoff when requested;
- concise changed-file list;
- exact Studio test instructions.

Never claim that another copy on the user's PC is identical unless it was actually supplied/checked.

## 9. Review
`/review` is read-only. Compare the exact baseline artifact to the exact edited artifact, verify scope/root cause/tests, then list remaining human evidence.

## 10. Current Core V3 hard rule
Until the Flat Gate passes:
- no walls/steps/gaps/tunnels in the validation path;
- no AntiStall/+X helper;
- no obstacle recovery;
- no return to twin-drive/legacy leg architecture.
