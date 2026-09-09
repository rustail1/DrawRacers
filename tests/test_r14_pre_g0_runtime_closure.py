from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def test_r14_1_server_returns_authoritative_accepted_shape_points() -> None:
    service = read("src/server/Services/LegShapeService.lua")
    assert "acceptedPoints" in service
    assert "buildResult.shapeSpec" in service
    assert "normalizedPoints" in service
    assert "acceptedPoints =" in service


def test_r14_1_client_renders_server_authoritative_points_not_pending_candidate() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    result_start = drawing.index("function DrawingController:_onStrokeResult")
    result_end = drawing.index("function DrawingController:_onPointer", result_start)
    result_body = drawing[result_start:result_end]

    assert "result.acceptedPoints" in result_body
    assert "copySemanticPoints(result.acceptedPoints)" in result_body

    accepted_start = result_body.index("if result.accepted == true then")
    accepted_end = result_body.index("return", accepted_start)
    accepted_branch = result_body[accepted_start:accepted_end]
    assert "copySemanticPoints(pending)" not in accepted_branch


def test_r14_1_studio_b12_compares_result_points_to_current_shape_spec() -> None:
    studio_spec = read("src/server/Tests/B12StrokeRemoteSpec.lua")
    assert "accepted.acceptedPoints" in studio_spec
    assert "GetCurrentShapeSpec" in studio_spec
    assert "normalizedPoints" in studio_spec
