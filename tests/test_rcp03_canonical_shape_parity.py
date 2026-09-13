from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_rcp03_shared_canonical_builder_owns_shape_processing() -> None:
    builder_path = ROOT / "src/shared/Math/CanonicalLegShape.lua"
    legacy_path = ROOT / "src/shared/Math/LegShapeMath.lua"
    assert builder_path.is_file(), "MR-01 requires shared CanonicalLegShape"
    assert not legacy_path.exists(), "MR-01 retires LegShapeMath"
    builder = builder_path.read_text(encoding="utf-8")

    ordered = [
        "StrokeMath.ClampToRect",
        "StrokeMath.Dedupe",
        "StrokeMath.SimplifyRDP",
        "StrokeMath.Resample",
        "StrokeMath.AnchorToFirstPoint",
        "GeometryMath.BuildSegmentPlan",
    ]
    cursor = -1
    for token in ordered:
        next_cursor = builder.index(token)
        assert next_cursor > cursor, f"canonical pipeline order broken at: {token}"
        cursor = next_cursor

    for token in [
        "function CanonicalLegShape.Build",
        "StrokeMath.MeasureLength",
        "StrokeMath.ComputeBounds",
        "normalizedPoints",
        "mappedPoints",
        "segmentPlan",
        "extent",
        "table.freeze",
    ]:
        assert token in builder, f"missing canonical builder token: {token}"

    for forbidden in ["Workspace", "Players", "RemoteEvent", "Instance.new", "FireServer"]:
        assert forbidden not in builder, f"canonical builder must stay pure: {forbidden}"


def test_rcp03_server_uses_shared_canonical_builder_and_remains_authoritative() -> None:
    server = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")

    assert 'WaitForChild("CanonicalLegShape")' in server
    assert "CanonicalLegShape.Build" in server
    assert "ApplyValidatedShape" in server
    assert "StrokeMath.SimplifyRDP" not in server
    assert "StrokeMath.Resample" not in server
    assert "GeometryMath.BuildSegmentPlan" not in server
    assert "serializeSemanticPoints(shapeSpec.normalizedPoints)" in server


def test_rcp03_client_prediction_uses_same_builder_without_second_cleanup_pipeline() -> None:
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")

    assert 'WaitForChild("CanonicalLegShape")' in client
    assert "CanonicalLegShape.Build" in client
    assert "_renderLiveCanonicalPreview" in client
    assert "StrokeMath.Normalize" in client
    assert "StrokeMath.SimplifyRDP" not in client
    assert "StrokeMath.Resample" not in client
    assert "StrokeMath.Dedupe" not in client
    assert "StrokeMath.ClampToRect" not in client


def test_rcp03_client_submits_raw_semantic_samples_and_uses_fixed_main_canvas_mapping() -> None:
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")

    assert "rawSemanticPoints" in client
    assert "local serializedRawPoints = vector2ToSemanticPoints(rawSemanticPoints)" in client
    assert "points = serializedRawPoints" in client
    assert "semanticPointsToPixels" in client
    assert "fitSemanticPointsToPixels(self._acceptedSemanticPoints" in client, (
        "auto-fit remains allowed only for the thumbnail"
    )
    assert "DESKTOP_CANVAS_SIZE = UDim2.fromScale(0.70, 0.40)" in client
    assert "TOUCH_CANVAS_SIZE = UDim2.fromScale(0.84, 0.48)" in client


def test_rcp03_polyline_renderer_fills_sharp_corner_joints_without_changing_centerline() -> None:
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")

    assert "local function drawJoint" in client
    assert 'joint.Name = "Joint"' in client
    assert "UDim2.fromOffset(thickness, thickness)" in client
    assert "for index = 2, #points - 1 do" in client
    assert "drawJoint(layer, points[index], thickness, transparency)" in client
    assert 'child.Name == "Segment" or child.Name == "Joint"' in client
