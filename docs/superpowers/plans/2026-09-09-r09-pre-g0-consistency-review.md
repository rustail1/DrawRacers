# R09 Pre-G0 consistency review — implementation plan

> Bounded B17/G0 rework only. This plan must not start C01/M0.5 or promote G0 without human evidence.

**Goal:** synchronize repository status docs with R07/R08 and close concrete pre-G0 correctness/architecture gaps found by the 2026-09-09 repository audit.

## Task 1 — RED regressions
- Add `tests/test_r09_pre_g0_review.py`.
- Cover accepted-shape preview independence from responsive layout size, exact touch DrawHUD tokens, obstacle RequirementTag precedence over recovery assist, and removal of template-only `RuntimeAttachments` from spawned racer models.
- Extend the existing documentation consistency contract so status docs must mention R08/R09 while keeping B17/G0 pending.
- Push RED and record failing `python verify.py` CI evidence.

## Task 2 — Minimal production repairs
- `DrawingController.lua`: keep accepted/pending shape presentation in semantic normalized coordinates and map to the current DrawInputRect only when rendering; re-render after between-stroke layout changes; apply the exact touch ValidationToast/DrawHint layout from doc 59.
- `RacerAntiStall.lua`: obstacle RequirementTag wins over `RecoverySurface`; only `FAST_ROLL`/explicit recovery with no conflicting obstacle tag may assist.
- `RacerStabilizer.lua`: after moving the two template attachments onto BodyCollider, destroy the now-empty template-only `RuntimeAttachments` folder so the spawned racer matches doc 65 runtime tree.

## Task 3 — Status/document synchronization
- Update root `README.md`, `docs/SESSION.md`, `docs/FEATURE_LIST.md` and add a bounded R07–R09 audit decision record.
- Preserve historical R01–R06 evidence; record R08 baseline `77 passed, 0 failed`; keep `B17/G0 HUMAN_GATE` as the current hard stop.
- Do not claim Studio or external-tester PASS.

## Task 4 — Verification
- Run full `python verify.py` through GitHub Actions on the resulting `main`.
- Inspect the exact workflow conclusion/logs before claiming completion.
- Only after green automation, request local `git pull --ff-only` + Rojo/Studio G0 evidence from the Product Owner.
