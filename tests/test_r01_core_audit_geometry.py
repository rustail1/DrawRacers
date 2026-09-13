from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r01_geometry_has_one_authoritative_plan_owner():
    geometry_path = ROOT / "src" / "shared" / "Math" / "GeometryMath.lua"
    builder_path = ROOT / "src" / "shared" / "Math" / "CanonicalLegShape.lua"
    legacy_builder_path = ROOT / "src" / "shared" / "Math" / "LegShapeMath.lua"
    assert geometry_path.is_file(), "R01 requires shared GeometryMath owner"
    assert builder_path.is_file(), "MR-01 requires shared CanonicalLegShape owner"
    assert not legacy_builder_path.exists(), "legacy LegShapeMath must not remain as a parallel owner"
    geometry = geometry_path.read_text(encoding="utf-8")
    builder = builder_path.read_text(encoding="utf-8")
    assert "BuildSegmentPlan" in geometry
    assert "Instance.new" not in geometry
    assert "GeometryMath.BuildSegmentPlan" in builder
    assert "Instance.new" not in builder

    service = read("src/server/Services/LegShapeService.lua")
    assert "CanonicalLegShape.Build" in service
    assert "local function mapPointToLegSpace" not in service
    assert "local function buildSegmentPlan" not in service

    leg = read("src/server/Runtime/LegAssembly.lua")
    assert "shapeSpec" in leg
    assert "shapeSpec.segmentPlan" in leg
    assert "local function mapPoint" not in leg
    assert "distanceFromOriginToSegment" not in leg

    # MR-04 routes internal/test ApplyShape through the same canonical owner
    # instead of keeping a second StrokeMath/GeometryMath construction path.
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    assert "CanonicalLegShape.Build" in runtime
    assert "GeometryMath.BuildSegmentPlan" not in runtime
    assert "StrokeMath.AnchorToFirstPoint" not in runtime
    assert "ApplyValidatedShape(shapeSpec" in runtime


def test_r01_draw_input_rect_is_r16_3b_wide_semantic_surface():
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "UIAspectRatioConstraint" in drawing
    assert "R16WideDrawSurfaceConstraint" in drawing
    assert "SemanticSquareConstraint" not in drawing
    assert "RawSemanticHalfWidth" in drawing
    assert "RawSemanticHalfHeight" in drawing
    assert "Enum.DominantAxis.Height" in drawing
    assert 'makeFrame("StrokePreview", drawInputRect)' in drawing
    assert "strokePreview.Size = UDim2.fromScale(1, 1)" in drawing
    assert "drawInputRect.Size = DRAW_INPUT_SIZE" in drawing
    assert "DRAW_INPUT_SIZE = UDim2.fromScale(1, 1)" in drawing
