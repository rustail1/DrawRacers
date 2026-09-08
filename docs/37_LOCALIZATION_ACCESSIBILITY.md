# 37 — LOCALIZATION & ACCESSIBILITY
Статус: **PLAYER REACH CONTRACT v1.3.4**.

## Platforms at launch
Mobile touch + desktop mouse/keyboard. Landscape orientation. Console/gamepad/VR are not launch scope; supporting them requires a separate input-UX design/scope decision rather than silently adapting launch controls.

## Localization
Game source language = English for player-facing strings. Internal docs may remain Russian. Enable Roblox localization/automatic translations; manual polish only after traffic justifies it. All player strings use localization keys, not concatenated prose.

## UI
Responsive safe-area layout, readable type, large touch targets, no critical information by color alone. DrawCanvas remains reachable by thumb without covering upcoming obstacle. Exact launch safe margins, touch-target minimums, responsive modes and screenshot matrix are owned by `59`.

## Accessibility settings
- Music on/off
- SFX on/off
- Reduce Motion
- Hide/Reduce Rival Shape Detail
- High Contrast Progress Markers toggle (launch setting, default Off)

## Motion
Reduce Motion disables strong camera shake, excessive finish zoom and rapid screen flashes; core physics remains unchanged.

## Input
No required precise double-clicks. One-finger drawing is sufficient. Desktop click-drag mirrors touch. UI navigation never steals active drawing gesture unexpectedly.


UI implementation/focus binding for these accessibility controls is owned by `68_UI_COMPONENT_HIERARCHY_IMPLEMENTATION_SPEC.md`; exact placements remain `59`.
