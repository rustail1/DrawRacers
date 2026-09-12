from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_rcp03_shared_canonical_builder_owns_shape_processing() -> None:
    builder_path = ROOT / "src/shared/Math/LegShapeMath.lua"
    assert builder_path.is_file(), "RCP-03 requires shared LegShapeMath"
    builder = builder_path.read_text(encoding="utf-8")

    for token in [
        "function LegShapeMath.BuildCanonical",
        "StrokeMath.ClampToRect",
        "StrokeMath.Dedupe",
        "StrokeMath.SimplifyRDP",
        "StrokeMath.Resample",
        "StrokeMath.MeasureLength",
        "StrokeMath.AnchorToFirstPoint",
        "StrokeMath.ComputeBounds",
        "GeometryMath.BuildSegmentPlan",
        "normalizedPoints",
        "mappedPoints",
        "segmentPlan",
        "extent",
    ]:
        assert token in builder, f"missing canonical builder token: {token}"

    for forbidden in ["Workspace", "Players", "RemoteEvent", "Instance.new", "FireServer"]:
        assert forbidden not in builder, f"canonical builder must stay pure: {forbidden}"


def test_rcp03_client_and_server_use_same_canonical_builder() -> None:
    server = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")

    assert 'WaitForChild("LegShapeMath")' in server
    assert 'WaitForChild("LegShapeMath")' in client
    assert "LegShapeMath.BuildCanonical" in server
    assert "LegShapeMath.BuildCanonical" in client
    assert "StrokeMath.SimplifyRDP" not in server
    assert "StrokeMath.Resample" not in server


def test_rcp03_main_canvas_uses_fixed_canonical_mapping_and_larger_surface() -> None:
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")

    assert "local DESKTOP_CANVAS_SIZE = UDim2.fromScale(0.70, 0.40)" in client
    assert "local TOUCH_CANVAS_SIZE = UDim2.fromScale(0.84, 0.48)" in client
    assert "_renderLiveCanonicalStroke" in client
    assert "semanticPointsToPixels" in client
    live_body = client.split("function DrawingController:_renderLiveCanonicalStroke", 1)[1].split("function DrawingController:", 1)[0]
    assert "LegShapeMath.BuildCanonical" in live_body
    assert "fitSemanticPointsToPixels" not in live_body
    assert "fitSemanticPointsToPixels" in client, "auto-fit remains allowed for thumbnail only"
