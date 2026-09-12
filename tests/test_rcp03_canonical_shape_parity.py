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


def test_rcp03_server_uses_shared_canonical_builder_and_remains_authoritative() -> None:
    server = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")

    assert 'WaitForChild("LegShapeMath")' in server
    assert "LegShapeMath.BuildCanonical" in server
    assert "ApplyValidatedShape" in server
    assert "StrokeMath.SimplifyRDP" not in server
    assert "StrokeMath.Resample" not in server
    assert "GeometryMath.BuildSegmentPlan" not in server
