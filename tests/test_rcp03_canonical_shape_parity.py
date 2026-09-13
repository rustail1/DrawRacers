from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_rcp03_shared_canonical_builder_owns_fixed_pivot_shape_processing() -> None:
    builder = read("src/shared/Math/CanonicalLegShape.lua")
    for token in [
        "StrokeMath.ClampToRect", "PivotStartRadiusNormalized", "START_OFF_PIVOT",
        "StrokeMath.Dedupe", "StrokeMath.SimplifyRDP", "StrokeMath.Resample",
        "Vector2.zero", "GeometryMath.BuildSegmentPlan",
    ]:
        assert token in builder
    assert "StrokeMath.AnchorToFirstPoint" not in builder
    assert "presentationAnchor" not in builder


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


def test_rcp03_client_submits_raw_semantic_samples_and_uses_fixed_main_canvas_mapping() -> None:
    client = read("src/client/Controllers/DrawingController.lua")
    submit = client.split("function DrawingController:_submitStrokeIntent", 1)[1].split("function DrawingController:_onStrokeResult", 1)[0]
    assert "local serializedRawPoints = vector2ToSemanticPoints(rawSemanticPoints)" in submit
    assert "points = serializedRawPoints" in submit
    assert "semanticPointsToPixels" in client
    assert "vectorPointsToPixels" in client
    assert "fitSemanticPointsToPixels" in client
    assert 'pivotMarker.Name = "PivotMarker"' in client


def test_rcp03_polyline_renderer_fills_sharp_corner_joints_without_changing_centerline() -> None:
    client = read("src/client/Controllers/DrawingController.lua")
    assert "local function drawSegment" in client
    assert "local function drawJoint" in client
    assert "local function renderPolyline" in client
    assert "for index = 2, #points - 1 do drawJoint" in client
