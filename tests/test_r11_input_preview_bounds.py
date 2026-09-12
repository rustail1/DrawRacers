from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r11_hybrid_layout_changes_only_from_non_drawing_input() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    handler_start = drawing.index("UserInputService.LastInputTypeChanged")
    handler_end = drawing.index('print("[DrawRacers][B02] local draw preview ready")', handler_start)
    handler = drawing[handler_start:handler_end]

    assert "self._drawing" in handler
    assert "return" in handler
    assert "self:_applyLayout(family)" in handler
    assert "self._pendingLayoutFamily = family" not in handler

    start_block = drawing[
        drawing.index('if event.phase == "start" then'):
        drawing.index('elseif event.phase == "move" then')
    ]
    assert "self._pendingLayoutFamily = event.family" in start_block


def test_r11_live_preview_instances_are_bounded_by_existing_stroke_cap() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert "function DrawingController:_compactLivePoints" in drawing
    assert "function DrawingController:_appendLivePoint" in drawing
    assert "function DrawingController:_renderLiveCanonicalPreview" in drawing

    append_start = drawing.index("function DrawingController:_appendLivePoint")
    append_end = drawing.index("function DrawingController:_buildCanonicalFromPixels", append_start)
    append_block = drawing[append_start:append_end]
    assert "PhysicsConfig.StrokeProcessing.MaxRawPoints" in append_block
    assert "self:_compactLivePoints()" in append_block

    compact_start = drawing.index("function DrawingController:_compactLivePoints")
    compact_end = drawing.index("function DrawingController:_appendLivePoint", compact_start)
    compact_block = drawing[compact_start:compact_end]
    assert "table.clear(self._livePoints)" in compact_block

    preview_start = drawing.index("function DrawingController:_renderLiveCanonicalPreview")
    preview_end = drawing.index("function DrawingController:_prepareRawSemanticPoints", preview_start)
    preview_block = drawing[preview_start:preview_end]
    assert "LegShapeMath.BuildCanonical" not in preview_block  # delegated through _buildCanonicalFromPixels
    assert "self:_buildCanonicalFromPixels" in preview_block
    assert "renderPolyline(self._ui.liveLayer" in preview_block

    capture_start = drawing.index("function DrawingController:_capturePointerPoint")
    capture_end = drawing.index("function DrawingController:_onPointer", capture_start)
    capture_block = drawing[capture_start:capture_end]
    assert "self:_appendLivePoint" in capture_block
    assert "self:_tryAppendSemanticPoint" in capture_block
    assert "self:_renderLiveCanonicalPreview" in capture_block

    pointer_start = drawing.index("function DrawingController:_onPointer")
    pointer_end = drawing.index("function DrawingController:Start", pointer_start)
    pointer_block = drawing[pointer_start:pointer_end]
    assert "self:_capturePointerPoint" in pointer_block
    assert "table.insert(self._livePoints, point)" not in pointer_block
