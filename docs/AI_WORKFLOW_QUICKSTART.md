# AI WORKFLOW QUICKSTART — LOCAL FILE -> ROJO -> ROBLOX STUDIO

Status: **CURRENT HUMAN OPERATOR QUICKSTART — 2026-09-15**

Current development runs without Git/GitHub. The exact local project folder/archive provided for the session is the baseline.

## Workflow

```text
local project folder/archive
-> AI/Codex reads only the relevant owner cluster
-> bounded edit in a separate copy/overlay
-> automated/static checks
-> Rojo
-> Roblox Studio
-> video/Output/measurements
-> next bounded fix or acceptance
```

Do not fetch/pull/commit/push/branch unless the Product Owner explicitly re-enables Git.

## Current Core V3 start prompt
Read first:
- `CURRENT_CORE_V3_SOURCE_OF_TRUTH.md`;
- `FEATURE_LIST.md`;
- `SESSION.md`;
- `ARCHITECTURE_MAP.md`;
- relevant current source files only.

For Core V3 physics, begin with:
- `RacerRuntime.lua`;
- `Runtime/CoreV3/*`;
- `LegShapeService.lua`;
- `DrawingController` / stroke result path;
- C01–C07;
- `CoreV3FlatHarness.lua`;
- `StudioHarnessConfig.lua`.

## Bugfix rule
`evidence -> root cause -> one hypothesis -> minimal fix -> verification -> Studio evidence`

Do not stack speculative fixes. After three failed fixes in one physical subsystem, stop and revisit the architecture.

## Completion language
If Roblox Studio/live physics was not actually observed, use:

`AUTOMATED PASS / HUMAN PHYSICS PENDING`

## Current Core V3 validation
- `COREV3_TEST`: C01–C07.
- `COREV3`: isolated flat human physics harness.
- First human test: one ROUND from rest, wait 5 seconds.
- Only after ROUND passes: SMALL_ROUND, LONG, HOOK, ASYMMETRIC, then 20 moving redraws.
