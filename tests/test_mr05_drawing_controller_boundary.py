from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    return text.split(start, 1)[1].split(end, 1)[0]


def test_mr05_gameplay_sampling_is_semantic_before_canonical_processing() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    assert 'WaitForChild("CanonicalLegShape")' in drawing
    assert 'WaitForChild("StrokeMath")' in drawing
    assert "StrokeMath.Normalize" in drawing
    assert "_rawSemanticPoints" in drawing
    assert "_semanticPixelPoints" not in drawing

    for forbidden in [
        "StrokeMath.SimplifyRDP",
        "StrokeMath.Resample",
        "StrokeMath.Dedupe",
        "StrokeMath.ClampToRect",
        "StrokeMath.AnchorToFirstPoint",
        "GeometryMath",
    ]:
        assert forbidden not in drawing, f"client owns duplicate canonical operation: {forbidden}"


def test_mr05_capture_keeps_pixel_trace_separate_from_raw_semantic_gameplay_samples() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    capture = section(drawing, "function DrawingController:_capturePointerPoint", "function DrawingController:_onPointer")

    assert "self:_appendLivePoint(point" in capture
    assert "self:_toSemantic(point)" in capture
    assert "self:_tryAppendRawSemanticPoint" in capture
    assert "self:_renderLiveCanonicalPreview()" in capture

    clear = section(drawing, "function DrawingController:_clearLiveStroke", "function DrawingController:_setValidation")
    assert "table.clear(self._livePoints)" in clear
    assert "table.clear(self._rawSemanticPoints)" in clear


def test_mr05_canonical_prediction_consumes_raw_semantic_points_directly() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    build = section(drawing, "function DrawingController:_buildCanonical", "function DrawingController:_renderLiveCanonicalPreview")
    preview = section(drawing, "function DrawingController:_renderLiveCanonicalPreview", "function DrawingController:_pendingStrokeCount")

    assert "CanonicalLegShape.Build" in build
    assert "StrokeMath.Normalize" not in build
    assert "rawSemanticPoints" in build
    assert "self:_buildCanonical(self._rawSemanticPoints)" in preview


def test_mr05_submit_sends_raw_semantic_samples_not_client_canonical_geometry() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    submit = section(drawing, "function DrawingController:_submitStrokeIntent", "function DrawingController:_onStrokeResult")

    assert "vector2ToSemanticPoints(rawSemanticPoints)" in submit
    assert "points = serializedRawPoints" in submit
    assert "canonical.presentationAnchor" in submit
    assert "canonical.normalizedPoints" not in submit
    assert "FireServer" in submit


def test_mr05_fixed_gameplay_mapping_and_thumbnail_only_autofit() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")

    main_map = section(drawing, "local function semanticPointsToPixels", "local function vectorPointsToPixels")
    assert "local unit = size.Y * 0.5" in main_map
    assert "fitSemanticPointsToPixels" not in main_map

    thumbnail = section(drawing, "function DrawingController:_renderThumbnail", "function DrawingController:_applyLayout")
    assert "fitSemanticPointsToPixels(self._acceptedSemanticPoints" in thumbnail

    accepted = section(drawing, "function DrawingController:_renderAcceptedStroke", "function DrawingController:_renderThumbnail")
    assert "semanticPointsToPixels" in accepted
    assert "fitSemanticPointsToPixels" not in accepted


def test_mr05_server_accept_remains_authoritative_and_anchor_scoped() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    result = section(drawing, "function DrawingController:_onStrokeResult", "function DrawingController:_capturePointerPoint")

    assert "result.acceptedPoints" in result
    assert "sequence > self._lastAcceptedSequence" in result
    assert "self._acceptedSemanticPoints = copySemanticPoints(result.acceptedPoints)" in result
    assert "self._presentationAnchors[sequence]" in result
    assert "self._acceptedPresentationAnchor" in result
