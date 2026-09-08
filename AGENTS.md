# AGENTS.md — Draw Racers repository entry point

This root file routes AI/developer work to the production handoff in `docs/`. It does not replace specialized owner specs.

## Mandatory task start
1. Read `docs/AGENTS.md`.
2. Read `docs/FEATURE_LIST.md` and `docs/SESSION.md`.
3. Read `docs/26_HANDOFF_MAP.md`.
4. Read the exact current task row in `docs/66_ZERO_TO_RELEASE_TASK_ACCEPTANCE_CATALOG.md`.
5. Read only the owner specs named by that task row plus relevant existing code.

## Hard rules
- Work only on the current task; do not jump ahead.
- Do not load or recreate old `_HISTORY` documentation in normal implementation context.
- Do not invent numeric Roblox Place/Product/Pass/Asset IDs.
- Do not create duplicate top-level Service/Controller families that conflict with `docs/21_SYSTEM_CLASS_ARCHITECTURE.md`.
- Filesystem/Rojo-managed scripts are the version-controlled source; do not create competing manual copies in Studio.
- Human Studio acceptance is required for physics feel, camera, touch UX, visual readability, and any task whose acceptance row requires it.
- A failed task is reworked before the next task starts.

## Current bootstrap dependency
`A01 -> A02 -> A03 -> A04 -> B01` is mandatory.

A01 is complete only after local `rojo build`, `rojo serve`, and a Roblox Studio sync round-trip pass. Until then, do not implement A02 or gameplay.
