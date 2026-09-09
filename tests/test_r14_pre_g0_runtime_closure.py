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


def test_r14_3_studio_runner_aggregates_failures_under_xpcall() -> None:
    runner_path = ROOT / "src/server/Tests/StudioSpecRunner.lua"
    assert runner_path.is_file(), "R14.3 requires StudioSpecRunner.lua"
    runner = runner_path.read_text(encoding="utf-8")
    assert "xpcall" in runner
    assert "debug.traceback" in runner
    assert "failures" in runner
    assert "specNames" in runner
    assert "return #failures == 0" in runner


def test_r14_3_server_bootstrap_gates_harness_on_ready() -> None:
    bootstrap = read("src/server/Bootstrap.server.lua")
    assert 'local STUDIO_GATE_ATTRIBUTE = "DrawRacersStudioGateState"' in bootstrap
    assert 'SetAttribute(STUDIO_GATE_ATTRIBUTE, "TESTING")' in bootstrap
    assert 'SetAttribute(STUDIO_GATE_ATTRIBUTE, "BLOCKED")' in bootstrap
    assert 'SetAttribute(STUDIO_GATE_ATTRIBUTE, "READY")' in bootstrap
    assert 'WaitForChild("StudioSpecRunner")' in bootstrap
    assert "STUDIO_REGRESSION_SPECS" in bootstrap
    for task in [3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 16]:
        assert f'"B{task:02d}' in bootstrap
    assert "if specsPassed then" in bootstrap
    ready_branch = bootstrap.split("if specsPassed then", 1)[1]
    assert "M0HumanHarness.start()" in ready_branch


def test_r14_3_client_does_not_start_studio_drawing_before_ready() -> None:
    bootstrap = read("src/client/Bootstrap.client.lua")
    assert 'GetAttribute("DrawRacersStudioGateState")' in bootstrap
    assert 'GetAttributeChangedSignal("DrawRacersStudioGateState")' in bootstrap
    assert 'if state == "READY" then' in bootstrap
    ready_branch = bootstrap.split('if state == "READY" then', 1)[1].split('elseif state == "BLOCKED" then', 1)[0]
    assert "drawingController:Start()" in ready_branch
    assert 'G0 BLOCKED — SERVER TEST FAILED' in bootstrap
    assert 'G0 TESTS RUNNING' in bootstrap


def test_r14_5_pending_strokes_are_count_and_time_bounded() -> None:
    config = read("src/shared/Config/PhysicsConfig.lua")
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "StrokeResultTimeout = 3.0" in config
    assert "MaxPendingStrokes = 4" in config
    assert "_pendingStrokeCount" in drawing
    assert "config.MaxPendingStrokes" in drawing
    assert "task.delay(config.StrokeResultTimeout" in drawing
    assert "NETWORK_TIMEOUT" in drawing
    assert "CLIENT_PENDING_LIMIT" in drawing


def test_r14_5_late_authoritative_accept_can_still_replace_timed_out_preview() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    result_start = drawing.index("function DrawingController:_onStrokeResult")
    result_end = drawing.index("function DrawingController:_onPointer", result_start)
    result_body = drawing[result_start:result_end]
    assert "if result.accepted == true then" in result_body
    assert "sequence > self._lastAcceptedSequence" in result_body
    pending_guard = 'if pending == nil then\n\t\treturn\n\tend'
    assert pending_guard not in result_body, "late trusted server ACCEPT must not be discarded only because local timeout evicted pending state"


def test_r14_5_transport_contains_processor_exception_and_returns_generic_error() -> None:
    transport = read("src/server/Services/StrokeRemoteTransport.lua")
    service = read("src/server/Services/LegShapeService.lua")
    assert "xpcall" in transport
    assert "debug.traceback" in transport
    assert '"SERVER_ERROR"' in transport
    assert "ExtractSafeSequence" in transport
    assert "function LegShapeService.ExtractSafeSequence" in service
