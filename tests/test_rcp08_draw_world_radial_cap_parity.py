from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_canvas_preview_uses_post_mapping_points_that_world_leg_uses() -> None:
    shape = (ROOT / "src/shared/Math/LegShapeMath.lua").read_text(encoding="utf-8")
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")
    server = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")

    # GeometryMath can radially clamp mappedPoints at MaxLegExtentFromHub. The
    # canonical normalized path exposed to both preview and server feedback must
    # therefore be reconstructed from mappedPoints, not the pre-cap anchored path.
    assert "presentationPoints" in shape
    assert "geometryPlan.mappedPoints" in shape
    assert "mapped / geometryConfig.LegCanvasHalfSpan" in shape
    assert "normalizedPoints = presentationPoints" in shape

    # Existing client/server consumers can keep using canonical.normalizedPoints;
    # it now names the actual world-leg semantic centerline after radial capping.
    assert "canonical.normalizedPoints" in client
    assert "serializeSemanticPoints(shapeSpec.normalizedPoints)" in server


def test_presentation_bounds_are_computed_from_world_equivalent_points() -> None:
    shape = (ROOT / "src/shared/Math/LegShapeMath.lua").read_text(encoding="utf-8")

    assert "StrokeMath.ComputeBounds(presentationPoints)" in shape
    assert "LegCanvasHalfSpan must be positive" in shape
