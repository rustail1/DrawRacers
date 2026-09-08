# 42 — TRACKPIECE AUTHORING GUIDE
Статус: **LEVEL CONTENT CONTRACT v1.3.4**.

## Required hierarchy
`65_STUDIO_DATAMODEL_INSTANCE_PROPERTY_SPEC.md` is the exact Instance-tree owner. Every production template uses:
```text
Piece_<Id> (Model) [PrimaryPart = AuthoringRoot]
  AuthoringRoot (Part) invisible, anchored
  Geometry (Folder)
    Collision_* (BasePart...)
    Visual_* (BasePart/MeshPart...)
  Start (Attachment or invisible Part+Attachment)
  End (Attachment or invisible Part+Attachment)
  Recovery (Folder)
    RecoveryFloor (optional)
    Respawn (Attachment)
  Triggers (Folder)
    Checkpoint (Part)
  AuthoringMeta (Folder)
```
Simple pieces may have an empty Recovery folder, but the folder/name remains so TrackBuilder/validator never branches on a different template family. Checkpoint presence follows the `60` catalog/HasCheckpoint attribute. Do not omit `AuthoringRoot`, `Triggers` or `AuthoringMeta`.

## Rules
- Start/End orientation identical convention.
- No hidden collision lips that snag legal shapes unintentionally.
- Decorative meshes non-collidable unless explicitly gameplay geometry.
- Every piece has flat approach/read distance unless tagged `COMBO_ONLY`.
- Piece must be solvable by at least two legal shape families and meaningfully worse for at least one other family unless it is an onboarding demonstration.
- Recovery exit exists for geometry likely to trap racers.

## Authoring test
Run canonical suite: Round, Long, Hook, Small, Asymmetric. Record completion time, stalls, redraw need. Reject piece if one universal shape trivially dominates or legal shapes frequently explode solver.

## Variant policy
Parameters (height/gap/angle) stay inside validated ranges. Random generation may select only validated combinations.


## Numeric owner
Do not eyeball launch geometry. Exact default dimensions/ranges and which pieces require recovery behavior are `60_TRACKPIECE_PARAMETER_CATALOG.md`.
