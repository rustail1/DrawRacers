from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_canvas_preview_uses_post_mapping_points_that_world_leg_uses() -> None:
    shape = (ROOT / "src/shared/Math/CanonicalLegShape.lua").read_text(encoding="utf-8")
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")
    server = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")

    # GeometryMath may radially clamp mappedPoints at MaxLegExtentFromHub. The
    # canonical normalized path exposed to preview and server feedback is rebuilt
    # from accepted mappedPoints so both sides describe the world-leg centerline.
    assert "geometryPlan.mappedPoints" in shape
    assert "mapped / geometryConfig.LegCanvasHalfSpan" in shape
    assert "normalizedPoints" in shape

    assert "canonical.normalizedPoints" in client
    assert "serializeSemanticPoints(shapeSpec.normalizedPoints)" in server


def test_presentation_bounds_are_computed_from_world_equivalent_points() -> None:
    shape = (ROOT / "src/shared/Math/CanonicalLegShape.lua").read_text(encoding="utf-8")

    assert "StrokeMath.ComputeBounds(normalizedPoints)" in shape
    assert "geometryConfig.LegCanvasHalfSpan <= 0" in shape
