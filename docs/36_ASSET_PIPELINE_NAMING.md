# 36 — ASSET PIPELINE & NAMING
Статус: **CONTENT PRODUCTION CONTRACT v1.3.4**.

## Naming
`Body_<Theme>_<NN>`, `Ink_<Theme>_<NN>`, `Trail_<Theme>_<NN>`, `Finish_<Theme>_<NN>`, `Track_<Theme>_<NN>`, `Piece_<Archetype>_<NN>`, `SFX_<System>_<Action>`, `VFX_<System>_<Action>`.

## Ownership
Production assets uploaded by project owner/group. Do not depend on personal third-party asset IDs that can disappear.

## Models
Cosmetic Body model contains visual root only; physics body is runtime template. TrackPiece models must satisfy `42_TRACKPIECE_AUTHORING_GUIDE.md` sockets and collision requirements.

## Imported content
Review polygon count, texture resolution, collisions, shadows, hidden scripts/metadata. Reuse asset IDs; do not upload duplicates.

## Audio
One manifest maps semantic key → asset id. Gameplay code never hardcodes audio IDs.

## VFX
Client-owned presentation by semantic event. VFX cannot decide gameplay outcome.

## Third-party libraries/assets
Only trusted source + explicit license + code/content review. External package version is pinned and listed in `SOURCE_MAP.md`/dependency manifest.


## Launch manifest
`62_LAUNCH_CONTENT_ART_DIRECTION_MANIFEST.md` is the required asset list and visual identity owner. Exact production-state workflow = `69_CONTENT_PRODUCTION_EXECUTION_PLAYBOOK.md`; generated AssetIds/provenance registry = `70_ENVIRONMENT_ASSET_ID_REGISTRY_CONTRACT.md`. Missing items in that checklist block public launch unless explicitly cut by Product Owner Decision Log.
