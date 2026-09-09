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


def test_r14_6_g0_fall_recovery_respawns_only_the_racer() -> None:
    config = read("src/shared/Config/M0SceneConfig.lua")
    harness = read("src/server/Tests/M0HumanHarness.lua")
    assert "RecoveryKillY = -12" in config
    assert "recoveryConnection" in harness
    assert "RunService.Heartbeat" in harness
    assert "M0SceneConfig.RecoveryKillY" in harness
    assert "respawnActiveRacer" in harness
    recovery_body = harness.split("local function respawnActiveRacer", 1)[1].split("end", 1)[0]
    assert "restoreCharacter" not in recovery_body
    assert "activeRacer:Destroy()" in harness


def test_r14_7_atomic_redraw_rolls_back_partial_commit_failure() -> None:
    runtime = read("src/server/Runtime/RacerRuntime.lua")
    studio_spec = read("src/server/Tests/B13AtomicRedrawSpec.lua")
    assert "commitOk" in runtime
    assert "commitError" in runtime
    assert 'oldLeftModel.Name = "LeftLeg"' in runtime
    assert 'oldRightModel.Name = "RightLeg"' in runtime
    assert "stagedLeftLeg:Destroy()" in runtime
    assert "stagedRightLeg:Destroy()" in runtime
    assert "local originalCommit = LegAssembly.Commit" in studio_spec
    assert "B13 injected right-leg commit failure" in studio_spec
    assert 'FindFirstChild("LeftLeg_Retiring") == nil' in studio_spec
    assert 'FindFirstChild("RightLeg_Retiring") == nil' in studio_spec


def test_r14_8_player_toast_maps_internal_reason_codes_to_copy() -> None:
    drawing = read("src/client/Controllers/DrawingController.lua")
    assert "validationMessageForReason" in drawing
    assert '"DRAW A DIFFERENT SHAPE"' in drawing
    assert '"TRY AGAIN"' in drawing
    assert "_setValidationReason" in drawing
    assert 'self:_setValidation(rejectReasonCode)' not in drawing
    assert 'self:_setValidation("TOO_FEW_POINTS")' not in drawing
    assert 'self:_setValidation("NETWORK_NOT_READY")' not in drawing


def test_r14_9_ci_builds_the_rojo_project_after_contract_checks() -> None:
    workflow = read(".github/workflows/contract-verify.yml")
    assert "paradoxum-games/setup-rokit@v3" in workflow
    assert "version: 1.1.0" in workflow
    assert "rokit install" in workflow
    assert "rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx" in workflow
    assert workflow.index("python verify.py") < workflow.index("rojo build default.project.json -o /tmp/DrawRacersDev.rbxlx")


def test_r14_10_stroke_types_own_network_payloads_and_runtime_debug_fields() -> None:
    stroke_types = read("src/shared/Types/StrokeTypes.lua")
    for token in [
        "export type SemanticPoint",
        "export type SemanticPoints",
        "export type SubmitStrokePayload",
        "export type StrokeResultPayload",
        "acceptedPoints",
        "rejectReasonCode",
        "debugRawPointCount",
        "debugPhysicsPointCount",
    ]:
        assert token in stroke_types, f"missing R14.10 StrokeTypes token: {token}"


def test_r14_10_active_remote_consumers_use_remote_names_registry() -> None:
    bootstrap = read("src/client/Bootstrap.client.lua")
    harness = read("src/server/Tests/M0HumanHarness.lua")
    for source in [bootstrap, harness]:
        assert 'WaitForChild("RemoteNames")' in source
        assert "RemoteNames.SubmitStroke" in source
        assert "RemoteNames.StrokeResult" in source


def test_r14_11_status_docs_record_code_closure_without_passing_human_gate() -> None:
    evidence_sha = "8a6a05a31427346d2a1437820ffa759f21fca90c"
    evidence_run = "34387618626"
    for path in ["README.md", "docs/README.md", "docs/SESSION.md", "docs/FEATURE_LIST.md"]:
        text = read(path)
        for token in [
            "R14.1–R14.11",
            evidence_sha,
            evidence_run,
            "120 passed, 0 failed",
            "Rojo build",
            "Studio checkpoints: HUMAN PENDING",
            "B17/G0",
            "HUMAN_GATE",
        ]:
            assert token in text, f"{path} missing R14.11 evidence token: {token}"
        assert "ACCEPTED — B17" not in text

    decision = read("docs/DECISION_LOG_PRE_G0_RUNTIME_CLOSURE_R14_2026-09-09.md")
    for task in range(1, 12):
        assert f"R14.{task}" in decision
    for token in [evidence_sha, evidence_run, "120 passed, 0 failed", "Rojo build", "HUMAN PENDING", "B17/G0"]:
        assert token in decision
    assert "ACCEPTED — B17" not in decision


def test_r14_11_architecture_marks_target_tree_as_non_authorizing_and_keeps_racer_service_d05() -> None:
    architecture = read("docs/21_SYSTEM_CLASS_ARCHITECTURE.md")
    for token in [
        "TARGET architecture",
        "does not authorize early implementation",
        "RacerService remains D05",
        "Studio-only injected resolver",
        "Do not implement RacerService before D05",
    ]:
        assert token in architecture, f"architecture missing R14.11 boundary: {token}"
