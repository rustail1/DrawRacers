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


def test_mr05_submit_sends_raw_semantic_samples_while_presentation_anchor_stays_client_only() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    submit = section(drawing, "function DrawingController:_submitStrokeIntent", "function DrawingController:_onStrokeResult")
    assert "local serializedRawPoints = vector2ToSemanticPoints(rawSemanticPoints)" in submit
    assert "points = serializedRawPoints" in submit
    assert "canonical.normalizedPoints" not in submit
    assert "canonical.presentationAnchor" in submit
    payload = submit.split("local payload: SubmitStrokePayload", 1)[1]
    assert "presentationAnchor" not in payload.split("self._submitStroke:FireServer", 1)[0]


def test_mr05_free_draw_uses_fixed_scale_with_sequence_presentation_anchor_and_no_thumbnail() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "PivotMarker" not in drawing
    assert "START FROM THE DOT" not in drawing
    assert "PivotStartRadiusNormalized" not in drawing
    assert "semanticPointsToPixels" in drawing
    assert "vectorPointsToPixels" in drawing
    assert "fitSemanticPointsToPixels" not in drawing
    assert "AcceptedShapeThumbnail" not in drawing
    assert "_presentationAnchors" in drawing
    assert "_acceptedPresentationAnchor" in drawing


def test_mr05_server_accept_remains_authoritative() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    result = section(drawing, "function DrawingController:_onStrokeResult", "function DrawingController:_capturePointerPoint")
    assert "validServerSemanticPoints(result.acceptedPoints)" in result
    assert "self._acceptedSemanticPoints = copySemanticPoints(result.acceptedPoints)" in result
    assert "self._acceptedPresentationAnchor" in result
    assert "self:_renderAcceptedStroke()" in result
    assert "_renderThumbnail" not in result
