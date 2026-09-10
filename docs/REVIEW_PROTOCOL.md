# REVIEW PROTOCOL — READ-ONLY BUGFIX AUDIT

Status: **MANDATORY READ-ONLY REVIEW CONTRACT**  
Trigger: user sends `/review` or explicitly asks to review the just-implemented bugfix.

Purpose: verify that the implemented fix matches the approved plan and removes the established root cause without scope creep or architecture damage.

---

## 1. REVIEW IS READ-ONLY

During `/review`:
- do not modify/create/delete files;
- do not commit/push;
- do not silently repair issues you discover;
- do not widen the original task;
- do not convert missing human evidence into PASS.

Read only the approved plan/bug contract, current Source of Truth owners, the fix diff, tests/CI evidence, and directly affected dependencies.

## 2. REVIEW INPUTS

Recover or request only what is necessary:

```text
BUG/TASK ID: <if one exists>
BASE_SHA: <approved plan base>
FIX_HEAD: <current main head>
APPROVED ROOT CAUSE: ...
APPROVED FILES TO CHANGE: ...
APPROVED DO NOT TOUCH: ...
APPROVED TEST/MANUAL ACCEPTANCE PLAN: ...
```

If the approved plan is in the current conversation or repository, use it. Do not ask the user to restate information already available.

## 3. DIFF SCOPE CHECK

Compare `BASE_SHA -> FIX_HEAD` and report:
- every changed path;
- whether each path was approved;
- any unplanned file/change;
- any generated/binary/noise file;
- whether a public contract changed unexpectedly.

A changed file outside approved scope is a review issue unless it is clearly required evidence/documentation already covered by the approved blast radius.

## 4. ROOT-CAUSE CHECK

Verify:
1. the implementation actually changes the proven failure point;
2. the fix does not merely hide the symptom;
3. the original root-cause chain remains technically valid after the diff;
4. no second speculative fix was stacked on top;
5. the expected behavior still follows current Source of Truth.

If the diff works only because an assertion/threshold/test was weakened, mark review as an issue unless that expectation change was explicitly approved as a CONTRACT_CHANGE/TUNING decision.

## 5. ARCHITECTURE / CONTRACT CHECK

Check only relevant existing contracts:
- current owner module still owns the responsibility;
- no duplicate Manager/Service/Controller/Event/Storage family was created;
- dependency direction remains valid;
- no circular project dependency was introduced;
- client/server authority remains correct;
- DataStore/schema remains unchanged unless approved;
- Rojo mapping remains unchanged unless approved;
- collision/physics ownership remains unchanged unless approved;
- gameplay/balance rules remain unchanged unless approved;
- public ModuleScript APIs/remotes/data shapes remain compatible unless approved.

## 6. REGRESSION / VERIFICATION CHECK

Verify the evidence promised by the plan:
- regression RED was the correct failure, when automation was appropriate;
- targeted GREEN passed;
- required existing regressions passed;
- full repository checks passed when required;
- fresh GitHub Actions/Contract Verify belongs to `FIX_HEAD`;
- Rojo build evidence belongs to `FIX_HEAD` when required;
- warnings/errors were not ignored if relevant.

For physics/camera/UI/visual/feel bugs, confirm the manual acceptance step is still pending until user evidence exists.

## 7. SCOPE-CREEP CHECK

Explicitly answer:

```text
UNRELATED REFACTOR: YES / NO
ARCHITECTURE EXPANSION: YES / NO
PUBLIC CONTRACT CHANGE: YES / NO
GAMEPLAY/BALANCE CHANGE: YES / NO
ROJO MAPPING CHANGE: YES / NO
UNPLANNED FILES: YES / NO
```

Any `YES` must point to exact evidence and whether it was approved.

## 8. REVIEW RESULT

Use one verdict:

### `REVIEW PASS`
Use only when the diff matches the plan, root cause is addressed at code/contract level, automated evidence is adequate, and no unapproved scope/architecture issue remains.

`REVIEW PASS` does **not** mean Studio/human acceptance passed.

### `REVIEW ISSUES`
Use when concrete problems exist. For every issue report:

```text
SEVERITY: P0 / P1 / P2 / P3
PATH / AREA: ...
EVIDENCE: ...
WHY IT MATTERS: ...
PLAN VIOLATION / CONTRACT: ...
NEXT ACTION: plan amendment / new bounded bugfix / human evidence needed
```

Do not implement the fix during review.

### `REVIEW BLOCKED`
Use when the necessary plan/base/diff/evidence cannot be established safely.

## 9. FINAL REVIEW FORMAT

```text
VERDICT: REVIEW PASS / REVIEW ISSUES / REVIEW BLOCKED
BASE_SHA: ...
FIX_HEAD: ...

PLAN MATCH:
...

ROOT CAUSE ADDRESSED:
YES / NO / NOT PROVABLE

SCOPE CREEP:
...

ARCHITECTURE / CONTRACTS:
...

TEST / CI / ROJO EVIDENCE:
...

HUMAN STUDIO STATUS:
PENDING / PASS / FAIL / NOT REQUIRED

REMAINING RISKS:
...

NEXT ACTION:
...
```

If human Studio evidence is still required, the correct next state after a successful code review is `READY FOR HUMAN ACCEPTANCE`, not final PASS.
