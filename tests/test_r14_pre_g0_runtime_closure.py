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


def test_r14_2_g0_presentation_harness_is_studio_only_and_non_physical() -> None:
    harness_path = ROOT / "src/client/Dev/M0G0PresentationHarness.lua"
    assert harness_path.is_file(), "R14.2 requires a Studio-only G0 presentation harness"
    harness = harness_path.read_text(encoding="utf-8")
    for token in [
        'RunService:IsStudio()',
        'StudioHarnessConfig.Mode ~= "G0"',
        'GetAttribute("DebugTarget") == true',
        'FindFirstChild("BodyCollider")',
        'CameraType = Enum.CameraType.Scriptable',
        'CFrame.lookAt',
        'G0DebugBodyProxy',
        'CanCollide = false',
        'CanTouch = false',
        'CanQuery = false',
        'RenderStepped',
    ]:
        assert token in harness, f"missing R14.2 presentation contract token: {token}"
    assert "RaceCameraController" not in harness
    assert "CosmeticService" not in harness


def test_r14_2_client_bootstrap_wires_g0_presentation_without_future_camera_owner() -> None:
    bootstrap = read("src/client/Bootstrap.client.lua")
    assert 'WaitForChild("Dev")' in bootstrap
    assert 'WaitForChild("M0G0PresentationHarness")' in bootstrap
    assert "M0G0PresentationHarness.start()" in bootstrap
    assert "RaceCameraController" not in bootstrap
