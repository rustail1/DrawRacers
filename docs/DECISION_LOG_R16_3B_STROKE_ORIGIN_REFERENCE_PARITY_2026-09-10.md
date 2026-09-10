# DECISION LOG — R16.3B Stroke-Origin Reference Parity

Date: 2026-09-10  
Status: **APPROVED IMPLEMENTATION / HUMAN STUDIO PENDING**

## Decision
R16.3B supersedes the R16.3A **bounds-center** mechanical-origin rule and the earlier square semantic DrawInputRect presentation rule.

The authoritative stroke keeps the player's cleaned shape size, proportions, direction and point order, but translation is now defined by the **first cleaned point**:

- after clamp/dedupe/RDP/resample, `origin = cleaned[1]`;
- every authoritative point becomes `point - origin`;
- therefore the first authoritative point is exactly `(0,0)` and is the mechanical hub origin;
- there is no bounds-center recentering, no resize, no rotation, no mirror and no automatic closing segment;
- one resulting ShapeSpec is still duplicated to Left/Right with the existing 180-degree phase contract.

## Draw surface
The player-facing semantic input surface is now one **wide semantic DrawInputRect** with a 1.75:1 aspect. Raw semantic limits are owned by `PhysicsConfig.StrokeProcessing`:

- `RawSemanticHalfWidth = 1.75`;
- `RawSemanticHalfHeight = 1.0`.

Normalization remains isotropic: one semantic unit is half the DrawInputRect height on both axes, so a wide UI does not stretch X versus Y. The visible input surface and pointer-capture surface are the same rectangle.

## Network contract
The `SubmitStroke` payload schema is unchanged: `{ sequence, points }`. R16.3B adds no `canvasAspect`, pivot, anchor or world-space fields to the client request. The server returns the first-point anchored authoritative ShapeSpec points through the existing `StrokeResult.acceptedPoints`; **payload schema unchanged**.

## Physics / presentation separation
Physical leg collider boxes remain the server-authoritative locomotion geometry and keep the existing collision/motor/material limits. Presentation is separate: physical collider Parts stay hidden and nonphysical visual segments/joints render the accepted shape. Presentation cannot change contact truth, mass, motor torque or race authority.

## Studio evidence path
R16.3B adds/uses the unified `R16FINAL` Studio evidence route so automated R16 evidence runs before the interactive human G0 handoff. The side presentation camera and F3 debug-panel toggle are presentation-only.

This decision does **not** promote any human gate:

- Studio Gate A — **HUMAN STUDIO PENDING**;
- Studio Gate B — **HUMAN STUDIO PENDING**;
- Studio Gate C — **HUMAN STUDIO PENDING**;
- B17/G0 — **HUMAN_GATE PENDING**.

R16.11 must not freeze before Studio Gate C is actually recorded from Roblox Studio evidence. CI/Rokit/Rojo results never substitute for live Studio solver/visual evidence.

## Superseded wording
Any statement that the server must place the cleaned stroke's **bounds center** or bounds midpoint at the hub is historical R16.3A wording and is superseded by R16.3B. Current mechanical origin is the first cleaned authoritative point.
