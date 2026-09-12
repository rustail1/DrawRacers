from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_canvas_preview_uses_post_mapping_points_that_world_leg_uses() -> None:
    shape = (ROOT / "src/shared/Math/LegShapeMath.lua").read_text(encoding="utf-8")
    client = (ROOT / "src/client/Controllers/DrawingController.lua").read_text(encoding="utf-8")
    server = (ROOT / "src/server/Services/LegShapeService.lua").read_text(encoding="utf-8")

    # GeometryMath can radially clamp mappedPoints at MaxLegExtentFromHub. The
    # gameplay canvas must therefore render a semantic projection of mappedPoints,
    # not the pre-cap anchored normalizedPoints.
    assert "presentationPoints" in shape
    assert "geometryPlan.mappedPoints" in shape
    assert "geometryConfig.LegCanvasHalfSpan" in shape
    assert "canonical.presentationPoints" in client
    assert "canonical.normalizedPoints" not in client.split("function DrawingController:_renderLiveCanonicalPreview", 1)[1].split("end\n\nfunction", 1)[0]

    # Accepted server feedback must use the same post-mapping presentation path,
    # otherwise the canvas can jump back to the pre-cap shape after ACCEPT.
    assert "serializeSemanticPoints(canonical.presentationPoints)" in server


def test_presentation_points_remain_hub_local_semantic_coordinates() -> None:
    shape = (ROOT / "src/shared/Math/LegShapeMath.lua").read_text(encoding="utf-8")

    assert "presentationPoints" in shape
    assert "mapped / geometryConfig.LegCanvasHalfSpan" in shape
