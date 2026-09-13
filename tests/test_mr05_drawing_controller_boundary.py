from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_mr05_capture_keeps_pixel_trace_separate_from_raw_semantic_samples() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    capture = section(drawing, "function DrawingController:_capturePointerPoint", "function DrawingController:_onPointer")
    assert "self:_appendLivePoint(point)" in capture
    assert "self:_toSemantic(point)" in capture
    assert "self:_tryAppendRawSemanticPoint(semantic, forceFinal)" in capture
    assert "self:_renderLiveCanonicalPreview()" in capture


def test_mr05_canonical_prediction_consumes_raw_semantic_points_directly() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    build = section(drawing, "function DrawingController:_buildCanonical", "function DrawingController:_renderLiveCanonicalPreview")
    assert "rawSemanticPoints" in build
    assert "CanonicalLegShape.Build(rawSemanticPoints" in build
    assert "StrokeMath.Simplify" not in build
    assert "StrokeMath.Resample" not in build


def test_mr05_submit_sends_raw_semantic_samples_not_client_canonical_geometry() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    submit = section(drawing, "function DrawingController:_submitStrokeIntent", "function DrawingController:_onStrokeResult")
    assert "local serializedRawPoints = vector2ToSemanticPoints(rawSemanticPoints)" in submit
    assert "points = serializedRawPoints" in submit
    assert "canonical.normalizedPoints" not in submit
    assert "presentationAnchor" not in submit


def test_mr05_fixed_pivot_and_fixed_main_canvas_mapping() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert 'pivotMarker.Name = "PivotMarker"' in drawing
    assert "START FROM THE DOT" in drawing
    assert "PivotStartRadiusNormalized" in drawing
    assert "semanticPointsToPixels" in drawing
    assert "vectorPointsToPixels" in drawing
    assert "fitSemanticPointsToPixels" in drawing
    assert "_presentationAnchors" not in drawing
    assert "_acceptedPresentationAnchor" not in drawing


def test_mr05_server_accept_remains_authoritative() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    result = section(drawing, "function DrawingController:_onStrokeResult", "function DrawingController:_capturePointerPoint")
    assert "validServerSemanticPoints(result.acceptedPoints)" in result
    assert "self._acceptedSemanticPoints = copySemanticPoints(result.acceptedPoints)" in result
    assert "self:_renderAcceptedStroke()" in result
    assert "self:_renderThumbnail()" in result
