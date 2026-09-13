from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_rcp03_shared_canonical_builder_owns_cr3_support_anchor_shape_processing() -> None:
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    for token in [
        "StrokeMath.ClampToRect", "StrokeMath.Dedupe", "StrokeMath.SimplifyRDP", "StrokeMath.Resample",
        "selectSupportAnchor", "leftCandidate", "topCandidate", "rightCandidate",
        "point - supportAnchor", "presentationAnchor", "GeometryMath.BuildSegmentPlan",
    ]:
        assert token in builder
    assert "PivotStartRadiusNormalized" not in builder
    assert "START_OFF_PIVOT" not in builder
    assert "StrokeMath.AnchorToFirstPoint" not in builder


def test_rcp03_server_uses_shared_canonical_builder_and_remains_authoritative() -> None:
    service = read("src/server/Services/LegShapeService.lua")
    assert "CanonicalLegShape.Build" in service
    assert "racerRuntime:ApplyValidatedShape(shapeSpec, motorEnabled)" in service
    assert "acceptedPoints = serializeSemanticPoints(shapeSpec.normalizedPoints)" in service


def test_rcp03_client_prediction_uses_same_builder_without_second_cleanup_pipeline() -> None:
    client = read("src/client/Controllers/DrawingController.lua")
    build = client.split("function DrawingController:_buildCanonical", 1)[1].split("function DrawingController:_renderLiveCanonicalPreview", 1)[0]
    assert "CanonicalLegShape.Build(rawSemanticPoints" in build
    for forbidden in ["SimplifyRDP", "Resample(", "BuildSegmentPlan"]:
        assert forbidden not in build


def test_rcp03_client_submits_raw_semantic_samples_and_uses_fixed_scale_free_draw_mapping() -> None:
    client = read("src/client/Controllers/DrawingController.lua")
    submit = client.split("function DrawingController:_submitStrokeIntent", 1)[1].split("function DrawingController:_onStrokeResult", 1)[0]
    assert "local serializedRawPoints = vector2ToSemanticPoints(rawSemanticPoints)" in submit
    assert "points = serializedRawPoints" in submit
    assert "semanticPointsToPixels" in client
    assert "vectorPointsToPixels" in client
    assert "fitSemanticPointsToPixels" not in client
    assert "AcceptedShapeThumbnail" not in client
    assert "PivotMarker" not in client
    assert "_presentationAnchors" in client


def test_rcp03_polyline_renderer_fills_sharp_corner_joints_without_changing_centerline() -> None:
    client = read("src/client/Controllers/DrawingController.lua")
    assert "local function drawSegment" in client
    assert "local function drawJoint" in client
    assert "local function renderPolyline" in client
    assert "for index = 2, #points - 1 do drawJoint" in client
